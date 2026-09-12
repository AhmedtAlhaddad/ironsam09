-- Product color visual metadata. Apply to STAGING only first.
-- This migration does not recreate product_colors or change inventory logic.

alter table public.product_colors
  add column if not exists hex_code text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.product_colors'::regclass
      and conname = 'product_colors_hex_code_format_check'
  ) then
    alter table public.product_colors
      add constraint product_colors_hex_code_format_check
      check (hex_code is null or hex_code ~ '^#[0-9A-Fa-f]{6}$');
  end if;
end $$;

notify pgrst, 'reload schema';
