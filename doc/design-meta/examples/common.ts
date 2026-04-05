export type KindParams = {
  hierarchy?: string[];
  language?: string;
};

export type KeyParams = {
  localKeyId?: string;
  keyId: string;
  secureKeyId?: string;
  version?: string;
  kind?: KindParams;
};

export type KeyValueParams = {
  key: KeyParams;
  value?: string;
};

export type Envelope<T> = {
  id: string;
  status: string;
  message?: string;
  data: T;
};

export type EventEnvelope = {
  eventId: string;
  rootKey: KeyParams;
  operation: 'set' | 'snapshot-replaced';
  created: string;
  key?: KeyParams;
  keyValue?: KeyValueParams;
  snapshotVersion?: string;
};
