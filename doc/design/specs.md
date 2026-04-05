# beaming_yggdrasil Design

Transport-first Dart client spec for the chatty mock server.

## 01 Overview

Purpose, scope, and package boundary.

### 01 Purpose and Scope

Repository target, client goal, and transport-first ownership boundaries.

#### Design Ownership

| category | not_owned_by_client | owned_by_client |
| --- | --- | --- |
| transport-dtos | authoritative protocol evolution | request and response DTOs |
| rest-surface | server-side business logic | REST endpoint calls |
| websocket-surface | event-store or broker persistence | WebSocket command and event payloads |
| envelopes | deep domain state derivation | shallow envelope handling |
| correlation | server-side request orchestration | preserve request ids and correlation ids |
| error-handling | changing canonical server status semantics | practical client-side error mapping |

#### Client Goals

| goal | rationale |
| --- | --- |
| provide a Dart client for the chatty mock server | give Dart applications a practical transport client for the mock Yggdrasil service |
| conform to the shipped REST and WebSocket payload formats | keep the client aligned with the server contracts it is expected to speak |
| keep key handling intentionally lightweight | avoid overcommitting the package to server-owned key semantics |
| avoid embedding strong keyId parsing or validation rules | leave deep key interpretation to a dedicated key library if one is needed later |

#### Explicit Non-Goals

| non_goal | reason |
| --- | --- |
| parse the full logical key grammar | this package should not become the authority on key semantics |
| derive authoritative kind values from keyId | the server remains the current source of truth for kind derivation |
| duplicate server access-control logic | permissions should not be reimplemented in the Dart transport client |
| mix local persistence concerns into the transport contract | offline storage belongs in a higher-level package or application layer |

#### Main Responsibilities

| responsibility | why_it_matters |
| --- | --- |
| send REST requests that match the mock server payload formats | client calls need to align with the transport contract |
| decode shallow REST response envelopes | applications need stable DTOs instead of raw maps |
| open and manage the optional WebSocket connection | realtime sync should be available without extra protocol glue in app code |
| send WebSocket commands and decode event messages | the client should cover both command and subscription traffic |
| preserve correlation ids and status values | callers need enough wire detail to debug and recover from failures |
| expose practical Dart-friendly client abstractions over the wire DTOs | the library should feel like a client package rather than a bag of JSON helpers |

#### Client Summary

`beaming_yggdrasil` is a transport-first Dart client library for the `chatty` mock server and compatible Yggdrasil-style services.

The package should make the wire contract easy to use from Dart without pretending to be the authority on `keyId` structure or other server-owned semantics.

### 02 Product Shape

Major client areas, scope boundaries, and preferred API direction.

#### Practical API Direction

| avoid | provide |
| --- | --- |
| a large code-generated schema framework before the core flows are pleasant to use | DTO classes for request and response payloads |
| overengineering transport composition before the main operations are stable | a small HTTP client wrapper |
| forcing applications to assemble subscription lifecycle handling manually | a WebSocket session wrapper |
| hiding wire status values behind overly opinionated abstractions | typed status enums or string constants |
| committing the package to heavyweight keyId modeling too early | a transport error model that preserves server status and message content |

#### Planned Surface

| intent | surface_area |
| --- | --- |
| bootstrap or replace state through snapshot endpoints | snapshot client methods |
| support targeted reads and writes without full snapshot reloads | node read and write client methods |
| map provisional local keys to server-generated keys | create client methods |
| keep mock-only controls available without polluting core application flows | optional admin commands for test harness usage |
| allow incremental updates after initial bootstrap | optional WebSocket subscription and event handling |

#### Client Scope

| area | in_scope | out_of_scope |
| --- | --- | --- |
| rest-payloads | encode and decode shipped request response envelopes | server-side business logic |
| websocket-payloads | encode and decode command and event messages | event-store persistence |
| key-handling | carry keyId strings and optional kind hints | full key grammar and derivation rules |
| error-model | map HTTP and websocket statuses into practical client errors | changing server status semantics |
| test-support | support mock-server admin flows as optional APIs | production-only operations not present in chatty |
| local-state | allow app code to build on DTOs if needed | shipping a full offline sync engine in this package |

#### Source Layout

| path | role |
| --- | --- |
| doc/design-meta/app.cue | assembles the canonical Flyb model and report structure |
| doc/design-meta/examples/*.csv | stores durable reviewable design tables |
| doc/design-meta/examples/*.ts | stores payload-shape examples for transport contracts |
| doc/design/specs.md | generated markdown output from Flyb |

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

## 05 Diagnostics and Observability

Hooks and signals for understanding transport behavior without locking the package into one tooling stack.

### 01 Diagnostics Hooks

Observability should be customizable and implementation-agnostic while the final operational model is still evolving.

#### Diagnostics Hooks

| concern | customisation_hook | recommended_behavior | why_it_matters |
| --- | --- | --- | --- |
| transport lifecycle | connection state listener or stream | emit connect open closing closed and failure transitions | applications need to observe readiness and degraded sessions without parsing logs |
| REST request execution | request hook with operation metadata | expose request start finish failure and latency events | callers may want tracing metrics or custom audit pipelines |
| WebSocket session activity | session event hook | expose subscribe unsubscribe ping pong and reconnect-related events | light websocket support still needs visibility when sessions flap or drift |
| decode and protocol failures | error hook with typed context | surface malformed payload and contract mismatch details | integrators need to distinguish transport outages from protocol bugs |
| retry and recovery decisions | policy hook invoked around recovery actions | emit when the higher layer retries refreshes or re-subscribes | the final recovery strategy is still evolving and should stay replaceable |
| sensitive data handling | redaction hook or formatter hook | allow redaction before diagnostics leave the library | observability should not force unsafe payload logging |

#### Observability Principles

Diagnostics and observability should be treated as first-class extension points rather than hard-coded framework choices.

The client should prefer hooks, listeners, or pluggable adapters over committing early to one logging, tracing, or metrics dependency. That keeps the package usable in different environments while the final operational model is still unsettled.

The package should surface enough structured context for higher layers to build:

- logging
- tracing
- metrics
- audit trails
- custom debugging tools

without forcing all consumers to adopt the same observability stack.

