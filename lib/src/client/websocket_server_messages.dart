// purpose: Define the inbound WebSocket messages emitted by the server.
// responsibilities: Decode subscribed, unsubscribed, pong, status, and event
// messages and serialize them back to the wire shape when needed.
// architecture notes: Server messages keep status and protocol details intact
// because those wire semantics are part of the client contract.
part of 'websocket.dart';

/// Base type for typed server-to-client WebSocket messages.
sealed class BeamingServerMessage {
  final String? id;
  final String kind;

  const BeamingServerMessage({
    required this.kind,
    this.id,
  });

  /// Decodes a typed server message from JSON.
  static BeamingServerMessage fromJson(Map<String, Object?> json) {
    final kind = _readRequiredString(json, 'kind');
    return switch (kind) {
      'subscribed' => BeamingSubscribedMessage.fromJson(json),
      'unsubscribed' => BeamingUnsubscribedMessage.fromJson(json),
      'pong' => BeamingPongMessage.fromJson(json),
      'status' => BeamingStatusMessage.fromJson(json),
      'event' => BeamingEventMessage.fromJson(json),
      _ => throw BeamingClientError(
          kind: BeamingClientErrorKind.protocolViolation,
          message: "Unsupported server message kind '$kind'.",
        ),
    };
  }

  /// Serializes the message to JSON.
  Map<String, Object?> toJson();
}

/// Acknowledgement that the server accepted a subscription request.
class BeamingSubscribedMessage extends BeamingServerMessage {
  final List<String> rootKeys;

  const BeamingSubscribedMessage({
    required this.rootKeys,
    super.id,
  }) : super(kind: 'subscribed');

  /// Decodes the message from JSON.
  factory BeamingSubscribedMessage.fromJson(Map<String, Object?> json) {
    final message = _readRootKeysMessage(json);
    return BeamingSubscribedMessage(
      id: message.id,
      rootKeys: message.rootKeys,
    );
  }

  /// Serializes the message to JSON.
  @override
  Map<String, Object?> toJson() {
    return _messageWithRootKeys(id, kind, rootKeys);
  }
}

/// Acknowledgement that the server updated the active subscription set.
class BeamingUnsubscribedMessage extends BeamingServerMessage {
  final List<String> rootKeys;

  const BeamingUnsubscribedMessage({
    required this.rootKeys,
    super.id,
  }) : super(kind: 'unsubscribed');

  /// Decodes the message from JSON.
  factory BeamingUnsubscribedMessage.fromJson(Map<String, Object?> json) {
    final message = _readRootKeysMessage(json);
    return BeamingUnsubscribedMessage(
      id: message.id,
      rootKeys: message.rootKeys,
    );
  }

  /// Serializes the message to JSON.
  @override
  Map<String, Object?> toJson() {
    return _messageWithRootKeys(id, kind, rootKeys);
  }
}

/// Pong reply returned by the server.
class BeamingPongMessage extends BeamingServerMessage {
  const BeamingPongMessage({
    super.id,
  }) : super(kind: 'pong');

  /// Decodes the message from JSON.
  factory BeamingPongMessage.fromJson(Map<String, Object?> json) {
    return BeamingPongMessage(
      id: json['id'] as String?,
    );
  }

  /// Serializes the message to JSON.
  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
    };
  }
}

/// Status message returned by the server for invalid or informational cases.
class BeamingStatusMessage extends BeamingServerMessage {
  final String status;
  final String? message;

  const BeamingStatusMessage({
    required this.status,
    this.message,
    super.id,
  }) : super(kind: 'status');

  /// Decodes the message from JSON.
  factory BeamingStatusMessage.fromJson(Map<String, Object?> json) {
    return BeamingStatusMessage(
      id: json['id'] as String?,
      status: _readRequiredString(json, 'status'),
      message: json['message'] as String?,
    );
  }

  /// Serializes the message to JSON.
  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
      'status': status,
      if (message != null) 'message': message,
    };
  }
}

/// Server message carrying an event envelope.
class BeamingEventMessage extends BeamingServerMessage {
  final BeamingEventEnvelope event;

  const BeamingEventMessage({
    required this.event,
  }) : super(kind: 'event');

  /// Decodes the message from JSON.
  factory BeamingEventMessage.fromJson(Map<String, Object?> json) {
    return BeamingEventMessage(
      event: BeamingEventEnvelope.fromJson(
        _readRequiredMap(json, 'event'),
      ),
    );
  }

  /// Serializes the message to JSON.
  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind,
      'event': event.toJson(),
    };
  }
}
