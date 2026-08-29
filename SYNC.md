# Synchronization Strategy

## Offline-First Philosophy
The application must never block the user from taking an order if the internet is down.
All read and write operations are performed against the **local SQLite database** (via Drift).

## Real-time Sync (Supabase)
When online:
1. **Push**: The Sync Engine detects local database changes (inserts/updates). It attempts to push these to Supabase.
2. **Pull (Realtime)**: The app subscribes to Supabase Realtime channels for the `business_id`. When a change occurs on another device (e.g., an order status changes from NEW to PREPARING), Supabase broadcasts the change. The Sync Engine receives it and updates the local SQLite database, immediately reflecting in the UI via Riverpod streams.

## Conflict Resolution
- **UUIDs**: All primary keys are UUIDs generated locally. This prevents ID collisions when multiple devices create orders offline.
- **Order Numbers**: Order numbers (e.g., 27-AUG-001) are deterministic or use a safe incrementing strategy (e.g., `<date>-<uuid-short>` or resolving sequences upon sync).
- **Immutable Financials**: Payments and Order Items should ideally be append-only or use last-write-wins with `updated_at` timestamps based on server time.
- **Sync Status**: Each record locally has a `sync_status` (PENDING, SYNCED, FAILED) and an `updated_at` timestamp.

## Sync Flow
```
[ Device A (Local DB) ]  <---> [ Sync Engine ] <---> [ Supabase (Postgres + Realtime) ] <---> [ Sync Engine ] <---> [ Device B (Local DB) ]
```
