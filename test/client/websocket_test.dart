import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

import '../../support/in_memory_harness.dart';

void main() {
  test(
      'in-memory websocket session acknowledges subscribe ping and unsubscribe',
      () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);
    final nextMessages = harness.webSocketSession.messages().take(3).toList();

    await harness.webSocketSession.send(
      const BeamingSubscribeMessage(
        id: 'sub-1',
        rootKeys: ['roots/oak'],
      ),
    );
    await harness.webSocketSession.send(
      const BeamingPingMessage(id: 'ping-1'),
    );
    await harness.webSocketSession.send(
      const BeamingUnsubscribeMessage(
        id: 'unsub-1',
        rootKeys: ['roots/oak'],
      ),
    );

    final messages = await nextMessages;

    expect(messages[0], isA<BeamingSubscribedMessage>());
    expect((messages[0] as BeamingSubscribedMessage).rootKeys, ['roots/oak']);
    expect(messages[1], isA<BeamingPongMessage>());
    expect((messages[1] as BeamingPongMessage).id, 'ping-1');
    expect(messages[2], isA<BeamingUnsubscribedMessage>());
    expect((messages[2] as BeamingUnsubscribedMessage).rootKeys, isEmpty);
  });

  test('websocket session emits typed event messages for subscribed roots',
      () async {
    final harness = createBeamingInMemoryHarness();
    addTearDown(harness.close);

    await harness.webSocketSession.send(
      const BeamingSubscribeMessage(
        id: 'sub-1',
        rootKeys: ['roots/oak'],
      ),
    );

    final nextEventMessage = harness.webSocketSession.messages().firstWhere(
          (message) => message is BeamingEventMessage,
        );

    await harness.testingClient.replaceSnapshot(
      'roots/oak',
      [
        const BeamingValue(
          key: BeamingClientKey(keyId: 'roots/oak/title', version: 'v-2'),
          value: 'oak',
        ),
      ],
    );

    final message = await nextEventMessage as BeamingEventMessage;
    final event = message.event.toEvent();

    expect(message.event.eventId, 'event-1');
    expect(message.event.created, 'created-1');
    expect(event, isA<BeamingSnapshotReplacedEvent>());
    expect(
      (event as BeamingSnapshotReplacedEvent).rootKey.keyId,
      'roots/oak',
    );
  });

  test('server message json decodes back into the existing event model', () {
    final decoded = BeamingServerMessage.fromJson(<String, Object?>{
      'kind': 'event',
      'event': <String, Object?>{
        'eventId': 'event-7',
        'rootKey': <String, Object?>{
          'keyId': 'roots/oak',
          'version': 'root-v-3',
        },
        'operation': 'set',
        'created': 'created-7',
        'keyValue': <String, Object?>{
          'key': <String, Object?>{
            'keyId': 'roots/oak/title',
            'version': 'title-v-2',
          },
          'value': 'oak',
        },
      },
    });

    expect(decoded, isA<BeamingEventMessage>());
    final event = (decoded as BeamingEventMessage).event.toEvent();

    expect(event, isA<BeamingSetEvent>());
    expect((event as BeamingSetEvent).keyValue.key.keyId, 'roots/oak/title');
    expect(event.keyValue.value, 'oak');
  });
}
