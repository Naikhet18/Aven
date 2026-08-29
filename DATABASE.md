# Database Schema (Supabase PostgreSQL)

## Overview
All tables are isolated per business using `business_id` and secured with Row Level Security (RLS).
UUIDs are used as primary keys to prevent conflicts across devices.

## Core Tables

### `businesses`
- `id` (UUID, PK)
- `name` (TEXT)
- `address` (TEXT)
- `phone` (TEXT)
- `created_at` (TIMESTAMP)

### `devices`
- `id` (UUID, PK)
- `business_id` (UUID, FK)
- `device_name` (TEXT)
- `platform` (TEXT)
- `last_seen` (TIMESTAMP)

### `categories`
- `id` (UUID, PK)
- `business_id` (UUID, FK)
- `name` (TEXT)
- `sort_order` (INTEGER)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `deleted_at` (TIMESTAMP) - For soft deletes

### `menu_items`
- `id` (UUID, PK)
- `business_id` (UUID, FK)
- `category_id` (UUID, FK)
- `name` (TEXT)
- `price` (NUMERIC)
- `is_available` (BOOLEAN)
- `sort_order` (INTEGER)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `deleted_at` (TIMESTAMP)

### `orders`
- `id` (UUID, PK)
- `business_id` (UUID, FK)
- `order_number` (TEXT) - e.g., 27-AUG-001
- `order_type` (TEXT) - DINE_IN, TAKEAWAY, COUNTER
- `table_number` (TEXT, Nullable)
- `status` (TEXT) - NEW, PREPARING, READY, COMPLETED, CANCELLED
- `payment_status` (TEXT) - UNPAID, PARTIALLY_PAID, PAID
- `subtotal` (NUMERIC)
- `tax` (NUMERIC)
- `discount` (NUMERIC)
- `total` (NUMERIC)
- `created_by_device` (UUID, FK)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### `order_items`
- `id` (UUID, PK)
- `order_id` (UUID, FK)
- `menu_item_id` (UUID, FK)
- `item_name_snapshot` (TEXT)
- `unit_price` (NUMERIC)
- `quantity` (NUMERIC)
- `notes` (TEXT)
- `total` (NUMERIC)

### `payments`
- `id` (UUID, PK)
- `order_id` (UUID, FK)
- `business_id` (UUID, FK)
- `payment_method` (TEXT) - CASH, UPI, CARD, OTHER
- `payment_status` (TEXT)
- `amount` (NUMERIC)
- `payment_time` (TIMESTAMP)
- `device_id` (UUID, FK)

### `sync_events` (Optional for advanced delta sync, or handle via updated_at)
- To track offline events for deterministic resolution.
