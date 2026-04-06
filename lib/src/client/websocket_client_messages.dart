// purpose: Define the outbound WebSocket commands sent by clients.
// responsibilities: Represent subscribe, unsubscribe, and ping messages and
// serialize them to the wire format.
// architecture notes: These message types stay small and explicit so command
// semantics are visible in the type system instead of hidden in raw maps.
part of 'websocket.dart';

/// Base type for typed client-to-server WebSocket messages.
sealed class BeamingClientMessage {
  final String? id;
  final String kind;

  const BeamingClientMessage({
    required this.kind,
    this.id,
  });

  /// Serializes the message to JSON.
  Map<String, Object?> toJson();
}

/// Subscribe command for one or more root keys.
class BeamingSubscribeMessage extends BeamingClientMessage {
  final List<String> rootKeys;

  const BeamingSubscribeMessage({
    required this.rootKeys,
    super.id,
  }) : super(kind: 'subscribe');

  /// Serializes the message to JSON.
  @override
  Map<String, Object?> toJson() {
    return _messageWithRootKeys(id, kind, rootKeys);
  }
}

/// Unsubscribe command for one or more root keys.
class BeamingUnsubscribeMessage extends BeamingClientMessage {
  final List<String> rootKeys;

  const BeamingUnsubscribeMessage({
    required this.rootKeys,
    super.id,
  }) : super(kind: 'unsubscribe');

  /// Serializes the message to JSON.
  @override
  Map<String, Object?> toJson() {
    return _messageWithRootKeys(id, kind, rootKeys);
  }
}

/// Ping command used to check session liveness.
class BeamingPingMessage extends BeamingClientMessage {
  const BeamingPingMessage({
    super.id,
  }) : super(kind: 'ping');

  /// Serializes the message to JSON.
  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
    };
  }
}
