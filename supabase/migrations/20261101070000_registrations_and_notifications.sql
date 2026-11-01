alter table public.organization_members add column member_role text not null default 'manager' check(member_role in ('manager','member'));
create table public.role_requests(
 id uuid primary key, user_id uuid not null default auth.uid() references public.profiles(id),
 message text not null check(length(trim(message)) between 10 and 1000),
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 review_reason text, reviewed_by uuid references public.profiles(id), created_at timestamptz not null default now(), reviewed_at timestamptz
);
create unique index one_pending_volunteer_request on public.role_requests(user_id) where status='pending';
create table public.organization_applications(
 id uuid primary key, applicant_id uuid not null default auth.uid() references public.profiles(id),
 name text not null check(length(trim(name)) between 2 and 150),
 kind text not null check(kind in ('social_institution','disaster_post','recycling_partner')),
 area text not null check(length(trim(area)) between 2 and 150),
 contact_name text not null check(length(trim(contact_name)) between 2 and 100),
 contact_phone text not null check(length(trim(contact_phone)) between 6 and 30), document_path text,
 status text not null default 'draft' check(status in ('draft','pending','approved','rejected')),
 organization_id uuid references public.organizations(id), review_reason text, reviewed_by uuid references public.profiles(id),
 created_at timestamptz not null default now(), reviewed_at timestamptz
);
create unique index one_open_org_application on public.organization_applications(applicant_id) where status in ('draft','pending');
alter table public.role_requests enable row level security;
alter table public.organization_applications enable row level security;
revoke all on public.role_requests,public.organization_applications from public,anon,authenticated;
grant select on public.role_requests,public.organization_applications to authenticated;
create policy read_own_role_request on public.role_requests for select to authenticated using(user_id=auth.uid() or private.is_admin());
create policy read_own_org_application on public.organization_applications for select to authenticated using(applicant_id=auth.uid() or private.is_admin());
create index role_requests_admin_queue on public.role_requests(status,created_at,id);
create index org_applications_admin_queue on public.organization_applications(status,created_at,id);

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('verification-documents','verification-documents',false,5242880,array['application/pdf','image/jpeg','image/png']) on conflict(id) do nothing;
create policy pk_verification_insert on storage.objects for insert to authenticated
with check(bucket_id='verification-documents' and (storage.foldername(name))[1]=auth.uid()::text
and exists(select 1 from public.organization_applications a where a.id::text=(storage.foldername(name))[2] and a.applicant_id=auth.uid() and a.status='draft'));
create policy pk_verification_read on storage.objects for select to authenticated
using(bucket_id='verification-documents' and exists(select 1 from public.organization_applications a where a.document_path=name and (a.applicant_id=auth.uid() or private.is_admin())));
create policy pk_verification_delete on storage.objects for delete to authenticated
using(bucket_id='verification-documents' and (storage.foldername(name))[1]=auth.uid()::text
and exists(select 1 from public.organization_applications a where a.id::text=(storage.foldername(name))[2] and a.applicant_id=auth.uid() and a.status='draft'));

create function public.apply_volunteer(p_id uuid,p_message text) returns uuid
language plpgsql security definer set search_path='' as $$
declare r public.role_requests;
begin
 if auth.uid() is null then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if p_id is null or length(trim(p_message)) not between 10 and 1000 or p_message is null then raise exception 'Invalid motivation'; end if;
 perform pg_advisory_xact_lock(hashtextextended('volunteer:'||auth.uid()::text,0));
 select * into r from public.role_requests where id=p_id;
 if found then
   if r.user_id<>auth.uid() then raise exception 'FORBIDDEN' using errcode='42501'; end if;
   if r.message<>trim(p_message) then raise exception 'Request payload changed'; end if;
   return r.id;
 end if;
 if private.has_role('relawan') then raise exception 'Already a volunteer'; end if;
 if exists(select 1 from public.role_requests where user_id=auth.uid() and status='pending') then raise exception 'Request already pending'; end if;
 insert into public.role_requests(id,user_id,message) values(p_id,auth.uid(),trim(p_message));
 return p_id;
end $$;

create function public.save_organization_application(p_id uuid,p_payload jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare a public.organization_applications;
begin
 if auth.uid() is null then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if p_id is null or jsonb_typeof(p_payload) is distinct from 'object' then raise exception 'Invalid application'; end if;
 perform pg_advisory_xact_lock(hashtextextended('organization:'||auth.uid()::text,0));
 select * into a from public.organization_applications where id=p_id for update;
 if found then
   if a.applicant_id<>auth.uid() then raise exception 'FORBIDDEN' using errcode='42501'; end if;
   if a.status='pending' then return a.id; end if;
   if a.status='approved' then raise exception 'Application already approved'; end if;
   update public.organization_applications set name=trim(p_payload->>'name'),kind=p_payload->>'kind',area=trim(p_payload->>'area'),
     contact_name=trim(p_payload->>'contact_name'),contact_phone=trim(p_payload->>'contact_phone'),status='draft',review_reason=null,reviewed_at=null,reviewed_by=null
     where id=p_id;
 else
   insert into public.organization_applications(id,applicant_id,name,kind,area,contact_name,contact_phone)
   values(p_id,auth.uid(),trim(p_payload->>'name'),p_payload->>'kind',trim(p_payload->>'area'),trim(p_payload->>'contact_name'),trim(p_payload->>'contact_phone'));
 end if;
 return p_id;
end $$;

create function public.submit_organization_application(p_id uuid,p_document text) returns void
language plpgsql security definer set search_path='' as $$
declare a public.organization_applications;
begin
 select * into a from public.organization_applications where id=p_id for update;
 if not found or a.applicant_id is distinct from auth.uid() then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if a.status='pending' and a.document_path=p_document then return; end if;
 if a.status<>'draft' or p_document is null or split_part(p_document,'/',1)<>auth.uid()::text or split_part(p_document,'/',2)<>a.id::text
 or not exists(select 1 from storage.objects where bucket_id='verification-documents' and name=p_document) then raise exception 'Valid verification document required'; end if;
 update public.organization_applications set document_path=p_document,status='pending' where id=a.id;
end $$;

create function public.review_registration(p_type text,p_id uuid,p_approve boolean,p_reason text) returns void
language plpgsql security definer set search_path='' as $$
declare r public.role_requests; a public.organization_applications; org uuid; decision text;
begin
 if not private.is_admin() or auth.uid() is null then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if p_approve is null or length(coalesce(p_reason,''))>1000 or (not p_approve and nullif(trim(p_reason),'') is null) then raise exception 'Review reason required'; end if;
 decision:=case when p_approve then 'approved' else 'rejected' end;
 if p_type='volunteer' then
   select * into r from public.role_requests where id=p_id for update;
   if not found then raise exception 'Application missing'; end if;
   if r.status=decision then return; end if;
   if r.status<>'pending' then raise exception 'Application already reviewed'; end if;
   if p_approve then insert into public.user_roles(user_id,role,granted_by) values(r.user_id,'relawan',auth.uid()) on conflict do nothing; end if;
   update public.role_requests set status=decision,review_reason=nullif(trim(p_reason),''),reviewed_by=auth.uid(),reviewed_at=now() where id=r.id;
 elsif p_type='organization' then
   select * into a from public.organization_applications where id=p_id for update;
   if not found then raise exception 'Application missing'; end if;
   if a.status=decision then return; end if;
   if a.status<>'pending' then raise exception 'Application is not awaiting review'; end if;
   if p_approve then
     insert into public.organizations(name,kind,area,verified,active) values(a.name,a.kind,a.area,true,true) returning id into org;
     insert into public.organization_members(organization_id,user_id,active,member_role) values(org,a.applicant_id,true,'manager');
     insert into public.user_roles(user_id,role,granted_by) values(a.applicant_id,'mitra',auth.uid()) on conflict do nothing;
   end if;
   update public.organization_applications set status=decision,organization_id=org,review_reason=nullif(trim(p_reason),''),reviewed_by=auth.uid(),reviewed_at=now() where id=a.id;
 else raise exception 'Unknown application type'; end if;
end $$;

create function private.is_org_manager(p_org uuid) returns boolean language sql stable security definer set search_path='' as $$
select auth.uid() is not null and (private.is_admin() or (private.org_access(p_org) and exists(
 select 1 from public.organization_members where organization_id=p_org and user_id=auth.uid() and active and member_role='manager')))
$$;
revoke all on function private.is_org_manager(uuid) from public,anon,authenticated;

create function public.list_organization_members(p_org uuid,p_offset int default 0,p_limit int default 26)
returns table(user_id uuid,display_name text,active boolean,member_role text)
language plpgsql stable security definer set search_path='' as $$
begin
 if not private.org_access(p_org) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 return query select m.user_id,p.display_name,m.active,m.member_role from public.organization_members m
 join public.profiles p on p.id=m.user_id where m.organization_id=p_org order by p.display_name,m.user_id
 offset greatest(p_offset,0) limit least(greatest(p_limit,1),101);
end $$;
create function public.manage_organization_member(p_org uuid,p_email text,p_user uuid,p_active boolean) returns void
language plpgsql security definer set search_path='' as $$
declare target uuid; current_role text;
begin
 if not private.is_org_manager(p_org) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if p_active is null then raise exception 'Membership status required'; end if;
 target:=p_user;
 if target is null then select id into target from auth.users where lower(email)=lower(trim(p_email)); end if;
 if target is null then raise exception 'Registered account not found'; end if;
 select member_role into current_role from public.organization_members where organization_id=p_org and user_id=target for update;
 if current_role='manager' then raise exception 'Manager membership cannot be changed here'; end if;
 insert into public.organization_members(organization_id,user_id,active,member_role) values(p_org,target,p_active,'member')
 on conflict(organization_id,user_id) do update set active=excluded.active;
 if p_active then insert into public.user_roles(user_id,role,granted_by) values(target,'mitra',auth.uid()) on conflict do nothing; end if;
end $$;
create function public.save_collection_point(p_id uuid,p_org uuid,p_name text,p_address text,p_hours text,p_active boolean) returns uuid
language plpgsql security definer set search_path='' as $$
declare target uuid;
begin
 if not private.is_org_manager(p_org) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if length(trim(coalesce(p_name,''))) not between 2 and 150 or length(trim(coalesce(p_address,''))) not between 5 and 500 or p_active is null then raise exception 'Invalid service point'; end if;
 if p_id is null then
   insert into public.collection_points(organization_id,name,public_address,opening_hours,active) values(p_org,trim(p_name),trim(p_address),p_hours,p_active) returning id into target;
 else
   update public.collection_points set name=trim(p_name),public_address=trim(p_address),opening_hours=p_hours,active=p_active where id=p_id and organization_id=p_org returning id into target;
   if target is null then raise exception 'Service point unavailable'; end if;
 end if;
 return target;
end $$;

revoke all on function public.apply_volunteer(uuid,text),public.save_organization_application(uuid,jsonb),public.submit_organization_application(uuid,text),
public.review_registration(text,uuid,boolean,text),public.list_organization_members(uuid,int,int),public.manage_organization_member(uuid,text,uuid,boolean),
public.save_collection_point(uuid,uuid,text,text,text,boolean) from public,anon;
grant execute on function public.apply_volunteer(uuid,text),public.save_organization_application(uuid,jsonb),public.submit_organization_application(uuid,text),
public.review_registration(text,uuid,boolean,text),public.list_organization_members(uuid,int,int),public.manage_organization_member(uuid,text,uuid,boolean),
public.save_collection_point(uuid,uuid,text,text,text,boolean) to authenticated;

alter table public.notifications add column route text;
alter table public.notifications add column event_key text unique;
create index notification_inbox_order on public.notifications(user_id,created_at desc,id);
create function public.notification_unread_count() returns bigint language sql stable security invoker set search_path='' as $$
select count(*) from public.notifications where user_id=auth.uid() and read_at is null $$;
revoke all on function public.notification_unread_count() from public,anon;
grant execute on function public.notification_unread_count() to authenticated;

create function private.notify_core_events() returns trigger language plpgsql security definer set search_path='' as $$
declare recipient uuid; target_route text; title text; body text; prefix text;
begin
 if tg_table_name='donation_events' then
   select donor_id into recipient from public.donations where id=new.donation_id;
   insert into public.notifications(user_id,title,body,route,event_key)
   values(recipient,'Kabar donasimu',new.summary,'/tracking?donation='||new.donation_id,'donation-event:'||new.id) on conflict(event_key) do nothing;
 elsif tg_table_name='logistics_tasks' then
   if new.status='assigned' and (tg_op='INSERT' or new.assigned_to is distinct from old.assigned_to or old.status<>'assigned') then
     insert into public.notifications(user_id,title,body,route,event_key) values(new.assigned_to,'Tugas relawan baru','Ada tugas baru untuk ditinjau.','/operations/tasks/'||new.id,'task:'||gen_random_uuid());
   end if;
 elsif tg_table_name='shipments' then
   if tg_op='INSERT' and new.assigned_to is not null then
     insert into public.notifications(user_id,title,body,route,event_key) values(new.assigned_to,'Kiriman baru','Kamu ditugaskan mengantar kiriman.','/operations/shipments/'||new.id,'shipment-new:'||new.id);
   elsif tg_op='UPDATE' and new.status='in_transit' and old.status is distinct from new.status then
     insert into public.notifications(user_id,title,body,route,event_key)
     select m.user_id,'Kiriman menuju lembagamu','Kiriman sudah berangkat. Siapkan penerimaan.','/operations/shipments/'||new.id,'shipment-arrival:'||new.id||':'||m.user_id
     from public.organization_members m join public.collection_points p on p.organization_id=m.organization_id
     where p.id=new.destination_point_id and m.active on conflict(event_key) do nothing;
   end if;
 elsif tg_table_name in ('role_requests','organization_applications') then
   prefix:=case when tg_table_name='role_requests' then 'volunteer' else 'organization' end;
   recipient:=case when tg_table_name='role_requests' then (to_jsonb(new)->>'user_id')::uuid else (to_jsonb(new)->>'applicant_id')::uuid end;
   if new.status='pending' and (tg_op='INSERT' or old.status is distinct from new.status) then
     insert into public.notifications(user_id,title,body,route,event_key)
     select r.user_id,'Pengajuan baru','Ada pengajuan '||case when prefix='volunteer' then 'relawan' else 'lembaga' end||' untuk ditinjau.',
     '/operations/registrations/'||prefix||'/'||new.id,'application-pending:'||prefix||':'||new.id||':'||r.user_id||':'||gen_random_uuid()
     from public.user_roles r where r.role='admin';
   elsif tg_op='UPDATE' and new.status in ('approved','rejected') and old.status is distinct from new.status then
     insert into public.notifications(user_id,title,body,route,event_key)
     values(recipient,'Hasil pengajuanmu',case when new.status='approved' then 'Pengajuan disetujui. Akses akunmu sudah diperbarui.' else 'Pengajuan perlu diperbaiki: '||coalesce(new.review_reason,'') end,
     '/join','application-result:'||prefix||':'||new.id||':'||gen_random_uuid());
   end if;
 end if;
 return new;
end $$;
revoke all on function private.notify_core_events() from public,anon,authenticated;
create trigger notify_donation_events after insert on public.donation_events for each row execute function private.notify_core_events();
create trigger notify_assigned_tasks after insert or update on public.logistics_tasks for each row execute function private.notify_core_events();
create trigger notify_shipments after insert or update on public.shipments for each row execute function private.notify_core_events();
create trigger notify_role_applications after insert or update on public.role_requests for each row execute function private.notify_core_events();
create trigger notify_org_applications after insert or update on public.organization_applications for each row execute function private.notify_core_events();

do $$ declare t text; begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') then
   foreach t in array array['notifications','role_requests','organization_applications','donations','donation_events','logistics_tasks','shipments','needs','inventory_batches','user_roles','organization_members','collection_points','profiles','organizations'] loop
     if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
       execute format('alter publication supabase_realtime add table public.%I',t);
     end if;
   end loop;
 end if;
end $$;
