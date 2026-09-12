-- Safety hardening for order creation and status transitions.
-- Apply after 002_influencer_commissions.sql.

alter table public.orders
  add column if not exists client_request_id uuid;

create unique index if not exists orders_client_request_id_uidx
  on public.orders(client_request_id)
  where client_request_id is not null;

-- The legacy seven-argument RPC remains available to the database wrapper only.
-- Clients must use the idempotent wrapper below.
revoke execute on function public.submit_order(
  text, text, text, text, text, text, jsonb
) from public, anon, authenticated;

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
    -- Serialize retries using the same request id. If the first transaction
    -- already committed, return its receipt instead of creating a duplicate.
    perform pg_advisory_xact_lock(hashtextextended(p_request_id::text, 0));
    select jsonb_build_object(
      'order_id', o.id,
      'order_number', o.order_number,
      'subtotal', o.subtotal_lyd,
      'discount', o.discount_amount_lyd,
      'total', o.total_lyd
    )
    into existing_order
    from public.orders o
    where o.client_request_id = p_request_id;
    if existing_order is not null then
      return existing_order;
    end if;
  end if;

  -- The existing trusted RPC performs product, stock, discount, subtotal,
  -- commission, and atomic order-item validation in one database transaction.
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

revoke execute on function public.submit_order(
  text, text, text, text, text, text, jsonb, uuid
) from public, anon, authenticated;

grant execute on function public.submit_order(
  text, text, text, text, text, text, jsonb, uuid
) to anon, authenticated;

create or replace function public.set_order_status(
  p_order_id uuid,
  p_status public.order_status
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  old_status public.order_status;
  item record;
  changed integer;
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  select status into old_status
  from public.orders
  where id = p_order_id
  for update;
  if not found then raise exception 'order_not_found'; end if;
  if old_status = p_status then return; end if;

  if not (
    (old_status = 'pending' and p_status in ('confirmed', 'cancelled'))
    or (old_status = 'confirmed' and p_status in ('preparing', 'cancelled'))
    or (old_status = 'preparing' and p_status in ('delivered', 'cancelled'))
    or (old_status = 'cancelled' and p_status = 'confirmed')
  ) then
    raise exception 'invalid_order_transition:%:%', old_status, p_status;
  end if;

  if old_status = 'pending' and p_status = 'confirmed' then
    for item in select * from public.order_items where order_id = p_order_id loop
      update public.product_variants
      set stock_quantity = stock_quantity - item.quantity
      where id = item.variant_id and stock_quantity >= item.quantity;
      get diagnostics changed = row_count;
      if changed <> 1 then
        raise exception 'insufficient_stock:%:%', item.product_name_snapshot, item.selected_size;
      end if;
    end loop;
  elsif old_status in ('confirmed', 'preparing') and p_status = 'cancelled' then
    update public.product_variants v
    set stock_quantity = v.stock_quantity + oi.quantity
    from public.order_items oi
    where oi.order_id = p_order_id and oi.variant_id = v.id;
  elsif old_status = 'cancelled' and p_status = 'confirmed' then
    for item in select * from public.order_items where order_id = p_order_id loop
      update public.product_variants
      set stock_quantity = stock_quantity - item.quantity
      where id = item.variant_id and stock_quantity >= item.quantity;
      get diagnostics changed = row_count;
      if changed <> 1 then
        raise exception 'insufficient_stock:%:%', item.product_name_snapshot, item.selected_size;
      end if;
    end loop;
  end if;

  update public.orders
  set status = p_status,
      commission_status = case
        when p_status = 'cancelled' then 'void'
        when p_status = 'delivered' and influencer_id is not null then 'approved'
        when p_status = 'confirmed'
             and old_status = 'cancelled'
             and influencer_id is not null then 'pending'
        else commission_status
      end
  where id = p_order_id;
end;
$$;

create or replace function public.set_commission_status(
  p_order_id uuid,
  p_status text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  order_row public.orders;
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  select * into order_row
  from public.orders
  where id = p_order_id
  for update;
  if not found then raise exception 'order_not_found'; end if;
  if p_status not in ('pending', 'approved', 'paid', 'void') then
    raise exception 'invalid_commission_status';
  end if;
  if p_status = order_row.commission_status then return; end if;

  if order_row.status = 'cancelled' then
    if p_status <> 'void' then raise exception 'cancelled_order_commission_must_be_void'; end if;
  elsif order_row.influencer_id is null then
    if p_status <> 'void' then raise exception 'order_has_no_athlete'; end if;
  elsif p_status = 'approved' then
    if order_row.status <> 'delivered' or order_row.commission_status <> 'pending' then
      raise exception 'invalid_commission_transition';
    end if;
  elsif p_status = 'paid' then
    if order_row.status <> 'delivered' or order_row.commission_status <> 'approved' then
      raise exception 'invalid_commission_transition';
    end if;
  else
    raise exception 'invalid_commission_transition';
  end if;

  update public.orders set commission_status = p_status where id = p_order_id;
end;
$$;

revoke execute on function public.set_order_status(uuid, public.order_status)
  from public, anon, authenticated;
revoke execute on function public.set_commission_status(uuid, text)
  from public, anon, authenticated;
grant execute on function public.set_order_status(uuid, public.order_status)
  to authenticated;
grant execute on function public.set_commission_status(uuid, text)
  to authenticated;
