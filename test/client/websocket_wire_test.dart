import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  group('WebSocket client messages', () {
    test('serialize subscribe and unsubscribe messages with root keys', () {
      const subscribe = BeamingSubscribeMessage(
        id: 'sub-1',
        rootKeys: ['roots/oak'],
      );
      const unsubscribe = BeamingUnsubscribeMessage(
        id: 'unsub-1',
        rootKeys: ['roots/oak'],
      );

      expect(subscribe.toJson(), <String, Object?>{
        'id': 'sub-1',
        'kind': 'subscribe',
        'rootKeys': ['roots/oak'],
      });
      expect(unsubscribe.toJson(), <String, Object?>{
        'id': 'unsub-1',
        'kind': 'unsubscribe',
        'rootKeys': ['roots/oak'],
      });
    });

    test('serialize ping message', () {
      const ping = BeamingPingMessage(id: 'ping-1');
      expect(ping.toJson(), <String, Object?>{'id': 'ping-1', 'kind': 'ping'});
    });

    test('serialize client messages without optional id', () {
      const subscribe = BeamingSubscribeMessage(rootKeys: ['roots/oak']);
      const unsubscribe = BeamingUnsubscribeMessage(rootKeys: ['roots/oak']);
      const ping = BeamingPingMessage();

      expect(subscribe.toJson().containsKey('id'), isFalse);
      expect(unsubscribe.toJson().containsKey('id'), isFalse);
      expect(ping.toJson().containsKey('id'), isFalse);
    });
  });

  group('WebSocket server messages', () {
    test('decode all supported message kinds', () {
      final subscribed = BeamingServerMessage.fromJson(<String, Object?>{
        'id': 'sub-1',
        'kind': 'subscribed',
        'rootKeys': ['roots/oak'],
      });
      final unsubscribed = BeamingServerMessage.fromJson(<String, Object?>{
        'id': 'unsub-1',
        'kind': 'unsubscribed',
        'rootKeys': ['roots/oak'],
      });
      final pong = BeamingServerMessage.fromJson(<String, Object?>{
        'id': 'ping-1',
        'kind': 'pong',
      });
      final status = BeamingServerMessage.fromJson(<String, Object?>{
        'id': 'status-1',
        'kind': 'status',
        'status': 'invalid',
        'message': 'bad request',
      });
      final event = BeamingServerMessage.fromJson(<String, Object?>{
        'kind': 'event',
        'event': <String, Object?>{
          'eventId': 'event-1',
          'rootKey': <String, Object?>{'keyId': 'roots/oak'},
          'operation': 'snapshot-replaced',
          'created': 'created-1',
          'snapshotVersion': 'v-2',
        },
      });

      expect(subscribed, isA<BeamingSubscribedMessage>());
      expect(unsubscribed, isA<BeamingUnsubscribedMessage>());
      expect(pong, isA<BeamingPongMessage>());
      expect(status, isA<BeamingStatusMessage>());
      expect(event, isA<BeamingEventMessage>());
      expect((event as BeamingEventMessage).event.toEvent(),
          isA<BeamingSnapshotReplacedEvent>());
    });

    test('subscribed and unsubscribed tolerate missing rootKeys as empty list',
        () {
      final subscribed = BeamingServerMessage.fromJson(<String, Object?>{
        'kind': 'subscribed',
      }) as BeamingSubscribedMessage;
      final unsubscribed = BeamingServerMessage.fromJson(<String, Object?>{
        'kind': 'unsubscribed',
      }) as BeamingUnsubscribedMessage;

      expect(subscribed.rootKeys, isEmpty);
      expect(unsubscribed.rootKeys, isEmpty);
    });

    test('toJson on server message DTOs preserves wire fields', () {
      const status = BeamingStatusMessage(
        id: 'status-1',
        status: 'invalid',
        message: 'bad request',
      );
      final event = BeamingEventMessage(
        event: BeamingEventEnvelope.fromEvent(
          const BeamingSetEvent(
            rootKey: BeamingClientKey(keyId: 'roots/oak'),
            keyValue: BeamingValue(
              key: BeamingClientKey(keyId: 'roots/oak/title'),
              value: 'oak',
            ),
          ),
          eventId: 'event-1',
          created: 'created-1',
        ),
      );

      expect(status.toJson(), <String, Object?>{
        'id': 'status-1',
        'kind': 'status',
        'status': 'invalid',
        'message': 'bad request',
      });
      expect(event.toJson()['kind'], 'event');
      expect(event.toJson()['event'], isA<Map<String, Object?>>());
    });

    test('invalid payloads throw protocolViolation errors', () {
      expect(
        () => BeamingServerMessage.fromJson(<String, Object?>{
          'kind': 'unknown-kind',
        }),
        throwsA(
          isA<BeamingClientError>().having(
            (error) => error.kind,
            'kind',
            BeamingClientErrorKind.protocolViolation,
          ),
        ),
      );

      expect(
        () => BeamingServerMessage.fromJson(<String, Object?>{
          'kind': 1,
        }),
        throwsA(isA<BeamingClientError>()),
      );

      expect(
        () => BeamingServerMessage.fromJson(<String, Object?>{
          'kind': 'status',
          'status': '',
        }),
        throwsA(isA<BeamingClientError>()),
      );

      expect(
        () => BeamingServerMessage.fromJson(<String, Object?>{
          'kind': 'subscribed',
          'rootKeys': [123],
        }),
        throwsA(isA<BeamingClientError>()),
      );

      expect(
        () => BeamingServerMessage.fromJson(<String, Object?>{
          'kind': 'event',
          'event': 'bad-event',
        }),
        throwsA(isA<BeamingClientError>()),
      );
    });
  });
}
