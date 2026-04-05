import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  test('public api surfaces remain separated in the in-memory harness',
      () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);

    final client = harness.client;
    final testingClient = harness.testingClient;

    await testingClient.replaceSnapshot(
      'roots/oak',
      [
        BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/title'),
          value: 'oak',
        ),
      ],
    );

    expect(await client.getSnapshot('roots/oak'), hasLength(1));
    expect(testingClient, isA<BeamingYggdrasilTestingClient>());
    expect(client, isA<BeamingYggdrasilClient>());
  });
}
