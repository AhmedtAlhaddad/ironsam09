-- Optional product labels managed from the admin product editor.
-- An empty value keeps the customer-facing label automatic from stock.
alter table public.products
  add column if not exists badge text not null default '';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'products_badge_check'
      and conrelid = 'public.products'::regclass
  ) then
    alter table public.products
      add constraint products_badge_check
      check (badge in ('', 'new', 'rare', 'limited'));
  end if;
end
$$;
