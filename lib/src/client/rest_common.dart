/// purpose: Hold the shared REST wire primitives and decoding helpers used by
/// both request and response DTOs.
///
/// responsibilities: Encode and decode envelopes, keys, key-values, lists, and
/// required scalar fields for REST models.
///
/// architecture notes: The helpers stay library-private so decoding rules
/// remain consistent across DTOs without becoming part of the public API
/// surface.
part of 'rest.dart';

/// Generic REST envelope with status, message, and typed data payload.
class BeamingRestEnvelope<T> {
  final String? id;
  final String? status;
  final String? message;
  final T data;

  const BeamingRestEnvelope({
    required this.data,
    this.id,
    this.status,
    this.message,
  });

  /// Serializes the envelope while delegating the data payload encoding.
  Map<String, Object?> toJson(Object? Function(T value) encodeData) {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
      'data': encodeData(data),
    };
  }

  /// Decodes an envelope using the supplied typed payload decoder.
  static BeamingRestEnvelope<T> fromJson<T>(
    Map<String, Object?> json,
    T Function(Map<String, Object?> json) decodeData,
  ) {
    return BeamingRestEnvelope<T>(
      id: json['id'] as String?,
      status: json['status'] as String?,
      message: json['message'] as String?,
      data: decodeData(_readMap(json, 'data')),
    );
  }
}

/// Wire-level key representation shared by REST requests and responses.
class BeamingKeyParams {
  final String keyId;
  final String? version;
  final String? localKeyId;

  const BeamingKeyParams({
    required this.keyId,
    this.version,
    this.localKeyId,
  });

  /// Creates wire params from a public client key.
  factory BeamingKeyParams.fromClientKey(BeamingClientKey key) {
    return BeamingKeyParams(
      keyId: key.keyId,
      version: key.version,
      localKeyId: key.localKeyId,
    );
  }

  /// Decodes wire params from JSON.
  factory BeamingKeyParams.fromJson(Map<String, Object?> json) {
    return BeamingKeyParams(
      keyId: _requireString(json, 'keyId'),
      version: json['version'] as String?,
      localKeyId: json['localKeyId'] as String?,
    );
  }

  /// Converts wire params back into the public key type.
  BeamingClientKey toClientKey() {
    return BeamingClientKey(
      keyId: keyId,
      version: version,
      localKeyId: localKeyId,
    );
  }

  /// Serializes the key params to the wire shape.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'keyId': keyId,
      if (version != null) 'version': version,
      if (localKeyId != null) 'localKeyId': localKeyId,
    };
  }
}

/// Wire-level key and string value pair.
class BeamingKeyValueParams {
  final BeamingKeyParams key;
  final String? value;

  const BeamingKeyValueParams({
    required this.key,
    this.value,
  });

  /// Creates wire params from a public value object.
  factory BeamingKeyValueParams.fromValue(BeamingValue value) {
    return BeamingKeyValueParams(
      key: BeamingKeyParams.fromClientKey(value.key),
      value: value.value,
    );
  }

  /// Decodes a key and value pair from JSON.
  factory BeamingKeyValueParams.fromJson(Map<String, Object?> json) {
    return BeamingKeyValueParams(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      value: json['value'] as String?,
    );
  }

  /// Converts wire params back into the public value type.
  BeamingValue toValue() {
    return BeamingValue(
      key: key.toClientKey(),
      value: value,
    );
  }

  /// Serializes the key and value pair to the wire shape.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
      'value': value,
    };
  }
}

Map<String, Object?> _readMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw BeamingClientError(
    kind: BeamingClientErrorKind.invalidResponse,
    message: "Expected '$key' to be an object.",
  );
}

List<T> _readList<T>(
  Map<String, Object?> json,
  String key,
  T Function(Map<String, Object?> json) decodeItem,
) {
  final value = json[key];
  if (value is! List) {
    throw BeamingClientError(
      kind: BeamingClientErrorKind.invalidResponse,
      message: "Expected '$key' to be a list.",
    );
  }
  return List<T>.unmodifiable(
    value.map((item) {
      if (item is Map<String, Object?>) {
        return decodeItem(item);
      }
      if (item is Map) {
        return decodeItem(item.cast<String, Object?>());
      }
      throw BeamingClientError(
        kind: BeamingClientErrorKind.invalidResponse,
        message: "Expected '$key' items to be objects.",
      );
    }),
  );
}

String _requireString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw BeamingClientError(
    kind: BeamingClientErrorKind.invalidResponse,
    message: "Expected '$key' to be a non-empty string.",
  );
}
