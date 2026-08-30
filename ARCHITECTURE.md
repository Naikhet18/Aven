# Architecture

## Overview
This application follows a **Feature-first Clean Architecture**.
- **UI (Presentation)**: Flutter Widgets, Riverpod providers.
- **Domain**: Business models, entities, and use cases.
- **Data**: Repositories, local SQLite (Drift) database, Supabase backend.
- **Sync Engine**: Handles offline-first capabilities and real-time syncing (push + pull + Realtime).

## Core Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Local Database**: Drift (SQLite)
- **Backend / Realtime**: Supabase (PostgreSQL + Auth + Realtime)
- **Printing**: `print_bluetooth_thermal` (Bluetooth ESC/POS) + raw TCP sockets (network printers)
- **QR Scanning**: `mobile_scanner`; **QR Generation**: `qr_flutter`
- **Charts**: `fl_chart`

## Directory Structure
```
lib/
├── core/
│   ├── config/          # env.dart (compile-time Supabase config), app_router.dart
│   ├── database/        # Drift local database setup
│   ├── device/          # Per-install device identity (id + short display tag)
│   ├── sync/            # Bidirectional sync engine (push/pull/realtime)
│   ├── printing/        # PrinterService + PrinterConfig (Bluetooth/network)
│   ├── audit/           # AuditLogService -- who-did-what for sensitive actions
│   ├── export/          # CSV export
│   ├── theme/           # App themes (Light/Dark)
│   └── utils/           # AppLogger, Currency formatting
├── features/
│   ├── splash/          # Boot screen: real init (session check, sync warm-up) before landing
│   ├── auth/            # Owner sign in/up + business creation/picker, staff code-join, role storage
│   ├── dashboard/       # Dashboard with real metrics (sales, active orders, low stock, unpaid)
│   ├── menu/            # Categories and Menu Items
│   ├── tables/          # Dine-in tables: CRUD + the grid used when starting a Dine In order
│   ├── orders/          # New Order screen (order-type/table setup -> menu -> cart), Order Details, QR scan
│   ├── kitchen/         # KOT / Kitchen display
│   ├── billing/         # Checkout, split/partial payments
│   ├── inventory/       # Ingredients, stock ledger, recipes
│   ├── customers/       # Customer directory + loyalty
│   ├── finance/         # Expenses + Suppliers (Owner-only)
│   ├── reports/         # Sales analytics: date ranges, revenue chart, payment mix
│   └── settings/        # Business settings, printer setup, activity log, staff codes/devices, logout
├── shared/
│   ├── models/          # Shared domain models (each with fromJson/toJson for sync)
│   ├── widgets/         # Common UI components (AppScaffold navigation, role-gated)
│   └── providers/       # Global providers (DB, sync service, repositories)
└── main.dart            # Entry point
```

## Offline-First Approach
1. UI reads/writes exclusively to the **Local Database (Drift)**.
2. Every repository write also queues a `sync_operations` row and calls `SyncService.triggerPush()`.
3. `SyncService` also runs a periodic **pull** per registered table (rows changed since the last successful pull) and subscribes to **Supabase Realtime** for the same tables, merging remote changes into the local DB as they arrive.
4. If offline, local changes stay queued in `sync_operations` (status `PENDING`, retried with a capped retry count, `FAILED` after repeated failures) until connectivity returns.

## Multi-tenancy
A `business_members` table (business_id, user_id, role) scopes every tenant table's Row Level Security policy via a `is_business_member(business_id)` helper -- see `supabase/migrations/20260829120000_multi_tenancy_and_payments.sql`. The owner's login looks up their businesses through this table rather than assuming a single business exists.

## Two ways onto a device
1. **Owner**: real Supabase email/password account. Sign up creates a business (auto-seeded with 8 tables and a `join_code`), sign-in picks from the businesses they belong to. This is the account used for recovery -- it's the only path that can ever hold `role = 'OWNER'`.
2. **Staff (Cashier/Manager, Waiter)**: no password at all. The device calls Supabase **Anonymous Sign-In** (a real `auth.users` row + JWT, just with no credential prompt), then a `SECURITY DEFINER` RPC (`join_business_with_code`) looks up the business by its short `join_code` and adds the anonymous user to `business_members` with role `MANAGER` or `STAFF` (never `OWNER` -- hardcoded in the function). See `SYNC.md` for why this needs zero changes to any table's RLS policy.

## Role-gated navigation
`AppScaffold` filters which nav destinations a role can see (`OWNER` sees everything; `MANAGER` loses Finance and the Staff/Devices settings tab; `STAFF` only gets New Order + Kitchen + a bare logout screen). `app_router.dart`'s redirect enforces the same set of allowed routes so a hidden screen isn't still reachable via a deep link or the back button.

**This is app-level (client) gating, not an additional RLS layer.** Business-level isolation (business A can never see business B's data) is fully enforced by Postgres RLS regardless of role. Role-level enforcement (can a `STAFF` device's Supabase API calls be blocked from writing to `expenses` even if the UI is bypassed?) is not implemented -- a reasonable trade-off for a small trusted-team tool, and the next hardening step if that assumption ever stops holding.
