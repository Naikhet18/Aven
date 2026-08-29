-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Businesses
create table businesses (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    address text,
    phone text,
    created_at timestamp with time zone default now()
);

-- 2. Devices
create table devices (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    device_name text,
    platform text,
    last_seen timestamp with time zone default now()
);

-- 3. Categories
create table categories (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    name text not null,
    sort_order integer default 0,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    deleted_at timestamp with time zone
);

-- 4. Menu Items
create table menu_items (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    category_id uuid not null references categories(id) on delete cascade,
    name text not null,
    price numeric(10, 2) not null,
    is_available boolean default true,
    sort_order integer default 0,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    deleted_at timestamp with time zone
);

-- 5. Orders
create table orders (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    order_number text not null,
    order_type text not null, -- DINE_IN, TAKEAWAY, COUNTER
    table_number text,
    status text not null, -- NEW, PREPARING, READY, COMPLETED, CANCELLED
    payment_status text not null, -- UNPAID, PARTIALLY_PAID, PAID
    subtotal numeric(10, 2) not null default 0,
    tax numeric(10, 2) not null default 0,
    discount numeric(10, 2) not null default 0,
    total numeric(10, 2) not null default 0,
    created_by_device uuid references devices(id),
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- 6. Order Items
create table order_items (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references orders(id) on delete cascade,
    menu_item_id uuid not null references menu_items(id),
    item_name_snapshot text not null,
    unit_price numeric(10, 2) not null,
    quantity numeric(10, 2) not null,
    notes text,
    total numeric(10, 2) not null
);

-- 7. Payments
create table payments (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references orders(id) on delete cascade,
    business_id uuid not null references businesses(id) on delete cascade,
    payment_method text not null, -- CASH, UPI, CARD, OTHER
    payment_status text not null, -- UNPAID, PARTIALLY_PAID, PAID
    amount numeric(10, 2) not null,
    payment_time timestamp with time zone default now(),
    device_id uuid references devices(id)
);

-- Indexes for performance
create index idx_businesses_id on businesses(id);
create index idx_devices_business_id on devices(business_id);
create index idx_categories_business_id on categories(business_id);
create index idx_menu_items_business_id on menu_items(business_id);
create index idx_menu_items_category_id on menu_items(category_id);
create index idx_orders_business_id on orders(business_id);
create index idx_order_items_order_id on order_items(order_id);
create index idx_payments_order_id on payments(order_id);
create index idx_payments_business_id on payments(business_id);

-- Enable RLS and setup basic policies (for now, allow all for authenticated users)
alter table businesses enable row level security;
alter table devices enable row level security;
alter table categories enable row level security;
alter table menu_items enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table payments enable row level security;

create policy "Enable all for authenticated users" on businesses for all to authenticated using (true);
create policy "Enable all for authenticated users" on devices for all to authenticated using (true);
create policy "Enable all for authenticated users" on categories for all to authenticated using (true);
create policy "Enable all for authenticated users" on menu_items for all to authenticated using (true);
create policy "Enable all for authenticated users" on orders for all to authenticated using (true);
create policy "Enable all for authenticated users" on order_items for all to authenticated using (true);
create policy "Enable all for authenticated users" on payments for all to authenticated using (true);

-- Create a realtime publication for the relevant tables
begin;
  drop publication if exists supabase_realtime;
  create publication supabase_realtime;
commit;
alter publication supabase_realtime add table businesses, devices, categories, menu_items, orders, order_items, payments;
