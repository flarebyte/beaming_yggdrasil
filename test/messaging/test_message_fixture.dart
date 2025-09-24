import 'package:beaming_yggdrasil/beaming-yggdrasil.dart';

class TestMessages {
  /// Celtic druidic prophecy message.
  static Message celticProphecy() {
    return MessageBuilder()
        .setId('11111111-aaaa-bbbb-cccc-000000000001')
        .setKind('prophecy')
        .setSource('user/druid-aedan')
        .setDestination('group/circle-of-oaks')
        .setKeyId('tribe/gael/forest/connacht/oracle')
        .setValue(
            'The mist shall rise before the blood moon, revealing the path to the lost grove.')
        .setVersion('11111111-aaaa-bbbb-cccc-000000000002')
        .setCreated(DateTime.utc(2023, 10, 31))
        .setApplicationVersion('1.2.5')
        .setLanguage('ga') // Irish Gaelic
        .build();
  }

  /// Nordic saga fragment message.
  static Message nordicSaga() {
    return MessageBuilder()
        .setId('22222222-bbbb-cccc-dddd-000000000001')
        .setKind('saga')
        .setSource('user/skald-ingvar')
        .setDestination('group/longhouse/ulfheim')
        .setKeyId('realm/midgard/scrolls/ulfheim/legends')
        .setValue(
            'In the shadow of the fjord, the wyrm sleeps under snow and ash.')
        .setVersion('22222222-bbbb-cccc-dddd-000000000002')
        .setCreated(DateTime.utc(2025, 1, 1))
        .setApplicationVersion('2.1.0')
        .setLanguage('non') // Old Norse
        .build();
  }

  /// Elven bard's poetic note.
  static Message elvenBardSong() {
    return MessageBuilder()
        .setId('33333333-cccc-dddd-eeee-000000000001')
        .setKind('note')
        .setSource('user/lyrien')
        .setDestination('group/forest/glade')
        .setKeyId('court/elves/songs/lament-of-the-stars')
        .setValue(
            'Stars whisper songs in the tongue of silver leaves and moonlit wind.')
        .setVersion('33333333-cccc-dddd-eeee-000000000002')
        .setCreated(DateTime.utc(2024, 7, 21))
        .setApplicationVersion('1.8.3')
        .setLanguage('en')
        .build();
  }

  /// Norse rune reading message.
  static Message runeReading() {
    return MessageBuilder()
        .setId('44444444-dddd-eeee-ffff-000000000001')
        .setKind('divination')
        .setSource('user/seer-freyja')
        .setDestination('user/thorvald')
        .setKeyId('temple/asgard/runes/vision-path')
        .setValue('ᚠᛁᚢᚾ — The winds bring change. Be wary of the third sun.')
        .setVersion('44444444-dddd-eeee-ffff-000000000002')
        .setCreated(DateTime.utc(2025, 5, 15))
        .setApplicationVersion('2.0.4')
        .build(); // language omitted (unknown)
  }

  /// Battlefield report from a Nordic shieldmaiden.
  static Message battlefieldReport() {
    return MessageBuilder()
        .setId('55555555-eeee-ffff-aaaa-000000000001')
        .setKind('report')
        .setSource('user/astrid')
        .setDestination('server/war-room')
        .setKeyId('campaign/ragnarok/frontline/niflheim')
        .setValue('Shield wall held. Reinforcements needed before dusk.')
        .setVersion('55555555-eeee-ffff-aaaa-000000000002')
        .setCreated(DateTime.utc(2025, 9, 24))
        .setApplicationVersion('3.0.0')
        .setLanguage('en')
        .build();
  }
}
