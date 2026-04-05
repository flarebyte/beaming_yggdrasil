part of 'rest.dart';

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
