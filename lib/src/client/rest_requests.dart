/// purpose: Define the outbound REST request DTOs used to speak the server wire
/// contract in a typed and deterministic way.
///
/// responsibilities: Represent snapshot, node, and create request payloads and
/// convert them to and from JSON maps.
///
/// architecture notes: These types preserve request ordering and wire field
/// names exactly so HTTP adapters do not need ad hoc map assembly logic.
part of 'rest.dart';

/// Request body for test-only snapshot replacement.
class BeamingSetSnapshotRequest {
  final String? id;
  final BeamingKeyParams key;
  final List<BeamingKeyValueParams> keyValueList;

  const BeamingSetSnapshotRequest({
    required this.key,
    required this.keyValueList,
    this.id,
  });

  /// Decodes the request body from JSON.
  factory BeamingSetSnapshotRequest.fromJson(Map<String, Object?> json) {
    return BeamingSetSnapshotRequest(
      id: json['id'] as String?,
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      keyValueList:
          _readList(json, 'keyValueList', BeamingKeyValueParams.fromJson),
    );
  }

  /// Serializes the request body to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'key': key.toJson(),
      'keyValueList': keyValueList.map((value) => value.toJson()).toList(),
    };
  }
}

/// Request body for reading a full snapshot.
class BeamingGetSnapshotRequest {
  final String? id;
  final BeamingKeyParams key;

  const BeamingGetSnapshotRequest({
    required this.key,
    this.id,
  });

  /// Decodes the request body from JSON.
  factory BeamingGetSnapshotRequest.fromJson(Map<String, Object?> json) {
    return BeamingGetSnapshotRequest(
      id: json['id'] as String?,
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
    );
  }

  /// Serializes the request body to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'key': key.toJson(),
    };
  }
}

/// Request body for writing one or more node values.
class BeamingSetKeyValueRequest {
  final String? id;
  final BeamingKeyParams rootKey;
  final List<BeamingKeyValueParams> keyValueList;

  const BeamingSetKeyValueRequest({
    required this.rootKey,
    required this.keyValueList,
    this.id,
  });

  /// Decodes the request body from JSON.
  factory BeamingSetKeyValueRequest.fromJson(Map<String, Object?> json) {
    return BeamingSetKeyValueRequest(
      id: json['id'] as String?,
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      keyValueList:
          _readList(json, 'keyValueList', BeamingKeyValueParams.fromJson),
    );
  }

  /// Serializes the request body to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'rootKey': rootKey.toJson(),
      'keyValueList': keyValueList.map((value) => value.toJson()).toList(),
    };
  }
}

/// Request body for reading selected node values.
class BeamingGetKeyValueRequest {
  final String? id;
  final BeamingKeyParams rootKey;
  final List<BeamingKeyParams> keyList;

  const BeamingGetKeyValueRequest({
    required this.rootKey,
    required this.keyList,
    this.id,
  });

  /// Decodes the request body from JSON.
  factory BeamingGetKeyValueRequest.fromJson(Map<String, Object?> json) {
    return BeamingGetKeyValueRequest(
      id: json['id'] as String?,
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      keyList: _readList(json, 'keyList', BeamingKeyParams.fromJson),
    );
  }

  /// Serializes the request body to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'rootKey': rootKey.toJson(),
      'keyList': keyList.map((value) => value.toJson()).toList(),
    };
  }
}

/// Child descriptor used during create requests.
class BeamingNewKeyChildRequest {
  final String localKeyId;
  final String expectedKind;

  const BeamingNewKeyChildRequest({
    required this.localKeyId,
    required this.expectedKind,
  });

  /// Decodes the child descriptor from JSON.
  factory BeamingNewKeyChildRequest.fromJson(Map<String, Object?> json) {
    return BeamingNewKeyChildRequest(
      localKeyId: _requireString(json, 'localKeyId'),
      expectedKind: _requireString(json, 'expectedKind'),
    );
  }

  /// Serializes the child descriptor to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'localKeyId': localKeyId,
      'expectedKind': expectedKind,
    };
  }
}

/// Parent and child request descriptor used during create requests.
class BeamingNewKeyRequest {
  final BeamingKeyParams key;
  final String expectedKind;
  final List<BeamingNewKeyChildRequest> children;

  const BeamingNewKeyRequest({
    required this.key,
    required this.expectedKind,
    required this.children,
  });

  /// Decodes the create request entry from JSON.
  factory BeamingNewKeyRequest.fromJson(Map<String, Object?> json) {
    return BeamingNewKeyRequest(
      key: BeamingKeyParams.fromJson(_readMap(json, 'key')),
      expectedKind: _requireString(json, 'expectedKind'),
      children: _readList(json, 'children', BeamingNewKeyChildRequest.fromJson),
    );
  }

  /// Serializes the create request entry to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key.toJson(),
      'expectedKind': expectedKind,
      'children': children.map((value) => value.toJson()).toList(),
    };
  }
}

/// Request body for server-side child creation.
class BeamingNewKeysRequest {
  final String? id;
  final BeamingKeyParams rootKey;
  final List<BeamingNewKeyRequest> newKeys;

  const BeamingNewKeysRequest({
    required this.rootKey,
    required this.newKeys,
    this.id,
  });

  /// Decodes the request body from JSON.
  factory BeamingNewKeysRequest.fromJson(Map<String, Object?> json) {
    return BeamingNewKeysRequest(
      id: json['id'] as String?,
      rootKey: BeamingKeyParams.fromJson(_readMap(json, 'rootKey')),
      newKeys: _readList(json, 'newKeys', BeamingNewKeyRequest.fromJson),
    );
  }

  /// Serializes the request body to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'rootKey': rootKey.toJson(),
      'newKeys': newKeys.map((value) => value.toJson()).toList(),
    };
  }
}
