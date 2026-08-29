# Database Schema (Supabase PostgreSQL)

## Overview
All tables are isolated per business using `business_id`, enforced by Row Level Security policies
scoped through the `business_members` table (see below) -- not a blanket `using (true)`.
UUIDs are used as primary keys to prevent conflicts across devices.

Migrations live in `supabase/migrations/`. To apply them to the linked project: `supabase db push`.

## Multi-tenancy

### `business_members`
- `id` (UUID, PK)
- `business_id` (UUID, FK -> businesses)
- `user_id` (UUID, FK -> auth.users)
- `role` (TEXT) - OWNER, MANAGER, STAFF
- `created_at` (TIMESTAMP)
- unique (business_id, user_id)

Every tenant table's RLS policy calls `is_business_member(business_id)` (a `security definer`
function) instead of allowing any authenticated user through. A new `businesses` row automatically
adds its creator as `OWNER` via the `on_business_created` trigger.

## Core Tables

### `businesses`
- `id` (UUID, PK)
- `name` (TEXT)
- `address` (TEXT)
- `phone` (TEXT)
- `created_at` (TIMESTAMP)

### `devices`
- `id` (UUID, PK) -- matches the app's persisted per-install device id
- `business_id` (UUID, FK)
- `device_name` (TEXT)
- `platform` (TEXT)
- `last_seen` (TIMESTAMP)

### `categories`
- `id` (UUID, PK)
- `business_id` (UUID, FK)
- `name` (TEXT)
- `sort_order` (INTEGER)
- `created_at` / `updated_at` / `deleted_at` (TIMESTAMP, soft delete)

### `menu_items`
- `id` (UUID, PK)
- `business_id` (UUID, FK)
- `category_id` (UUID, FK)
- `name` (TEXT)
- `price` (NUMERIC)
- `is_available` (BOOLEAN)
- `sort_order` (INTEGER)
- `created_at` / `updated_at` / `deleted_at`

### `orders`
- `id` (UUID, PK)
- `business_id` (UUID, FK)
- `order_number` (TEXT) - e.g. `260829-A1-001` (date-deviceTag-sequence; see SYNC.md)
- `order_type` (TEXT) - DINE_IN, TAKEAWAY, COUNTER
- `table_number` (TEXT, nullable)
- `status` (TEXT) - NEW, PREPARING, READY, COMPLETED, CANCELLED
- `payment_status` (TEXT) - UNPAID, PARTIALLY_PAID, PAID
- `subtotal`, `tax`, `discount`, `total` (NUMERIC)
- `created_by_device` (UUID, FK -> devices)
- `customer_id` (UUID, FK -> customers, nullable)
- `discount_type` (TEXT) - PERCENTAGE, FIXED
- `discount_reason` (TEXT)
- `created_at` / `updated_at`

### `order_items`
- `id` (UUID, PK)
- `order_id` (UUID, FK)
- `menu_item_id` (UUID, FK)
- `item_name_snapshot` (TEXT)
- `unit_price`, `quantity`, `total` (NUMERIC)
- `notes` (TEXT)

### `payments`
Append-only ledger; an order can have multiple payments (split/partial payment).
- `id` (UUID, PK)
- `order_id` (UUID, FK)
- `business_id` (UUID, FK)
- `payment_method` (TEXT) - CASH, UPI, CARD, OTHER
- `amount` (NUMERIC)
- `payment_time` (TIMESTAMP)
- `device_id` (UUID, FK)

## Inventory

### `ingredients`
- `id`, `business_id`, `name`, `unit` (kg/g/liter/ml/piece), `current_stock`, `low_stock_threshold`,
  `created_at` / `updated_at` / `deleted_at`

### `recipes`
Bill-of-materials line linking a menu item to an ingredient.
- `id`, `menu_item_id` (FK), `ingredient_id` (FK), `quantity_required`, `created_at`

### `inventory_transactions`
Append-only stock ledger. Positive `quantity_change` = added (PURCHASE, MANUAL_ADJUSTMENT); negative
= removed (CONSUMPTION on sale, WASTAGE, or a MANUAL_ADJUSTMENT reversal on order cancellation).
- `id`, `business_id`, `ingredient_id` (FK), `transaction_type`, `quantity_change`, `supplier_id`
  (FK, nullable), `cost` (nullable), `notes`, `created_at`, `created_by_device`

## Customers & Loyalty

### `customers`
- `id`, `business_id`, `phone`, `name`, `total_spent`, `total_orders`, `loyalty_points`,
  `last_visit`, `created_at` / `updated_at`

## Finance

### `suppliers`
- `id`, `business_id`, `name`, `contact_name`, `phone`, `email`, `address`,
  `created_at` / `updated_at` / `deleted_at`

### `expenses`
- `id`, `business_id`, `category` (RENT/GAS/ELECTRICITY/INGREDIENTS/SALARY/MISC), `amount`,
  `expense_date`, `supplier_id` (FK, nullable), `notes`, `created_at`, `created_by_device`

## Audit

### `audit_logs`
- `id`, `business_id`, `device_id`, `action_type` (CANCEL_ORDER, REFUND, MODIFY_STOCK, CHANGE_PRICE),
  `details` (JSONB), `created_at`

## Local-only table

### `sync_operations` (Drift/SQLite only, never synced to Supabase)
The push queue: `operation` (INSERT/UPDATE/UPSERT/DELETE), `target_table`, `record_id`, `payload`
(JSON), `status` (PENDING/FAILED), `retry_count`, `created_at`.
