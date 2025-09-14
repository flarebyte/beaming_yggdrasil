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
-   `destination`: Target (e.g., server).
-   `key id`: Tree path identifier (e.g., project/uuid/topic/uuid/title).
-   `local key id`: Optional local reference (e.g., numeric or
    device-specific).
-   `value`: Typically a string or a reference to binary/media data.
-   `version`: UUID used for chronological versioning.
-   `integrity hash`: Optional hash to validate content.
-   `size`: Optional content size (used if `value` is a reference).
-   `media type`: Optional content type (e.g., image/jpeg).
-   `flags`: Optional list of string flags for metadata.

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

**Extensibility and Callbacks**

-   Framework must allow registration of external callbacks to handle cache
    updates.
-   It must not hard-link to specific libraries or storage systems.
-   Message format should be flexible for future security enhancements
    (e.g., JWT).

**Debugging and Monitoring**

-   The system should expose diagnostics hooks.
-   It should allow integration with logging and monitoring tools.

**Use Cases**

-   User edits a note title → message sent to server, local cache updated.
-   Server pushes a topic rename → local tree updated.
-   User uploads a photo → value is a media reference, tracked via file
    cache.
-   Device API injects a location tag as a message.
-   Offline device syncs multiple changes upon reconnection.

**Edge Cases**

-   Message lost mid-sync; retry with version tracking.
-   Conflicting versions between server and local state.
-   Large media file partially synced, needs resumable strategy.
-   Server tree path deleted but cache still retains data.
-   Device API sends malformed or unauthorized message.

**Limitations / Non-goals**

-   No direct server ↔ device API communication unless explicitly routed
    via user.
-   No assumption of fixed message format or schema enforcement.
-   No embedded file storage logic — file handling is external via
    callbacks.
-   No hard dependency on backend protocols or real-time systems.
-   No direct tree merging or conflict resolution logic (must be handled
    externally).
-   No UI or visualization logic.
