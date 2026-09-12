-- Configurable customer discounts and athlete commissions.
-- Run this file after 001_initial.sql in the Supabase SQL editor.

alter table public.discount_codes
  add column if not exists customer_discount_percent numeric(5,2) not null default 5,
  add column if not exists athlete_commission_percent numeric(5,2) not null default 5;

alter table public.orders
  add column if not exists customer_discount_percent numeric(5,2) not null default 0,
  add column if not exists athlete_commission_percent numeric(5,2) not null default 0,
  add column if not exists athlete_commission_amount_lyd numeric(12,2) not null default 0,
  add column if not exists commission_status text not null default 'void';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'discount_codes_customer_discount_percent_check'
  ) then
    alter table public.discount_codes
      add constraint discount_codes_customer_discount_percent_check
      check (customer_discount_percent >= 0 and customer_discount_percent <= 100);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'discount_codes_athlete_commission_percent_check'
  ) then
    alter table public.discount_codes
      add constraint discount_codes_athlete_commission_percent_check
      check (athlete_commission_percent >= 0 and athlete_commission_percent <= 100);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'orders_customer_discount_percent_check'
  ) then
    alter table public.orders
      add constraint orders_customer_discount_percent_check
      check (customer_discount_percent >= 0 and customer_discount_percent <= 100);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'orders_athlete_commission_percent_check'
  ) then
    alter table public.orders
      add constraint orders_athlete_commission_percent_check
      check (athlete_commission_percent >= 0 and athlete_commission_percent <= 100);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'orders_commission_status_check'
  ) then
    alter table public.orders
      add constraint orders_commission_status_check
      check (commission_status in ('pending', 'approved', 'paid', 'void'));
  end if;
end $$;

-- Existing orders created by version 1 used a fixed 5% customer discount.
update public.orders
set customer_discount_percent = case
      when discount_code is null then 0
      else 5
    end,
    athlete_commission_percent = case
      when influencer_id is null then 0
      else 5
    end,
    athlete_commission_amount_lyd = case
      when influencer_id is null then 0
      else round(subtotal_lyd * 0.05, 2)
    end,
    commission_status = case
      when influencer_id is null or status = 'cancelled' then 'void'
      when status = 'delivered' then 'approved'
      else 'pending'
    end;

create or replace function public.submit_order(
  p_customer_name text,
  p_phone text,
  p_city text,
  p_address text,
  p_notes text,
  p_discount_code text,
  p_items jsonb
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  item jsonb;
  product_row record;
  variant_row record;
  discount_row public.discount_codes;
  cover_url text;
  order_row public.orders;
  subtotal numeric(12,2) := 0;
  discount numeric(12,2) := 0;
  customer_discount_rate numeric(5,2) := 0;
  athlete_commission_rate numeric(5,2) := 0;
  athlete_commission numeric(12,2) := 0;
  order_influencer_id uuid := null;
  normalized_code text := nullif(upper(trim(p_discount_code)), '');
begin
  if jsonb_array_length(p_items) = 0 then raise exception 'cart_empty'; end if;

  for item in select * from jsonb_array_elements(p_items) loop
    select p.* into product_row
    from public.products p
    where p.id = (item->>'product_id')::uuid and p.active = true;
    if not found then raise exception 'product_unavailable'; end if;

    select v.* into variant_row
    from public.product_variants v
    where v.id = (item->>'variant_id')::uuid
      and v.product_id = product_row.id
      and v.size = item->>'size'
      and v.active = true;
    if not found then raise exception 'size_unavailable'; end if;
    if (item->>'quantity')::integer < 1
       or variant_row.stock_quantity < (item->>'quantity')::integer then
      raise exception 'insufficient_stock';
    end if;
    subtotal := subtotal + product_row.price_lyd * (item->>'quantity')::integer;
  end loop;

  if normalized_code is not null then
    select d.* into discount_row
    from public.discount_codes d
    where d.code = normalized_code
      and d.active
      and (d.expires_at is null or d.expires_at >= now());
    if not found then raise exception 'invalid_discount'; end if;

    customer_discount_rate := coalesce(discount_row.customer_discount_percent, 5);
    order_influencer_id := discount_row.influencer_id;
    athlete_commission_rate := case
      when discount_row.influencer_id is null then 0
      else coalesce(discount_row.athlete_commission_percent, 5)
    end;
    discount := round(subtotal * customer_discount_rate / 100, 2);
    -- The athlete commission is intentionally based on the original subtotal,
    -- before the customer discount and excluding delivery (delivery is free).
    athlete_commission := round(subtotal * athlete_commission_rate / 100, 2);
  end if;

  insert into public.orders(
    customer_name,
    phone,
    city,
    address,
    notes,
    subtotal_lyd,
    discount_amount_lyd,
    total_lyd,
    discount_code,
    influencer_id,
    customer_discount_percent,
    athlete_commission_percent,
    athlete_commission_amount_lyd,
    commission_status
  )
  values (
    p_customer_name,
    p_phone,
    p_city,
    p_address,
    coalesce(p_notes, ''),
    subtotal,
    discount,
    greatest(subtotal - discount, 0),
    normalized_code,
    order_influencer_id,
    customer_discount_rate,
    athlete_commission_rate,
    athlete_commission,
    case when order_influencer_id is null then 'void' else 'pending' end
  ) returning * into order_row;

  for item in select * from jsonb_array_elements(p_items) loop
    select p.* into product_row
    from public.products p where p.id = (item->>'product_id')::uuid;
    select v.* into variant_row
    from public.product_variants v where v.id = (item->>'variant_id')::uuid;
    select pi.url into cover_url
    from public.product_images pi
    where pi.product_id = product_row.id
    order by pi.is_cover desc, pi.sort_order asc
    limit 1;
    insert into public.order_items(
      order_id,
      product_id,
      variant_id,
      product_name_snapshot,
      product_image_url_snapshot,
      selected_size,
      quantity,
      unit_price_lyd,
      line_total_lyd
    )
    values (
      order_row.id,
      product_row.id,
      variant_row.id,
      product_row.name_ar,
      cover_url,
      variant_row.size,
      (item->>'quantity')::integer,
      product_row.price_lyd,
      product_row.price_lyd * (item->>'quantity')::integer
    );
  end loop;

  return jsonb_build_object(
    'order_id', order_row.id,
    'order_number', order_row.order_number,
    'subtotal', subtotal,
    'discount', discount,
    'athlete_commission', athlete_commission,
    'total', order_row.total_lyd
  );
end;
$$;

create or replace function public.set_order_status(
  p_order_id uuid,
  p_status public.order_status
) returns void language plpgsql security definer set search_path = public as $$
declare
  old_status public.order_status;
  item record;
  changed integer;
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;
  select status into old_status from public.orders where id = p_order_id for update;
  if not found then raise exception 'order_not_found'; end if;

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
  elsif old_status in ('confirmed', 'preparing', 'delivered')
        and p_status = 'cancelled' then
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
        when p_status = 'confirmed' and old_status = 'cancelled' and influencer_id is not null then 'pending'
        else commission_status
      end
  where id = p_order_id;
end;
$$;

create or replace function public.set_commission_status(
  p_order_id uuid,
  p_status text
) returns void language plpgsql security definer set search_path = public as $$
declare order_row public.orders;
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;
  if p_status not in ('pending', 'approved', 'paid', 'void') then
    raise exception 'invalid_commission_status';
  end if;
  select * into order_row from public.orders where id = p_order_id for update;
  if not found then raise exception 'order_not_found'; end if;
  if p_status = 'paid' and order_row.status <> 'delivered' then
    raise exception 'order_not_delivered';
  end if;
  if p_status in ('approved', 'paid') and order_row.influencer_id is null then
    raise exception 'order_has_no_athlete';
  end if;
  update public.orders set commission_status = p_status where id = p_order_id;
end;
$$;

grant execute on function public.set_commission_status(uuid, text) to authenticated;
