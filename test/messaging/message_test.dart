import 'package:beaming_yggdrasil/beaming-yggdrasil.dart';
import 'package:test/test.dart';

void main() {
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
}
