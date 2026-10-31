-- Additive core workflow endpoints. Existing stock RPCs remain authoritative.
create function private.save_need(p_id uuid,p_org uuid,p_point uuid,p_title text,
 p_description text,p_deadline timestamptz,p_incident uuid,p_items jsonb)
returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid; line jsonb; lid uuid; kept uuid[] := '{}'; old_org uuid;
begin
 if not private.org_access(p_org) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if nullif(trim(p_title),'') is null or p_deadline is null or
    jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items)=0 then
   raise exception 'Title, deadline and items are required'; end if;
 if p_id is null then
   insert into public.needs(organization_id,point_id,title,description,deadline_at,incident_id)
   values(p_org,p_point,trim(p_title),p_description,p_deadline,p_incident) returning id into v;
 else
   select organization_id into old_org from public.needs where id=p_id for update;
   if not found or not private.org_access(old_org) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
   v:=p_id;
   update public.needs set organization_id=p_org,point_id=p_point,title=trim(p_title),
     description=p_description,deadline_at=p_deadline,incident_id=p_incident where id=v;
 end if;
 for line in select value from jsonb_array_elements(p_items) loop
   lid:=nullif(line->>'id','')::uuid;
   if nullif(trim(line->>'category'),'') is null or nullif(trim(line->>'size_code'),'') is null
     or nullif(trim(line->>'age_group'),'') is null or coalesce((line->>'requested_qty')::int,0)<=0 then
     raise exception 'Invalid need item'; end if;
   if lid is null then
     insert into public.need_items(need_id,category,size_code,age_group,requested_qty)
     values(v,line->>'category',line->>'size_code',line->>'age_group',(line->>'requested_qty')::int)
     returning id into lid;
   else
     if lid=any(kept) then raise exception 'Duplicate item'; end if;
     update public.need_items set category=line->>'category',size_code=line->>'size_code',
       age_group=line->>'age_group',requested_qty=(line->>'requested_qty')::int where id=lid and need_id=v;
     if not found then raise exception 'Item belongs to another need'; end if;
   end if;
   kept:=array_append(kept,lid);
 end loop;
 -- FK constraints intentionally reject removal of allocated items; transaction rolls back.
 delete from public.need_items where need_id=v and not(id=any(kept));
 return v;
end $$;

create function private.need_status(p_id uuid,p_status text) returns void
language plpgsql security definer set search_path='' as $$
declare n public.needs;
begin
 select * into n from public.needs where id=p_id for update;
 if not found or not private.org_access(n.organization_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if p_status is null or p_status not in ('open','paused','closed','fulfilled') then raise exception 'Invalid need status'; end if;
 if p_status='open' then
   if n.deadline_at<=now() or not exists(select 1 from public.need_items where need_id=p_id)
     or not exists(select 1 from public.collection_points p join public.organizations o on o.id=p.organization_id
       where p.id=n.point_id and p.active and o.active and o.verified) then raise exception 'Need unavailable'; end if;
   if n.incident_id is not null and not exists(select 1 from public.incidents i where i.id=n.incident_id
     and i.status='active' and i.starts_at<=now() and i.ends_at>now()) then raise exception 'Incident unavailable'; end if;
 end if;
 if p_status='fulfilled' and exists(select 1 from public.need_items ni where ni.need_id=p_id and
   ni.requested_qty>coalesce((select sum(si.received_good) from public.shipment_items si
     join public.allocations a on a.id=si.allocation_id where a.need_item_id=ni.id),0)) then
   raise exception 'Need is not fulfilled'; end if;
 update public.needs set status=p_status where id=p_id;
end $$;

create function private.delete_need(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare n public.needs;
begin
 select * into n from public.needs where id=p_id for update;
 if not found or not private.org_access(n.organization_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if exists(select 1 from public.need_items ni join public.allocations a on a.need_item_id=ni.id where ni.need_id=p_id)
 or exists(select 1 from public.donations where preferred_need_id=p_id) then raise exception 'Need has dependencies; close it instead'; end if;
 delete from public.need_items where need_id=p_id;
 delete from public.needs where id=p_id;
end $$;

create function private.schedule_donation(p_id uuid,p_at timestamptz) returns void
language plpgsql security definer set search_path='' as $$
declare d public.donations;
begin
 select * into d from public.donations where id=p_id for update;
 if not found or not private.point_access(d.point_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if p_at is null or p_at<now() or d.status not in ('submitted','scheduled') then raise exception 'Invalid schedule'; end if;
 update public.donations set scheduled_at=p_at,status='scheduled' where id=p_id;
 insert into public.donation_events(donation_id,event_type,summary,actor_id)
 values(p_id,'scheduled','Jadwal penyerahan dikonfirmasi',auth.uid());
end $$;

create function private.assign_task(p_id uuid,p_donation uuid,p_point uuid,p_volunteer uuid,
 p_kind text,p_at timestamptz,p_notes text) returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid; t public.logistics_tasks;
begin
 if not private.point_access(p_point) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if p_kind is null or p_kind not in ('pickup','curation') then raise exception 'Delivery is assigned via create_shipment'; end if;
 if not exists(select 1 from public.donations where id=p_donation and point_id=p_point and
    status in ('submitted','scheduled','received','curated')) then raise exception 'Donation unavailable'; end if;
 if not exists(select 1 from public.user_roles where user_id=p_volunteer and role='relawan') then raise exception 'Assignee must have relawan role'; end if;
 if p_at is not null and p_at<now() then raise exception 'Schedule is in the past'; end if;
 if p_id is null then
   -- Serialize assignments for a donation, preventing duplicate active tasks of the same kind.
   perform 1 from public.donations where id=p_donation for update;
   if exists(select 1 from public.logistics_tasks where donation_id=p_donation and kind=p_kind
      and status in ('assigned','accepted','in_progress')) then raise exception 'Task already active'; end if;
   insert into public.logistics_tasks(donation_id,point_id,assigned_to,kind,scheduled_at,notes)
   values(p_donation,p_point,p_volunteer,p_kind,p_at,p_notes) returning id into v;
 else
   select * into t from public.logistics_tasks where id=p_id for update;
   if not found or not private.point_access(t.point_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
   if t.donation_id is distinct from p_donation or t.point_id<>p_point or t.kind<>p_kind
     or t.status not in ('assigned','declined','cancelled','failed') then raise exception 'Task cannot be reassigned'; end if;
   perform 1 from public.donations where id=p_donation for update;
   if exists(select 1 from public.logistics_tasks where donation_id=p_donation and kind=p_kind and id<>p_id
      and status in ('assigned','accepted','in_progress')) then raise exception 'Task already active'; end if;
   update public.logistics_tasks set assigned_to=p_volunteer,status='assigned',scheduled_at=p_at,notes=p_notes where id=p_id;
   v:=p_id;
 end if;
 return v;
end $$;

-- Lock parent rows before client edits so submit/curation cannot race item edits.
create function private.guard_draft_child() returns trigger language plpgsql security definer set search_path='' as $$
declare d public.donations; target uuid;
begin
 -- Trusted maintenance/fixture sessions may import history; clients cannot.
 if coalesce(current_setting('role',true),'none') not in ('authenticated','anon') then
   return case when tg_op='DELETE' then old else new end;
 end if;
 if tg_op='UPDATE' and new.donation_id<>old.donation_id then raise exception 'Cannot move donation child'; end if;
 target:=case when tg_op='DELETE' then old.donation_id else new.donation_id end;
 select * into d from public.donations where id=target for update;
 -- Parent deletion cascades: no parent left, no mutation to a submitted donation.
 if not found and tg_op='DELETE' then return old; end if;
 if not found or d.status not in ('draft','needs_revision') then raise exception 'Donation is no longer editable'; end if;
 if tg_table_name='donation_photos' and tg_op<>'DELETE' then
   if not exists(select 1 from storage.objects where bucket_id='donation-photos' and name=new.storage_path) then raise exception 'Photo object missing'; end if;
   if tg_op='INSERT' and (select count(*) from public.donation_photos where donation_id=target)>=5 then raise exception 'Maximum 5 photos'; end if;
 end if;
 return case when tg_op='DELETE' then old else new end;
end $$;
create trigger guard_draft_items before insert or update or delete on public.donation_items for each row execute function private.guard_draft_child();
create trigger guard_draft_photos before insert or update or delete on public.donation_photos for each row execute function private.guard_draft_child();

-- Expose only invoker wrappers, with explicit execution grants.
create function public.save_need(p_id uuid,p_org uuid,p_point uuid,p_title text,p_description text,p_deadline timestamptz,p_incident uuid,p_items jsonb)
returns uuid language sql set search_path='' as $$select private.save_need(p_id,p_org,p_point,p_title,p_description,p_deadline,p_incident,p_items)$$;
create function public.set_need_status(p_id uuid,p_status text) returns void language sql set search_path='' as $$select private.need_status(p_id,p_status)$$;
create function public.delete_need(p_id uuid) returns void language sql set search_path='' as $$select private.delete_need(p_id)$$;
create function public.schedule_donation(p_id uuid,p_at timestamptz) returns void language sql set search_path='' as $$select private.schedule_donation(p_id,p_at)$$;
create function public.assign_logistics_task(p_id uuid,p_donation uuid,p_point uuid,p_volunteer uuid,p_kind text,p_at timestamptz,p_notes text)
returns uuid language sql set search_path='' as $$select private.assign_task(p_id,p_donation,p_point,p_volunteer,p_kind,p_at,p_notes)$$;
revoke all on function private.guard_draft_child() from public,anon,authenticated;
revoke all on function private.save_need(uuid,uuid,uuid,text,text,timestamptz,uuid,jsonb),private.need_status(uuid,text),private.delete_need(uuid),private.schedule_donation(uuid,timestamptz),private.assign_task(uuid,uuid,uuid,uuid,text,timestamptz,text) from public,anon,authenticated;
grant execute on function private.save_need(uuid,uuid,uuid,text,text,timestamptz,uuid,jsonb),private.need_status(uuid,text),private.delete_need(uuid),private.schedule_donation(uuid,timestamptz),private.assign_task(uuid,uuid,uuid,uuid,text,timestamptz,text) to authenticated;
revoke all on function public.save_need(uuid,uuid,uuid,text,text,timestamptz,uuid,jsonb),public.set_need_status(uuid,text),public.delete_need(uuid),public.schedule_donation(uuid,timestamptz),public.assign_logistics_task(uuid,uuid,uuid,uuid,text,timestamptz,text) from public,anon;
grant execute on function public.save_need(uuid,uuid,uuid,text,text,timestamptz,uuid,jsonb),public.set_need_status(uuid,text),public.delete_need(uuid),public.schedule_donation(uuid,timestamptz),public.assign_logistics_task(uuid,uuid,uuid,uuid,text,timestamptz,text) to authenticated;
