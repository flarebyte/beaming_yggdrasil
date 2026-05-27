import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  test('builders throw invalidRequest errors for missing required fields', () {
    expect(
      () => BeamingClientKeyBuilder().build(),
      throwsA(
        isA<BeamingClientError>()
            .having((error) => error.kind, 'kind',
                BeamingClientErrorKind.invalidRequest)
            .having((error) => error.message, 'message', contains('keyId')),
      ),
    );

    expect(
      () => BeamingValueBuilder().setValue('oak').build(),
      throwsA(
        isA<BeamingClientError>()
            .having((error) => error.kind, 'kind',
                BeamingClientErrorKind.invalidRequest)
            .having((error) => error.message, 'message', contains('key')),
      ),
    );
  });

  test('rest decoding throws invalidResponse errors for malformed payloads',
      () {
    expect(
      () => BeamingGetSnapshotResponseData.fromJson(<String, Object?>{
        'key': 'not-an-object',
        'keyValueList': const [],
      }),
      throwsA(
        isA<BeamingClientError>().having(
          (error) => error.kind,
          'kind',
          BeamingClientErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test(
      'websocket decoding throws protocolViolation errors for invalid messages',
      () {
    expect(
      () => BeamingServerMessage.fromJson(<String, Object?>{
        'kind': 'mystery',
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
        'kind': 'event',
        'event': <String, Object?>{
          'eventId': 'event-1',
          'rootKey': <String, Object?>{'keyId': 'roots/oak'},
          'operation': 'snapshot-replaced',
          'created': 'created-1',
        },
      }).toJson(),
      returnsNormally,
    );

    expect(
      () => BeamingEventEnvelope.fromJson(<String, Object?>{
        'eventId': 'event-2',
        'rootKey': <String, Object?>{'keyId': 'roots/oak'},
        'operation': 'snapshot-replaced',
        'created': 'created-2',
      }).toEvent(),
      throwsA(
        isA<BeamingClientError>().having(
          (error) => error.kind,
          'kind',
          BeamingClientErrorKind.protocolViolation,
        ),
      ),
    );
  });
}
