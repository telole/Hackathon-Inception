-- Minimal directory for dispatch/assignment; never exposes email, phone or address.
create or replace function public.list_assignable_volunteers()
returns table(user_id uuid, display_name text)
language plpgsql stable security definer set search_path = '' as $$
begin
  if auth.uid() is null or not (
    private.is_admin() or (
      private.has_role('mitra') and exists (
        select 1 from public.organization_members m
        join public.organizations o on o.id=m.organization_id
        where m.user_id=auth.uid() and m.active and o.active and o.verified
      )
    )
  ) then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  return query select r.user_id,p.display_name
  from public.user_roles r join public.profiles p on p.id=r.user_id
  where r.role='relawan' order by p.display_name,r.user_id limit 100;
end $$;
revoke all on function public.list_assignable_volunteers() from public,anon;
grant execute on function public.list_assignable_volunteers() to authenticated;
