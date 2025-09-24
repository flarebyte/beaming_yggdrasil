# Architecture decision records

An [architecture
decision](https://cloud.google.com/architecture/architecture-decision-records)
is a software design choice that evaluates:

-   a functional requirement (features).
-   a non-functional requirement (technologies, methodologies, libraries).

The purpose is to understand the reasons behind the current architecture, so
they can be carried-on or re-visited in the future.

## Initial idea

**Problem**
Establish a synchronization framework in Dart that enables reliable,
message-based syncing between a remote server's hierarchical data tree and a
device's local cache (likely a key-value store). Sync operations are modeled
as messages exchanged between three actors: server, user, and device API.

**Actors**

-   **Server**: Hosts the authoritative hierarchical tree structure.
-   **User**: Triggers actions (e.g., creating or updating nodes).
-   **Device API**: Optional local system interface (e.g., Web API) for
    message routing.

**Message Model**
Each message includes:

-   `id`: Unique message identifier (UUID).
-   `kind`: Logical type (e.g., note).
-   `source`: Originator (e.g., user).
-   `destination`: Target (e.g., server, group/123, user/123).
-   `key id`: Tree path identifier (e.g., project/uuid/topic/uuid/title).
-   `local key id`: Optional local reference (e.g., numeric or
    device-specific).
-   `value`: Typically a string or a reference to binary/media data.
-   `version`: UUID used for chronological versioning.
-   `integrity hash`: Optional hash to validate content (checksum)
-   `size`: Optional content size (used if `value` is a reference).
-   `content type`: Optional content type (e.g., image/jpeg).
-   `flags`: Optional list of string flags for metadata.
-   `sequence`: Monotonic integer that increases with each event within its
    logical group.
-   `created` — When the event was created (UTC) - perhaps just date no
    time -`application version` — Useful for auditing.
-   position / offset — The event’s global position across all streams
    (read only)
-   `language`: iso code of the language for the value

Note: perhaps additional fields like userId, tenantId, correlationId,
causationId, ... may be required on the server side.


### 🧩 Field Ownership & Trust Review

| Field                | Type            | Created By             | Should Be Required? | Trust Server Only? | Notes                                                                                     |
| -------------------- | --------------- | ---------------------- | ------------------- | ------------------ | ----------------------------------------------------------------------------------------- |
| `id`                 | `String`        | Client                 | ✅ Yes               | ❌ No               | UUIDv4 is fine from client; useful for deduplication. Server may reassign in edge cases.  |
| `kind`               | `String`        | Client                 | ✅ Yes               | ❌ No               | Defines message purpose. No need to override.                                             |
| `source`             | `String`        | Client                 | ✅ Yes               | ❌ No               | Origin label (e.g., user ID). Usually signed/authenticated separately.                    |
| `destination`        | `String`        | Client                 | ✅ Yes               | ❌ No               | Target address or group. Validated by server, but client-provided.                        |
| `keyId`              | `String`        | Client                 | ✅ Yes               | ❌ No               | Logical path/grouping. Client-driven, validated on server.                                |
| `localKeyId`         | `String?`       | Client                 | ❌ No                | ❌ No               | Temporary or local use only. Not trusted or used by server.                               |
| `value`              | `String`        | Client                 | ✅ Yes               | ❌ No               | Main content. Trust depends on authentication, not this field.                            |
| `version`            | `String`        | Client                 | ✅ Yes               | ❌ No               | Client must version its events for ordering/deduplication.                                |
| `integrityHash`      | `String?`       | Server (or recomputed) | ❌ No                | ✅ Yes              | If client provides it, it should be ignored/validated. Server should recompute if needed. |
| `size`               | `int?`          | Server (or recomputed) | ❌ No                | ✅ Yes              | Must reflect actual byte size. Server recomputes if `value` is a reference.               |
| `contentType`        | `String?`       | Client                 | ❌ No                | ❌ No               | Suggestive only. Server may override for binary validation.                               |
| `flags`              | `List<String>?` | Client or Server       | ❌ No                | ❌ No               | Metadata for UX/UI or filtering. Server may enrich.                                       |
| `sequence`           | `int`           | Server                 | ❌ No                | ✅ Yes              | Defines logical order in stream. Must be assigned by the server.                          |
| `created`            | `DateTime`      | Client or Server       | ✅ Yes               | ❌ No               | Usually client-generated, but server may validate clock drift.                            |
| `applicationVersion` | `String`        | Client                 | ✅ Yes               | ❌ No               | Important for audit/compatibility. Client-provided.                                       |
| `position`           | `int`           | Server                 | ❌ No                | ✅ Yes              | Global offset. Always assigned by server during commit.                                   |
| `language`           | `String?`       | Client or Server       | ❌ No                | ❌ No               | May be inferred by server, but optional at source.                                        |

---

### 🔐 Trust Model Interpretation

| Field Category                                | Fields                                                                                                                                  |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| ✅ **Safe from client**                        | `id`, `kind`, `source`, `destination`, `keyId`, `value`, `version`, `created`, `applicationVersion`, `flags`, `language`, `contentType` |
| ⚠️ **Client-submitted but must be validated** | `destination`, `contentType`, `created` (clock), `language`                                                                             |
| 🔒 **Must be server-generated or verified**   | `sequence`, `position`, `integrityHash`, `size`                                                                                         |


**Tree Structure**
The remote store represents a tree where each node has a parent. `key id`
encodes the full path.

**Synchronization**

-   Device maintains two caches:

    -   **Object cache**: Stores structured (JSON-like) data.
    -   **File cache**: Stores referenced binary/media data.

-   Messages are used to synchronize state between remote and local.

-   A sync state tracks:

    -   Per-`key id` version status.
    -   Message status (sent, received, retry count, error state).

-   Sync should support retries and error recovery.

-   There must be mechanisms to send messages from the user's perspective.

**Event Sequence Model**
Each change is treated as an append-only event within its group (e.g., topic,
project), assigned a monotonic sequence number (`sequence`). This sequence is
included in every WebSocket push. Clients use it to detect missing events and
re-establish state by querying “events after last seen sequence.” This helps
ensure message continuity and recovery after a connection loss.

**Extensibility and Callbacks**

-   Framework must allow registration of external callbacks to handle cache
    updates.
-   It must not hard-link to specific libraries or storage systems.
-   Message format should be flexible for future security enhancements
    (e.g., JWT).

**Debugging and Monitoring**

-   The system should expose diagnostics hooks.
-   It should allow integration with logging and monitoring tools.

## Possible use of RxDart

-   Use RxDart Subject or StreamController to represent incoming message
    streams (e.g. WebSocket pushes). Each message can carry the full
    metadata (including the sequence number).

-   Have local replay logic: keep the last seen sequence number in local
    sync state; when connection resumes, make a call to the server: “give
    me all events after seq X”. RxDart stream will receive the incoming
    events.

-   Buffer events while offline, then replay or when online fetch missing,
    feed into the stream.

-   Use RxDart operators for filtering, mapping, deduplication (if you get
    duplicate events), throttling if too many in batch, etc.

-   Subscribe separately to object vs file events: e.g. if message
    references media, route it to a file cache subscriber; otherwise to
    JSON/object cache subscriber.

-   Use RxDart error handling, retry operators / logic to retry failed
    sends or missing fetches.

Here is the additional paragraph that fits with the rest of the spec:

## WebSocket Integration

The framework should support a WebSocket communication layer compatible with
AWS API Gateway WebSocket protocol. It must use a bespoke application-level
message format to carry synchronization messages. The WebSocket connection
must implement a heartbeat mechanism using periodic ping/pong messages to
keep the connection alive and detect stale or dropped connections. It should
include a replay mechanism where clients can request missing messages based
on the last acknowledged sequence number. A smart retry mechanism must handle
transient failures, with exponential backoff, jitter, and re-authentication
if required. The system must detect internet connectivity loss promptly and
suspend retries until a connection is restored, at which point it should
resume synchronization by querying for any missed messages using the
sequence-based replay protocol.
