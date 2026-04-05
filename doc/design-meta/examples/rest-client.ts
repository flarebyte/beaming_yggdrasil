import type { Envelope, KeyParams, KeyValueParams } from './common';

export type SetSnapshotRequest = {
  id?: string;
  key: KeyParams;
  keyValueList: KeyValueParams[];
};

export type GetSnapshotRequest = {
  id?: string;
  key: KeyParams;
};

export type SetKeyValueRequest = {
  id?: string;
  rootKey: KeyParams;
  keyValueList: KeyValueParams[];
};

export type GetKeyValueRequest = {
  id?: string;
  rootKey: KeyParams;
  keyList: KeyParams[];
};

export type NewKeysRequest = {
  id?: string;
  rootKey: KeyParams;
  newKeys: Array<{
    key: KeyParams;
    expectedKind: string;
    children: Array<{
      localKeyId: string;
      expectedKind: string;
    }>;
  }>;
};

export interface BeamingYggdrasilRestClient {
  getSnapshot(
    request: GetSnapshotRequest,
  ): Promise<Envelope<{ key: KeyParams; keyValueList: KeyValueParams[] }>>;

  setNode(
    request: SetKeyValueRequest,
  ): Promise<
    Envelope<{
      rootKey: KeyParams;
      keyList: Array<{
        key: KeyParams;
        status: string;
        message?: string;
      }>;
    }>
  >;

  getNode(
    request: GetKeyValueRequest,
  ): Promise<
    Envelope<{
      rootKey: KeyParams;
      keyValueList: Array<{
        keyValue: KeyValueParams;
        status: string;
        message?: string;
      }>;
    }>
  >;

  create(
    request: NewKeysRequest,
  ): Promise<
    Envelope<{
      rootKey: KeyParams;
      newKeys: Array<{
        key: KeyParams;
        status: string;
        message?: string;
        children: Array<{
          key: KeyParams;
          status: string;
          message?: string;
        }>;
      }>;
    }>
  >;
}

export interface BeamingYggdrasilTestingClient {
  setSnapshot(
    request: SetSnapshotRequest,
  ): Promise<Envelope<{ key: KeyParams }>>;
}

// Dart translation guidance:
// - prefer value classes or freezed-style DTOs if the repo uses them
// - keep field names aligned with the wire format
// - do not force a rich key parser into this package
