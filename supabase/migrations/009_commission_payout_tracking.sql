-- Commission payout auditability and influencer-level payouts.
-- Apply to STAGING only first. This migration does not change commission
-- amounts or order/stock lifecycle behavior.

alter table public.orders
  add column if not exists commission_paid_at timestamptz null;

create index if not exists orders_influencer_commission_status_idx
  on public.orders(influencer_id, commission_status);

-- Preserve the existing admin-only transition rules while recording the time
-- of an approved -> paid transition. Commission amounts remain immutable.
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
    if p_status <> 'void' then
      raise exception 'cancelled_order_commission_must_be_void';
    end if;
  elsif order_row.influencer_id is null then
    if p_status <> 'void' then raise exception 'order_has_no_athlete'; end if;
  elsif p_status = 'approved' then
    if order_row.status <> 'delivered'
       or order_row.commission_status <> 'pending' then
      raise exception 'invalid_commission_transition';
    end if;
  elsif p_status = 'paid' then
    if order_row.status <> 'delivered'
       or order_row.commission_status <> 'approved' then
      raise exception 'invalid_commission_transition';
    end if;
  else
    raise exception 'invalid_commission_transition';
  end if;

  update public.orders
  set commission_status = p_status,
      commission_paid_at = case
        when p_status = 'paid' then now()
        else commission_paid_at
      end
  where id = p_order_id;
end;
$$;

revoke execute on function public.set_commission_status(uuid, text)
  from public, anon, authenticated;
grant execute on function public.set_commission_status(uuid, text)
  to authenticated;

create or replace function public.admin_mark_influencer_commissions_paid(
  p_influencer_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  orders_paid integer;
  total_paid numeric(12,2);
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;
  if p_influencer_id is null then raise exception 'influencer_required'; end if;

  with paid_orders as (
    update public.orders
    set commission_status = 'paid',
        commission_paid_at = now()
    where influencer_id = p_influencer_id
      and commission_status = 'approved'
      and status = 'delivered'
    returning athlete_commission_amount_lyd
  )
  select count(*)::integer,
         coalesce(sum(athlete_commission_amount_lyd), 0)::numeric(12,2)
  into orders_paid, total_paid
  from paid_orders;

  return jsonb_build_object(
    'orders_paid', orders_paid,
    'total_paid', total_paid
  );
end;
$$;

revoke execute on function public.admin_mark_influencer_commissions_paid(uuid)
  from public, anon, authenticated;
grant execute on function public.admin_mark_influencer_commissions_paid(uuid)
  to authenticated;

notify pgrst, 'reload schema';
