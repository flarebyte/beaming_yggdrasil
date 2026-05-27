// purpose: Translate between wire-level WebSocket event envelopes and the
// package's public event model.
// responsibilities: Encode event payloads, decode them from JSON, and convert
// them to immutable public events.
// architecture notes: Event conversion is isolated here so protocol wiring and
// public event semantics can evolve without tangling session message code.
part of 'websocket.dart';

/// Typed event payload transported over the WebSocket protocol.
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

  /// Creates a wire event from a public event object.
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

  /// Decodes the wire event from JSON.
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

  /// Converts the wire event back into the public event model.
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

  /// Serializes the event envelope to JSON.
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
