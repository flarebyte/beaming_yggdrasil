/// purpose: Define the inbound REST response DTOs so server replies can be
/// decoded into stable typed structures before reaching higher client layers.
///
/// responsibilities: Represent snapshot, node, create, and status-bearing
/// response payloads and convert them to and from JSON maps.
///
/// architecture notes: Response DTOs preserve server statuses and messages
/// instead of flattening them, because those wire semantics are part of the
/// client contract.
part of 'rest.dart';

/// Response data returned after test-only snapshot replacement.
class BeamingSetSnapshotResponseData {
  final BeamingKeyParams key;

  const BeamingSetSnapshotResponseData({
    required this.key,
  });

  /// Decodes the response data from JSON.
  factory BeamingSetSnapshotResponseData.fromJson(Map<String, Object?> json) {
    return BeamingSetSnapshotResponseData(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
    );
  }

  /// Serializes the response data to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
    };
  }
}

/// Response data returned when reading a full snapshot.
class BeamingGetSnapshotResponseData {
  final BeamingKeyParams key;
  final List<BeamingKeyValueParams> keyValueList;

  const BeamingGetSnapshotResponseData({
    required this.key,
    required this.keyValueList,
  });

  /// Decodes the response data from JSON.
  factory BeamingGetSnapshotResponseData.fromJson(Map<String, Object?> json) {
    return BeamingGetSnapshotResponseData(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      keyValueList:
          _readList(json, 'keyValueList', BeamingKeyValueParams.fromJson),
    );
  }

  /// Serializes the response data to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
      'keyValueList': keyValueList.map((value) => value.toJson()).toList(),
    };
  }
}

/// Shared base for response entries that carry a key, status, and message.
abstract class _BeamingStatusKeyEntry {
  final BeamingKeyParams key;
  final String status;
  final String? message;

  const _BeamingStatusKeyEntry({
    required this.key,
    required this.status,
    this.message,
  });

  /// Serializes the status entry to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
      'status': status,
      if (message != null) 'message': message,
    };
  }
}

/// Status item returned by node write and similar responses.
class BeamingStatusKeyItem extends _BeamingStatusKeyEntry {
  const BeamingStatusKeyItem({
    required super.key,
    required super.status,
    super.message,
  });

  /// Decodes the status item from JSON.
  factory BeamingStatusKeyItem.fromJson(Map<String, Object?> json) {
    return BeamingStatusKeyItem(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      status: _requireString(json, 'status'),
      message: json['message'] as String?,
    );
  }
}

/// Status item returned by node read responses.
class BeamingStatusKeyValueItem {
  final BeamingKeyValueParams keyValue;
  final String status;
  final String? message;

  const BeamingStatusKeyValueItem({
    required this.keyValue,
    required this.status,
    this.message,
  });

  /// Decodes the status item from JSON.
  factory BeamingStatusKeyValueItem.fromJson(Map<String, Object?> json) {
    return BeamingStatusKeyValueItem(
      keyValue: BeamingKeyValueParams.fromJson(_readMap(json, 'keyValue')),
      status: _requireString(json, 'status'),
      message: json['message'] as String?,
    );
  }

  /// Serializes the status item to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'keyValue': keyValue.toJson(),
      'status': status,
      if (message != null) 'message': message,
    };
  }
}

/// Response data returned after writing node values.
class BeamingSetKeyValueResponseData {
  final BeamingKeyParams rootKey;
  final List<BeamingStatusKeyItem> keyList;

  const BeamingSetKeyValueResponseData({
    required this.rootKey,
    required this.keyList,
  });

  /// Decodes the response data from JSON.
  factory BeamingSetKeyValueResponseData.fromJson(Map<String, Object?> json) {
    return BeamingSetKeyValueResponseData(
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      keyList: _readList(json, 'keyList', BeamingStatusKeyItem.fromJson),
    );
  }

  /// Serializes the response data to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'rootKey': rootKey.toJson(),
      'keyList': keyList.map((value) => value.toJson()).toList(),
    };
  }
}

/// Response data returned after reading selected node values.
class BeamingGetKeyValueResponseData {
  final BeamingKeyParams rootKey;
  final List<BeamingStatusKeyValueItem> keyValueList;

  const BeamingGetKeyValueResponseData({
    required this.rootKey,
    required this.keyValueList,
  });

  /// Decodes the response data from JSON.
  factory BeamingGetKeyValueResponseData.fromJson(Map<String, Object?> json) {
    return BeamingGetKeyValueResponseData(
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      keyValueList:
          _readList(json, 'keyValueList', BeamingStatusKeyValueItem.fromJson),
    );
  }

  /// Serializes the response data to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'rootKey': rootKey.toJson(),
      'keyValueList': keyValueList.map((value) => value.toJson()).toList(),
    };
  }
}

/// Child creation status entry returned by create responses.
class BeamingNewKeyChildResponse extends _BeamingStatusKeyEntry {
  const BeamingNewKeyChildResponse({
    required super.key,
    required super.status,
    super.message,
  });

  /// Decodes the child response from JSON.
  factory BeamingNewKeyChildResponse.fromJson(Map<String, Object?> json) {
    return BeamingNewKeyChildResponse(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      status: _requireString(json, 'status'),
      message: json['message'] as String?,
    );
  }
}

/// Parent creation status entry returned by create responses.
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

  /// Decodes the create response entry from JSON.
  factory BeamingNewKeyResponse.fromJson(Map<String, Object?> json) {
    return BeamingNewKeyResponse(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      status: _requireString(json, 'status'),
      message: json['message'] as String?,
      children:
          _readList(json, 'children', BeamingNewKeyChildResponse.fromJson),
    );
  }

  /// Serializes the create response entry to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
      'status': status,
      if (message != null) 'message': message,
      'children': children.map((value) => value.toJson()).toList(),
    };
  }
}

/// Response data returned by server-side child creation.
class BeamingNewKeysResponseData {
  final BeamingKeyParams rootKey;
  final List<BeamingNewKeyResponse> newKeys;

  const BeamingNewKeysResponseData({
    required this.rootKey,
    required this.newKeys,
  });

  /// Decodes the response data from JSON.
  factory BeamingNewKeysResponseData.fromJson(Map<String, Object?> json) {
    return BeamingNewKeysResponseData(
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      newKeys: _readList(json, 'newKeys', BeamingNewKeyResponse.fromJson),
    );
  }

  /// Serializes the response data to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'rootKey': rootKey.toJson(),
      'newKeys': newKeys.map((value) => value.toJson()).toList(),
    };
  }
}
