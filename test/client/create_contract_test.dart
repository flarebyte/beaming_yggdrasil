import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

import '../../support/in_memory_harness.dart';

void main() {
  test('createChildren preserves localKeyId and returns stable results',
      () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);
    final provisionalKeys = _provisionalChildren();

    final first =
        await harness.client.createChildren('roots/oak', provisionalKeys);
    final second =
        await harness.client.createChildren('roots/oak', provisionalKeys);

    expect(
      first.map((result) => result.key.localKeyId).toList(),
      ['local-branch', 'local-leaf'],
    );
    expect(
      first.map((result) => result.status).toList(),
      ['ok', 'ok'],
    );
    expect(
      first.map((result) => result.key.version).toList(),
      ['created:local-branch', 'created:local-leaf'],
    );
    expect(
      first.map((result) => result.key.keyId).toList(),
      second.map((result) => result.key.keyId).toList(),
    );
    expect(
      first.map((result) => result.key.version).toList(),
      second.map((result) => result.key.version).toList(),
    );
  });

  test('createChildren keeps partial failures observable', () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);

    final results = await harness.client.createChildren(
      'roots/oak',
      [
        const BeamingClientKey(
          keyId: 'roots/oak/branch',
          localKeyId: 'local-branch',
        ),
        const BeamingClientKey(
          keyId: 'roots/pine/foreign',
          localKeyId: 'local-foreign',
        ),
        const BeamingClientKey(
          keyId: 'roots/oak/missing-local',
        ),
      ],
    );

    expect(
      results.map((result) => result.status).toList(),
      ['ok', 'invalid', 'invalid'],
    );
    expect(results[1].message, 'created keys must be children of the root key');
    expect(results[2].message, 'localKeyId is required for createChildren');
    expect(results[0].key.localKeyId, 'local-branch');
  });
}

List<BeamingClientKey> _provisionalChildren() {
  return const [
    BeamingClientKey(
      keyId: 'roots/oak/branch',
      localKeyId: 'local-branch',
    ),
    BeamingClientKey(
      keyId: 'roots/oak/branch/leaf',
      localKeyId: 'local-leaf',
    ),
  ];
}
