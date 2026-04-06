part of 'rest.dart';

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

  Map<String, Object?> toJson(Object? Function(T value) encodeData) {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
      'data': encodeData(data),
    };
  }

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

class BeamingKeyParams {
  final String keyId;
  final String? version;
  final String? localKeyId;

  const BeamingKeyParams({
    required this.keyId,
    this.version,
    this.localKeyId,
  });

  factory BeamingKeyParams.fromClientKey(BeamingClientKey key) {
    return BeamingKeyParams(
      keyId: key.keyId,
      version: key.version,
      localKeyId: key.localKeyId,
    );
  }

  factory BeamingKeyParams.fromJson(Map<String, Object?> json) {
    return BeamingKeyParams(
      keyId: _requireString(json, 'keyId'),
      version: json['version'] as String?,
      localKeyId: json['localKeyId'] as String?,
    );
  }

  BeamingClientKey toClientKey() {
    return BeamingClientKey(
      keyId: keyId,
      version: version,
      localKeyId: localKeyId,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'keyId': keyId,
      if (version != null) 'version': version,
      if (localKeyId != null) 'localKeyId': localKeyId,
    };
  }
}

class BeamingKeyValueParams {
  final BeamingKeyParams key;
  final String? value;

  const BeamingKeyValueParams({
    required this.key,
    this.value,
  });

  factory BeamingKeyValueParams.fromValue(BeamingValue value) {
    return BeamingKeyValueParams(
      key: BeamingKeyParams.fromClientKey(value.key),
      value: value.value,
    );
  }

  factory BeamingKeyValueParams.fromJson(Map<String, Object?> json) {
    return BeamingKeyValueParams(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      value: json['value'] as String?,
    );
  }

  BeamingValue toValue() {
    return BeamingValue(
      key: key.toClientKey(),
      value: value,
    );
  }

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
