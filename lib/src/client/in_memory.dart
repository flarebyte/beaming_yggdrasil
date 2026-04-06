/// purpose: Provide an in-memory harness that exercises the public client
/// contracts early without pretending to be the production HTTP or WebSocket
/// implementation.
///
/// responsibilities: Seed snapshots, apply node writes, emit events, expose
/// classic and Rx clients, and offer lightweight diagnostics-aware test
/// scaffolding.
///
/// architecture notes: This file intentionally validates API shape and
/// deterministic workflows rather than modeling real transport internals, so do
/// not treat it as the production backend adapter.
library;

import 'dart:async';

import 'client.dart';
import 'diagnostics.dart';
import 'model.dart';
import 'rx_client.dart';
import 'testing_client.dart';
import 'websocket.dart';

/// Small in-memory harness for early consumer workflow testing.
///
/// This is intentionally not a production transport implementation. It exists
/// to validate the public API shape and the first useful workflow without
/// committing to HTTP or WebSocket internals too early.
class BeamingInMemoryHarness {
  final BeamingYggdrasilClient client;
  final BeamingYggdrasilRxClient rxClient;
  final BeamingYggdrasilTestingClient testingClient;
  final BeamingYggdrasilWebSocketSession webSocketSession;

  final _InMemoryState _state;

  BeamingInMemoryHarness._(
    this.client,
    this.rxClient,
    this.testingClient,
    this.webSocketSession,
    this._state,
  );

  factory BeamingInMemoryHarness() {
    return BeamingInMemoryHarness.withDiagnostics();
  }

  factory BeamingInMemoryHarness.withDiagnostics({
    BeamingDiagnosticsHook? diagnosticsHook,
    BeamingDiagnosticsRedactor? diagnosticsRedactor,
  }) {
    final state = _InMemoryState(
      diagnosticsHook: diagnosticsHook,
      diagnosticsRedactor: diagnosticsRedactor,
    );
    final client = _InMemoryClient(state);
    return BeamingInMemoryHarness._(
      client,
      BeamingClassicRxClient(client),
      _InMemoryTestingClient(state),
      _InMemoryWebSocketSession(state),
      state,
    );
  }

  /// Closes the harness and releases its internal controllers.
  Future<void> close() => _state.close();
}

/// Creates a diagnostics-aware in-memory harness for examples and tests.
BeamingInMemoryHarness createBeamingInMemoryHarness({
  BeamingDiagnosticsHook? diagnosticsHook,
  BeamingDiagnosticsRedactor? diagnosticsRedactor,
}) =>
    BeamingInMemoryHarness.withDiagnostics(
      diagnosticsHook: diagnosticsHook,
      diagnosticsRedactor: diagnosticsRedactor,
    );

class _InMemoryClient implements BeamingYggdrasilClient {
  final _InMemoryState _state;

  _InMemoryClient(this._state);

  @override
  Future<List<BeamingWriteResult>> createChildren(
    String rootKeyId,
    List<BeamingClientKey> provisionalKeys,
  ) async {
    _state.emitRequest(
      'createChildren',
      <String, Object?>{
        'rootKeyId': rootKeyId,
        'count': provisionalKeys.length,
      },
    );
    return _state.createChildren(rootKeyId, provisionalKeys);
  }

  @override
  Future<List<BeamingValue>> getNode(
      String rootKeyId, List<String> keyIds) async {
    _state.emitRequest(
      'getNode',
      <String, Object?>{
        'rootKeyId': rootKeyId,
        'keyIds': keyIds,
      },
    );
    final snapshot = _state.snapshotValues(rootKeyId);
    final byKeyId = {
      for (final value in snapshot) value.key.keyId: value,
    };
    return List<BeamingValue>.unmodifiable(
      keyIds.map((keyId) => byKeyId[keyId]).whereType<BeamingValue>().toList(),
    );
  }

  @override
  Future<List<BeamingValue>> getSnapshot(String rootKeyId) async {
    _state.emitRequest(
      'getSnapshot',
      <String, Object?>{'rootKeyId': rootKeyId},
    );
    return _state.snapshotValues(rootKeyId);
  }

  @override
  Future<List<BeamingWriteResult>> setNode(
    String rootKeyId,
    List<BeamingValue> values,
  ) async {
    _state.emitRequest(
      'setNode',
      <String, Object?>{
        'rootKeyId': rootKeyId,
        'count': values.length,
      },
    );
    _state.applyNodeValues(rootKeyId, values);
    return List<BeamingWriteResult>.unmodifiable(
      values
          .map(
            (value) => BeamingWriteResult(
              key: value.key,
              status: 'ok',
            ),
          )
          .toList(),
    );
  }

  @override
  Stream<BeamingEvent> watch(List<String> rootKeyIds) {
    _state.emitSession(
      'watch',
      <String, Object?>{'rootKeyIds': rootKeyIds},
    );
    final allowed = Set<String>.from(rootKeyIds);
    return _state.events.where((event) {
      return switch (event) {
        BeamingSetEvent(:final rootKey) => allowed.contains(rootKey.keyId),
        BeamingSnapshotReplacedEvent(:final rootKey) =>
          allowed.contains(rootKey.keyId),
      };
    });
  }
}

class _InMemoryTestingClient implements BeamingYggdrasilTestingClient {
  final _InMemoryState _state;

  _InMemoryTestingClient(this._state);

  @override
  Future<void> replaceSnapshot(
    String rootKeyId,
    List<BeamingValue> values,
  ) async {
    _state.emitRequest(
      'replaceSnapshot',
      <String, Object?>{
        'rootKeyId': rootKeyId,
        'count': values.length,
      },
    );
    _state.replaceSnapshot(rootKeyId, values);
  }
}

class _InMemoryWebSocketSession implements BeamingYggdrasilWebSocketSession {
  final _InMemoryState _state;
  final StreamController<BeamingServerMessage> _messages =
      StreamController<BeamingServerMessage>.broadcast();
  final Set<String> _subscribedRootKeys = <String>{};
  late final StreamSubscription<BeamingEvent> _eventSubscription;

  _InMemoryWebSocketSession(this._state) {
    _eventSubscription = _state.events.listen((event) {
      final rootKeyId = switch (event) {
        BeamingSetEvent(:final rootKey) => rootKey.keyId,
        BeamingSnapshotReplacedEvent(:final rootKey) => rootKey.keyId,
      };
      if (_subscribedRootKeys.contains(rootKeyId)) {
        _messages.add(
          BeamingEventMessage(
            event: BeamingEventEnvelope.fromEvent(
              event,
              eventId: _state.nextEventId(),
              created: _state.nextCreatedMarker(),
            ),
          ),
        );
      }
    });
  }

  @override
  Future<void> close() async {
    await _eventSubscription.cancel();
    await _messages.close();
  }

  @override
  Stream<BeamingServerMessage> messages() => _messages.stream;

  @override
  Future<void> send(BeamingClientMessage message) async {
    switch (message) {
      case BeamingSubscribeMessage(:final rootKeys, :final id):
        _state.emitSession(
          'subscribe',
          <String, Object?>{
            'id': id,
            'rootKeys': rootKeys,
          },
        );
        _subscribedRootKeys.addAll(rootKeys);
        _messages.add(
          BeamingSubscribedMessage(
            id: id,
            rootKeys: _subscribedRootKeys.toList()..sort(),
          ),
        );
      case BeamingUnsubscribeMessage(:final rootKeys, :final id):
        _state.emitSession(
          'unsubscribe',
          <String, Object?>{
            'id': id,
            'rootKeys': rootKeys,
          },
        );
        _subscribedRootKeys.removeAll(rootKeys);
        _messages.add(
          BeamingUnsubscribedMessage(
            id: id,
            rootKeys: _subscribedRootKeys.toList()..sort(),
          ),
        );
      case BeamingPingMessage(:final id):
        _state.emitSession(
          'ping',
          <String, Object?>{'id': id},
        );
        _messages.add(BeamingPongMessage(id: id));
    }
  }
}

class _InMemoryState {
  final StreamController<BeamingEvent> _events =
      StreamController<BeamingEvent>.broadcast();
  final Map<String, List<BeamingValue>> _snapshots = {};
  final Map<String, int> _snapshotCounters = {};
  final BeamingDiagnosticsHook? _diagnosticsHook;
  final BeamingDiagnosticsRedactor _diagnosticsRedactor;
  int _eventCounter = 0;

  _InMemoryState({
    BeamingDiagnosticsHook? diagnosticsHook,
    BeamingDiagnosticsRedactor? diagnosticsRedactor,
  })  : _diagnosticsHook = diagnosticsHook,
        _diagnosticsRedactor = diagnosticsRedactor ?? _identityDiagnostics;

  Stream<BeamingEvent> get events => _events.stream;

  void emitError(String action, Object error) {
    _emitDiagnostic(
      BeamingDiagnosticEvent(
        kind: BeamingDiagnosticEventKind.error,
        action: action,
        details: <String, Object?>{
          'error': error.toString(),
        },
      ),
    );
  }

  void emitRequest(String action, Map<String, Object?> details) {
    _emitDiagnostic(
      BeamingDiagnosticEvent(
        kind: BeamingDiagnosticEventKind.request,
        action: action,
        details: details,
      ),
    );
  }

  void emitSession(String action, Map<String, Object?> details) {
    _emitDiagnostic(
      BeamingDiagnosticEvent(
        kind: BeamingDiagnosticEventKind.session,
        action: action,
        details: details,
      ),
    );
  }

  Future<List<BeamingWriteResult>> createChildren(
    String rootKeyId,
    List<BeamingClientKey> provisionalKeys,
  ) async {
    final results = List<BeamingWriteResult>.unmodifiable(
      provisionalKeys.map((key) => _createChild(rootKeyId, key)).toList(),
    );
    if (results.any((result) => result.status != 'ok')) {
      emitError('createChildren', 'partial failure');
    }
    return results;
  }

  void applyNodeValues(String rootKeyId, List<BeamingValue> values) {
    final current = List<BeamingValue>.from(_snapshots[rootKeyId] ?? const []);
    for (final value in values) {
      final index = current.indexWhere(
        (existing) => existing.key.keyId == value.key.keyId,
      );
      if (index == -1) {
        current.add(value);
      } else {
        current[index] = value;
      }
      _events.add(
        BeamingSetEvent(
          rootKey: BeamingClientKey(keyId: rootKeyId),
          keyValue: value,
        ),
      );
    }
    _snapshots[rootKeyId] = List<BeamingValue>.unmodifiable(current);
  }

  Future<void> close() async {
    await _events.close();
  }

  BeamingWriteResult _createChild(String rootKeyId, BeamingClientKey key) {
    if (key.localKeyId == null || key.localKeyId!.trim().isEmpty) {
      return BeamingWriteResult(
        key: key,
        status: 'invalid',
        message: 'localKeyId is required for createChildren',
      );
    }
    if (!_isChildKey(rootKeyId, key.keyId)) {
      return BeamingWriteResult(
        key: key,
        status: 'invalid',
        message: 'created keys must be children of the root key',
      );
    }
    return BeamingWriteResult(
      key: BeamingClientKey(
        keyId: key.keyId,
        version: key.version ?? 'created:${key.localKeyId}',
        localKeyId: key.localKeyId,
      ),
      status: 'ok',
    );
  }

  void replaceSnapshot(String rootKeyId, List<BeamingValue> values) {
    final nextCounter = (_snapshotCounters[rootKeyId] ?? 0) + 1;
    _snapshotCounters[rootKeyId] = nextCounter;
    final snapshotVersion = 'snapshot-$nextCounter';
    _snapshots[rootKeyId] = List<BeamingValue>.unmodifiable(values);
    _events.add(
      BeamingSnapshotReplacedEvent(
        rootKey: BeamingClientKey(
          keyId: rootKeyId,
          version: snapshotVersion,
        ),
        snapshotVersion: snapshotVersion,
      ),
    );
  }

  List<BeamingValue> snapshotValues(String rootKeyId) {
    return List<BeamingValue>.unmodifiable(_snapshots[rootKeyId] ?? const []);
  }

  bool _isChildKey(String rootKeyId, String keyId) {
    return keyId.startsWith('$rootKeyId/');
  }

  void _emitDiagnostic(BeamingDiagnosticEvent event) {
    final hook = _diagnosticsHook;
    if (hook == null) {
      return;
    }
    try {
      hook(_diagnosticsRedactor(event));
    } catch (_) {
      // Diagnostics must not break core client behavior.
    }
  }

  String nextCreatedMarker() {
    return 'created-$_eventCounter';
  }

  String nextEventId() {
    _eventCounter += 1;
    return 'event-$_eventCounter';
  }
}

BeamingDiagnosticEvent _identityDiagnostics(BeamingDiagnosticEvent event) =>
    event;
