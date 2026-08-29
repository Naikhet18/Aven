# Testing Strategy

## Running tests
```bash
flutter test
```

## What's covered today
- `test/cart_calculations_test.dart` -- subtotal, percentage/fixed discount, tax-on-discounted-subtotal,
  and total math in `CartState`. This is the money logic most worth protecting in a POS.
- `test/models_json_test.dart` -- `fromJson`/`toJson` round-trips for the models the sync engine
  pushes/pulls (`Order`, `Payment`, `Ingredient`, `Customer`), including Supabase's snake_case keys
  and null timestamps.
- `test/printer_config_test.dart` -- `PrinterConfig` persists and restores correctly via
  `SharedPreferences`.
- `test/widget_test.dart` -- a real widget/interaction test for `DiscountDialog` (apply a percentage
  discount, verify `CartState`; remove a discount, verify it clears). Replaces the unmodified
  `flutter create` counter-app template that used to live here, which tested UI (a "+1" counter
  button) that has never existed in this app and would fail if run.

## What's not covered yet, and why
- **Repository/database tests** (e.g. `generateNextOrderNumber` uniqueness across device tags,
  `deductForOrder` stock math) would need either an injectable `QueryExecutor` on `AppDatabase` (it's
  currently hardcoded to the real `sqflite` backend) or `sqflite_common_ffi` for an in-memory SQLite
  in the test VM. Worth doing before this logic gets much more complex.
- **Sync engine tests** would need a fake/mockable `SupabaseClient` seam -- `SyncService` currently
  takes a real one directly. Consider extracting a small `SyncTransport` interface if the push/pull
  logic grows further.
- **Integration tests** (full offline-order-then-reconnect-and-sync flow, multi-device conflict
  scenarios) are not set up at all. `integration_test` package + two local Supabase projects (or a
  shared one with two simulated devices) would be the way to get there.

## Manual Testing
1. **Multi-device Sync Test**:
   - Device A and Device B logged into the same business.
   - Device A creates an order. It should appear on Device B via Realtime within moments (not just
     on the next periodic pull).
   - Device B updates the order status to "PREPARING". Device A should reflect it live.
2. **Split Payment**:
   - Create an order, go to Billing, pay part of it in Cash, part in UPI. Verify the balance-due
     figure updates between payments and `payment_status` only flips to PAID once fully covered.
3. **Offline Order Creation**:
   - Disable network, create an order. Verify it saves locally, gets a `<date>-<deviceTag>-<seq>`
     order number, and appears in `sync_operations` as PENDING. Reconnect and verify it pushes.
