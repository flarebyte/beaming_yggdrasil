import 'dart:convert';

import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

import 'support/chatty_e2e_helpers.dart';
import 'support/chatty_harness.dart';

void main() {
  test('chatty snapshot bootstrap stays deterministic end to end', () async {
    final harness = await ChattyHarness.start();
    if (harness == null) {
      return;
    }
    addTearDown(harness.stop);

    const setSnapshotRequest = <String, Object?>{
      'id': 'req-set-snapshot-001',
      'key': {
        'keyId': rootKeyId,
        'secureKeyId': 'ok',
      },
      'keyValueList': [
        {
          'key': {
            'keyId': '$rootKeyId:note:n7c401c2:text',
            'secureKeyId': 'ok',
            'version': 'v1',
          },
          'value': 'hello world',
        },
        {
          'key': {
            'keyId': '$rootKeyId:note:n7c401c2:like:count',
            'secureKeyId': 'ok',
            'version': 'v1',
          },
          'value': '3',
        },
      ],
    };

    const getSnapshotRequest = <String, Object?>{
      'id': 'req-get-snapshot-001',
      'key': {
        'keyId': rootKeyId,
        'secureKeyId': 'ok',
      },
    };

    final setResponse = await harness.requestJson(
      'PUT',
      '/snapshot',
      jsonBody: setSnapshotRequest,
    );
    expect(setResponse.statusCode, 200);

    final firstResponse = await harness.requestJson(
      'GET',
      '/snapshot',
      jsonBody: getSnapshotRequest,
    );
    final secondResponse = await harness.requestJson(
      'GET',
      '/snapshot',
      jsonBody: getSnapshotRequest,
    );
    final firstEnvelope =
        BeamingRestEnvelope.fromJson<BeamingGetSnapshotResponseData>(
      jsonDecode(firstResponse.body) as Map<String, Object?>,
      BeamingGetSnapshotResponseData.fromJson,
    );
    final secondEnvelope =
        BeamingRestEnvelope.fromJson<BeamingGetSnapshotResponseData>(
      jsonDecode(secondResponse.body) as Map<String, Object?>,
      BeamingGetSnapshotResponseData.fromJson,
    );

    expect(firstResponse.statusCode, 200);
    expect(firstEnvelope.status, 'ok');
    expect(
      firstEnvelope.data.keyValueList.map((item) => item.key.keyId).toList(),
      secondEnvelope.data.keyValueList.map((item) => item.key.keyId).toList(),
    );
    expect(
      firstEnvelope.data.keyValueList.map((item) => item.value).toList(),
      secondEnvelope.data.keyValueList.map((item) => item.value).toList(),
    );
  }, timeout: const Timeout(Duration(seconds: 20)));
}
