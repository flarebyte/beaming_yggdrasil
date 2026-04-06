/// purpose: Define the immutable core value, key, result, and event objects
/// that every public client surface shares.
///
/// responsibilities: Represent client keys and values, build validated
/// immutable objects, and carry write and event payloads.
///
/// architecture notes: Values are string-only for now and builders are kept as
/// the explicit construction escape hatch for non-trivial immutable objects.
library;

import 'error.dart';

/// Immutable key reference used by the spec-aligned client surfaces.
class BeamingClientKey {
  final String keyId;
  final String? version;
  final String? localKeyId;

  const BeamingClientKey({
    required this.keyId,
    this.version,
    this.localKeyId,
  });
}

/// Builder for [BeamingClientKey].
///
/// This is a starting-point pattern for non-trivial immutable objects.
class BeamingClientKeyBuilder {
  String? _keyId;
  String? _version;
  String? _localKeyId;

  /// Sets the stable key identifier.
  BeamingClientKeyBuilder setKeyId(String keyId) => _with(() => _keyId = keyId);

  /// Sets the optimistic version carried with the key.
  BeamingClientKeyBuilder setVersion(String? version) =>
      _with(() => _version = version);

  /// Sets the provisional local key identifier used during create flows.
  BeamingClientKeyBuilder setLocalKeyId(String? localKeyId) =>
      _with(() => _localKeyId = localKeyId);

  /// Builds an immutable key after validating required fields.
  BeamingClientKey build() {
    return BeamingClientKey(
      keyId: _requireNonEmpty(_keyId, 'keyId'),
      version: _version,
      localKeyId: _localKeyId,
    );
  }

  BeamingClientKeyBuilder _with(void Function() update) {
    update();
    return this;
  }

  String _requireNonEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      throw BeamingClientError(
        kind: BeamingClientErrorKind.invalidRequest,
        message: "Field '$fieldName' must not be empty.",
      );
    }
    return value;
  }
}

/// String-only value payload for the current client contract.
class BeamingValue {
  final BeamingClientKey key;
  final String? value;

  const BeamingValue({
    required this.key,
    this.value,
  });
}

/// Starting-point builder for [BeamingValue].
class BeamingValueBuilder {
  BeamingClientKey? _key;
  String? _value;

  /// Sets the key associated with the value.
  BeamingValueBuilder setKey(BeamingClientKey key) => _with(() => _key = key);

  /// Sets the string payload value.
  BeamingValueBuilder setValue(String? value) => _with(() => _value = value);

  /// Builds an immutable value after validating required fields.
  BeamingValue build() {
    return BeamingValue(
      key: _key ?? _missing('key'),
      value: _value,
    );
  }

  BeamingValueBuilder _with(void Function() update) {
    update();
    return this;
  }

  Never _missing(String fieldName) {
    throw BeamingClientError(
      kind: BeamingClientErrorKind.invalidRequest,
      message: 'Missing required field: $fieldName',
    );
  }
}

/// Status result returned by write and create workflows.
class BeamingWriteResult {
  final BeamingClientKey key;
  final String status;
  final String? message;

  const BeamingWriteResult({
    required this.key,
    required this.status,
    this.message,
  });
}

/// Base type for immutable client-visible events.
sealed class BeamingEvent {
  const BeamingEvent();
}

/// Event emitted when a single value changes under a subscribed root.
class BeamingSetEvent extends BeamingEvent {
  final BeamingClientKey rootKey;
  final BeamingValue keyValue;

  const BeamingSetEvent({
    required this.rootKey,
    required this.keyValue,
  });
}

/// Event emitted when a snapshot has been replaced for a subscribed root.
class BeamingSnapshotReplacedEvent extends BeamingEvent {
  final BeamingClientKey rootKey;
  final String snapshotVersion;

  const BeamingSnapshotReplacedEvent({
    required this.rootKey,
    required this.snapshotVersion,
  });
}
