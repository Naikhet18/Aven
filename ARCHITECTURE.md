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
- **QR Scanning**: `mobile_scanner`
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
│   ├── auth/            # Sign in/up, business creation, business picker
│   ├── dashboard/       # Dashboard with real metrics (sales, active orders, low stock, unpaid)
│   ├── menu/            # Categories and Menu Items
│   ├── orders/          # New Order screen, Cart, Order Management, Order Details, QR scan
│   ├── kitchen/         # KOT / Kitchen display
│   ├── billing/         # Checkout, split/partial payments
│   ├── inventory/       # Ingredients, stock ledger, recipes
│   ├── customers/       # Customer directory + loyalty
│   ├── finance/         # Expenses + Suppliers
│   ├── reports/         # Sales analytics: date ranges, revenue chart, payment mix
│   └── settings/        # Business settings, printer setup, activity log, logout
├── shared/
│   ├── models/          # Shared domain models (each with fromJson/toJson for sync)
│   ├── widgets/         # Common UI components (AppScaffold navigation)
│   └── providers/       # Global providers (DB, sync service, repositories)
└── main.dart            # Entry point
```

## Offline-First Approach
1. UI reads/writes exclusively to the **Local Database (Drift)**.
2. Every repository write also queues a `sync_operations` row and calls `SyncService.triggerPush()`.
3. `SyncService` also runs a periodic **pull** per registered table (rows changed since the last successful pull) and subscribes to **Supabase Realtime** for the same tables, merging remote changes into the local DB as they arrive.
4. If offline, local changes stay queued in `sync_operations` (status `PENDING`, retried with a capped retry count, `FAILED` after repeated failures) until connectivity returns.

## Multi-tenancy
A `business_members` table (business_id, user_id, role) scopes every tenant table's Row Level Security policy via a `is_business_member(business_id)` helper -- see `supabase/migrations/20260829120000_multi_tenancy_and_payments.sql`. Login looks up the signed-in user's businesses through this table rather than assuming a single business exists.
