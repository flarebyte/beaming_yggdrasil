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

#### API Surfaces

| role | surface | why_it_exists |
| --- | --- | --- |
| primary public API using Future and Stream | classic Dart client | keeps the library idiomatic for Dart users without forcing an Rx dependency |
| optional secondary API layered on top of the classic client | Rx-friendly adapter | makes retry reconnect composition and derived state streams easier for Rx-oriented consumers |
| separate mock-control or testing surface | testing client | keeps test-only capabilities out of the real end-user client API |

#### Cache Integration Primitives

| primitive | why_it_helps_a_separate_cache_library |
| --- | --- |
| immutable DTOs | cache layers can snapshot transform and replay state without shared mutable transport objects |
| stable keyId and localKeyId fields | cache indexing provisional mapping and reconciliation remain straightforward |
| version propagation | cache sync layers can implement optimistic write tracking and stale-write detection |
| deterministic snapshot and node response shapes | cache adapters can normalize remote state into local key-value structures with less ambiguity |
| event envelopes with explicit operation kinds | cache adapters can apply incremental updates without inferring intent from raw payload differences |
| transport and stream hooks | cache-specific retry backoff and persistence logic can live in another package without forking this client |

#### Planned Surface

| intent | surface_area |
| --- | --- |
| bootstrap local state from server-created snapshots | snapshot read methods |
| support targeted reads and writes without full snapshot reloads | node read and write client methods |
| map provisional local keys to server-generated keys | create client methods |
| keep mock-only controls available without polluting core application flows | optional admin commands for test harness usage |
| allow incremental updates after initial bootstrap | optional WebSocket subscription and event handling |
| make key-value synchronization easier without embedding cache ownership in this package | cache-friendly primitives for separate libraries |

#### Client Scope

| area | in_scope | out_of_scope |
| --- | --- | --- |
| rest-payloads | encode and decode shipped request response envelopes | server-side business logic |
| websocket-payloads | encode and decode command and event messages | event-store persistence |
| key-handling | carry keyId strings and optional kind hints | full key grammar and derivation rules |
| error-model | map HTTP and websocket statuses into practical client errors | changing server status semantics |
| test-support | support mock-server admin flows as optional APIs | production-only operations not present in chatty |
| local-state | expose primitives that make cache synchronization possible in another library | shipping a full offline sync engine or key-value cache in this package |

#### Simplified Dart API Example

A higher-level Dart surface can sit on top of the wire-level DTOs, with an optional Rx-friendly adapter layered on top of the classic client:

    class BeamingClientKey {
      final String keyId;
      final String? version;
      final String? localKeyId;
    }

    class BeamingValue {
      final BeamingClientKey key;
      final String? value;
    }

    class BeamingWriteResult {
      final BeamingClientKey key;
      final String status;
      final String? message;
    }

    sealed class BeamingEvent {
      const BeamingEvent();
    }

    class BeamingSetEvent extends BeamingEvent {
      final BeamingClientKey rootKey;
      final BeamingValue keyValue;
    }

    class BeamingSnapshotReplacedEvent extends BeamingEvent {
      final BeamingClientKey rootKey;
      final String snapshotVersion;
    }

    abstract class BeamingYggdrasilClient {
      Future<List<BeamingValue>> getSnapshot(String rootKeyId);
      Future<List<BeamingValue>> getNode(String rootKeyId, List<String> keyIds);
      Future<List<BeamingWriteResult>> setNode(String rootKeyId, List<BeamingValue> values);
      Future<List<BeamingWriteResult>> createChildren(
        String rootKeyId,
        List<BeamingClientKey> provisionalKeys,
      );
      Stream<BeamingEvent> watch(List<String> rootKeyIds);
    }

    abstract class BeamingYggdrasilRxClient {
      Stream<List<BeamingValue>> snapshot$(String rootKeyId);
      Stream<List<BeamingValue>> node$(String rootKeyId, List<String> keyIds);
      Stream<List<BeamingWriteResult>> setNode$(
        String rootKeyId,
        List<BeamingValue> values,
      );
      Stream<BeamingEvent> watch$(List<String> rootKeyIds);
    }

    abstract class BeamingYggdrasilTestingClient {
      Future<void> replaceSnapshot(
        String rootKeyId,
        List<BeamingValue> values,
      );
    }

Design guidance:

- keep the classic `BeamingYggdrasilClient` as the primary public API
- offer the Rx-friendly API as an adapter layer rather than the only surface
- snapshots are created by the server and read by the real client
- snapshot replacement belongs in a separate testing or mock-control client
- preserve access to underlying statuses and versions
- make cache synchronization easy, but leave cache ownership to another package
- keep values immutable and string-only for now

#### Source Layout

| path | role |
| --- | --- |
| doc/design-meta/app.cue | assembles the canonical Flyb model and report structure |
| doc/design-meta/examples/*.csv | stores durable reviewable design tables |
| doc/design-meta/examples/*.ts | stores payload-shape examples for transport contracts |
| doc/design/specs.md | generated markdown output from Flyb |

#### Stream Integration Model

| aspect | preferred_direction | reason |
| --- | --- | --- |
| stream model | prefer Rx-style stream composition over imperative callback chains | reactive composition makes retry backoff and reconnection policies easier to layer without tangling transport code |
| immutability | pass immutable DTOs and immutable event snapshots through the stream pipeline | immutable values reduce accidental shared-state bugs during retries buffering and fan-out |
| retry support | model retries as higher-layer operators or policies around the stream rather than hidden transport behavior | keeps retry explicit testable and replaceable |
| integration surface | offer both a classic Future and Stream surface and an optional Rx-friendly adapter | lets consumers choose idiomatic Dart or richer reactive composition without splitting the core object model |
| transport boundary | keep raw transport separate from decoded reactive pipelines | preserves a narrow transport contract while still allowing rich stream orchestration above it |

#### Use Cases

| minimum_client_support | priority | usecase | why_it_matters |
| --- | --- | --- | --- |
| send GET /snapshot payloads and decode envelopes | 1 | snapshot bootstrap | lets a Dart app load baseline state quickly |
| send GET /node and PUT /node payloads and preserve item order | 2 | targeted node read and write | lets a Dart app update and query specific values without full snapshot reload |
| surface outdated status and HTTP 409 without hiding server details | 3 | optimistic conflict handling | lets a Dart app detect stale writes cleanly |
| send POST /create and preserve localKeyId mappings | 4 | create provisional records | lets a Dart app map local placeholders to server-generated keys |
| send subscribe/unsubscribe/ping and decode event messages | 5 | websocket sync | lets a Dart app receive incremental updates after bootstrap |
| support admin commands and test-only snapshot setup separately from the real client API | 6 | admin reset for tests | lets integration tests seed or reset mock state quickly |

## 02 REST Contract

HTTP actions and payload responsibilities.

### 01 REST Actions

Supported REST endpoint actions for the client.

#### REST Actions

| action | method | notes | path | request_body | response_shape |
| --- | --- | --- | --- | --- | --- |
| setSnapshot | PUT | mock-only or testing surface for seeding authoritative snapshot state rather than a normal end-user client operation | /snapshot | SetSnapshotRequest | Envelope<SetSnapshotResponseData> |
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

#### Value Boundary

| current_decision | future_position | rationale | topic |
| --- | --- | --- | --- |
| only string values are supported for now | binary or file-reference payloads require a later explicit design pass | keep the transport contract simple while the package scope is still settling | value-payload |
| no first-class binary payload support in this package today | defer until a concrete use case and transport shape are agreed | avoid accidental commitment to content-addressing upload or cache semantics | binary-content |
| do not add integrity hash size or content type fields to the core value contract yet | revisit only if non-string payloads become a real supported feature | metadata without a supported binary model adds ambiguity rather than clarity | content-metadata |

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

## 06 Testing Strategy

How the client should be validated against the real mock-server contract.

### 01 End-to-End Tests

End-to-end Dart tests should exercise this client against the external chatty mock server implementation.

#### End-to-End Test Coverage

| expected_coverage | test_area | why_it_matters |
| --- | --- | --- |
| Dart e2e tests should verify bootstrap and replace flows against a running chatty mock server | snapshot flows | confirms the client speaks the real REST contract rather than only local DTO assumptions |
| Dart e2e tests should verify targeted reads writes ordering and item-level statuses against chatty | node flows | protects the key-value style update model that application code will rely on |
| Dart e2e tests should verify provisional localKeyId mapping and returned server keys against chatty | create flows | ensures client-side creation helpers stay compatible with server behavior |
| Dart e2e tests should verify subscribe unsubscribe ping pong and event decoding against chatty | websocket flows | keeps the light websocket surface aligned with the mock server contract |
| Dart e2e tests should verify invalid outdated and other transport-visible failures against chatty | error flows | prevents regressions where the client hides or rewrites useful server signals |
| Dart e2e tests should run this client library against the mock server hosted at https://github.com/flarebyte/chatty-ratatoskr | cross-repo compatibility | anchors client behavior against the intended external reference implementation |

#### End-to-End Testing Principles

This library should include end-to-end tests written in Dart that validate the client against a running `chatty` mock server.

The purpose of these tests is not to re-test the server internals, but to ensure that `beaming_yggdrasil` remains compatible with the real external contract exposed by `chatty`.

The reference mock server for these tests is `flarebyte/chatty-ratatoskr`:

- https://github.com/flarebyte/chatty-ratatoskr

These tests should focus on client-visible behavior, wire compatibility, and transport semantics rather than implementation details inside either repository.

## 07 Implementation Guidance

Recommended Dart implementation style for building and publishing this library.

### 01 Dart Library Style

Implementation should follow idiomatic Dart API design while preserving the package-specific boundaries described in this spec.

#### Implementation Guidance

| recommendation | topic | why_it_matters |
| --- | --- | --- |
| follow Effective Dart design and style guidance for public library APIs | dart-api-style | keeps the package idiomatic and easier for Dart users to adopt |
| prefer immutable value objects and final fields for transport-facing DTOs | immutability | works well with stream pipelines retries and cache integration |
| use builders for assembling complex request or result objects when constructors would become noisy or error-prone | builder-pattern | helps preserve immutable public objects while keeping object creation ergonomic |
| prefer Dart naming conventions and avoid Java-style getter prefixes | naming | makes the library feel native in the Dart ecosystem |
| follow Dart package layout and publishing conventions for public libraries | package-layout | reduces friction when validating and publishing the package |
| run dart pub publish --dry-run and keep the package warning-free before publishing | publish-validation | catches packaging and ecosystem integration issues early |

#### Implementation Principles

The implementation should follow idiomatic Dart library design.

Use the official Dart guidance as the baseline for public API shape and package publishing:

- Effective Dart: Design: https://dart.dev/effective-dart/design
- Effective Dart: Style: https://dart.dev/effective-dart/style
- Publishing packages: https://dart.dev/tools/pub/publishing

Within this library, prefer immutable public objects and repository-specific builder types where object construction is non-trivial. Dart does not require builders for simple value classes, but builders are a reasonable pattern here when they help keep transport-facing objects immutable while avoiding large fragile constructors.

For published library code, the package should also follow Dart package conventions closely enough that `dart pub publish --dry-run` is a routine validation step rather than a late packaging surprise.

