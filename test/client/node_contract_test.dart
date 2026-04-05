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

    await harness.client.setNode('roots/oak', _oakNodeValues());

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

    await harness.client
        .setNode('roots/oak', _oakNodeValues().take(1).toList());

    final nodeValues = await harness.client.getNode(
      'roots/oak',
      ['roots/oak/missing', 'roots/oak/title'],
    );

    expect(nodeValues, hasLength(1));
    expect(nodeValues.single.key.keyId, 'roots/oak/title');
    expect(nodeValues.single.value, 'oak');
  });

  test('repeated identical node writes keep stable result and read ordering',
      () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);
    final values = _oakNodeValues().reversed.toList();

    final firstResults = await harness.client.setNode('roots/oak', values);
    final firstRead = await harness.client.getNode(
      'roots/oak',
      ['roots/oak/status', 'roots/oak/title'],
    );

    final secondResults = await harness.client.setNode('roots/oak', values);
    final secondRead = await harness.client.getNode(
      'roots/oak',
      ['roots/oak/status', 'roots/oak/title'],
    );

    expect(
      firstResults.map((result) => result.key.keyId).toList(),
      secondResults.map((result) => result.key.keyId).toList(),
    );
    expect(
      firstResults.map((result) => result.status).toList(),
      secondResults.map((result) => result.status).toList(),
    );
    expect(
      firstRead.map((value) => value.key.keyId).toList(),
      secondRead.map((value) => value.key.keyId).toList(),
    );
    expect(
      firstRead.map((value) => value.value).toList(),
      secondRead.map((value) => value.value).toList(),
    );
  });
}

List<BeamingValue> _oakNodeValues() {
  return [
    BeamingValue(
      key: BeamingClientKey(keyId: 'roots/oak/title', version: 'v-2'),
      value: 'oak',
    ),
    BeamingValue(
      key: BeamingClientKey(keyId: 'roots/oak/status', version: 'v-3'),
      value: 'healthy',
    ),
  ];
}
