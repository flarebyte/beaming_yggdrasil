import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  group('REST common DTOs', () {
    test('key params convert from and to client key', () {
      const clientKey = BeamingClientKey(
        keyId: 'roots/oak',
        version: 'v-1',
        localKeyId: 'local-root',
      );

      final params = BeamingKeyParams.fromClientKey(clientKey);

      expect(params.toJson(), <String, Object?>{
        'keyId': 'roots/oak',
        'version': 'v-1',
        'localKeyId': 'local-root',
      });
      final converted = params.toClientKey();
      expect(converted.keyId, clientKey.keyId);
      expect(converted.version, clientKey.version);
      expect(converted.localKeyId, clientKey.localKeyId);
    });

    test('key value params convert from and to value', () {
      const value = BeamingValue(
        key: BeamingClientKey(keyId: 'roots/oak/title', version: 'v-2'),
        value: 'oak',
      );

      final params = BeamingKeyValueParams.fromValue(value);

      final converted = params.toValue();
      expect(converted.key.keyId, value.key.keyId);
      expect(converted.key.version, value.key.version);
      expect(converted.value, value.value);
      expect(params.toJson()['key'], <String, Object?>{
        'keyId': 'roots/oak/title',
        'version': 'v-2',
      });
    });

    test('envelope round-trips custom payload decoders', () {
      final json = BeamingRestEnvelope<BeamingSetSnapshotResponseData>(
        id: 'req-1',
        status: 'ok',
        message: 'accepted',
        data: const BeamingSetSnapshotResponseData(
          key: BeamingKeyParams(keyId: 'roots/oak'),
        ),
      ).toJson((data) => data.toJson());

      final decoded =
          BeamingRestEnvelope.fromJson<BeamingSetSnapshotResponseData>(
        json,
        BeamingSetSnapshotResponseData.fromJson,
      );

      expect(decoded.id, 'req-1');
      expect(decoded.status, 'ok');
      expect(decoded.message, 'accepted');
      expect(decoded.data.key.keyId, 'roots/oak');
    });

    test('invalid wire field types throw invalidResponse errors', () {
      expect(
        () => BeamingGetSnapshotRequest.fromJson(<String, Object?>{
          'key': 'not-an-object',
        }),
        throwsA(
          isA<BeamingClientError>().having(
            (error) => error.kind,
            'kind',
            BeamingClientErrorKind.invalidResponse,
          ),
        ),
      );

      expect(
        () => BeamingGetKeyValueRequest.fromJson(<String, Object?>{
          'rootKey': <String, Object?>{'keyId': 'roots/oak'},
          'keyList': <Object?>['not-an-object'],
        }),
        throwsA(isA<BeamingClientError>()),
      );

      expect(
        () => BeamingKeyParams.fromJson(<String, Object?>{
          'keyId': '',
        }),
        throwsA(isA<BeamingClientError>()),
      );
    });
  });

  group('REST requests round-trip', () {
    test('getSnapshot request omits optional id when null', () {
      const request = BeamingGetSnapshotRequest(
        key: BeamingKeyParams(keyId: 'roots/oak'),
      );

      expect(request.toJson(), <String, Object?>{
        'key': <String, Object?>{'keyId': 'roots/oak'},
      });
    });

    test('all request DTOs round-trip with optional ids', () {
      final setSnapshot = BeamingSetSnapshotRequest.fromJson(<String, Object?>{
        'id': 'req-1',
        'key': <String, Object?>{'keyId': 'roots/oak'},
        'keyValueList': <Object?>[
          <String, Object?>{
            'key': <String, Object?>{'keyId': 'roots/oak/title'},
            'value': 'oak',
          },
        ],
      });
      final setNode = BeamingSetKeyValueRequest.fromJson(<String, Object?>{
        'id': 'req-2',
        'rootKey': <String, Object?>{'keyId': 'roots/oak'},
        'keyValueList': <Object?>[
          <String, Object?>{
            'key': <String, Object?>{'keyId': 'roots/oak/title'},
            'value': 'new-oak',
          },
        ],
      });
      final getNode = BeamingGetKeyValueRequest.fromJson(<String, Object?>{
        'id': 'req-3',
        'rootKey': <String, Object?>{'keyId': 'roots/oak'},
        'keyList': <Object?>[
          <String, Object?>{'keyId': 'roots/oak/title'},
        ],
      });
      final create = BeamingNewKeysRequest.fromJson(<String, Object?>{
        'id': 'req-4',
        'rootKey': <String, Object?>{'keyId': 'roots/oak'},
        'newKeys': <Object?>[
          <String, Object?>{
            'key': <String, Object?>{'keyId': 'roots/oak/branch'},
            'expectedKind': 'branch',
            'children': <Object?>[
              <String, Object?>{
                'localKeyId': 'local-leaf',
                'expectedKind': 'leaf',
              },
            ],
          },
        ],
      });

      expect(setSnapshot.toJson()['id'], 'req-1');
      expect(setNode.toJson()['id'], 'req-2');
      expect(getNode.toJson()['id'], 'req-3');
      expect(create.toJson()['id'], 'req-4');
    });

    test('child and create request DTOs serialize and decode directly', () {
      const child = BeamingNewKeyChildRequest(
        localKeyId: 'leaf-local',
        expectedKind: 'leaf',
      );
      const create = BeamingNewKeyRequest(
        key: BeamingKeyParams(keyId: 'roots/oak/branch'),
        expectedKind: 'branch',
        children: [child],
      );

      final decodedChild = BeamingNewKeyChildRequest.fromJson(child.toJson());
      final decodedCreate = BeamingNewKeyRequest.fromJson(create.toJson());

      expect(decodedChild.localKeyId, 'leaf-local');
      expect(decodedChild.expectedKind, 'leaf');
      expect(decodedCreate.expectedKind, 'branch');
      expect(decodedCreate.children.single.localKeyId, 'leaf-local');
    });
  });

  group('REST responses round-trip', () {
    test('snapshot and setSnapshot response DTOs round-trip', () {
      const snapshot = BeamingGetSnapshotResponseData(
        key: BeamingKeyParams(keyId: 'roots/oak'),
        keyValueList: [
          BeamingKeyValueParams(
            key: BeamingKeyParams(keyId: 'roots/oak/title'),
            value: 'oak',
          ),
        ],
      );
      const setSnapshot = BeamingSetSnapshotResponseData(
        key: BeamingKeyParams(keyId: 'roots/oak'),
      );

      final snapshotDecoded =
          BeamingGetSnapshotResponseData.fromJson(snapshot.toJson());
      final setSnapshotDecoded =
          BeamingSetSnapshotResponseData.fromJson(setSnapshot.toJson());

      expect(snapshotDecoded.keyValueList.single.key.keyId, 'roots/oak/title');
      expect(setSnapshotDecoded.key.keyId, 'roots/oak');
    });

    test('status and create response DTOs round-trip', () {
      final setResponse = BeamingSetKeyValueResponseData.fromJson(
        <String, Object?>{
          'rootKey': <String, Object?>{'keyId': 'roots/oak'},
          'keyList': <Object?>[
            <String, Object?>{
              'key': <String, Object?>{'keyId': 'roots/oak/title'},
              'status': 'ok',
              'message': 'updated',
            },
          ],
        },
      );
      final getResponse = BeamingGetKeyValueResponseData.fromJson(
        <String, Object?>{
          'rootKey': <String, Object?>{'keyId': 'roots/oak'},
          'keyValueList': <Object?>[
            <String, Object?>{
              'keyValue': <String, Object?>{
                'key': <String, Object?>{'keyId': 'roots/oak/title'},
                'value': 'oak',
              },
              'status': 'ok',
            },
          ],
        },
      );
      final createResponse = BeamingNewKeysResponseData.fromJson(
        <String, Object?>{
          'rootKey': <String, Object?>{'keyId': 'roots/oak'},
          'newKeys': <Object?>[
            <String, Object?>{
              'key': <String, Object?>{'keyId': 'roots/oak/branch'},
              'status': 'ok',
              'children': <Object?>[
                <String, Object?>{
                  'key': <String, Object?>{'keyId': 'roots/oak/branch/leaf'},
                  'status': 'ok',
                },
              ],
            },
          ],
        },
      );

      expect(setResponse.toJson()['keyList'], isA<List<Object?>>());
      expect(getResponse.toJson()['keyValueList'], isA<List<Object?>>());
      expect(createResponse.toJson()['newKeys'], isA<List<Object?>>());
      expect(createResponse.newKeys.single.children.single.status, 'ok');
    });

    test('status item and new key response preserve optional message fields',
        () {
      const statusItem = BeamingStatusKeyValueItem(
        keyValue: BeamingKeyValueParams(
          key: BeamingKeyParams(keyId: 'roots/oak/title'),
          value: 'oak',
        ),
        status: 'ok',
      );
      const newKeyResponse = BeamingNewKeyResponse(
        key: BeamingKeyParams(keyId: 'roots/oak/branch'),
        status: 'ok',
        children: [
          BeamingNewKeyChildResponse(
            key: BeamingKeyParams(keyId: 'roots/oak/branch/leaf'),
            status: 'ok',
          ),
        ],
      );

      final statusJson = statusItem.toJson();
      final newKeyJson = newKeyResponse.toJson();

      expect(statusJson.containsKey('message'), isFalse);
      expect(newKeyJson.containsKey('message'), isFalse);
      expect(
        BeamingStatusKeyValueItem.fromJson(statusJson).status,
        'ok',
      );
      expect(BeamingNewKeyResponse.fromJson(newKeyJson).status, 'ok');
    });

    test('response DTO validates required status fields', () {
      expect(
        () => BeamingStatusKeyItem.fromJson(<String, Object?>{
          'key': <String, Object?>{'keyId': 'roots/oak/title'},
          'status': '',
        }),
        throwsA(isA<BeamingClientError>()),
      );

      expect(
        () => BeamingNewKeyChildResponse.fromJson(<String, Object?>{
          'key': <String, Object?>{'keyId': 'roots/oak/title'},
        }),
        throwsA(isA<BeamingClientError>()),
      );
    });
  });
}
