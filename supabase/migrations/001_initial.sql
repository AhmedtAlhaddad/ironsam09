create extension if not exists pgcrypto;

create sequence if not exists public.iron_order_number_seq start 4821;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  slug text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  description_ar text not null default '',
  price_lyd numeric(12, 2) not null check (price_lyd >= 0),
  category_id uuid references public.categories(id) on delete set null,
  gender text not null default 'unisex' check (gender in ('men', 'women', 'unisex')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  storage_path text not null,
  url text not null,
  sort_order integer not null default 0,
  is_cover boolean not null default false,
  created_at timestamptz not null default now()
);

create unique index if not exists one_cover_image_per_product on public.product_images(product_id) where is_cover;

create table if not exists public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  size text not null,
  stock_quantity integer not null default 0 check (stock_quantity >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(product_id, size)
);

create table if not exists public.influencers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.discount_codes (
  id uuid primary key default gen_random_uuid(),
  influencer_id uuid references public.influencers(id) on delete set null,
  code text not null unique,
  active boolean not null default true,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create type public.order_status as enum ('pending', 'confirmed', 'preparing', 'delivered', 'cancelled');

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique default ('IRON-' || lpad(nextval('public.iron_order_number_seq')::text, 4, '0')),
  customer_name text not null,
  phone text not null,
  city text not null,
  address text not null,
  notes text not null default '',
  subtotal_lyd numeric(12, 2) not null check (subtotal_lyd >= 0),
  discount_amount_lyd numeric(12, 2) not null default 0 check (discount_amount_lyd >= 0),
  total_lyd numeric(12, 2) not null check (total_lyd >= 0),
  discount_code text references public.discount_codes(code) on delete set null,
  influencer_id uuid references public.influencers(id) on delete set null,
  status public.order_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  product_name_snapshot text not null,
  product_image_url_snapshot text,
  selected_size text not null,
  quantity integer not null check (quantity > 0),
  unit_price_lyd numeric(12, 2) not null check (unit_price_lyd >= 0),
  line_total_lyd numeric(12, 2) not null check (line_total_lyd >= 0),
  created_at timestamptz not null default now()
);

create index if not exists products_active_idx on public.products(active, category_id, gender);
create index if not exists variants_stock_idx on public.product_variants(stock_quantity, active);
create index if not exists orders_status_created_idx on public.orders(status, created_at desc);
create index if not exists order_items_order_idx on public.order_items(order_id);

create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

do $$ declare table_name text; begin
  foreach table_name in array array['profiles','categories','products','product_variants','influencers','discount_codes','orders'] loop
    execute format('drop trigger if exists %I_updated_at on public.%I', table_name, table_name);
    execute format('create trigger %I_updated_at before update on public.%I for each row execute function public.touch_updated_at()', table_name, table_name);
  end loop;
end $$;

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and is_admin = true);
$$;

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.product_variants enable row level security;
alter table public.influencers enable row level security;
alter table public.discount_codes enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create policy profiles_admin_read on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create policy categories_public_read on public.categories for select to anon, authenticated using (active or public.is_admin());
create policy categories_admin_write on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy products_public_read on public.products for select to anon, authenticated using (active or public.is_admin());
create policy products_admin_write on public.products for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy images_public_read on public.product_images for select to anon, authenticated using (exists(select 1 from public.products p where p.id = product_id and (p.active or public.is_admin())));
create policy images_admin_write on public.product_images for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy variants_public_read on public.product_variants for select to anon, authenticated using (exists(select 1 from public.products p where p.id = product_id and (p.active or public.is_admin())));
create policy variants_admin_write on public.product_variants for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy discount_public_validate on public.discount_codes for select to anon, authenticated using (active and (expires_at is null or expires_at >= now()));
create policy discount_admin_write on public.discount_codes for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy influencers_admin_only on public.influencers for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy orders_admin_read on public.orders for select to authenticated using (public.is_admin());
create policy order_items_admin_read on public.order_items for select to authenticated using (public.is_admin());

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
  cover_url text;
  order_row public.orders;
  subtotal numeric(12,2) := 0;
  discount numeric(12,2) := 0;
  normalized_code text := nullif(upper(trim(p_discount_code)), '');
begin
  if jsonb_array_length(p_items) = 0 then raise exception 'cart_empty'; end if;
  for item in select * from jsonb_array_elements(p_items) loop
    select p.* into product_row from public.products p where p.id = (item->>'product_id')::uuid and p.active = true;
    if not found then raise exception 'product_unavailable'; end if;
    select v.* into variant_row from public.product_variants v where v.id = (item->>'variant_id')::uuid and v.product_id = product_row.id and v.size = item->>'size' and v.active = true;
    if not found then raise exception 'size_unavailable'; end if;
    if (item->>'quantity')::integer < 1 or variant_row.stock_quantity < (item->>'quantity')::integer then raise exception 'insufficient_stock'; end if;
    subtotal := subtotal + product_row.price_lyd * (item->>'quantity')::integer;
  end loop;
  if normalized_code is not null then
    if not exists (select 1 from public.discount_codes d where d.code = normalized_code and d.active and (d.expires_at is null or d.expires_at >= now())) then raise exception 'invalid_discount'; end if;
    discount := round(subtotal * 0.05, 2);
  end if;
  insert into public.orders(customer_name, phone, city, address, notes, subtotal_lyd, discount_amount_lyd, total_lyd, discount_code, influencer_id)
  values (p_customer_name, p_phone, p_city, p_address, coalesce(p_notes, ''), subtotal, discount, greatest(subtotal - discount, 0), normalized_code, (select influencer_id from public.discount_codes where code = normalized_code)) returning * into order_row;
  for item in select * from jsonb_array_elements(p_items) loop
    select p.* into product_row from public.products p where p.id = (item->>'product_id')::uuid;
    select v.* into variant_row from public.product_variants v where v.id = (item->>'variant_id')::uuid;
    select pi.url into cover_url from public.product_images pi where pi.product_id = product_row.id order by pi.is_cover desc, pi.sort_order asc limit 1;
    insert into public.order_items(order_id, product_id, variant_id, product_name_snapshot, product_image_url_snapshot, selected_size, quantity, unit_price_lyd, line_total_lyd)
    values (order_row.id, product_row.id, variant_row.id, product_row.name_ar, cover_url, variant_row.size, (item->>'quantity')::integer, product_row.price_lyd, product_row.price_lyd * (item->>'quantity')::integer);
  end loop;
  return jsonb_build_object('order_id', order_row.id, 'order_number', order_row.order_number, 'subtotal', subtotal, 'discount', discount, 'total', order_row.total_lyd);
end;
$$;

create or replace function public.set_order_status(p_order_id uuid, p_status public.order_status) returns void language plpgsql security definer set search_path = public as $$
declare old_status public.order_status; item record; changed integer;
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;
  select status into old_status from public.orders where id = p_order_id for update;
  if not found then raise exception 'order_not_found'; end if;
  if old_status = 'pending' and p_status = 'confirmed' then
    for item in select * from public.order_items where order_id = p_order_id loop
      update public.product_variants set stock_quantity = stock_quantity - item.quantity where id = item.variant_id and stock_quantity >= item.quantity;
      get diagnostics changed = row_count;
      if changed <> 1 then raise exception 'insufficient_stock:%:%', item.product_name_snapshot, item.selected_size; end if;
    end loop;
  elsif old_status in ('confirmed','preparing','delivered') and p_status = 'cancelled' then
    update public.product_variants v set stock_quantity = v.stock_quantity + oi.quantity from public.order_items oi where oi.order_id = p_order_id and oi.variant_id = v.id;
  elsif old_status = 'cancelled' and p_status = 'confirmed' then
    for item in select * from public.order_items where order_id = p_order_id loop
      update public.product_variants set stock_quantity = stock_quantity - item.quantity where id = item.variant_id and stock_quantity >= item.quantity;
      get diagnostics changed = row_count;
      if changed <> 1 then raise exception 'insufficient_stock:%:%', item.product_name_snapshot, item.selected_size; end if;
    end loop;
  end if;
  update public.orders set status = p_status where id = p_order_id;
end;
$$;

grant execute on function public.submit_order(text,text,text,text,text,text,jsonb) to anon, authenticated;
grant execute on function public.set_order_status(uuid,public.order_status) to authenticated;

insert into storage.buckets (id, name, public) values ('product-images', 'product-images', true) on conflict (id) do update set public = true;
create policy product_images_storage_read on storage.objects for select to anon, authenticated using (bucket_id = 'product-images');
create policy product_images_storage_admin_insert on storage.objects for insert to authenticated with check (bucket_id = 'product-images' and public.is_admin());
create policy product_images_storage_admin_update on storage.objects for update to authenticated using (bucket_id = 'product-images' and public.is_admin()) with check (bucket_id = 'product-images' and public.is_admin());
create policy product_images_storage_admin_delete on storage.objects for delete to authenticated using (bucket_id = 'product-images' and public.is_admin());
