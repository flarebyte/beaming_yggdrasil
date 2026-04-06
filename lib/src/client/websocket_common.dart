// purpose: Hold the shared protocol helpers used across the WebSocket part
// files.
// responsibilities: Read and write common JSON shapes, parse root-key message
// payloads, and validate required protocol fields.
// architecture notes: These helpers stay private to the library so the public
// protocol surface remains small and typed.
part of 'websocket.dart';

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

({String? id, List<String> rootKeys}) _readRootKeysMessage(
  Map<String, Object?> json,
) {
  return (
    id: json['id'] as String?,
    rootKeys: _readStringList(json, 'rootKeys'),
  );
}

Map<String, Object?> _messageWithRootKeys(
  String? id,
  String kind,
  List<String> rootKeys,
) {
  return <String, Object?>{
    if (id != null) 'id': id,
    'kind': kind,
    'rootKeys': rootKeys,
  };
}
