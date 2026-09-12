-- Optional color-specific product images. Apply to STAGING only first.
-- Existing general images remain valid because color_id is nullable.

alter table public.product_images
  add column if not exists color_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.product_images'::regclass
      and conname = 'product_images_product_color_fk'
  ) then
    alter table public.product_images
      add constraint product_images_product_color_fk
      foreign key (product_id, color_id)
      references public.product_colors(product_id, id)
      on delete no action;
  end if;
end $$;

create index if not exists product_images_product_color_sort_idx
  on public.product_images(product_id, color_id, sort_order);

notify pgrst, 'reload schema';
