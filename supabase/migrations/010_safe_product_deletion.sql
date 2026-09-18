-- Preserve immutable order-item snapshots when catalog entities are removed.
--
-- Before this migration, order_items.product_id and order_items.variant_id
-- were NOT NULL foreign keys with ON DELETE RESTRICT. Deleting a product was
-- therefore blocked as soon as any historical order referenced it.
--
-- After this migration, these live catalog links are cleared while the order,
-- its order_items row, and all snapshot fields remain intact. Products that
-- belong to active orders cannot be deleted.

alter table public.order_items
  alter column product_id drop not null,
  alter column variant_id drop not null;

do $$
declare
  constraint_row record;
begin
  -- Drop only obsolete product/variant foreign keys. On a repeated run, the
  -- already-correct SET NULL constraints are left untouched.
  for constraint_row in
    select c.conname
    from pg_constraint c
    where c.conrelid = 'public.order_items'::regclass
      and c.contype = 'f'
      and c.confdeltype <> 'n'
      and (
        (
          c.confrelid = 'public.products'::regclass
          and (
            select array_agg(a.attname::text order by key.ordinality)
            from unnest(c.conkey) with ordinality as key(attnum, ordinality)
            join pg_attribute a
              on a.attrelid = c.conrelid and a.attnum = key.attnum
          ) = array['product_id']::text[]
        )
        or
        (
          c.confrelid = 'public.product_variants'::regclass
          and (
            select array_agg(a.attname::text order by key.ordinality)
            from unnest(c.conkey) with ordinality as key(attnum, ordinality)
            join pg_attribute a
              on a.attrelid = c.conrelid and a.attnum = key.attnum
          ) = array['variant_id']::text[]
        )
      )
  loop
    execute format(
      'alter table public.order_items drop constraint %I',
      constraint_row.conname
    );
  end loop;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    where c.conrelid = 'public.order_items'::regclass
      and c.confrelid = 'public.products'::regclass
      and c.contype = 'f'
      and c.confdeltype = 'n'
      and (
        select array_agg(a.attname::text order by key.ordinality)
        from unnest(c.conkey) with ordinality as key(attnum, ordinality)
        join pg_attribute a
          on a.attrelid = c.conrelid and a.attnum = key.attnum
      ) = array['product_id']::text[]
  ) then
    alter table public.order_items
      add constraint order_items_product_id_fkey
      foreign key (product_id)
      references public.products(id)
      on delete set null;
  end if;

  if not exists (
    select 1
    from pg_constraint c
    where c.conrelid = 'public.order_items'::regclass
      and c.confrelid = 'public.product_variants'::regclass
      and c.contype = 'f'
      and c.confdeltype = 'n'
      and (
        select array_agg(a.attname::text order by key.ordinality)
        from unnest(c.conkey) with ordinality as key(attnum, ordinality)
        join pg_attribute a
          on a.attrelid = c.conrelid and a.attnum = key.attnum
      ) = array['variant_id']::text[]
  ) then
    alter table public.order_items
      add constraint order_items_variant_id_fkey
      foreign key (variant_id)
      references public.product_variants(id)
      on delete set null;
  end if;
end
$$;

comment on column public.order_items.product_id is
  'Nullable link to the current catalog product. Historical details live in snapshot columns.';
comment on column public.order_items.variant_id is
  'Nullable link to the current catalog variant. Historical size/color details live in snapshot columns.';

-- Enforce the active-order rule even if a caller attempts a direct table
-- delete instead of using admin_delete_product.
create or replace function public.guard_product_delete_active_orders()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog
as $$
begin
  if exists (
    select 1
    from public.order_items oi
    join public.orders o on o.id = oi.order_id
    where o.status in ('pending', 'confirmed', 'preparing')
      and (
        oi.product_id = old.id
        or exists (
          select 1
          from public.product_variants v
          where v.id = oi.variant_id
            and v.product_id = old.id
        )
      )
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'active_orders_block_product_delete';
  end if;

  return old;
end;
$$;

revoke all on function public.guard_product_delete_active_orders() from public;

drop trigger if exists guard_product_delete_active_orders on public.products;
create trigger guard_product_delete_active_orders
before delete on public.products
for each row execute function public.guard_product_delete_active_orders();

-- Returns Storage object paths after the database deletion commits. The
-- authenticated Admin client removes those objects through the Storage API.
create or replace function public.admin_delete_product(p_product_id uuid)
returns text[]
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  image_paths text[] := array[]::text[];
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'not_admin';
  end if;

  perform 1
  from public.products p
  where p.id = p_product_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'product_not_found';
  end if;

  if exists (
    select 1
    from public.order_items oi
    join public.orders o on o.id = oi.order_id
    where o.status in ('pending', 'confirmed', 'preparing')
      and (
        oi.product_id = p_product_id
        or exists (
          select 1
          from public.product_variants v
          where v.id = oi.variant_id
            and v.product_id = p_product_id
        )
      )
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'active_orders_block_product_delete';
  end if;

  select coalesce(
    array_agg(distinct pi.storage_path)
      filter (where pi.storage_path is not null and pi.storage_path <> ''),
    array[]::text[]
  )
  into image_paths
  from public.product_images pi
  where pi.product_id = p_product_id;

  -- Keep the product-color composite FKs unchanged. Removing dependants first
  -- satisfies their existing RESTRICT/NO ACTION behavior safely.
  delete from public.product_images
  where product_id = p_product_id;

  delete from public.product_variants
  where product_id = p_product_id;

  delete from public.product_colors
  where product_id = p_product_id;

  delete from public.products
  where id = p_product_id;

  return image_paths;
end;
$$;

revoke all on function public.admin_delete_product(uuid)
from public, anon, authenticated;
grant execute on function public.admin_delete_product(uuid)
to authenticated;

comment on function public.admin_delete_product(uuid) is
  'Admin-only safe product deletion. Blocks active orders and preserves historical order-item snapshots.';

notify pgrst, 'reload schema';
