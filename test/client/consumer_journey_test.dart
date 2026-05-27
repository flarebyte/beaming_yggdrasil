import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

import '../../support/in_memory_harness.dart';

void main() {
  test('loads a snapshot and starts watching updates', () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);

    await harness.testingClient.replaceSnapshot(
      'roots/oak',
      [
        BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/title', version: 'v-1'),
          value: 'oak',
        ),
        BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/status', version: 'v-1'),
          value: 'healthy',
        ),
      ],
    );

    final values = await harness.client.getSnapshot('roots/oak');
    expect(
      values.map((value) => value.key.keyId).toList(),
      ['roots/oak/title', 'roots/oak/status'],
    );

    final nextEvent = harness.client.watch(['roots/oak']).first;

    await harness.testingClient.replaceSnapshot(
      'roots/oak',
      [
        BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/title', version: 'v-2'),
          value: 'oak',
        ),
      ],
    );

    final event = await nextEvent;
    expect(event, isA<BeamingSnapshotReplacedEvent>());
    expect(
      (event as BeamingSnapshotReplacedEvent).rootKey.keyId,
      'roots/oak',
    );
  });

  test('returns deterministic snapshot values across repeated reads', () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);

    await harness.testingClient.replaceSnapshot(
      'roots/oak',
      [
        BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/title'),
          value: 'oak',
        ),
        BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/status'),
          value: 'healthy',
        ),
      ],
    );

    final first = await harness.client.getSnapshot('roots/oak');
    final second = await harness.client.getSnapshot('roots/oak');

    expect(
      first.map((value) => value.key.keyId).toList(),
      second.map((value) => value.key.keyId).toList(),
    );
    expect(
      first.map((value) => value.value).toList(),
      second.map((value) => value.value).toList(),
    );
  });
}
