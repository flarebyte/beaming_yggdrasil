import 'dart:async';

import 'error.dart';
import 'model.dart';

/// Optional light WebSocket session boundary.
abstract class BeamingYggdrasilWebSocketSession {
  Future<void> send(BeamingClientMessage message);

  Stream<BeamingServerMessage> messages();

  Future<void> close();
}

sealed class BeamingClientMessage {
  final String? id;
  final String kind;

  const BeamingClientMessage({
    required this.kind,
    this.id,
  });

  Map<String, Object?> toJson();
}

class BeamingSubscribeMessage extends BeamingClientMessage {
  final List<String> rootKeys;

  const BeamingSubscribeMessage({
    required this.rootKeys,
    super.id,
  }) : super(kind: 'subscribe');

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
      'rootKeys': rootKeys,
    };
  }
}

class BeamingUnsubscribeMessage extends BeamingClientMessage {
  final List<String> rootKeys;

  const BeamingUnsubscribeMessage({
    required this.rootKeys,
    super.id,
  }) : super(kind: 'unsubscribe');

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
      'rootKeys': rootKeys,
    };
  }
}

class BeamingPingMessage extends BeamingClientMessage {
  const BeamingPingMessage({
    super.id,
  }) : super(kind: 'ping');

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
    };
  }
}

sealed class BeamingServerMessage {
  final String? id;
  final String kind;

  const BeamingServerMessage({
    required this.kind,
    this.id,
  });

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

  Map<String, Object?> toJson();
}

class BeamingSubscribedMessage extends BeamingServerMessage {
  final List<String> rootKeys;

  const BeamingSubscribedMessage({
    required this.rootKeys,
    super.id,
  }) : super(kind: 'subscribed');

  factory BeamingSubscribedMessage.fromJson(Map<String, Object?> json) {
    return BeamingSubscribedMessage(
      id: json['id'] as String?,
      rootKeys: _readStringList(json, 'rootKeys'),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
      'rootKeys': rootKeys,
    };
  }
}

class BeamingUnsubscribedMessage extends BeamingServerMessage {
  final List<String> rootKeys;

  const BeamingUnsubscribedMessage({
    required this.rootKeys,
    super.id,
  }) : super(kind: 'unsubscribed');

  factory BeamingUnsubscribedMessage.fromJson(Map<String, Object?> json) {
    return BeamingUnsubscribedMessage(
      id: json['id'] as String?,
      rootKeys: _readStringList(json, 'rootKeys'),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
      'rootKeys': rootKeys,
    };
  }
}

class BeamingPongMessage extends BeamingServerMessage {
  const BeamingPongMessage({
    super.id,
  }) : super(kind: 'pong');

  factory BeamingPongMessage.fromJson(Map<String, Object?> json) {
    return BeamingPongMessage(
      id: json['id'] as String?,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'kind': kind,
    };
  }
}

class BeamingStatusMessage extends BeamingServerMessage {
  final String status;
  final String? message;

  const BeamingStatusMessage({
    required this.status,
    this.message,
    super.id,
  }) : super(kind: 'status');

  factory BeamingStatusMessage.fromJson(Map<String, Object?> json) {
    return BeamingStatusMessage(
      id: json['id'] as String?,
      status: _readRequiredString(json, 'status'),
      message: json['message'] as String?,
    );
  }

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

class BeamingEventMessage extends BeamingServerMessage {
  final BeamingEventEnvelope event;

  const BeamingEventMessage({
    required this.event,
  }) : super(kind: 'event');

  factory BeamingEventMessage.fromJson(Map<String, Object?> json) {
    return BeamingEventMessage(
      event: BeamingEventEnvelope.fromJson(
        _readRequiredMap(json, 'event'),
      ),
    );
  }

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
