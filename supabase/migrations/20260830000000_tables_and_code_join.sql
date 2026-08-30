-- Real dine-in tables + password-less staff device join via a restaurant code.
--
-- Staff devices authenticate via Supabase Anonymous Sign-In (a real
-- auth.users row + JWT, no email/password prompt), then call
-- join_business_with_code() to attach themselves to a business. This means
-- zero changes are needed to any existing RLS policy: the moment a
-- business_members row exists for the anonymous user, everything already
-- works exactly as it does for a normal owner login.
--
-- PREREQUISITE (cannot be done from a migration): enable
-- Authentication -> Sign In / Providers -> Anonymous Sign-Ins in the
-- Supabase dashboard for this project. The join flow fails until that's on.

-- 1. Dine-in tables (mirrors `categories` exactly).
create table tables (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references businesses(id) on delete cascade,
    name text not null,
    sort_order integer default 0,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    deleted_at timestamp with time zone
);
create index idx_tables_business_id on tables(business_id);

alter table tables enable row level security;
create policy "members can access tables" on tables
  for all to authenticated using (is_business_member(business_id)) with check (is_business_member(business_id));

alter publication supabase_realtime add table tables;

-- 2. Restaurant join code.
alter table businesses add column join_code text unique;

-- 3. Password-less staff join. SECURITY DEFINER so it can look up a business
-- by code without a `businesses` SELECT policy that would let any
-- authenticated user enumerate every business's join_code.
create or replace function join_business_with_code(
  p_code text,
  p_role text,
  p_device_id uuid,
  p_device_name text,
  p_platform text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
begin
  if p_role not in ('MANAGER', 'STAFF') then
    raise exception 'invalid role for code join: %', p_role;
  end if;

  select id into v_business_id from businesses where join_code = p_code;
  if v_business_id is null then
    raise exception 'invalid restaurant code';
  end if;

  insert into business_members (business_id, user_id, role)
  values (v_business_id, auth.uid(), p_role)
  on conflict (business_id, user_id) do update set role = excluded.role;

  insert into devices (id, business_id, device_name, platform, last_seen)
  values (p_device_id, v_business_id, p_device_name, p_platform, now())
  on conflict (id) do update set
    business_id = excluded.business_id,
    device_name = excluded.device_name,
    platform = excluded.platform,
    last_seen = now();

  return v_business_id;
end;
$$;

grant execute on function join_business_with_code(text, text, uuid, text, text) to authenticated;
-- `devices.id` is already the primary key (see init migration), so the
-- `on conflict (id)` upsert above works as-is.
