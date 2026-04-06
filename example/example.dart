import 'dart:async';

import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';

const _oakRootKeyId = 'roots/oak';
const _oakSnapshotValues = <BeamingValue>[
  BeamingValue(
    key: BeamingClientKey(keyId: 'roots/oak/title', version: 'v-1'),
    value: 'oak',
  ),
  BeamingValue(
    key: BeamingClientKey(keyId: 'roots/oak/status', version: 'v-1'),
    value: 'healthy',
  ),
];

Future<void> main() async {
  final harness = createBeamingInMemoryHarness();
  final controller = TreeController(
    client: harness.client,
    rxClient: harness.rxClient,
  );

  try {
    await harness.testingClient.replaceSnapshot(_oakRootKeyId, _oakSnapshotValues);

    await controller.load(_oakRootKeyId);
    await controller.startWatching(_oakRootKeyId);

    final createResults = await controller.createBranch(_oakRootKeyId);
    final rxSnapshot = await controller.loadWithRx(_oakRootKeyId);

    print('Initial snapshot: ${controller.snapshot.length} values');
    print('Create results: ${createResults.map((result) => result.status).toList()}');
    print('Rx snapshot: ${rxSnapshot.map((value) => value.key.keyId).toList()}');
  } finally {
    await controller.dispose();
    await harness.close();
  }
}

/// Example application-side controller that could sit behind Flutter UI state.
class TreeController {
  final BeamingYggdrasilClient client;
  final BeamingYggdrasilRxClient rxClient;

  StreamSubscription<BeamingEvent>? _watchSubscription;
  List<BeamingValue> snapshot = const [];

  TreeController({
    required this.client,
    required this.rxClient,
  });

  Future<void> load(String rootKeyId) async {
    snapshot = await client.getSnapshot(rootKeyId);
  }

  Future<List<BeamingWriteResult>> createBranch(String rootKeyId) {
    return client.createChildren(
      rootKeyId,
      const [
        BeamingClientKey(
          keyId: 'roots/oak/branch',
          localKeyId: 'local-branch',
        ),
      ],
    );
  }

  Future<List<BeamingValue>> loadWithRx(String rootKeyId) {
    return rxClient.snapshot$(rootKeyId).first;
  }

  Future<void> startWatching(String rootKeyId) async {
    await _watchSubscription?.cancel();
    _watchSubscription = client.watch([rootKeyId]).listen((event) {
      switch (event) {
        case BeamingSetEvent(:final keyValue):
          _applyValue(keyValue);
        case BeamingSnapshotReplacedEvent():
          // A real Flutter app would usually refresh state here.
          break;
      }
    });
  }

  Future<void> dispose() async {
    await _watchSubscription?.cancel();
  }

  void _applyValue(BeamingValue nextValue) {
    final current = snapshot.toList();
    final index = current.indexWhere(
      (value) => value.key.keyId == nextValue.key.keyId,
    );
    if (index == -1) {
      current.add(nextValue);
    } else {
      current[index] = nextValue;
    }
    snapshot = List<BeamingValue>.unmodifiable(current);
  }
}
