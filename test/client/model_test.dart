import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  group('BeamingClientKeyBuilder', () {
    test('builds an immutable key with required keyId', () {
      final key = BeamingClientKeyBuilder()
          .setKeyId('roots/oak')
          .setVersion('v-1')
          .setLocalKeyId('local-root')
          .build();

      expect(key.keyId, 'roots/oak');
      expect(key.version, 'v-1');
      expect(key.localKeyId, 'local-root');
    });

    test('rejects missing or blank keyId', () {
      expect(
        () => BeamingClientKeyBuilder().build(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => BeamingClientKeyBuilder().setKeyId('   ').build(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('BeamingValueBuilder', () {
    test('builds a string-only value payload', () {
      final key = BeamingClientKeyBuilder().setKeyId('roots/oak').build();
      final value = BeamingValueBuilder()
          .setKey(key)
          .setValue('acorn')
          .build();

      expect(value.key.keyId, 'roots/oak');
      expect(value.value, 'acorn');
    });

    test('requires a key', () {
      expect(
        () => BeamingValueBuilder().setValue('acorn').build(),
        throwsA(isA<StateError>()),
      );
    });
  });

  test('event primitives stay immutable and typed', () {
    final rootKey = BeamingClientKeyBuilder().setKeyId('roots/oak').build();
    final childKey = BeamingClientKeyBuilder().setKeyId('roots/oak/name').build();
    final event = BeamingSetEvent(
      rootKey: rootKey,
      keyValue: BeamingValue(
        key: childKey,
        value: 'Yggdrasil',
      ),
    );

    expect(event.rootKey.keyId, 'roots/oak');
    expect(event.keyValue.key.keyId, 'roots/oak/name');
    expect(event.keyValue.value, 'Yggdrasil');
  });
}
