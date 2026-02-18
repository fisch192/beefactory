# How Sync Works

## Overview

The app uses an **offline-first** architecture. All data is stored locally in SQLite (via Drift) and synchronized with the PostgreSQL backend when connectivity is available.

## Principles

1. **Local-first writes**: Every user action writes to SQLite immediately. No network required.
2. **Eventual consistency**: Data syncs to server when online. Conflicts resolved by last-write-wins or immutability.
3. **Idempotent uploads**: Every event has a `clientEventId` (UUID generated on device). The server enforces uniqueness per user, so duplicate uploads are safe.
4. **Incremental downloads**: Client tracks `lastSyncTimestamp` and fetches only records with `updatedAt > lastSync`.

## Sync Triggers

| Trigger | Description |
|---------|-------------|
| App start | Sync runs after successful authentication |
| Connectivity restored | Fires when device regains network |
| Pull-to-refresh | User manually triggers sync |
| After local write | Opportunistic sync if online |

## Upload Flow

```
1. Query SyncQueue for pending items (ordered by createdAt ASC)
2. For each item:
   a. If entity (site/hive):
      - POST/PUT to server
      - On success: update syncStatus=uploaded, store serverId
      - On failure: increment retryCount, set lastError
   b. If event:
      - POST /v1/events with clientEventId
      - Server returns existing event if clientEventId already exists (idempotent)
      - On success: update syncStatus=uploaded
   c. If attachment:
      - POST /v1/attachments/presign → get uploadUrl
      - PUT file to uploadUrl
      - On success: mark attachment as uploaded
   d. If task:
      - POST /v1/tasks
      - On success: update syncStatus=uploaded
3. Remove completed items from SyncQueue
```

### Upload Order (Dependencies)

```
Sites → Hives → Events → Attachments → Tasks
```

Sites must sync before hives (hives reference site server IDs).
Hives must sync before events.
Events must sync before their attachments.

## Download Flow

```
1. GET /v1/events?since={lastSyncTimestamp}&limit=100
2. For each received event:
   a. Check if clientEventId exists locally
   b. If yes: update local record with server data
   c. If no: insert new record (came from another device or was created server-side)
3. GET /v1/tasks?since={lastSyncTimestamp}
4. Merge tasks similarly
5. Update lastSyncTimestamp to max(updatedAt) from response
6. If response had `limit` items, there may be more → repeat
```

## Conflict Resolution

### Events (Immutable)
Events are append-only. No conflicts possible — same `clientEventId` always returns the same event.

To "edit" an event, create a new event of the same type with a reference to the original. To "delete", create a DELETE event referencing the target.

### Sites & Hives (Last-Write-Wins)
If the same site/hive is edited on two devices:
- Both upload their version
- Server stores the latest `updatedAt`
- On next download, the newer version overwrites the local one

### Tasks
Tasks use last-write-wins on `updatedAt`.

## Error Handling

| Error | Action |
|-------|--------|
| Network timeout | Retry with exponential backoff (max 3 retries) |
| 401 Unauthorized | Attempt token refresh, retry once |
| 409 Conflict | For events: treat as success (idempotent). For others: re-fetch server version |
| 5xx Server Error | Queue for retry, increment retryCount |
| Max retries exceeded | Mark as `failed`, show in sync error list |

## Sync Status UI

- Sync indicator in app bar (spinning when active)
- Last sync time shown in settings
- Failed items count badge
- Pull-to-refresh on list screens
- Error details accessible but non-intrusive

## Data Integrity

- All IDs are UUIDs generated client-side
- Timestamps include both local time (for display) and UTC (for ordering/sync)
- Foreign keys reference server IDs after sync, local IDs before
- The SyncQueue persists across app restarts

## Limitations (MVP)

- No real-time push of changes from server (polling only)
- No multi-device conflict UI (last-write-wins silently)
- Attachments not downloaded for offline viewing (metadata only)
- No partial sync (all-or-nothing per entity type)
