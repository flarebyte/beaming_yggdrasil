import 'dart:convert';
import 'dart:io';

import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

import 'support/chatty_e2e_helpers.dart';
import 'support/chatty_harness.dart';

void main() {
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
          'rootKeys': [rootKeyId],
        }),
      );
      final subscribed = await readServerMessage(messages);
      expect(subscribed, isA<BeamingSubscribedMessage>());
      expect((subscribed as BeamingSubscribedMessage).rootKeys, [rootKeyId]);

      socket.add(
        jsonEncode(const <String, Object?>{
          'id': 'ping-e2e-001',
          'kind': 'ping',
        }),
      );
      final pong = await readServerMessage(messages);
      expect(pong, isA<BeamingPongMessage>());
      expect((pong as BeamingPongMessage).id, 'ping-e2e-001');

      final nextEventFuture = readServerMessage(messages);
      await harness.requestJson(
        'PUT',
        '/node',
        jsonBody: const <String, Object?>{
          'id': 'req-set-node-event-e2e-001',
          'rootKey': {
            'keyId': rootKeyId,
            'secureKeyId': 'ok',
          },
          'keyValueList': [
            {
              'key': {
                'keyId': '$rootKeyId:note:n7c401c2:text',
                'secureKeyId': 'ok',
              },
              'value': 'hello world',
            },
          ],
        },
      );
      final eventMessage = await nextEventFuture;
      expect(eventMessage, isA<BeamingEventMessage>());
      final decodedEvent =
          (eventMessage as BeamingEventMessage).event.toEvent();
      expect(decodedEvent, isA<BeamingSetEvent>());

      socket.add(
        jsonEncode(const <String, Object?>{
          'id': 'sub-e2e-002',
          'kind': 'subscribe',
          'rootKeys': ['not-allowed'],
        }),
      );
      final invalid = await readServerMessage(messages);
      expect(invalid, isA<BeamingStatusMessage>());
      expect((invalid as BeamingStatusMessage).status, 'invalid');
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
