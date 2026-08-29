# KhaoPiyo POS

A private, cross-platform (Android & iOS) restaurant/food-stall POS application optimized for fast counter ordering, offline-first reliability, and real-time synchronization.

## Features
- **Fast Counter Ordering**: POS layout optimized for touch and speed, with a dedicated New Order screen.
- **Cross-platform**: Runs on Android and iOS.
- **Offline-First**: Keep taking orders when the internet drops. Writes go to a local SQLite (Drift) database first and are queued for sync.
- **Real-time Sync**: Orders, menu, customers, and inventory sync across devices via Supabase Realtime, not just a one-way push.
- **Full POS Workflow**: KOT/Kitchen display (with optional auto-print), bill generation, split/partial payments across Cash/UPI/Card, daily sales reporting.
- **Tax & Discounts**: Configurable tax rate, percentage or fixed discounts with a reason.
- **Inventory**: Ingredient stock tracking, per-menu-item recipes, automatic deduction on sale, low-stock alerts.
- **Customers & Loyalty**: Attach a customer at checkout, track spend/visits, earn loyalty points.
- **Finance**: Expense and supplier tracking, net profit in Reports.
- **Real Receipt/KOT Printing**: Bluetooth (ESC/POS) or network (raw socket, port 9100) thermal printers.
- **QR Table Ordering**: Scan a table's QR code to jump straight into a dine-in order for that table.

## Running the app
Supabase configuration is supplied at build/run time, not hardcoded:
```bash
flutter run --dart-define-from-file=.env
```
`.env` (not committed) must contain:
```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```
The app deliberately refuses to start without these -- see [core/config/env.dart](lib/core/config/env.dart).

## Project Documentation
- [Architecture](ARCHITECTURE.md)
- [Database Schema](DATABASE.md)
- [Sync Strategy](SYNC.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Testing Strategy](TESTING.md)
