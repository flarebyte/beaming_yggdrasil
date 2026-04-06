import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  test('rx snapshot stream emits the same values as the classic client',
      () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);

    await harness.testingClient.replaceSnapshot(
      'roots/oak',
      [
        const BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/title', version: 'v-1'),
          value: 'oak',
        ),
        const BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/status', version: 'v-1'),
          value: 'healthy',
        ),
      ],
    );

    final classic = await harness.client.getSnapshot('roots/oak');
    final rx = await harness.rxClient.snapshot$('roots/oak').first;

    expect(
      rx.map((value) => value.key.keyId).toList(),
      classic.map((value) => value.key.keyId).toList(),
    );
    expect(
      rx.map((value) => value.value).toList(),
      classic.map((value) => value.value).toList(),
    );
  });

  test('rx createChildren stream preserves the classic create results',
      () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);
    final provisionalKeys = [
      const BeamingClientKey(
        keyId: 'roots/oak/branch',
        localKeyId: 'local-branch',
      ),
    ];

    final classic = await harness.client.createChildren(
      'roots/oak',
      provisionalKeys,
    );
    final rx = await harness.rxClient
        .createChildren$('roots/oak', provisionalKeys)
        .first;

    expect(
      rx.map((result) => result.key.localKeyId).toList(),
      classic.map((result) => result.key.localKeyId).toList(),
    );
    expect(
      rx.map((result) => result.key.version).toList(),
      classic.map((result) => result.key.version).toList(),
    );
    expect(
      rx.map((result) => result.status).toList(),
      classic.map((result) => result.status).toList(),
    );
  });

  test('repeated rx watch subscriptions observe equivalent event payloads',
      () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);

    final firstEventFuture = harness.rxClient.watch$(['roots/oak']).first;
    final secondEventFuture = harness.rxClient.watch$(['roots/oak']).first;

    await harness.testingClient.replaceSnapshot(
      'roots/oak',
      [
        const BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/title', version: 'v-2'),
          value: 'oak',
        ),
      ],
    );

    final firstEvent = await firstEventFuture;
    final secondEvent = await secondEventFuture;

    expect(firstEvent, isA<BeamingSnapshotReplacedEvent>());
    expect(secondEvent, isA<BeamingSnapshotReplacedEvent>());
    expect(
      (firstEvent as BeamingSnapshotReplacedEvent).rootKey.keyId,
      (secondEvent as BeamingSnapshotReplacedEvent).rootKey.keyId,
    );
    expect(firstEvent.snapshotVersion, secondEvent.snapshotVersion);
  });
}
