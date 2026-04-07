import 'dart:convert';

import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

import 'support/chatty_e2e_helpers.dart';
import 'support/chatty_harness.dart';

void main() {
  test('chatty node read write and outdated flows decode end to end', () async {
    final harness = await ChattyHarness.start();
    if (harness == null) {
      return;
    }
    addTearDown(harness.stop);

    final setResponse = await harness.requestJson(
      'PUT',
      '/node',
      jsonBody: const <String, Object?>{
        'id': 'req-set-node-e2e-001',
        'rootKey': {
          'keyId': rootKeyId,
          'secureKeyId': 'ok',
        },
        'keyValueList': [
          {
            'key': {
              'keyId': rootKeyId,
              'secureKeyId': 'ok',
              'version': 'v1',
            },
            'value': 'root-is-not-a-node-child',
          },
          {
            'key': {
              'keyId': '$rootKeyId:note:n7c401c2:text',
              'secureKeyId': 'ok',
              'version': 'v1',
            },
            'value': 'hello world',
          },
        ],
      },
    );
    final setEnvelope =
        BeamingRestEnvelope.fromJson<BeamingSetKeyValueResponseData>(
      jsonDecode(setResponse.body) as Map<String, Object?>,
      BeamingSetKeyValueResponseData.fromJson,
    );

    expect(setResponse.statusCode, 200);
    expect(
      setEnvelope.data.keyList.map((item) => item.status).toList(),
      ['invalid', 'ok'],
    );

    final getResponse = await harness.requestJson(
      'GET',
      '/node',
      jsonBody: const <String, Object?>{
        'id': 'req-get-node-e2e-001',
        'rootKey': {
          'keyId': rootKeyId,
          'secureKeyId': 'ok',
        },
        'keyList': [
          {
            'keyId': '$rootKeyId:note:n7c401c2:text',
            'secureKeyId': 'ok',
          },
          {
            'keyId': '$rootKeyId:note:n7c401c2:missing:text',
            'secureKeyId': 'ok',
          },
        ],
      },
    );
    final getEnvelope =
        BeamingRestEnvelope.fromJson<BeamingGetKeyValueResponseData>(
      jsonDecode(getResponse.body) as Map<String, Object?>,
      BeamingGetKeyValueResponseData.fromJson,
    );

    expect(getResponse.statusCode, 200);
    expect(
      getEnvelope.data.keyValueList.map((item) => item.status).toList(),
      ['ok', 'invalid'],
    );

    final seeded = await harness.requestJson(
      'PUT',
      '/node',
      jsonBody: const <String, Object?>{
        'id': 'req-set-node-e2e-002',
        'rootKey': {
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
            'value': 'before',
          },
        ],
      },
    );
    final seededEnvelope =
        BeamingRestEnvelope.fromJson<BeamingSetKeyValueResponseData>(
      jsonDecode(seeded.body) as Map<String, Object?>,
      BeamingSetKeyValueResponseData.fromJson,
    );

    expect(seeded.statusCode, 200);
    expect(seededEnvelope.status, 'ok');
    expect(seededEnvelope.data.keyList.single.status, 'ok');
    expect(seededEnvelope.data.keyList.single.key.version, 'v2');

    final stale = await harness.requestJson(
      'PUT',
      '/node',
      jsonBody: const <String, Object?>{
        'id': 'req-set-node-e2e-003',
        'rootKey': {
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
            'value': 'after',
          },
        ],
      },
    );
    final staleEnvelope =
        BeamingRestEnvelope.fromJson<BeamingSetKeyValueResponseData>(
      jsonDecode(stale.body) as Map<String, Object?>,
      BeamingSetKeyValueResponseData.fromJson,
    );

    expect(stale.statusCode, 409);
    expect(staleEnvelope.status, 'outdated');
    expect(staleEnvelope.data.keyList.single.status, 'outdated');
  }, timeout: const Timeout(Duration(seconds: 20)));
}
