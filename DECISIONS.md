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

Note: perhaps additional fields like userId, tenantId, correlationId,
causationId, ... may be required on the server side.

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
