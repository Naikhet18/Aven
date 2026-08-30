# KhaoPiyo POS

A private, cross-platform (Android & iOS) restaurant/food-stall POS application optimized for fast counter ordering, offline-first reliability, and real-time synchronization.

## Features
- **Boot screen**: a real preloader (session check, sync warm-up) with a smooth fade/scale-in, not just a timed splash.
- **Password-less staff join**: the owner registers once with email/password; a waiter or cashier's device joins with a short restaurant code or QR scan -- no password, no email.
- **Role-gated**: Owner sees everything; Manager/Cashier loses Finance; Waiter only gets New Order + Kitchen.
- **Order setup flow**: choose Dine In / Takeaway / Counter first; Dine In shows a live table grid (add/rename tables in Settings) before the menu opens, tagging the order to that table.
- **Fast Counter Ordering**: big-button categorized menu optimized for touch and speed.
- **Cross-platform**: Runs on Android and iOS.
- **Offline-First**: Keep taking orders when the internet drops. Writes go to a local SQLite (Drift) database first and are queued for sync.
- **Real-time Sync**: Orders, menu, tables, customers, and inventory sync across devices via Supabase Realtime, not just a one-way push.
- **Full POS Workflow**: KOT/Kitchen display (with optional auto-print), bill generation, split/partial payments across Cash/UPI/Card, daily sales reporting.
- **Tax & Discounts**: Configurable tax rate, percentage or fixed discounts with a reason.
- **Inventory**: Ingredient stock tracking, per-menu-item recipes, automatic deduction on sale, low-stock alerts.
- **Customers & Loyalty**: Attach a customer at checkout, track spend/visits, earn loyalty points.
- **Finance**: Expense and supplier tracking, net profit in Reports (Owner-only).
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
