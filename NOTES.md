# Implementation Notes: Todo List Synchronization

## High-Level Overview
The synchronization feature is designed to provide a bidirectional link between the local Rails application and one or more external todo list APIs. 

The solution consists of three main parts:
1.  **Strategy Pattern**: A flexible architecture (`ExternalSync::BaseStrategy`) that allows for different API providers (with or without authentication) to be plugged in seamlessly.
2.  **Sync Service**: A central coordinator (`ExternalSync::SyncService`) that manages the logic for merging remote data locally (pull) and propagating local changes externally (push).
3.  **State Tracking**: Database-level fields (`external_id`, `provider`, `last_synced_at`) to maintain the link between records and optimize sync frequency.

## Key Design Decisions
-   **Strategy Pattern for Extensibility**: By decoupling the API communication logic into strategy classes, the system can easily support new providers (e.g., OAuth-based APIs, different JSON schemas) without modifying the core synchronization service.
-   **Last Synced At (Timestamp-based optimization)**: Storing `last_synced_at` on the `TodoList` model enables the service to only push records that have actually changed since the last successful sync, minimizing unnecessary API calls and reducing overhead.
-   **Faraday for HTTP Communication**: Chose Faraday for its robust middleware support (JSON parsing, error handling) and ease of testing compared to the standard `Net::HTTP`.

## Resilience and Error Handling
-   **Graceful Partial Failures**: The `SyncService` wraps individual record operations (lists and items) in `begin/rescue` blocks. If a single item fails to push, the service logs the error and continues with the rest of the sync, preventing a single failure from blocking the entire process.
-   **Structured Logging**: Detailed `Rails.logger` messages provide visibility into the sync status, identified deletions, and API errors, which is critical for debugging synchronization discrepancies.
-   **API Error Class**: Custom `ExternalSync::ApiError` captures both the error message and the HTTP status code for better context in logs and potential UI feedback.

## Edge Cases
-   **Race Condition Protection**: A common issue in bidirectional sync is "sync loops" where a pulled record is immediately re-pushed. I handled this by ensuring `last_synced_at` is set slightly *after* the local update (`Time.current + 1.second`), ensuring that the subsequent push scan skips the records just synchronized.
-   **Deletion Propagation**:
    -   **Remote-to-Local Deletion**: The service identifies local records that have an `external_id` but are no longer present in the `fetch_all` results, safely removing them from the local database.
    -   **Safeguard for New Records**: The deletion logic explicitly ignores local records with `external_id: nil`, protecting newly created local items that haven't been pushed yet.

## Areas for Improvement
-   **Conflict Resolution**: Presently, "last update wins" is the implicit strategy. Implementing a more sophisticated conflict resolution (e.g., using a dedicated `conflict_at` state or user-prompted resolution) would be beneficial for high-concurrency environments.
-   **Asynchronous Processing**: Moving the `sync!` call to a background job (`Sidekiq`) would improve the user experience by preventing web requests from hanging during long sync operations.
-   **Webhook Support**: Implementing incoming webhooks would allow the external system to notify the application of changes immediately, enabling near-real-time synchronization rather than relying on polling.

## Assumptions
-   **External Source of Truth for IDs**: Assumed that the external system provides unique identifiers (`id`) and that these should be used as the primary lookup key (`external_id`).
-   **Source Identity**: Assumed that the external API's `source_id` field should be used to store our local record's primary key (`id`), allowing the external system to trace back to its origin.
-   **Incremental Item Sync**: Assumed that items can be updated individually via `PATCH /todolists/{listId}/todoitems/{itemId}` but are created in bulk during list creation/update.
