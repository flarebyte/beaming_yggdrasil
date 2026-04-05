import 'package:beaming_yggdrasil/beaming_yggdrasil.dart';
import 'package:test/test.dart';

void main() {
  group('REST request DTOs', () {
    test('serialize getSnapshot with wire-aligned field names', () {
      const request = BeamingGetSnapshotRequest(
        id: 'req-1',
        key: BeamingKeyParams(
          keyId: 'roots/oak',
          version: 'v-1',
        ),
      );

      expect(request.toJson(), <String, Object?>{
        'id': 'req-1',
        'key': <String, Object?>{
          'keyId': 'roots/oak',
          'version': 'v-1',
        },
      });
    });

    test('preserve create request child order and localKeyId values', () {
      const request = BeamingNewKeysRequest(
        rootKey: BeamingKeyParams(keyId: 'roots/oak'),
        newKeys: [
          BeamingNewKeyRequest(
            key: BeamingKeyParams(
              keyId: 'roots/oak/branch',
              localKeyId: 'local-branch',
            ),
            expectedKind: 'branch',
            children: [
              BeamingNewKeyChildRequest(
                localKeyId: 'local-leaf-1',
                expectedKind: 'leaf',
              ),
              BeamingNewKeyChildRequest(
                localKeyId: 'local-leaf-2',
                expectedKind: 'leaf',
              ),
            ],
          ),
        ],
      );

      final json = request.toJson();
      final newKeys = json['newKeys'] as List<Object?>;
      final firstNewKey = newKeys.single as Map<String, Object?>;
      final children = firstNewKey['children'] as List<Object?>;

      expect(
        children,
        <Object?>[
          <String, Object?>{
            'localKeyId': 'local-leaf-1',
            'expectedKind': 'leaf',
          },
          <String, Object?>{
            'localKeyId': 'local-leaf-2',
            'expectedKind': 'leaf',
          },
        ],
      );
    });
  });

  group('REST response DTOs', () {
    test('decode getNode envelope while preserving item order and statuses',
        () {
      final envelope =
          BeamingRestEnvelope.fromJson<BeamingGetKeyValueResponseData>(
        <String, Object?>{
          'id': 'req-9',
          'status': 'ok',
          'data': <String, Object?>{
            'rootKey': <String, Object?>{
              'keyId': 'roots/oak',
              'version': 'root-v-2',
            },
            'keyValueList': <Object?>[
              <String, Object?>{
                'keyValue': <String, Object?>{
                  'key': <String, Object?>{
                    'keyId': 'roots/oak/title',
                    'version': 'title-v-2',
                  },
                  'value': 'oak',
                },
                'status': 'ok',
              },
              <String, Object?>{
                'keyValue': <String, Object?>{
                  'key': <String, Object?>{
                    'keyId': 'roots/oak/status',
                    'version': 'status-v-3',
                  },
                  'value': 'healthy',
                },
                'status': 'outdated',
                'message': 'expected a newer version',
              },
            ],
          },
        },
        BeamingGetKeyValueResponseData.fromJson,
      );

      expect(envelope.id, 'req-9');
      expect(envelope.status, 'ok');
      expect(
        envelope.data.keyValueList
            .map((item) => item.keyValue.key.keyId)
            .toList(),
        ['roots/oak/title', 'roots/oak/status'],
      );
      expect(
        envelope.data.keyValueList.map((item) => item.status).toList(),
        ['ok', 'outdated'],
      );
      expect(
        envelope.data.keyValueList.last.message,
        'expected a newer version',
      );
    });

    test('round-trip snapshot response data with immutable item ordering', () {
      const data = BeamingGetSnapshotResponseData(
        key: BeamingKeyParams(keyId: 'roots/oak'),
        keyValueList: [
          BeamingKeyValueParams(
            key: BeamingKeyParams(keyId: 'roots/oak/title'),
            value: 'oak',
          ),
          BeamingKeyValueParams(
            key: BeamingKeyParams(keyId: 'roots/oak/status'),
            value: 'healthy',
          ),
        ],
      );

      final decoded = BeamingGetSnapshotResponseData.fromJson(data.toJson());

      expect(
        decoded.keyValueList.map((item) => item.key.keyId).toList(),
        ['roots/oak/title', 'roots/oak/status'],
      );
      expect(
        () => decoded.keyValueList.add(
          const BeamingKeyValueParams(
            key: BeamingKeyParams(keyId: 'roots/oak/extra'),
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
