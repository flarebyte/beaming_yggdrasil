import 'dart:convert';
import 'dart:io';

import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

import 'support/chatty_harness.dart';

const _rootKeyId = 'tenant:t8f3a1c2:group:g4b7d9e1:dashboard:d1e52f07';

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
        'keyId': _rootKeyId,
        'secureKeyId': 'ok',
      },
      'keyValueList': [
        {
          'key': {
            'keyId': '$_rootKeyId:note:n7c401c2:text',
            'secureKeyId': 'ok',
            'version': 'v1',
          },
          'value': 'hello world',
        },
        {
          'key': {
            'keyId': '$_rootKeyId:note:n7c401c2:like:count',
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
        'keyId': _rootKeyId,
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
          'keyId': _rootKeyId,
          'secureKeyId': 'ok',
        },
        'keyValueList': [
          {
            'key': {
              'keyId': _rootKeyId,
              'secureKeyId': 'ok',
              'version': 'v1',
            },
            'value': 'root-is-not-a-node-child',
          },
          {
            'key': {
              'keyId': '$_rootKeyId:note:n7c401c2:text',
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
          'keyId': _rootKeyId,
          'secureKeyId': 'ok',
        },
        'keyList': [
          {
            'keyId': '$_rootKeyId:note:n7c401c2:text',
            'secureKeyId': 'ok',
          },
          {
            'keyId': '$_rootKeyId:note:n7c401c2:missing:text',
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
          'keyId': _rootKeyId,
          'secureKeyId': 'ok',
        },
        'keyValueList': [
          {
            'key': {
              'keyId': '$_rootKeyId:note:n7c401c2:text',
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
          'keyId': _rootKeyId,
          'secureKeyId': 'ok',
        },
        'keyValueList': [
          {
            'key': {
              'keyId': '$_rootKeyId:note:n7c401c2:text',
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
          'keyId': _rootKeyId,
          'secureKeyId': 'ok',
        },
        'newKeys': [
          {
            'key': {
              'localKeyId': 'tmp-note-1',
              'keyId': _rootKeyId,
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
              'keyId': _rootKeyId,
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

  test(
      'chatty websocket subscribe ping event and invalid root flows work end to end',
      () async {
    final harness = await ChattyHarness.start(websocketEnabled: true);
    if (harness == null) {
      return;
    }
    addTearDown(harness.stop);

    final socket = await WebSocket.connect(harness.eventsUrl);
    addTearDown(socket.close);
    final messages = socket
        .cast<String>()
        .map(
          (raw) => BeamingServerMessage.fromJson(
            jsonDecode(raw) as Map<String, Object?>,
          ),
        )
        .asBroadcastStream();

    socket.add(
      jsonEncode(const <String, Object?>{
        'id': 'sub-e2e-001',
        'kind': 'subscribe',
        'rootKeys': [_rootKeyId],
      }),
    );
    final subscribed = await _readServerMessage(messages);
    expect(subscribed, isA<BeamingSubscribedMessage>());
    expect((subscribed as BeamingSubscribedMessage).rootKeys, [_rootKeyId]);

    socket.add(
      jsonEncode(const <String, Object?>{
        'id': 'ping-e2e-001',
        'kind': 'ping',
      }),
    );
    final pong = await _readServerMessage(messages);
    expect(pong, isA<BeamingPongMessage>());
    expect((pong as BeamingPongMessage).id, 'ping-e2e-001');

    final nextEventFuture = _readServerMessage(messages);
    await harness.requestJson(
      'PUT',
      '/node',
      jsonBody: const <String, Object?>{
        'id': 'req-set-node-event-e2e-001',
        'rootKey': {
          'keyId': _rootKeyId,
          'secureKeyId': 'ok',
        },
        'keyValueList': [
          {
            'key': {
              'keyId': '$_rootKeyId:note:n7c401c2:text',
              'secureKeyId': 'ok',
            },
            'value': 'hello world',
          },
        ],
      },
    );
    final eventMessage = await nextEventFuture;
    expect(eventMessage, isA<BeamingEventMessage>());
    final decodedEvent = (eventMessage as BeamingEventMessage).event.toEvent();
    expect(decodedEvent, isA<BeamingSetEvent>());

    socket.add(
      jsonEncode(const <String, Object?>{
        'id': 'sub-e2e-002',
        'kind': 'subscribe',
        'rootKeys': ['not-allowed'],
      }),
    );
    final invalid = await _readServerMessage(messages);
    expect(invalid, isA<BeamingStatusMessage>());
    expect((invalid as BeamingStatusMessage).status, 'invalid');
  }, timeout: const Timeout(Duration(seconds: 20)));
}

Future<BeamingServerMessage> _readServerMessage(
  Stream<BeamingServerMessage> messages,
) {
  return messages.first.timeout(const Duration(seconds: 5));
}
