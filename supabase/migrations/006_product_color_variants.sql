-- Product color variants. Apply to STAGING only first.
-- This migration is additive and intentionally does not change any prior migration.

create table if not exists public.product_colors (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  name_ar text not null check (char_length(trim(name_ar)) > 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists product_colors_product_name_uidx
  on public.product_colors(product_id, lower(trim(name_ar)));
create index if not exists product_colors_storefront_idx
  on public.product_colors(product_id, active);

-- A composite reference prevents a variant from pointing at another product's color.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'product_colors_product_id_id_key'
      and conrelid = 'public.product_colors'::regclass
  ) then
    alter table public.product_colors
      add constraint product_colors_product_id_id_key unique (product_id, id);
  end if;
end $$;

alter table public.product_variants
  add column if not exists color_id uuid;

do $$
declare
  old_constraint text;
begin
  -- Discover the legacy inline UNIQUE(product_id, size) constraint by its
  -- actual columns instead of assuming PostgreSQL's generated name.
  select c.conname into old_constraint
  from pg_constraint c
  where c.conrelid = 'public.product_variants'::regclass
    and c.contype = 'u'
    and (
      select array_agg(a.attname::text order by key.ordinality)
      from unnest(c.conkey) with ordinality as key(attnum, ordinality)
      join pg_attribute a
        on a.attrelid = c.conrelid and a.attnum = key.attnum
    ) = ARRAY['product_id', 'size']::text[];

  if old_constraint is not null then
    execute format(
      'alter table public.product_variants drop constraint %I',
      old_constraint
    );
  end if;
end $$;

create unique index if not exists product_variants_legacy_product_size_uidx
  on public.product_variants(product_id, size)
  where color_id is null;
create unique index if not exists product_variants_colored_product_color_size_uidx
  on public.product_variants(product_id, color_id, size)
  where color_id is not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'product_variants_product_color_fk'
      and conrelid = 'public.product_variants'::regclass
  ) then
    alter table public.product_variants
      add constraint product_variants_product_color_fk
      foreign key (product_id, color_id)
      references public.product_colors(product_id, id)
      on delete restrict;
  end if;
end $$;

alter table public.order_items
  add column if not exists color_name_ar text;

drop trigger if exists product_colors_updated_at on public.product_colors;
create trigger product_colors_updated_at
before update on public.product_colors
for each row execute function public.touch_updated_at();

alter table public.product_colors enable row level security;
drop policy if exists product_colors_public_read on public.product_colors;
create policy product_colors_public_read
on public.product_colors for select to anon, authenticated
using (
  (active and exists (
    select 1 from public.products p
    where p.id = product_colors.product_id and p.active
  ))
  or public.is_admin()
);
drop policy if exists product_colors_admin_write on public.product_colors;
create policy product_colors_admin_write
on public.product_colors for all to authenticated
using (public.is_admin())
with check (public.is_admin());

grant select on public.product_colors to anon, authenticated;
grant insert, update, delete on public.product_colors to authenticated;
revoke insert, update, delete on public.product_colors from anon;

-- Keep inactive colors and their inventory out of the public storefront read
-- path while retaining the existing admin policy and stock access behavior.
drop policy if exists variants_public_read on public.product_variants;
create policy variants_public_read
on public.product_variants for select to anon, authenticated
using (
  exists (
    select 1 from public.products p
    where p.id = product_variants.product_id and p.active
  )
  and (
    (
      product_variants.color_id is null
      and not exists (
        select 1
        from public.product_colors pc_active
        where pc_active.product_id = product_variants.product_id
          and pc_active.active
      )
    )
    or (
      product_variants.color_id is not null
      and exists (
        select 1 from public.product_colors pc
        where pc.id = product_variants.color_id
          and pc.product_id = product_variants.product_id
          and pc.active
      )
    )
  )
);

-- Keep the existing public/guarded RPC architecture. The guarded wrapper from
-- 004 continues to call this trusted 7-argument implementation.
create or replace function public.submit_order(
  p_customer_name text,
  p_phone text,
  p_city text,
  p_address text,
  p_notes text,
  p_discount_code text,
  p_items jsonb
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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
  if p_items is null or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'cart_empty';
  end if;

  for item in select * from jsonb_array_elements(p_items) loop
    select p.* into product_row
    from public.products p
    where p.id = (item->>'product_id')::uuid and p.active = true;
    if not found then raise exception 'product_unavailable'; end if;

    select v.*, pc.name_ar as resolved_color_name_ar
    into variant_row
    from public.product_variants v
    left join public.product_colors pc
      on pc.id = v.color_id and pc.product_id = v.product_id
    where v.id = (item->>'variant_id')::uuid
      and v.product_id = product_row.id
      and v.size = item->>'size'
      and v.active = true
      and (
        (
          v.color_id is null
          and not exists (
            select 1
            from public.product_colors pc_active
            where pc_active.product_id = v.product_id
              and pc_active.active
          )
        )
        or (
          v.color_id is not null
          and pc.id is not null
          and pc.active
        )
      );
    if not found then raise exception 'size_unavailable'; end if;

    if item ? 'color_id'
       and nullif(trim(item->>'color_id'), '') is distinct from variant_row.color_id::text then
      raise exception 'color_mismatch';
    end if;
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
    athlete_commission := round(subtotal * athlete_commission_rate / 100, 2);
  end if;

  insert into public.orders(
    customer_name, phone, city, address, notes,
    subtotal_lyd, discount_amount_lyd, total_lyd,
    discount_code, influencer_id, customer_discount_percent,
    athlete_commission_percent, athlete_commission_amount_lyd, commission_status
  ) values (
    p_customer_name, p_phone, p_city, p_address, coalesce(p_notes, ''),
    subtotal, discount, greatest(subtotal - discount, 0),
    normalized_code, order_influencer_id, customer_discount_rate,
    athlete_commission_rate, athlete_commission,
    case when order_influencer_id is null then 'void' else 'pending' end
  ) returning * into order_row;

  for item in select * from jsonb_array_elements(p_items) loop
    select p.* into product_row
    from public.products p where p.id = (item->>'product_id')::uuid;
    select v.*, pc.name_ar as resolved_color_name_ar
    into variant_row
    from public.product_variants v
    left join public.product_colors pc
      on pc.id = v.color_id and pc.product_id = v.product_id
    where v.id = (item->>'variant_id')::uuid
      and v.product_id = product_row.id;
    select pi.url into cover_url
    from public.product_images pi
    where pi.product_id = product_row.id
    order by pi.is_cover desc, pi.sort_order asc
    limit 1;
    insert into public.order_items(
      order_id, product_id, variant_id, product_name_snapshot,
      product_image_url_snapshot, selected_size, color_name_ar,
      quantity, unit_price_lyd, line_total_lyd
    ) values (
      order_row.id, product_row.id, variant_row.id, product_row.name_ar,
      cover_url, variant_row.size, variant_row.resolved_color_name_ar,
      (item->>'quantity')::integer, product_row.price_lyd,
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

comment on table public.product_colors is
  'Normalized active color definitions for products; inventory remains in product_variants.';
comment on column public.order_items.color_name_ar is
  'Server-resolved historical color snapshot; never sourced from client text.';
