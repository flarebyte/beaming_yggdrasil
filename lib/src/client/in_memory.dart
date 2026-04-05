import 'dart:async';

import 'client.dart';
import 'model.dart';
import 'testing_client.dart';

/// Small in-memory harness for early consumer workflow testing.
///
/// This is intentionally not a production transport implementation. It exists
/// to validate the public API shape and the first useful workflow without
/// committing to HTTP or WebSocket internals too early.
class BeamingInMemoryHarness {
  final BeamingYggdrasilClient client;
  final BeamingYggdrasilTestingClient testingClient;

  final _InMemoryState _state;

  BeamingInMemoryHarness._(
    this.client,
    this.testingClient,
    this._state,
  );

  factory BeamingInMemoryHarness() {
    final state = _InMemoryState();
    return BeamingInMemoryHarness._(
      _InMemoryClient(state),
      _InMemoryTestingClient(state),
      state,
    );
  }

  Future<void> close() => _state.close();
}

BeamingInMemoryHarness createBeamingInMemoryHarness() =>
    BeamingInMemoryHarness();

class _InMemoryClient implements BeamingYggdrasilClient {
  final _InMemoryState _state;

  _InMemoryClient(this._state);

  @override
  Future<List<BeamingWriteResult>> createChildren(
    String rootKeyId,
    List<BeamingClientKey> provisionalKeys,
  ) async {
    return List<BeamingWriteResult>.unmodifiable(
      provisionalKeys
          .map(
            (key) => BeamingWriteResult(
              key: key,
              status: 'ok',
            ),
          )
          .toList(),
    );
  }

  @override
  Future<List<BeamingValue>> getNode(
      String rootKeyId, List<String> keyIds) async {
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
    return _state.snapshotValues(rootKeyId);
  }

  @override
  Future<List<BeamingWriteResult>> setNode(
    String rootKeyId,
    List<BeamingValue> values,
  ) async {
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
    _state.replaceSnapshot(rootKeyId, values);
  }
}

class _InMemoryState {
  final StreamController<BeamingEvent> _events =
      StreamController<BeamingEvent>.broadcast();
  final Map<String, List<BeamingValue>> _snapshots = {};
  final Map<String, int> _snapshotCounters = {};

  Stream<BeamingEvent> get events => _events.stream;

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
}
