# Architecture

## Overview
This application follows a **Feature-first Clean Architecture**.
- **UI (Presentation)**: Flutter Widgets, Riverpod providers.
- **Domain**: Business models, entities, and use cases.
- **Data**: Repositories, local SQLite (Drift) database, Supabase backend.
- **Sync Engine**: Handles offline-first capabilities and real-time syncing.

## Core Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Local Database**: Drift (SQLite)
- **Backend / Realtime**: Supabase (PostgreSQL + Auth + Realtime)

## Directory Structure
```
lib/
├── core/
│   ├── config/          # Environment vars, constants
│   ├── database/        # Drift local database setup
│   ├── sync/            # Sync engine logic
│   ├── theme/           # App themes (Light/Dark)
│   ├── utils/           # Helper functions
│   └── error/           # Error handling models
├── features/
│   ├── auth/            # Authentication & Business selection
│   ├── dashboard/       # Dashboard & Daily Sales
│   ├── menu/            # Categories and Menu Items
│   ├── orders/          # New Order screen, Cart, Order Management
│   ├── kitchen/         # KOT / Kitchen display
│   ├── billing/         # Checkout, Bill generation, Payments
│   ├── reports/         # Detailed sales and analytics
│   └── settings/        # App & Business settings
├── shared/
│   ├── models/          # Shared domain models
│   ├── widgets/         # Common UI components
│   └── providers/       # Global state providers
└── main.dart            # Entry point
```

## Offline-First Approach
1. UI reads/writes exclusively to the **Local Database (Drift)**.
2. The **Sync Engine** listens for local changes and pushes them to Supabase.
3. The **Sync Engine** listens for remote changes (Supabase Realtime) and pulls them into the Local Database.
4. If offline, local changes remain queued in a `sync_events` or queue table until connectivity is restored.
