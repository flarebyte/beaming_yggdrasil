# Diff Against Historical Decisions

This note compares [HISTORICAL_DECISIONS.md](/Users/olivier/Documents/github/beaming_yggdrasil/HISTORICAL_DECISIONS.md) with the current generated spec at [doc/design/specs.md](/Users/olivier/Documents/github/beaming_yggdrasil/doc/design/specs.md).

The old direction assumed a message-centric sync framework with WebSocket replay as the main transport story. The current design is narrower and more pragmatic: REST owns the main state-changing and state-fetching flows, while WebSocket is now a light optional channel for subscription updates and reachability.

## Ideas Already Carried Forward

- Lightweight key handling is preserved. The new spec keeps `keyId` opaque, preserves `localKeyId`, and avoids deep kind derivation.
- Correlation and status propagation are preserved. The new spec explicitly keeps request ids, correlation ids, status values, and server messages visible to callers.
- Optimistic write semantics are preserved. The new spec keeps exact server version strings and surfaces conflict behavior instead of hiding it.
- Optional WebSocket support is preserved, but reduced in scope. The new spec still supports subscribe, unsubscribe, ping, pong, status, and event messages.
- The split between transport DTOs and higher-level application behavior is preserved. The new spec still avoids hard-linking the package to storage or business logic.

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

## Recommended Additions To The New Spec

If we want to recover the best parts of the historical design without regressing into the older WebSocket-heavy model, the best additions are:

1. Add a field trust and ownership table for request, response, and event DTOs.
2. Add a reconnect and recovery section centered on REST refresh, not event replay.
3. Add diagnostics and observability hooks as a first-class transport concern.
4. Clarify the intended Dart integration surface for async streams, callbacks, or adapters.
5. Clarify whether binary content references and metadata are supported, ignored, or deferred.

## Bottom Line

The new design is better scoped than the historical one. The main missing value is not the old chat-style WebSocket architecture itself, but the explicit operational thinking that came with it:

- trust boundaries
- recovery behavior
- diagnostics
- integration surfaces

Those ideas still fit the current REST plus light WebSocket direction and would strengthen the new spec without dragging it back toward a generic messaging framework.
