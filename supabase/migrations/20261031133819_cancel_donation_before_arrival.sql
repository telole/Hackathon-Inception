create function private.cancel_donation(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare d public.donations;
begin
 select * into d from public.donations where id=p_id for update;
 if not found or auth.uid() is null or (d.donor_id<>auth.uid() and not private.is_admin()) then raise exception 'FORBIDDEN' using errcode='42501';end if;
 if d.status='cancelled' then return;end if;
 if d.status not in ('draft','submitted','needs_revision','scheduled') then raise exception 'Cannot cancel after physical arrival';end if;
 update public.donations set status='cancelled' where id=p_id;
 update public.logistics_tasks set status='cancelled' where donation_id=p_id and status in ('assigned','accepted','in_progress');
 insert into public.donation_events(donation_id,event_type,summary,actor_id) values(p_id,'cancelled','Donasi dibatalkan sebelum penerimaan fisik',auth.uid());
end $$;
create function public.cancel_donation(p_id uuid) returns void language sql set search_path='' as $$select private.cancel_donation(p_id)$$;
revoke all on function private.cancel_donation(uuid) from public,anon,authenticated;
revoke all on function public.cancel_donation(uuid) from public,anon;
grant execute on function private.cancel_donation(uuid),public.cancel_donation(uuid) to authenticated;
