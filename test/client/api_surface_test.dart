import 'dart:async';

import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  test('public api surfaces can be stubbed independently', () async {
    final client = _FakeClient();
    final rxClient = _FakeRxClient();
    final testingClient = _FakeTestingClient();

    expect(await client.getSnapshot('roots/oak'), hasLength(1));
    expect(await rxClient.snapshot$('roots/oak').first, hasLength(1));
    expect(
      () => testingClient.replaceSnapshot('roots/oak', const []),
      returnsNormally,
    );
  });
}

class _FakeClient implements BeamingYggdrasilClient {
  @override
  Future<List<BeamingWriteResult>> createChildren(
    String rootKeyId,
    List<BeamingClientKey> provisionalKeys,
  ) async {
    return provisionalKeys
        .map(
          (key) => BeamingWriteResult(
            key: key,
            status: 'ok',
          ),
        )
        .toList();
  }

  @override
  Future<List<BeamingValue>> getNode(String rootKeyId, List<String> keyIds) async {
    return keyIds
        .map(
          (keyId) => BeamingValue(
            key: BeamingClientKey(keyId: keyId),
            value: 'value:$keyId',
          ),
        )
        .toList();
  }

  @override
  Future<List<BeamingValue>> getSnapshot(String rootKeyId) async {
    return [
      BeamingValue(
        key: BeamingClientKey(keyId: '$rootKeyId/title'),
        value: 'oak',
      ),
    ];
  }

  @override
  Future<List<BeamingWriteResult>> setNode(
    String rootKeyId,
    List<BeamingValue> values,
  ) async {
    return values
        .map(
          (value) => BeamingWriteResult(
            key: value.key,
            status: 'ok',
          ),
        )
        .toList();
  }

  @override
  Stream<BeamingEvent> watch(List<String> rootKeyIds) async* {
    yield BeamingSnapshotReplacedEvent(
      rootKey: BeamingClientKey(keyId: rootKeyIds.first),
      snapshotVersion: 'snapshot-v1',
    );
  }
}

class _FakeRxClient implements BeamingYggdrasilRxClient {
  @override
  Stream<List<BeamingValue>> node$(String rootKeyId, List<String> keyIds) async* {
    yield keyIds
        .map((keyId) => BeamingValue(key: BeamingClientKey(keyId: keyId)))
        .toList();
  }

  @override
  Stream<List<BeamingWriteResult>> setNode$(
    String rootKeyId,
    List<BeamingValue> values,
  ) async* {
    yield values
        .map((value) => BeamingWriteResult(key: value.key, status: 'ok'))
        .toList();
  }

  @override
  Stream<List<BeamingValue>> snapshot$(String rootKeyId) async* {
    yield [
      BeamingValue(
        key: BeamingClientKey(keyId: '$rootKeyId/title'),
        value: 'oak',
      ),
    ];
  }

  @override
  Stream<BeamingEvent> watch$(List<String> rootKeyIds) async* {
    yield BeamingSetEvent(
      rootKey: BeamingClientKey(keyId: rootKeyIds.first),
      keyValue: BeamingValue(
        key: BeamingClientKey(keyId: '${rootKeyIds.first}/title'),
        value: 'oak',
      ),
    );
  }
}

class _FakeTestingClient implements BeamingYggdrasilTestingClient {
  @override
  Future<void> replaceSnapshot(
    String rootKeyId,
    List<BeamingValue> values,
  ) async {}
}
