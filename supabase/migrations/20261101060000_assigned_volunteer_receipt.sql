-- Receiving is allowed only for the active assignee; other transitions keep point access.
create or replace function private.advance_donation(p_id uuid,p_status text) returns void
language plpgsql security definer set search_path='' as $$
declare d public.donations;
begin
 select * into d from public.donations where id=p_id for update;
 if not found or auth.uid() is null then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if not (private.point_access(d.point_id) or (
   p_status='received' and private.has_role('relawan') and exists (
     select 1 from public.logistics_tasks t where t.donation_id=d.id and t.point_id=d.point_id
     and t.assigned_to=auth.uid() and t.kind in ('pickup','curation') and t.status in ('accepted','in_progress')
   )
 )) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if d.status='received' and p_status='received' then return; end if;
 if not ((d.status='submitted' and p_status in ('needs_revision','scheduled','received'))
   or (d.status='scheduled' and p_status='received')) then raise exception 'Invalid status transition'; end if;
 update public.donations set status=p_status where id=p_id;
 insert into public.donation_events(donation_id,event_type,summary,actor_id)
 values(p_id,p_status,'Status donasi: '||p_status,auth.uid());
end $$;
