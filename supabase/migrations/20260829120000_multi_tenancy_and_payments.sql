-- Multi-tenancy fix + Payments ledger
--
-- PROBLEM: every RLS policy so far is `for all to authenticated using (true)`.
-- Any signed-in user can read/write *every* business's data. The app also has
-- no way to know which business(es) a user belongs to (login just grabbed
-- whichever business happened to be first in the table).
--
-- FIX: introduce `business_members` (a user can belong to more than one
-- business, e.g. staff working multiple locations, or an owner + employees
-- sharing one business) and scope every tenant table's RLS to membership via
-- a security-definer helper, instead of `using (true)`.

-- 1. Membership table
create table business_members (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role text not null default 'STAFF', -- OWNER, MANAGER, STAFF
    created_at timestamp with time zone default now(),
    unique (business_id, user_id)
);
create index idx_business_members_user_id on business_members(user_id);
create index idx_business_members_business_id on business_members(business_id);

alter table business_members enable row level security;

-- 2. Helper used by every policy below. security definer + a fixed search_path
-- so it can read business_members regardless of the caller's own RLS grants,
-- without being hijackable via search_path tricks.
create or replace function is_business_member(target_business_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from business_members
    where business_members.business_id = target_business_id
      and business_members.user_id = auth.uid()
  );
$$;

-- 3. Backfill: preserve access for whatever pre-existing dev/demo data is in
-- this project today. Every current auth user becomes a member of every
-- pre-existing business, so nobody already using the app gets locked out.
-- Going forward, new businesses are scoped to only their creator (see the
-- trigger below) -- this backfill only ever runs once, for rows that predate
-- this migration.
insert into business_members (business_id, user_id, role)
select b.id, u.id, 'OWNER'
from businesses b
cross join auth.users u
on conflict (business_id, user_id) do nothing;

-- 4. New businesses: whoever inserts the row becomes its OWNER automatically.
create or replace function handle_new_business()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into business_members (business_id, user_id, role)
  values (new.id, auth.uid(), 'OWNER')
  on conflict (business_id, user_id) do nothing;
  return new;
end;
$$;

create trigger on_business_created
  after insert on businesses
  for each row execute function handle_new_business();

-- 5. Replace every "using (true)" policy with membership-scoped ones.
drop policy if exists "Enable all for authenticated users" on businesses;
drop policy if exists "Enable all for authenticated users" on devices;
drop policy if exists "Enable all for authenticated users" on categories;
drop policy if exists "Enable all for authenticated users" on menu_items;
drop policy if exists "Enable all for authenticated users" on orders;
drop policy if exists "Enable all for authenticated users" on order_items;
drop policy if exists "Enable all for authenticated users" on payments;
drop policy if exists "Enable all for authenticated users" on suppliers;
drop policy if exists "Enable all for authenticated users" on ingredients;
drop policy if exists "Enable all for authenticated users" on recipes;
drop policy if exists "Enable all for authenticated users" on inventory_transactions;
drop policy if exists "Enable all for authenticated users" on customers;
drop policy if exists "Enable all for authenticated users" on expenses;
drop policy if exists "Enable all for authenticated users" on audit_logs;

-- businesses: members can select/update; anyone authenticated can insert
-- (that's how a brand-new user creates their first business).
create policy "members can read their business" on businesses
  for select to authenticated using (is_business_member(id));
create policy "members can update their business" on businesses
  for update to authenticated using (is_business_member(id));
create policy "authenticated users can create a business" on businesses
  for insert to authenticated with check (true);

create policy "members can manage own membership rows" on business_members
  for select to authenticated using (user_id = auth.uid() or is_business_member(business_id));

create policy "members can access devices" on devices
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

create policy "members can access categories" on categories
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

create policy "members can access menu_items" on menu_items
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

create policy "members can access orders" on orders
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

-- order_items has no business_id column directly -- scope through its parent order.
create policy "members can access order_items" on order_items
  for all to authenticated using (
    exists (select 1 from orders where orders.id = order_items.order_id and is_business_member(orders.business_id))
  ) with check (
    exists (select 1 from orders where orders.id = order_items.order_id and is_business_member(orders.business_id))
  );

create policy "members can access payments" on payments
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

create policy "members can access suppliers" on suppliers
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

create policy "members can access ingredients" on ingredients
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

-- recipes has no business_id column directly -- scope through the menu item.
create policy "members can access recipes" on recipes
  for all to authenticated using (
    exists (select 1 from menu_items where menu_items.id = recipes.menu_item_id and is_business_member(menu_items.business_id))
  ) with check (
    exists (select 1 from menu_items where menu_items.id = recipes.menu_item_id and is_business_member(menu_items.business_id))
  );

create policy "members can access inventory_transactions" on inventory_transactions
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

create policy "members can access customers" on customers
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

create policy "members can access expenses" on expenses
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

create policy "members can access audit_logs" on audit_logs
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

alter publication supabase_realtime add table business_members;
