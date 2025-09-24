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
}
