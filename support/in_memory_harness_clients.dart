// purpose: Implement the fake classic client, testing client, and WebSocket
// session used by the support harness.
// responsibilities: Delegate read and write behavior into shared state and
// translate support events into typed client and WebSocket flows.
// architecture notes: The fake clients are intentionally deterministic and
// side-effect light so tests can exercise the public API without real
// transport.
part of 'in_memory_harness.dart';

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
