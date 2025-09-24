import 'package:beaming_yggdrasil/beaming-yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  MessageBuilder _base() => MessageBuilder()
      .setId('id')
      .setKind('note')
      .setSource('user/x')
      .setDestination('group/y')
      .setKeyId('path/a/b')
      .setValue('content')
      .setVersion('v-1')
      .setCreated(DateTime.utc(2025, 1, 1))
      .setApplicationVersion('1.0.0');

  group('MessageBuilder – required non-empty string validation', () {
    test('throws when required strings are empty', () {
      expect(
        () => _base().setId('').build(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => _base().setKind('   ').build(), // blanks trimmed -> empty
        throwsA(isA<StateError>()),
      );
      expect(
        () => _base().setSource('').build(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => _base().setDestination('').build(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => _base().setKeyId('').build(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => _base().setValue('').build(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => _base().setVersion('   ').build(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => _base().setApplicationVersion('').build(),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when a required field is missing', () {
      // Remove each required field one by one.
      expect(
        () => MessageBuilder()
            .setKind('note')
            .setSource('user/x')
            .setDestination('group/y')
            .setKeyId('path/a/b')
            .setValue('content')
            .setVersion('v-1')
            .setCreated(DateTime.utc(2025, 1, 1))
            .setApplicationVersion('1.0.0')
            .build(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => MessageBuilder()
            .setId('id')
            .setSource('user/x')
            .setDestination('group/y')
            .setKeyId('path/a/b')
            .setValue('content')
            .setVersion('v-1')
            .setCreated(DateTime.utc(2025, 1, 1))
            .setApplicationVersion('1.0.0')
            .build(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => MessageBuilder()
            .setId('id')
            .setKind('note')
            .setDestination('group/y')
            .setKeyId('path/a/b')
            .setValue('content')
            .setVersion('v-1')
            .setCreated(DateTime.utc(2025, 1, 1))
            .setApplicationVersion('1.0.0')
            .build(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => MessageBuilder()
            .setId('id')
            .setKind('note')
            .setSource('user/x')
            .setKeyId('path/a/b')
            .setValue('content')
            .setVersion('v-1')
            .setCreated(DateTime.utc(2025, 1, 1))
            .setApplicationVersion('1.0.0')
            .build(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => MessageBuilder()
            .setId('id')
            .setKind('note')
            .setSource('user/x')
            .setDestination('group/y')
            .setValue('content')
            .setVersion('v-1')
            .setCreated(DateTime.utc(2025, 1, 1))
            .setApplicationVersion('1.0.0')
            .build(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => MessageBuilder()
            .setId('id')
            .setKind('note')
            .setSource('user/x')
            .setDestination('group/y')
            .setKeyId('path/a/b')
            .setVersion('v-1')
            .setCreated(DateTime.utc(2025, 1, 1))
            .setApplicationVersion('1.0.0')
            .build(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => MessageBuilder()
            .setId('id')
            .setKind('note')
            .setSource('user/x')
            .setDestination('group/y')
            .setKeyId('path/a/b')
            .setValue('content')
            .setCreated(DateTime.utc(2025, 1, 1))
            .setApplicationVersion('1.0.0')
            .build(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => MessageBuilder()
            .setId('id')
            .setKind('note')
            .setSource('user/x')
            .setDestination('group/y')
            .setKeyId('path/a/b')
            .setValue('content')
            .setVersion('v-1')
            .setApplicationVersion('1.0.0')
            .build(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => MessageBuilder()
            .setId('id')
            .setKind('note')
            .setSource('user/x')
            .setDestination('group/y')
            .setKeyId('path/a/b')
            .setValue('content')
            .setVersion('v-1')
            .setCreated(DateTime.utc(2025, 1, 1))
            .build(),
        throwsA(isA<StateError>()),
      );
    });

    test('language is optional (may be null)', () {
      final msg = _base().build();
      expect(msg.language, isNull);
    });
  });
  group('MessageBuilder – success', () {
    test('builds with minimal required client fields', () {
      final msg = MessageBuilder()
          .setId('id-1')
          .setKind('note')
          .setSource('user/alba')
          .setDestination('group/circle')
          .setKeyId('tribe/gael/forest/oracle')
          .setValue('Fog rolls over the cairn.')
          .setVersion('v-1')
          .setCreated(DateTime.utc(2025, 1, 1))
          .setApplicationVersion('1.0.0')
          .build();

      expect(msg.id, 'id-1');
      expect(msg.kind, 'note');
      expect(msg.source, 'user/alba');
      expect(msg.destination, 'group/circle');
      expect(msg.keyId, 'tribe/gael/forest/oracle');
      expect(msg.value, 'Fog rolls over the cairn.');
      expect(msg.version, 'v-1');
      expect(msg.created, DateTime.utc(2025, 1, 1));
      expect(msg.applicationVersion, '1.0.0');

      // Optional/server-enriched fields are null by default
      expect(msg.sequence, isNull);
      expect(msg.position, isNull);
      expect(msg.integrityHash, isNull);
      expect(msg.size, isNull);
      expect(msg.language, isNull);
      expect(msg.localKeyId, isNull);
      expect(msg.contentType, isNull);
      expect(msg.flags, isNull);
    });

    test('accepts optional server fields when provided', () {
      final msg = MessageBuilder()
          .setId('id-2')
          .setKind('saga')
          .setSource('user/skald')
          .setDestination('group/longhouse')
          .setKeyId('realm/midgard/ulfheim/legends')
          .setValue('Wyrm beneath the ash.')
          .setVersion('v-2')
          .setCreated(DateTime.utc(2025, 2, 2))
          .setApplicationVersion('2.0.0')
          // Optional/server-owned fields:
          .setSequence(42)
          .setPosition(10)
          .setIntegrityHash('abc123')
          .setSize(4096)
          // Optional client metadata:
          .setLanguage('non')
          .setLocalKeyId('local-9')
          .setContentType('text/plain')
          .setFlags(['pinned']).build();

      expect(msg.sequence, 42);
      expect(msg.position, 10);
      expect(msg.integrityHash, 'abc123');
      expect(msg.size, 4096);
      expect(msg.language, 'non');
      expect(msg.localKeyId, 'local-9');
      expect(msg.contentType, 'text/plain');
      expect(msg.flags, ['pinned']);
    });
  });
  test('Message fields are final and cannot be reassigned', () {
    final msg = MessageBuilder()
        .setId('id')
        .setKind('note')
        .setSource('user/a')
        .setDestination('group/b')
        .setKeyId('k/p')
        .setValue('v')
        .setVersion('ver')
        .setCreated(DateTime.utc(2025, 1, 1))
        .setApplicationVersion('1.0.0')
        .build();

    // Compile-time immutability check: uncommenting the following line
    // should fail to compile (no setters).
    //
    // msg.id = 'new-id'; // <-- not allowed

    expect(msg.id, 'id');
  });

  test('Builder is chainable and reusable only when reassigned intentionally',
      () {
    final b = MessageBuilder()
        .setId('id1')
        .setKind('note')
        .setSource('user/a')
        .setDestination('group/b')
        .setKeyId('k/p')
        .setValue('v')
        .setVersion('ver')
        .setCreated(DateTime.utc(2025, 1, 1))
        .setApplicationVersion('1.0.0');

    final m1 = b.build();
    expect(m1.id, 'id1');

    // Reusing builder for a different object is allowed but fields must be reset explicitly.
    final m2 = b.setId('id2').setVersion('ver2').build();

    expect(m2.id, 'id2');
    expect(m2.version, 'ver2');
  });
}
