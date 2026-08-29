# Synchronization Strategy

## Offline-First Philosophy
The application must never block the user from taking an order if the internet is down.
All read and write operations are performed against the **local SQLite database** (via Drift).

## Bidirectional Sync (`lib/core/sync/sync_service.dart`)

### Push
Every repository write (`addCategory`, `createOrder`, `recordTransaction`, ...) calls
`SyncService.queueMutation(operation, targetTable, recordId, payload)`, which inserts a row into
the local `sync_operations` table. A periodic timer (every 20s) plus a connectivity-regained
listener call `triggerPush()`, which flushes `PENDING` rows to Supabase (`INSERT`/`UPDATE`/`UPSERT`/`DELETE`),
retrying with an incrementing `retry_count` and marking a row `FAILED` after 5 attempts.

### Pull
Each syncable table is registered with the engine as a `SyncableTable` (table name, which timestamp
column to page by -- `updated_at` for mutable rows, `created_at` for append-only ledgers -- and a
function that merges a remote row into the local DB). A periodic timer (every 2 minutes) plus the
connectivity listener call `triggerPull()`, which, per table, fetches rows where
`business_id = <current business>` and `<timestamp column> > <last successful pull>`, then upserts
them locally and advances the per-table watermark (stored in `SharedPreferences`, keyed by table +
business id).

`order_items` has no `business_id` column of its own, so it isn't registered directly -- whenever an
`orders` row is pulled or received over Realtime, its items are fetched and merged in the same step
(see `onOrderUpserted` in `global_providers.dart`).

### Realtime
On `start(businessId)`, the engine opens one Supabase Realtime channel and subscribes to
`postgres_changes` for every registered table, filtered to `business_id = <current business>`. A
change from another device merges into the local DB within moments instead of waiting for the next
pull tick.

### Registered tables
`categories`, `menu_items`, `orders` (+ `order_items` via the hook above), `customers`, `ingredients`,
`inventory_transactions`, `suppliers`, `expenses`, `payments`, `audit_logs`.

`recipes` is push-only (no pull/realtime registration): it's low-churn, business-owner-edited data
without its own `business_id` column, and adding a join-based pull for it wasn't worth the added
complexity for this pass. If it turns out staff on multiple devices need to see recipe edits
propagate live, register it the way `order_items` is handled -- piggybacked on its parent
(`menu_items`).

## Conflict Resolution
- **UUIDs**: All primary keys are UUIDs generated locally, so offline inserts from different devices
  never collide on `id`.
- **Order numbers**: The human-readable order number embeds a short per-device tag
  (`260829-A1-001`), generated from a device identity persisted on first install (see
  `core/device/device_identity.dart`). This keeps numbering offline-safe -- no server round-trip --
  while making label collisions between devices effectively impossible.
- **Last-write-wins**: mutable rows carry `updated_at`; a pulled/realtime row is upserted directly.
  There is no field-level merge -- the later write (by `updated_at`) wins.
- **Sync status**: pending push operations live in `sync_operations` with a `status`
  (`PENDING`/`FAILED`) and `retry_count`, queryable via `SyncService.pendingCount`.

## Multi-tenancy & Realtime scoping
Every registered table's Realtime filter and pull query is scoped to the current `business_id`, and
Row Level Security enforces the same scoping server-side via `business_members` (see
`ARCHITECTURE.md`). A device only ever receives changes for the business it's currently signed into.
