-- Security hardening for guest checkout and public discount validation.
-- Apply after 001_initial.sql, 002_influencer_commissions.sql, and 003_order_safety.sql.
-- This migration is intentionally additive and must be reviewed before applying.

create table if not exists public.order_submission_rate_limits (
  rate_key text primary key,
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0,
  updated_at timestamptz not null default now(),
  constraint order_submission_rate_limits_key_length
    check (char_length(rate_key) between 8 and 256),
  constraint order_submission_rate_limits_count_check
    check (request_count >= 0)
);

alter table public.order_submission_rate_limits enable row level security;
revoke all on table public.order_submission_rate_limits from public, anon, authenticated;
create index if not exists order_submission_rate_limits_updated_idx
  on public.order_submission_rate_limits(updated_at);

create or replace function public.consume_order_submission_slot(
  p_rate_key text,
  p_window interval default interval '10 minutes',
  p_limit integer default 5
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  current_row public.order_submission_rate_limits;
begin
  if p_rate_key is null or char_length(trim(p_rate_key)) < 8
     or char_length(trim(p_rate_key)) > 256
     or p_limit < 1 then
    return false;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(trim(p_rate_key), 0));

  select * into current_row
  from public.order_submission_rate_limits
  where rate_key = trim(p_rate_key)
  for update;

  if not found then
    insert into public.order_submission_rate_limits(
      rate_key, window_started_at, request_count, updated_at
    ) values (trim(p_rate_key), now(), 1, now());
    return true;
  end if;

  if current_row.window_started_at <= now() - p_window then
    update public.order_submission_rate_limits
    set window_started_at = now(), request_count = 1, updated_at = now()
    where rate_key = current_row.rate_key;
    return true;
  end if;

  if current_row.request_count >= p_limit then
    return false;
  end if;

  update public.order_submission_rate_limits
  set request_count = current_row.request_count + 1, updated_at = now()
  where rate_key = current_row.rate_key;
  return true;
end;
$$;

revoke execute on function public.consume_order_submission_slot(text, interval, integer)
  from public, anon, authenticated;

-- Keep the guest RPC available, but apply a per-phone server-side throttle.
create or replace function public.submit_order(
  p_customer_name text,
  p_phone text,
  p_city text,
  p_address text,
  p_notes text,
  p_discount_code text,
  p_items jsonb,
  p_request_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_order jsonb;
  created_order jsonb;
begin
  if nullif(trim(p_customer_name), '') is null
     or char_length(trim(p_customer_name)) > 120 then
    raise exception 'invalid_customer_name';
  end if;
  if p_phone is null or p_phone !~ '^09[0-9]{8}$' then
    raise exception 'invalid_phone';
  end if;
  if nullif(trim(p_city), '') is null or char_length(trim(p_city)) > 100 then
    raise exception 'invalid_city';
  end if;
  if nullif(trim(p_address), '') is null
     or char_length(trim(p_address)) > 500 then
    raise exception 'invalid_address';
  end if;
  if char_length(coalesce(p_notes, '')) > 2000 then
    raise exception 'invalid_notes';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'cart_empty';
  end if;

  if p_request_id is not null then
    perform pg_advisory_xact_lock(hashtextextended(p_request_id::text, 0));
    select jsonb_build_object(
      'order_id', o.id,
      'order_number', o.order_number,
      'subtotal', o.subtotal_lyd,
      'discount', o.discount_amount_lyd,
      'total', o.total_lyd
    ) into existing_order
    from public.orders o
    where o.client_request_id = p_request_id;
    if existing_order is not null then
      return existing_order;
    end if;
  end if;

  if not public.consume_order_submission_slot('phone:' || p_phone) then
    raise exception 'order_rate_limited';
  end if;

  created_order := public.submit_order(
    trim(p_customer_name),
    trim(p_phone),
    trim(p_city),
    trim(p_address),
    coalesce(trim(p_notes), ''),
    nullif(upper(trim(p_discount_code)), ''),
    p_items
  );

  if p_request_id is not null then
    update public.orders
    set client_request_id = p_request_id
    where id = (created_order->>'order_id')::uuid;
  end if;

  return created_order;
end;
$$;

-- The Edge Function adds a request-origin key for IP-level throttling.
create or replace function public.submit_order_guarded(
  p_customer_name text,
  p_phone text,
  p_city text,
  p_address text,
  p_notes text,
  p_discount_code text,
  p_items jsonb,
  p_request_id uuid,
  p_rate_key text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.consume_order_submission_slot('edge:' || trim(p_rate_key), interval '10 minutes', 20) then
    raise exception 'order_rate_limited';
  end if;

  return public.submit_order(
    p_customer_name,
    p_phone,
    p_city,
    p_address,
    p_notes,
    p_discount_code,
    p_items,
    p_request_id
  );
end;
$$;

revoke execute on function public.submit_order_guarded(
  text, text, text, text, text, text, jsonb, uuid, text
) from public, anon, authenticated;
grant execute on function public.submit_order_guarded(
  text, text, text, text, text, text, jsonb, uuid, text
) to service_role;

-- Do not expose commission columns through the public table read path.
drop policy if exists discount_public_validate on public.discount_codes;
revoke select on public.discount_codes from public, anon, authenticated;
grant select (
  id, code, active, expires_at, customer_discount_percent
) on public.discount_codes to anon, authenticated;

create or replace function public.validate_discount_code_public(p_code text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'valid', true,
        'code', d.code,
        'discount_percentage', d.customer_discount_percent
      )
      from public.discount_codes d
      where d.code = nullif(upper(trim(p_code)), '')
        and d.active
        and (d.expires_at is null or d.expires_at >= now())
      limit 1
    ),
    jsonb_build_object(
      'valid', false,
      'code', upper(trim(coalesce(p_code, ''))),
      'discount_percentage', 0
    )
  );
$$;

revoke execute on function public.validate_discount_code_public(text)
  from public;
grant execute on function public.validate_discount_code_public(text)
  to anon, authenticated;

-- Admins still receive commission information through a protected RPC only.
create or replace function public.admin_list_discount_codes()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  return query
  select jsonb_build_object(
    'id', d.id,
    'code', d.code,
    'active', d.active,
    'expires_at', d.expires_at,
    'customer_discount_percent', d.customer_discount_percent,
    'athlete_commission_percent', d.athlete_commission_percent,
    'influencers', case
      when i.id is null then null
      else jsonb_build_object('name', i.name)
    end
  )
  from public.discount_codes d
  left join public.influencers i on i.id = d.influencer_id
  order by d.created_at desc;
end;
$$;

revoke execute on function public.admin_list_discount_codes() from public, anon;
grant execute on function public.admin_list_discount_codes() to authenticated;
