-- V1 Expansion: Inventory, Recipes, Customers, Expenses, Suppliers, Audit Logs

-- 1. Suppliers
create table suppliers (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    name text not null,
    contact_name text,
    phone text,
    email text,
    address text,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    deleted_at timestamp with time zone
);

-- 2. Ingredients (Raw materials)
create table ingredients (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    name text not null,
    unit text not null, -- kg, g, liter, ml, piece
    current_stock numeric(10, 3) not null default 0,
    low_stock_threshold numeric(10, 3) default 0,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    deleted_at timestamp with time zone
);

-- 3. Recipes (Mapping menu_items to ingredients)
create table recipes (
    id uuid primary key default gen_random_uuid(),
    menu_item_id uuid not null references menu_items(id) on delete cascade,
    ingredient_id uuid not null references ingredients(id) on delete cascade,
    quantity_required numeric(10, 3) not null,
    created_at timestamp with time zone default now()
);

-- 4. Inventory Transactions (Ledger for stock changes)
create table inventory_transactions (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    ingredient_id uuid not null references ingredients(id) on delete cascade,
    transaction_type text not null, -- PURCHASE, CONSUMPTION, WASTAGE, MANUAL_ADJUSTMENT
    quantity_change numeric(10, 3) not null, -- positive for purchase, negative for consumption/wastage
    supplier_id uuid references suppliers(id),
    cost numeric(10, 2), -- total cost of purchase (if applicable)
    notes text,
    created_at timestamp with time zone default now(),
    created_by_device uuid references devices(id)
);

-- 5. Customers
create table customers (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    phone text,
    name text,
    total_spent numeric(10, 2) default 0,
    total_orders integer default 0,
    loyalty_points integer default 0,
    last_visit timestamp with time zone,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- 6. Expenses
create table expenses (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    category text not null, -- RENT, GAS, ELECTRICITY, INGREDIENTS, SALARY, MISC
    amount numeric(10, 2) not null,
    expense_date date not null default current_date,
    supplier_id uuid references suppliers(id),
    notes text,
    created_at timestamp with time zone default now(),
    created_by_device uuid references devices(id)
);

-- 7. Audit Logs
create table audit_logs (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    device_id uuid references devices(id),
    action_type text not null, -- CANCEL_ORDER, REFUND, MODIFY_STOCK, CHANGE_PRICE
    details jsonb,
    created_at timestamp with time zone default now()
);

-- 8. Alter Orders Table
alter table orders 
add column customer_id uuid references customers(id),
add column discount_type text, -- PERCENTAGE, FIXED
add column discount_reason text;

-- Indexes
create index idx_suppliers_business_id on suppliers(business_id);
create index idx_ingredients_business_id on ingredients(business_id);
create index idx_recipes_menu_item_id on recipes(menu_item_id);
create index idx_inventory_transactions_ingredient_id on inventory_transactions(ingredient_id);
create index idx_customers_business_id on customers(business_id);
create index idx_customers_phone on customers(phone);
create index idx_expenses_business_id on expenses(business_id);
create index idx_audit_logs_business_id on audit_logs(business_id);

-- Enable RLS (allow all for authenticated users temporarily for V1)
alter table suppliers enable row level security;
alter table ingredients enable row level security;
alter table recipes enable row level security;
alter table inventory_transactions enable row level security;
alter table customers enable row level security;
alter table expenses enable row level security;
alter table audit_logs enable row level security;

create policy "Enable all for authenticated users" on suppliers for all to authenticated using (true);
create policy "Enable all for authenticated users" on ingredients for all to authenticated using (true);
create policy "Enable all for authenticated users" on recipes for all to authenticated using (true);
create policy "Enable all for authenticated users" on inventory_transactions for all to authenticated using (true);
create policy "Enable all for authenticated users" on customers for all to authenticated using (true);
create policy "Enable all for authenticated users" on expenses for all to authenticated using (true);
create policy "Enable all for authenticated users" on audit_logs for all to authenticated using (true);

-- Add to realtime publication
alter publication supabase_realtime add table suppliers, ingredients, recipes, inventory_transactions, customers, expenses, audit_logs;
