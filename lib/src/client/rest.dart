import 'model.dart';

/// Transport-facing REST client boundary.
///
/// This keeps the wire DTO layer explicit without committing the main public
/// client surface to any specific HTTP package yet.
abstract class BeamingYggdrasilRestClient {
  Future<BeamingRestEnvelope<BeamingGetSnapshotResponseData>> getSnapshot(
    BeamingGetSnapshotRequest request,
  );

  Future<BeamingRestEnvelope<BeamingSetKeyValueResponseData>> setNode(
    BeamingSetKeyValueRequest request,
  );

  Future<BeamingRestEnvelope<BeamingGetKeyValueResponseData>> getNode(
    BeamingGetKeyValueRequest request,
  );

  Future<BeamingRestEnvelope<BeamingNewKeysResponseData>> create(
    BeamingNewKeysRequest request,
  );
}

/// Test-only REST boundary for mock snapshot seeding.
abstract class BeamingYggdrasilTestingRestClient {
  Future<BeamingRestEnvelope<BeamingSetSnapshotResponseData>> setSnapshot(
    BeamingSetSnapshotRequest request,
  );
}

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

class BeamingSetSnapshotRequest {
  final String? id;
  final BeamingKeyParams key;
  final List<BeamingKeyValueParams> keyValueList;

  const BeamingSetSnapshotRequest({
    required this.key,
    required this.keyValueList,
    this.id,
  });

  factory BeamingSetSnapshotRequest.fromJson(Map<String, Object?> json) {
    return BeamingSetSnapshotRequest(
      id: json['id'] as String?,
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      keyValueList:
          _readList(json, 'keyValueList', BeamingKeyValueParams.fromJson),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'key': key.toJson(),
      'keyValueList': keyValueList.map((value) => value.toJson()).toList(),
    };
  }
}

class BeamingGetSnapshotRequest {
  final String? id;
  final BeamingKeyParams key;

  const BeamingGetSnapshotRequest({
    required this.key,
    this.id,
  });

  factory BeamingGetSnapshotRequest.fromJson(Map<String, Object?> json) {
    return BeamingGetSnapshotRequest(
      id: json['id'] as String?,
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'key': key.toJson(),
    };
  }
}

class BeamingSetKeyValueRequest {
  final String? id;
  final BeamingKeyParams rootKey;
  final List<BeamingKeyValueParams> keyValueList;

  const BeamingSetKeyValueRequest({
    required this.rootKey,
    required this.keyValueList,
    this.id,
  });

  factory BeamingSetKeyValueRequest.fromJson(Map<String, Object?> json) {
    return BeamingSetKeyValueRequest(
      id: json['id'] as String?,
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      keyValueList:
          _readList(json, 'keyValueList', BeamingKeyValueParams.fromJson),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'rootKey': rootKey.toJson(),
      'keyValueList': keyValueList.map((value) => value.toJson()).toList(),
    };
  }
}

class BeamingGetKeyValueRequest {
  final String? id;
  final BeamingKeyParams rootKey;
  final List<BeamingKeyParams> keyList;

  const BeamingGetKeyValueRequest({
    required this.rootKey,
    required this.keyList,
    this.id,
  });

  factory BeamingGetKeyValueRequest.fromJson(Map<String, Object?> json) {
    return BeamingGetKeyValueRequest(
      id: json['id'] as String?,
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      keyList: _readList(json, 'keyList', BeamingKeyParams.fromJson),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'rootKey': rootKey.toJson(),
      'keyList': keyList.map((value) => value.toJson()).toList(),
    };
  }
}

class BeamingNewKeyChildRequest {
  final String localKeyId;
  final String expectedKind;

  const BeamingNewKeyChildRequest({
    required this.localKeyId,
    required this.expectedKind,
  });

  factory BeamingNewKeyChildRequest.fromJson(Map<String, Object?> json) {
    return BeamingNewKeyChildRequest(
      localKeyId: _requireString(json, 'localKeyId'),
      expectedKind: _requireString(json, 'expectedKind'),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'localKeyId': localKeyId,
      'expectedKind': expectedKind,
    };
  }
}

class BeamingNewKeyRequest {
  final BeamingKeyParams key;
  final String expectedKind;
  final List<BeamingNewKeyChildRequest> children;

  const BeamingNewKeyRequest({
    required this.key,
    required this.expectedKind,
    required this.children,
  });

  factory BeamingNewKeyRequest.fromJson(Map<String, Object?> json) {
    return BeamingNewKeyRequest(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      expectedKind: _requireString(json, 'expectedKind'),
      children: _readList(json, 'children', BeamingNewKeyChildRequest.fromJson),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
      'expectedKind': expectedKind,
      'children': children.map((value) => value.toJson()).toList(),
    };
  }
}

class BeamingNewKeysRequest {
  final String? id;
  final BeamingKeyParams rootKey;
  final List<BeamingNewKeyRequest> newKeys;

  const BeamingNewKeysRequest({
    required this.rootKey,
    required this.newKeys,
    this.id,
  });

  factory BeamingNewKeysRequest.fromJson(Map<String, Object?> json) {
    return BeamingNewKeysRequest(
      id: json['id'] as String?,
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      newKeys: _readList(json, 'newKeys', BeamingNewKeyRequest.fromJson),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'rootKey': rootKey.toJson(),
      'newKeys': newKeys.map((value) => value.toJson()).toList(),
    };
  }
}

class BeamingSetSnapshotResponseData {
  final BeamingKeyParams key;

  const BeamingSetSnapshotResponseData({
    required this.key,
  });

  factory BeamingSetSnapshotResponseData.fromJson(Map<String, Object?> json) {
    return BeamingSetSnapshotResponseData(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
    };
  }
}

class BeamingGetSnapshotResponseData {
  final BeamingKeyParams key;
  final List<BeamingKeyValueParams> keyValueList;

  const BeamingGetSnapshotResponseData({
    required this.key,
    required this.keyValueList,
  });

  factory BeamingGetSnapshotResponseData.fromJson(Map<String, Object?> json) {
    return BeamingGetSnapshotResponseData(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      keyValueList:
          _readList(json, 'keyValueList', BeamingKeyValueParams.fromJson),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
      'keyValueList': keyValueList.map((value) => value.toJson()).toList(),
    };
  }
}

class BeamingStatusKeyItem {
  final BeamingKeyParams key;
  final String status;
  final String? message;

  const BeamingStatusKeyItem({
    required this.key,
    required this.status,
    this.message,
  });

  factory BeamingStatusKeyItem.fromJson(Map<String, Object?> json) {
    return BeamingStatusKeyItem(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      status: _requireString(json, 'status'),
      message: json['message'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
      'status': status,
      if (message != null) 'message': message,
    };
  }
}

class BeamingStatusKeyValueItem {
  final BeamingKeyValueParams keyValue;
  final String status;
  final String? message;

  const BeamingStatusKeyValueItem({
    required this.keyValue,
    required this.status,
    this.message,
  });

  factory BeamingStatusKeyValueItem.fromJson(Map<String, Object?> json) {
    return BeamingStatusKeyValueItem(
      keyValue: BeamingKeyValueParams.fromJson(_readMap(json, 'keyValue')),
      status: _requireString(json, 'status'),
      message: json['message'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'keyValue': keyValue.toJson(),
      'status': status,
      if (message != null) 'message': message,
    };
  }
}

class BeamingSetKeyValueResponseData {
  final BeamingKeyParams rootKey;
  final List<BeamingStatusKeyItem> keyList;

  const BeamingSetKeyValueResponseData({
    required this.rootKey,
    required this.keyList,
  });

  factory BeamingSetKeyValueResponseData.fromJson(Map<String, Object?> json) {
    return BeamingSetKeyValueResponseData(
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      keyList: _readList(json, 'keyList', BeamingStatusKeyItem.fromJson),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'rootKey': rootKey.toJson(),
      'keyList': keyList.map((value) => value.toJson()).toList(),
    };
  }
}

class BeamingGetKeyValueResponseData {
  final BeamingKeyParams rootKey;
  final List<BeamingStatusKeyValueItem> keyValueList;

  const BeamingGetKeyValueResponseData({
    required this.rootKey,
    required this.keyValueList,
  });

  factory BeamingGetKeyValueResponseData.fromJson(Map<String, Object?> json) {
    return BeamingGetKeyValueResponseData(
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      keyValueList:
          _readList(json, 'keyValueList', BeamingStatusKeyValueItem.fromJson),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'rootKey': rootKey.toJson(),
      'keyValueList': keyValueList.map((value) => value.toJson()).toList(),
    };
  }
}

class BeamingNewKeyChildResponse {
  final BeamingKeyParams key;
  final String status;
  final String? message;

  const BeamingNewKeyChildResponse({
    required this.key,
    required this.status,
    this.message,
  });

  factory BeamingNewKeyChildResponse.fromJson(Map<String, Object?> json) {
    return BeamingNewKeyChildResponse(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      status: _requireString(json, 'status'),
      message: json['message'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
      'status': status,
      if (message != null) 'message': message,
    };
  }
}

class BeamingNewKeyResponse {
  final BeamingKeyParams key;
  final String status;
  final String? message;
  final List<BeamingNewKeyChildResponse> children;

  const BeamingNewKeyResponse({
    required this.key,
    required this.status,
    required this.children,
    this.message,
  });

  factory BeamingNewKeyResponse.fromJson(Map<String, Object?> json) {
    return BeamingNewKeyResponse(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      status: _requireString(json, 'status'),
      message: json['message'] as String?,
      children:
          _readList(json, 'children', BeamingNewKeyChildResponse.fromJson),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
      'status': status,
      if (message != null) 'message': message,
      'children': children.map((value) => value.toJson()).toList(),
    };
  }
}

class BeamingNewKeysResponseData {
  final BeamingKeyParams rootKey;
  final List<BeamingNewKeyResponse> newKeys;

  const BeamingNewKeysResponseData({
    required this.rootKey,
    required this.newKeys,
  });

  factory BeamingNewKeysResponseData.fromJson(Map<String, Object?> json) {
    return BeamingNewKeysResponseData(
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      newKeys: _readList(json, 'newKeys', BeamingNewKeyResponse.fromJson),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'rootKey': rootKey.toJson(),
      'newKeys': newKeys.map((value) => value.toJson()).toList(),
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
  throw FormatException("Expected '$key' to be an object.");
}

List<T> _readList<T>(
  Map<String, Object?> json,
  String key,
  T Function(Map<String, Object?> json) decodeItem,
) {
  final value = json[key];
  if (value is! List) {
    throw FormatException("Expected '$key' to be a list.");
  }
  return List<T>.unmodifiable(
    value.map((item) {
      if (item is Map<String, Object?>) {
        return decodeItem(item);
      }
      if (item is Map) {
        return decodeItem(item.cast<String, Object?>());
      }
      throw FormatException("Expected '$key' items to be objects.");
    }),
  );
}

String _requireString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException("Expected '$key' to be a non-empty string.");
}
