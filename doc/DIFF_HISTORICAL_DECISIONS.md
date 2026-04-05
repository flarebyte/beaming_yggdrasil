# Diff Against Historical Decisions

This note compares `HISTORICAL_DECISIONS.md` with the current generated spec at `doc/design/specs.md`.

The old direction assumed a message-centric sync framework with WebSocket replay as the main transport story. The current design is narrower and more pragmatic: REST owns the main state-changing and state-fetching flows, while WebSocket is now a light optional channel for subscription updates and reachability.

## What The Draft `lib/` Implementation Shows

The draft code under `lib/src/messaging/message.dart`, `lib/src/messaging/transport.dart`, `lib/src/messaging/transport_types.dart`, `lib/src/messaging/rx/transport_rx.dart`, and `lib/src/messaging/rx/transport_rx_impl.dart` makes the transition state very visible.

Two implementation threads coexist:

- a broad old-spec `Message` model that still assumes a generic routed messaging system
- a lower-level `Transport` and `TransportRx` layer that is closer to what the new spec actually needs for light WebSocket support

That split is useful evidence when deciding what should be retained and what should be retired.

## Ideas Already Carried Forward

- Lightweight key handling is preserved. The new spec keeps `keyId` opaque, preserves `localKeyId`, and avoids deep kind derivation.
- Correlation and status propagation are preserved. The new spec explicitly keeps request ids, correlation ids, status values, and server messages visible to callers.
- Optimistic write semantics are preserved. The new spec keeps exact server version strings and surfaces conflict behavior instead of hiding it.
- Optional WebSocket support is preserved, but reduced in scope. The new spec still supports subscribe, unsubscribe, ping, pong, status, and event messages.
- The split between transport DTOs and higher-level application behavior is preserved. The new spec still avoids hard-linking the package to storage or business logic.
- The draft `Transport` abstraction is a good match for the new design direction. It keeps framing, retry, reconnection, auth, and payload encoding out of the transport interface, which is consistent with REST being primary and WebSocket remaining deliberately light.

## Good Historical Ideas Missing From The New Spec

These points still look useful even after moving away from the chat-style WebSocket model.

### 1. Explicit trust ownership per field

The historical note had a strong distinction between:

- client-authored fields
- client-authored but server-validated fields
- server-authored fields

The new spec hints at this, but it does not define it clearly enough. That leaves ambiguity around fields such as:

- `id`
- `version`
- `created`
- `secureKeyId`
- item-level `status`
- event identifiers

Recommendation: add a dedicated table describing field ownership and trust boundaries for REST DTOs and WebSocket event envelopes.

### 2. Diagnostics hooks and observability

The historical note explicitly asked for diagnostics hooks and integration with logging and monitoring. The new spec talks about transport errors, but not about observability surfaces.

Recommendation: add a small section describing:

- structured transport diagnostics
- connection lifecycle events
- retry and reconnect visibility
- optional logging hooks instead of hard-coded logging

### 3. Retry and recovery policy

The old note was explicit about retries, retry counts, and recovery after failures. The new spec mentions ping/pong and transport error mapping, but it does not describe client behavior when:

- REST calls fail transiently
- WebSocket disconnects
- subscriptions need re-establishing
- the client reconnects after being offline

Recommendation: add a non-goal-safe recovery section. It does not need full stream replay, but it should state the expected client behavior around reconnect, re-subscribe, and refresh via REST.

### 4. Separation between object data and binary/file references

The historical note distinguished object cache and file cache, and also mentioned fields such as `integrityHash`, `size`, and `contentType`. The current spec keeps `value?: string` and lightly mentions `secureKeyId`, but it does not say whether binary payload references are first-class, deferred, or out of scope.

Recommendation: decide explicitly whether this package:

- only carries string values for now
- may carry references to external binary content later
- should preserve content metadata passively without interpreting it

### 5. Callback or stream integration model

The historical note emphasized external callbacks and Rx-style event handling. The new spec exposes `AsyncIterable<ServerMessage>`, which is a good low-level primitive, but it does not explain the intended integration style for Dart consumers.

Recommendation: document whether the preferred surface is:

- async iterables only
- adapters around `Stream`
- optional observer callbacks layered on top

This matters because the old design correctly identified that local apps need integration points, not just DTO definitions.

### 6. A clear migration path away from the generic `Message` type

The current code still centers `Message` in `lib/src/messaging/message.dart`, which requires fields such as:

- `source`
- `destination`
- `applicationVersion`
- `value`

and optionally carries:

- `sequence`
- `position`
- `integrityHash`
- `size`
- `contentType`
- `language`

That structure maps closely to the historical messaging architecture, but only loosely to the new REST and light-WebSocket contract.

Recommendation: the new spec should explicitly say whether `Message` is:

- a temporary historical compatibility type to be removed
- an internal event envelope used only in one narrow subsystem
- or a public abstraction that still deserves first-class support

Without that decision, the codebase risks keeping an attractive but misaligned domain type simply because it already exists.

## Historical Ideas That Should Stay Out

These are mostly tied to the older chat-oriented sync model and should not be copied back blindly.

### 1. Full message-centric architecture

The old note modeled almost everything as a generic message exchanged among server, user, and device API. The current design is intentionally simpler and should stay that way. REST now owns snapshot, node, create, and admin operations directly.

This older abstraction would likely add indirection without improving the new transport-first client.

### 2. Sequence-based replay as the core recovery mechanism

The historical model depended on monotonic sequence numbers and querying for "events after X". That made sense for a primary event-stream transport. It is not the right center of gravity anymore.

With the new model, recovery should primarily be:

- reconnect WebSocket
- re-subscribe if needed
- refresh authoritative state through REST when continuity is uncertain

That is a materially different design choice and should be preserved.

### 3. Rich actor/source/destination routing model

Fields such as `source`, `destination`, and group-addressed routing belonged to a broader messaging system. The current client spec is much more concrete and endpoint-focused. Reintroducing those concepts now would blur the transport contract.

### 4. Local sync engine responsibilities

The old note discussed local caches, replay buffers, retry state, and device-side synchronization machinery. The current spec correctly keeps that out of scope for this package.

Those concerns may still matter at the application or higher-level SDK layer, but they should not be pulled back into `beaming_yggdrasil` unless the package is intentionally widened.

### 5. Making the public Dart API revolve around `MessageBuilder`

The builder in `lib/src/messaging/message.dart` bakes the old message shape directly into the construction flow. That is a good fit for the historical system, but a poor default for the newer contract where the main public surfaces are likely to be:

- REST request and response DTOs
- WebSocket command DTOs
- WebSocket event DTOs

Keeping `MessageBuilder` as the main authoring surface would pull the package back toward a generic messaging framework instead of a transport-first client.

## Implementation-Specific Gaps And Risks

Reviewing the draft code reveals a few concrete gaps that are worth recording because they sharpen the spec discussion.

### 1. The transport layer is more mature than the domain model

The `Transport` contract is intentionally narrow and reusable. It already encodes several good decisions:

- no implicit payload encoding
- no reconnection policy inside the transport interface
- no auth/session coupling
- ordered delivery expectations
- explicit lifecycle state reporting

This is the strongest piece of alignment between implementation and the new spec. The architecture should probably build from here rather than from `Message`.

### 2. The draft domain model still assumes routed chat-like traffic

Required `source` and `destination` fields in `lib/src/messaging/message.dart` suggest peer-style addressing, not the REST endpoint plus optional subscription model described in the new spec.

That is a concrete sign that the current implementation is still biased toward the old architecture, not merely inspired by it.

### 3. The Rx integration idea is still useful, but its scope should narrow

`lib/src/messaging/rx/transport_rx.dart` and `lib/src/messaging/rx/transport_rx_impl.dart` show that the old RxDart thought process was not entirely misplaced.

What still looks useful:

- hot state streams
- buffering policy as an opt-in concern
- explicit outbound error streams
- separation between raw transport and reactive adapters

What should change:

- the reactive layer should adapt WebSocket session behavior, not revive the old generic message bus
- buffering should be framed as transport convenience, not as offline sync or durable replay

### 4. There is at least one draft-level code health issue in the Rx split

`lib/src/messaging/rx/transport_rx_impl.dart` uses `part of 'transport_rx.dart';`, but `lib/src/messaging/rx/transport_rx.dart` is written like a standalone library file rather than a `part` owner.

That looks like a draft integration problem rather than a design choice, but it matters because it reinforces that the Rx layer is still exploratory and should not yet be treated as proof that the old architecture was correct.

### 5. The implementation currently exposes no REST-aligned DTO layer

The new spec is organized around concrete REST operations and light WebSocket commands/events. The code in `lib/` does not yet expose corresponding public DTOs for:

- snapshot requests and responses
- node requests and responses
- create requests and responses
- subscribe, unsubscribe, ping, and event payloads

That absence is important. It means the implementation evidence currently comes mostly from the old messaging draft and the generic transport layer, not from a first pass at the new transport-first contract.

## Recommended Additions To The New Spec

If we want to recover the best parts of the historical design without regressing into the older WebSocket-heavy model, the best additions are:

1. Add a field trust and ownership table for request, response, and event DTOs.
2. Add a reconnect and recovery section centered on REST refresh, not event replay.
3. Add diagnostics and observability hooks as a first-class transport concern.
4. Clarify the intended Dart integration surface for async streams, callbacks, or adapters.
5. Clarify whether binary content references and metadata are supported, ignored, or deferred.
6. State explicitly that the old generic `Message` model is either transitional or out of scope for the public API.
7. Build the next implementation pass around REST DTOs and narrow WebSocket DTOs, reusing `Transport` only where it actually helps.

## Bottom Line

The new design is better scoped than the historical one. The main missing value is not the old chat-style WebSocket architecture itself, but the explicit operational thinking that came with it:

- trust boundaries
- recovery behavior
- diagnostics
- integration surfaces

Those ideas still fit the current REST plus light WebSocket direction and would strengthen the new spec without dragging it back toward a generic messaging framework.
