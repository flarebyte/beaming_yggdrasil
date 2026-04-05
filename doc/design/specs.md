# beaming_yggdrasil Design

Transport-first Dart client spec for the chatty mock server.

## 01 Overview

Purpose, scope, and package boundary.

### 01 Intent

What the Dart client should own and what it should leave to other libraries.

#### Client Overview

```markdown
# beaming_yggdrasil Overview

## Purpose

`beaming_yggdrasil` should be a Dart client library for the `chatty` mock server and compatible Yggdrasil-style services.

The library should make the transport contract easy to use from Dart applications without pretending to be the authority on `keyId` structure.

## Main Responsibilities

- send REST requests that match the mock server payload formats
- decode shallow REST response envelopes
- open and manage the optional WebSocket connection
- send WebSocket commands and decode event messages
- preserve correlation ids and status values
- expose practical Dart-friendly client abstractions over the wire DTOs

## Explicit Non-Goals

- do not parse the full logical key grammar in this package
- do not derive authoritative `kind` values from `keyId`
- do not duplicate server access-control logic
- do not mix local persistence concerns into the transport contract

## Key Boundary

For this client, `keyId` should normally be treated as an opaque string.

Minimal expectations:

- a request may require a `keyId` string
- the client may preserve optional client-supplied `kind` hints in DTOs
- the client must not invent server-derived key semantics locally unless a future dedicated key library is introduced

If richer key tooling is needed later, it should live in a separate Dart package and compose with `beaming_yggdrasil`.

## Planned Surface

The client spec currently assumes these major areas:

- snapshot client methods
- node read and write client methods
- create client methods
- optional admin commands for test harness usage
- optional WebSocket subscription and event handling

## Practical API Direction

The eventual Dart package should likely provide:

- DTO classes for request and response payloads
- a small HTTP client wrapper
- a WebSocket session wrapper
- typed status enums or string constants
- a transport error model that preserves server status and message content

It should avoid:

- a large code-generated schema framework before the core flows are pleasant to use
- committing the package to heavyweight `keyId` modeling too early
```

#### beaming_yggdrasil Specs

```markdown
# beaming_yggdrasil Specs

This folder contains draft specs for the Dart client library `beaming_yggdrasil`.

Repository target:

- GitHub project: `beaming_yggdrasil`

Client goal:

- provide a Dart client for the `chatty` mock server
- conform to the shipped REST and WebSocket payload formats
- keep key handling intentionally lightweight
- avoid embedding strong `keyId` parsing or validation rules that are better owned by a separate key library

## Design Intent

`beaming_yggdrasil` should be a transport-first client library.

It should own:

- request and response DTOs
- REST endpoint calls
- WebSocket command and event payloads
- shallow envelope handling
- correlation id plumbing
- practical client-side error mapping

It should not own:

- authoritative `keyId` grammar
- deep key derivation rules
- full access-scope evaluation
- server-side kind derivation logic

## Folder Layout

- [overview.md](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/overview.md)
- [examples/usecases.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/usecases.csv)
- [examples/client-scope.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/client-scope.csv)
- [examples/rest-actions.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/rest-actions.csv)
- [examples/websocket-actions.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/websocket-actions.csv)
- [examples/error-mapping.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/error-mapping.csv)
- [examples/key-boundary.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/key-boundary.csv)
- [examples/common.ts](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/common.ts)
- [examples/rest-client.ts](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/rest-client.ts)
- [examples/websocket-client.ts](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/websocket-client.ts)

## Notes

- The `.ts` files are payload-shape examples, not implementation language requirements.
- The CSV files are intended to stay readable and easy to review without heavy Flyb or CUE machinery.
- The source protocol reference remains [doc/design/yggdrasil-mock-server.md](/Users/olivier/Documents/github/chatty-ratatoskr/doc/design/yggdrasil-mock-server.md).
```

### 02 Use Cases

Core client workflows and success criteria.

#### Client Scope

| area | in_scope | out_of_scope |
| --- | --- | --- |
| rest-payloads | encode and decode shipped request response envelopes | server-side business logic |
| websocket-payloads | encode and decode command and event messages | event-store persistence |
| key-handling | carry keyId strings and optional kind hints | full key grammar and derivation rules |
| error-model | map HTTP and websocket statuses into practical client errors | changing server status semantics |
| test-support | support mock-server admin flows as optional APIs | production-only operations not present in chatty |
| local-state | allow app code to build on DTOs if needed | shipping a full offline sync engine in this package |

#### Use Cases

| minimum_client_support | priority | usecase | why_it_matters |
| --- | --- | --- | --- |
| send PUT /snapshot and GET /snapshot payloads and decode envelopes | 1 | snapshot bootstrap | lets a Dart app load baseline state quickly |
| send GET /node and PUT /node payloads and preserve item order | 2 | targeted node read and write | lets a Dart app update and query specific values without full snapshot reload |
| surface outdated status and HTTP 409 without hiding server details | 3 | optimistic conflict handling | lets a Dart app detect stale writes cleanly |
| send POST /create and preserve localKeyId mappings | 4 | create provisional records | lets a Dart app map local placeholders to server-generated keys |
| send subscribe/unsubscribe/ping and decode event messages | 5 | websocket sync | lets a Dart app receive incremental updates after bootstrap |
| support admin commands separately from protocol APIs | 6 | admin reset for tests | lets integration tests reset mock state quickly |

## 02 REST Contract

HTTP actions and payload responsibilities.

### 01 REST Actions

Supported REST endpoint actions for the client.

#### REST Actions

| action | method | notes | path | request_body | response_shape |
| --- | --- | --- | --- | --- | --- |
| setSnapshot | PUT | replaces authoritative snapshot for one root key | /snapshot | SetSnapshotRequest | Envelope<SetSnapshotResponseData> |
| getSnapshot | GET | returns deterministic keyValueList ordering from server | /snapshot | GetSnapshotRequest | Envelope<GetSnapshotResponseData> |
| setNode | PUT | preserves item order and item statuses | /node | SetKeyValueRequest | Envelope<SetKeyValueResponseData> |
| getNode | GET | returns requested item order and item statuses | /node | GetKeyValueRequest | Envelope<GetKeyValueResponseData> |
| create | POST | preserves localKeyId and child ordering | /create | NewKeysRequest | Envelope<NewKeysResponseData> |
| setAdminCommands | PUT | optional mock-only surface for tests | /admin/commands | SetAdminCommandsRequest | Envelope<SetAdminCommandsResponseData> |
| getAdminCommand | GET | optional mock-only surface for tests | /admin/commands | GetAdminCommandRequest | Envelope<GetAdminCommandResponseData> |

#### REST Client Example Shapes

```ts
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
  setSnapshot(
    request: SetSnapshotRequest,
  ): Promise<Envelope<{ key: KeyParams }>>;

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

// Dart translation guidance:
// - prefer value classes or freezed-style DTOs if the repo uses them
// - keep field names aligned with the wire format
// - do not force a rich key parser into this package
```

### 02 Error Mapping

How server responses should map into client-facing transport outcomes.

#### Error Mapping

| client_expectation | server_signal | transport |
| --- | --- | --- |
| surface a typed invalid response or error with server message preserved | 400 invalid | http |
| surface conflict semantics without rewriting the message | 409 outdated | http |
| preserve oversize failure distinctly from malformed JSON | 413 invalid | http |
| keep top-level success separate from item-level failure details | 200 ok with item-level invalid | http |
| treat as protocol-level invalid command not socket death | status invalid | websocket |
| surface transport error with close context when available | connection close due to limits | websocket |
| do not assume every message is a response to a prior command | event payloads | websocket |

## 03 WebSocket Contract

Optional websocket session responsibilities.

### 01 WebSocket Actions

Command and message kinds used by the optional event channel.

#### WebSocket Actions

| direction | kind | minimum_client_behavior | purpose |
| --- | --- | --- | --- |
| client->server | subscribe | send rootKeys and preserve correlation id if supplied | add allowed root subscriptions |
| client->server | unsubscribe | handle successful no-op unsubscribe | remove subscribed roots |
| client->server | ping | decode pong and preserve correlation id | explicit application-level heartbeat |
| server->client | subscribed | update client session state if needed | acknowledge active roots |
| server->client | unsubscribed | allow empty remaining root set | acknowledge remaining roots |
| server->client | pong | keep separate from transport-level websocket ping/pong | confirm application-level reachability |
| server->client | status | do not collapse this into transport failure | report invalid command or invalid root |
| server->client | event | decode event envelope and route by operation | deliver set or snapshot-replaced changes |

#### WebSocket Client Example Shapes

```ts
import type { EventEnvelope } from './common';

export type ClientMessage =
  | {
      id?: string;
      kind: 'subscribe';
      rootKeys: string[];
    }
  | {
      id?: string;
      kind: 'unsubscribe';
      rootKeys: string[];
    }
  | {
      id?: string;
      kind: 'ping';
    };

export type ServerMessage =
  | {
      id?: string;
      kind: 'subscribed';
      rootKeys?: string[];
    }
  | {
      id?: string;
      kind: 'unsubscribed';
      rootKeys?: string[];
    }
  | {
      id?: string;
      kind: 'pong';
    }
  | {
      id?: string;
      kind: 'status';
      status: string;
      message?: string;
    }
  | {
      kind: 'event';
      event: EventEnvelope;
    };

export interface BeamingYggdrasilWebSocketSession {
  send(message: ClientMessage): Promise<void>;
  messages(): AsyncIterable<ServerMessage>;
  close(): Promise<void>;
}

// Dart translation guidance:
// - keep websocket command DTOs close to the wire
// - preserve correlation ids when supplied
// - expose event messages directly rather than hiding them behind imperative callbacks only
```

## 04 Key Boundary

Explicit separation between transport DTOs and key semantics.

### 01 Key Boundary

Why this package keeps key handling intentionally lightweight.

#### Common Payload Shapes

```ts
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
```

#### Key Boundary

| client_rule | rationale | topic |
| --- | --- | --- |
| treat as opaque string by default | server is the current authority on accepted key grammar | keyId |
| allow optional hint fields in DTOs but do not trust them as authoritative | server may ignore or derive kind values | kind |
| preserve client-side placeholders across create flows | this is needed for provisional object mapping | localKeyId |
| preserve exact server version strings and send them back on optimistic writes | client should not invent version formats | version |
| carry mock or auth-related values through the payload without interpreting them deeply | server controls forcing and validation behavior | secureKeyId |
| limit client validation to nullability and obvious request-shape checks | avoid duplicating parsing logic that may move into another package | key-validation |

