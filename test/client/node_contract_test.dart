import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  test('setNode preserves input order and returns status per item', () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);

    final writeResults = await harness.client.setNode(
      'roots/oak',
      [
        BeamingValue(
          key: BeamingClientKey(
            keyId: 'roots/oak/status',
            version: 'v-3',
          ),
          value: 'healthy',
        ),
        BeamingValue(
          key: BeamingClientKey(
            keyId: 'roots/oak/title',
            version: 'v-2',
          ),
          value: 'oak',
        ),
      ],
    );

    expect(
      writeResults.map((result) => result.key.keyId).toList(),
      ['roots/oak/status', 'roots/oak/title'],
    );
    expect(
      writeResults.map((result) => result.status).toList(),
      ['ok', 'ok'],
    );
  });

  test('getNode returns values in requested key order after writes', () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);

    await harness.client.setNode(
      'roots/oak',
      [
        BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/title', version: 'v-2'),
          value: 'oak',
        ),
        BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/status', version: 'v-3'),
          value: 'healthy',
        ),
      ],
    );

    final nodeValues = await harness.client.getNode(
      'roots/oak',
      ['roots/oak/status', 'roots/oak/title'],
    );

    expect(
      nodeValues.map((value) => value.key.keyId).toList(),
      ['roots/oak/status', 'roots/oak/title'],
    );
    expect(
      nodeValues.map((value) => value.value).toList(),
      ['healthy', 'oak'],
    );
    expect(
      nodeValues.map((value) => value.key.version).toList(),
      ['v-3', 'v-2'],
    );
  });

  test('getNode skips missing keys without disturbing requested matches',
      () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);

    await harness.client.setNode(
      'roots/oak',
      [
        BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/title', version: 'v-2'),
          value: 'oak',
        ),
      ],
    );

    final nodeValues = await harness.client.getNode(
      'roots/oak',
      ['roots/oak/missing', 'roots/oak/title'],
    );

    expect(nodeValues, hasLength(1));
    expect(nodeValues.single.key.keyId, 'roots/oak/title');
    expect(nodeValues.single.value, 'oak');
  });
}
