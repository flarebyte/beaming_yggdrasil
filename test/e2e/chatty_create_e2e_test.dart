import 'dart:convert';

import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

import 'support/chatty_e2e_helpers.dart';
import 'support/chatty_harness.dart';

void main() {
  test('chatty create workflow preserves local keys end to end', () async {
    final harness = await ChattyHarness.start();
    if (harness == null) {
      return;
    }
    addTearDown(harness.stop);

    final response = await harness.requestJson(
      'POST',
      '/create',
      jsonBody: const <String, Object?>{
        'id': 'req-create-e2e-001',
        'rootKey': {
          'keyId': rootKeyId,
          'secureKeyId': 'ok',
        },
        'newKeys': [
          {
            'key': {
              'localKeyId': 'tmp-note-1',
              'keyId': rootKeyId,
              'secureKeyId': 'ok',
            },
            'expectedKind': 'note',
            'children': [
              {
                'localKeyId': 'tmp-text-1',
                'expectedKind': 'text',
              },
              {
                'localKeyId': 'tmp-thumb-1',
                'expectedKind': 'thumbnail',
              },
            ],
          },
          {
            'key': {
              'localKeyId': 'tmp-note-2',
              'keyId': rootKeyId,
            },
            'expectedKind': 'invalid-kind',
            'children': [],
          },
        ],
      },
    );
    final envelope = BeamingRestEnvelope.fromJson<BeamingNewKeysResponseData>(
      jsonDecode(response.body) as Map<String, Object?>,
      BeamingNewKeysResponseData.fromJson,
    );

    expect(response.statusCode, 200);
    expect(envelope.status, 'ok');
    expect(
      envelope.data.newKeys.map((item) => item.key.localKeyId).toList(),
      ['tmp-note-1', 'tmp-note-2'],
    );
    expect(
      envelope.data.newKeys.map((item) => item.status).toList(),
      ['ok', 'invalid'],
    );
    expect(
      envelope.data.newKeys.first.children
          .map((item) => item.key.localKeyId)
          .toList(),
      ['tmp-text-1', 'tmp-thumb-1'],
    );
  }, timeout: const Timeout(Duration(seconds: 20)));
}
