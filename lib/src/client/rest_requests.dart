part of 'rest.dart';

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
