import 'package:meta/meta.dart';

/// Represents an immutable message containing structured content and metadata.
/// Use [MessageBuilder] to construct instances.
@immutable
class Message {
  /// Unique message identifier (typically a UUID).
  final String id;

  /// Logical type of the message (e.g., 'note', 'event', etc.).
  final String kind;

  /// Identifier of the originator (e.g., 'user', 'system').
  final String source;

  /// Target recipient (e.g., 'server', 'group/123', 'user/456').
  final String destination;

  /// Hierarchical path identifier for grouping messages, such as
  /// 'project/{uuid}/topic/{uuid}/title'.
  final String keyId;

  /// Optional local reference to the message, typically a numeric or device-specific identifier.
  final String? localKeyId;

  /// Message content as a string, or a reference to binary/media data.
  final String value;

  /// Chronological versioning UUID. Used for deduplication and ordering.
  final String version;

  /// Optional integrity checksum hash (e.g., SHA-256) for content validation.
  final String? integrityHash;

  /// Optional size in bytes. Relevant when [value] is a reference to external content.
  final int? size;

  /// Optional media type of the content (e.g., 'text/plain', 'image/jpeg').
  final String? contentType;

  /// Optional list of metadata flags (e.g., ['pinned', 'urgent']).
  final List<String>? flags;

  /// Logical sequence number within its group. Must increase monotonically.
  final int sequence;

  /// UTC timestamp of message creation. Only the date portion may be relevant.
  final DateTime created;

  /// Version of the application that created the message. Useful for audit and compatibility checks.
  final String applicationVersion;

  /// Global stream offset across all events. Read-only, assigned during stream processing.
  final int position;

  /// ISO 639-1 or ISO 639-3 language code of the content (e.g., 'en', 'fr').
  final String language;

  /// Private named constructor. Use [MessageBuilder] to create instances.
  const Message._({
    required this.id,
    required this.kind,
    required this.source,
    required this.destination,
    required this.keyId,
    this.localKeyId,
    required this.value,
    required this.version,
    this.integrityHash,
    this.size,
    this.contentType,
    this.flags,
    required this.sequence,
    required this.created,
    required this.applicationVersion,
    required this.position,
    required this.language,
  });
}

/// Builder class for constructing immutable [Message] instances.
///
/// All required fields must be set before calling [build].
///
/// Usage:
/// ```dart
/// final message = MessageBuilder()
///   .setId('uuid')
///   .setKind('note')
///   .setSource('user')
///   .setDestination('group/123')
///   .setKeyId('project/uuid/topic/uuid/title')
///   .setValue('Hello World')
///   .setVersion('ver-uuid')
///   .setSequence(1)
///   .setCreated(DateTime.utc(2025, 9, 24))
///   .setApplicationVersion('1.0.0')
///   .setPosition(100)
///   .setLanguage('en')
///   .build();
/// ```
class MessageBuilder {
  String? _id;
  String? _kind;
  String? _source;
  String? _destination;
  String? _keyId;
  String? _localKeyId;
  String? _value;
  String? _version;
  String? _integrityHash;
  int? _size;
  String? _contentType;
  List<String>? _flags;
  int? _sequence;
  DateTime? _created;
  String? _applicationVersion;
  int? _position;
  String? _language;

  /// Sets the unique message identifier (UUID).
  MessageBuilder setId(String id) => _with(() => _id = id);

  /// Sets the logical message type (e.g., 'note', 'event').
  MessageBuilder setKind(String kind) => _with(() => _kind = kind);

  /// Sets the originator of the message (e.g., 'user').
  MessageBuilder setSource(String source) => _with(() => _source = source);

  /// Sets the message target (e.g., 'group/123', 'server').
  MessageBuilder setDestination(String destination) =>
      _with(() => _destination = destination);

  /// Sets the hierarchical key identifier for message grouping.
  MessageBuilder setKeyId(String keyId) => _with(() => _keyId = keyId);

  /// Sets an optional local reference (e.g., numeric or device-specific ID).
  MessageBuilder setLocalKeyId(String? localKeyId) =>
      _with(() => _localKeyId = localKeyId);

  /// Sets the message content or reference to external data.
  MessageBuilder setValue(String value) => _with(() => _value = value);

  /// Sets the chronological version UUID.
  MessageBuilder setVersion(String version) => _with(() => _version = version);

  /// Sets an optional checksum for validating content integrity.
  MessageBuilder setIntegrityHash(String? integrityHash) =>
      _with(() => _integrityHash = integrityHash);

  /// Sets the optional content size (used if [value] is a reference).
  MessageBuilder setSize(int? size) => _with(() => _size = size);

  /// Sets the optional MIME content type (e.g., 'text/plain').
  MessageBuilder setContentType(String? contentType) =>
      _with(() => _contentType = contentType);

  /// Sets optional metadata flags (e.g., 'pinned', 'urgent').
  MessageBuilder setFlags(List<String>? flags) => _with(() => _flags = flags);

  /// Sets the logical sequence number within its group.
  MessageBuilder setSequence(int sequence) => _with(() => _sequence = sequence);

  /// Sets the UTC timestamp of creation.
  MessageBuilder setCreated(DateTime created) =>
      _with(() => _created = created);

  /// Sets the originating application version.
  MessageBuilder setApplicationVersion(String applicationVersion) =>
      _with(() => _applicationVersion = applicationVersion);

  /// Sets the global stream offset position.
  MessageBuilder setPosition(int position) => _with(() => _position = position);

  /// Sets the ISO language code for the content.
  MessageBuilder setLanguage(String language) =>
      _with(() => _language = language);

  /// Builds and returns an immutable [Message] instance.
  ///
  /// Throws a [StateError] if any required fields are missing.
  Message build() {
    return Message._(
      id: _requireNonEmpty(_id, 'id'),
      kind: _requireNonEmpty(_kind, 'kind'),
      source: _requireNonEmpty(_source, 'source'),
      destination: _requireNonEmpty(_destination, 'destination'),
      keyId: _requireNonEmpty(_keyId, 'keyId'),
      localKeyId: _localKeyId,
      value: _requireNonEmpty(_value, 'value'),
      version: _requireNonEmpty(_version, 'version'),
      integrityHash: _integrityHash,
      size: _size,
      contentType: _contentType,
      flags: _flags,
      sequence: _sequence ?? _missing('sequence'),
      created: _created ?? _missing('created'),
      applicationVersion:
          _requireNonEmpty(_applicationVersion, 'applicationVersion'),
      position: _position ?? _missing('position'),
      language: _requireNonEmpty(_language, 'language'),
    );
  }

  MessageBuilder _with(void Function() updater) {
    updater();
    return this;
  }

  String _requireNonEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      throw StateError("Field '$fieldName' must not be empty.");
    }
    return value;
  }

  Never _missing(String field) =>
      throw StateError("Missing required field: $field");
}
