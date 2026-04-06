/// purpose: Define the lightweight WebSocket protocol boundary so real-time
/// session messages can be encoded and decoded without hard-wiring a socket
/// implementation.
///
/// responsibilities: Describe client commands, server messages, event
/// envelopes, and protocol validation helpers for the event channel.
///
/// architecture notes: This is intentionally a thin protocol layer, not a
/// reconnecting transport stack, so higher-level recovery and policy stay
/// outside this file.
library;

import 'dart:async';

import 'error.dart';
import 'model.dart';

/// Optional light WebSocket session boundary.
abstract class BeamingYggdrasilWebSocketSession {
  /// Sends a typed client message over the session.
  Future<void> send(BeamingClientMessage message);

  /// Returns the decoded server message stream for this session.
  Stream<BeamingServerMessage> messages();

  /// Closes the session and releases any resources.
  Future<void> close();
}

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
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
      'rootKeys': rootKeys,
    };
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
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
      'rootKeys': rootKeys,
    };
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
    return BeamingSubscribedMessage(
      id: json['id'] as String?,
      rootKeys: _readStringList(json, 'rootKeys'),
    );
  }

  /// Serializes the message to JSON.
  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
      'rootKeys': rootKeys,
    };
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
    return BeamingUnsubscribedMessage(
      id: json['id'] as String?,
      rootKeys: _readStringList(json, 'rootKeys'),
    );
  }

  /// Serializes the message to JSON.
  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
      'rootKeys': rootKeys,
    };
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

/// Typed event payload transported over the WebSocket protocol.
class BeamingEventEnvelope {
  final String eventId;
  final BeamingClientKey rootKey;
  final String operation;
  final String created;
  final BeamingClientKey? key;
  final BeamingValue? keyValue;
  final String? snapshotVersion;

  const BeamingEventEnvelope({
    required this.eventId,
    required this.rootKey,
    required this.operation,
    required this.created,
    this.key,
    this.keyValue,
    this.snapshotVersion,
  });

  /// Creates a wire event from a public event object.
  factory BeamingEventEnvelope.fromEvent(
    BeamingEvent event, {
    required String eventId,
    required String created,
  }) {
    return switch (event) {
      BeamingSetEvent(:final rootKey, :final keyValue) => BeamingEventEnvelope(
          eventId: eventId,
          rootKey: rootKey,
          operation: 'set',
          created: created,
          key: keyValue.key,
          keyValue: keyValue,
        ),
      BeamingSnapshotReplacedEvent(:final rootKey, :final snapshotVersion) =>
        BeamingEventEnvelope(
          eventId: eventId,
          rootKey: rootKey,
          operation: 'snapshot-replaced',
          created: created,
          snapshotVersion: snapshotVersion,
        ),
    };
  }

  /// Decodes the wire event from JSON.
  factory BeamingEventEnvelope.fromJson(Map<String, Object?> json) {
    final operation = _readRequiredString(json, 'operation');
    return BeamingEventEnvelope(
      eventId: _readRequiredString(json, 'eventId'),
      rootKey: _readClientKey(json, 'rootKey'),
      operation: operation,
      created: _readRequiredString(json, 'created'),
      key: json.containsKey('key') ? _readClientKey(json, 'key') : null,
      keyValue:
          json.containsKey('keyValue') ? _readValue(json, 'keyValue') : null,
      snapshotVersion: json['snapshotVersion'] as String?,
    );
  }

  /// Converts the wire event back into the public event model.
  BeamingEvent toEvent() {
    return switch (operation) {
      'set' => BeamingSetEvent(
          rootKey: rootKey,
          keyValue: keyValue ?? _missingEventValue('keyValue'),
        ),
      'snapshot-replaced' => BeamingSnapshotReplacedEvent(
          rootKey: rootKey,
          snapshotVersion:
              snapshotVersion ?? _missingEventValue('snapshotVersion'),
        ),
      _ => throw BeamingClientError(
          kind: BeamingClientErrorKind.protocolViolation,
          message: "Unsupported event operation '$operation'.",
        ),
    };
  }

  /// Serializes the event envelope to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'eventId': eventId,
      'rootKey': _clientKeyToJson(rootKey),
      'operation': operation,
      'created': created,
      if (key != null) 'key': _clientKeyToJson(key!),
      if (keyValue != null) 'keyValue': _valueToJson(keyValue!),
      if (snapshotVersion != null) 'snapshotVersion': snapshotVersion,
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

Map<String, Object?> _clientKeyToJson(BeamingClientKey key) {
  return <String, Object?>{
    'keyId': key.keyId,
    if (key.version != null) 'version': key.version,
    if (key.localKeyId != null) 'localKeyId': key.localKeyId,
  };
}

Map<String, Object?> _valueToJson(BeamingValue value) {
  return <String, Object?>{
    'key': _clientKeyToJson(value.key),
    'value': value.value,
  };
}

BeamingClientKey _readClientKey(Map<String, Object?> json, String key) {
  final value = _readRequiredMap(json, key);
  return BeamingClientKey(
    keyId: _readRequiredString(value, 'keyId'),
    version: value['version'] as String?,
    localKeyId: value['localKeyId'] as String?,
  );
}

BeamingValue _readValue(Map<String, Object?> json, String key) {
  final value = _readRequiredMap(json, key);
  return BeamingValue(
    key: _readClientKey(value, 'key'),
    value: value['value'] as String?,
  );
}

Map<String, Object?> _readRequiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw BeamingClientError(
    kind: BeamingClientErrorKind.protocolViolation,
    message: "Expected '$key' to be an object.",
  );
}

String _readRequiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw BeamingClientError(
    kind: BeamingClientErrorKind.protocolViolation,
    message: "Expected '$key' to be a non-empty string.",
  );
}

List<String> _readStringList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return const <String>[];
  }
  if (value is! List) {
    throw BeamingClientError(
      kind: BeamingClientErrorKind.protocolViolation,
      message: "Expected '$key' to be a list.",
    );
  }
  return List<String>.unmodifiable(
    value.map((item) {
      if (item is String) {
        return item;
      }
      throw BeamingClientError(
        kind: BeamingClientErrorKind.protocolViolation,
        message: "Expected '$key' items to be strings.",
      );
    }),
  );
}

Never _missingEventValue(String fieldName) {
  throw BeamingClientError(
    kind: BeamingClientErrorKind.protocolViolation,
    message: "Missing required event field '$fieldName'.",
  );
}
