
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
create type public.app_role as enum ('donatur','relawan','mitra','admin');
create table public.profiles(id uuid primary key references auth.users(id) on delete cascade, display_name text not null default '' check(length(display_name)<=100), avatar_path text, area text, created_at timestamptz not null default now());
create table public.user_roles(user_id uuid references public.profiles(id) on delete cascade, role public.app_role not null, granted_by uuid references public.profiles(id), granted_at timestamptz not null default now(), primary key(user_id,role));
create table public.organizations(id uuid primary key default gen_random_uuid(), name text not null, kind text not null check(kind in ('social_institution','disaster_post','recycling_partner')), area text, verified boolean not null default false, active boolean not null default true, created_at timestamptz not null default now());
create table public.organization_members(organization_id uuid references public.organizations(id), user_id uuid references public.profiles(id), active boolean not null default true, primary key(organization_id,user_id));
create table public.collection_points(id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), name text not null, public_address text not null, latitude double precision check(latitude between -90 and 90), longitude double precision check(longitude between -180 and 180), opening_hours text, capacity_pieces integer check(capacity_pieces>=0), active boolean not null default true);
create table public.incidents(id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), title text not null, area text, status text not null default 'requested' check(status in ('requested','active','closed','rejected')), starts_at timestamptz not null, ends_at timestamptz not null, approved_by uuid references public.profiles(id), check(ends_at>starts_at), check(status<>'active' or approved_by is not null));
create table public.needs(id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id), point_id uuid not null references public.collection_points(id), incident_id uuid references public.incidents(id), title text not null, description text, deadline_at timestamptz not null, status text not null default 'draft' check(status in ('draft','open','paused','closed','fulfilled')), created_at timestamptz not null default now());
create table public.need_items(id uuid primary key default gen_random_uuid(), need_id uuid not null references public.needs(id), category text not null, size_code text not null, age_group text not null, requested_qty integer not null check(requested_qty>0));
create table public.donations(id uuid primary key default gen_random_uuid(), donor_id uuid not null default auth.uid() references public.profiles(id), tracking_code text not null unique default ('PK-'||upper(replace(gen_random_uuid()::text,'-',''))), point_id uuid references public.collection_points(id), preferred_need_id uuid references public.needs(id), method text not null default 'dropoff' check(method in ('dropoff','pickup')), status text not null default 'draft' check(status in ('draft','submitted','needs_revision','scheduled','received','curated','cancelled')), clean_check boolean not null default false, intact_check boolean not null default false, not_torn_check boolean not null default false, scheduled_at timestamptz, created_at timestamptz not null default now());
create table private.donation_contacts(donation_id uuid primary key references public.donations(id) on delete cascade, address text, contact_name text, phone text);
create table public.donation_items(id uuid primary key default gen_random_uuid(), donation_id uuid not null references public.donations(id) on delete cascade, category text not null, size_code text not null, age_group text not null, quantity integer not null check(quantity>0));
create table public.donation_photos(id uuid primary key default gen_random_uuid(), donation_id uuid not null references public.donations(id) on delete cascade, storage_path text not null unique, created_at timestamptz not null default now());
create table public.logistics_tasks(id uuid primary key default gen_random_uuid(), donation_id uuid references public.donations(id), point_id uuid not null references public.collection_points(id), assigned_to uuid references public.profiles(id), kind text not null check(kind in ('pickup','curation','delivery')), status text not null default 'assigned' check(status in ('assigned','accepted','in_progress','completed','declined','cancelled','failed')), scheduled_at timestamptz, notes text, created_at timestamptz not null default now());
create table public.inspections(id uuid primary key default gen_random_uuid(), item_id uuid not null unique references public.donation_items(id), point_id uuid not null references public.collection_points(id), inspector_id uuid not null references public.profiles(id), passed_qty integer not null check(passed_qty>=0), rejected_qty integer not null check(rejected_qty>=0), rejection_reason text, created_at timestamptz not null default now(), check(rejected_qty=0 or length(trim(rejection_reason))>0));
create table public.inventory_batches(id uuid primary key default gen_random_uuid(), inspection_id uuid not null unique references public.inspections(id), point_id uuid not null references public.collection_points(id), category text not null, size_code text not null, age_group text not null, initial_qty integer not null check(initial_qty>0), on_hand_qty integer not null check(on_hand_qty>=0), reserved_qty integer not null default 0 check(reserved_qty>=0), check(reserved_qty<=on_hand_qty), check(on_hand_qty<=initial_qty));
create table public.allocations(id uuid primary key default gen_random_uuid(), batch_id uuid not null references public.inventory_batches(id), need_item_id uuid not null references public.need_items(id), quantity integer not null check(quantity>0), status text not null default 'reserved' check(status in ('reserved','dispatched','received','disputed','cancelled')), request_key uuid not null, created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(), unique(created_by,request_key));
create table public.shipments(id uuid primary key default gen_random_uuid(), source_point_id uuid not null references public.collection_points(id), destination_point_id uuid not null references public.collection_points(id), assigned_to uuid references public.profiles(id), status text not null default 'ready' check(status in ('ready','in_transit','received','disputed','cancelled')), received_by uuid references public.profiles(id), dispatched_at timestamptz, received_at timestamptz, created_at timestamptz not null default now(), check(source_point_id<>destination_point_id));
create table public.shipment_items(id uuid primary key default gen_random_uuid(), shipment_id uuid not null references public.shipments(id), allocation_id uuid not null unique references public.allocations(id), quantity integer not null check(quantity>0), received_good integer, rejected integer, missing integer, check((received_good is null and rejected is null and missing is null) or (received_good>=0 and rejected>=0 and missing>=0 and received_good+rejected+missing=quantity)));
create table public.donation_events(id bigint generated always as identity primary key, donation_id uuid not null references public.donations(id), event_type text not null, summary text not null, actor_id uuid references public.profiles(id), created_at timestamptz not null default now());
create table public.notifications(id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, title text not null, body text not null, read_at timestamptz, created_at timestamptz not null default now());
create table public.recycling_referrals(id uuid primary key default gen_random_uuid(), inspection_id uuid not null unique references public.inspections(id), quantity integer not null check(quantity>0), partner_id uuid references public.organizations(id), status text not null default 'awaiting_partner' check(status in ('awaiting_partner','handed_over','processing_confirmed')), evidence_path text);
create table private.audit_logs(id bigint generated always as identity primary key, actor_id uuid, action text not null, entity_id uuid, details jsonb not null default '{}', created_at timestamptz not null default now());

create function private.has_role(p_role public.app_role) returns boolean language sql stable security definer set search_path='' as $$select auth.uid() is not null and exists(select 1 from public.user_roles where user_id=auth.uid() and role=p_role)$$;
create function private.is_admin() returns boolean language sql stable security definer set search_path='' as $$select private.has_role('admin')$$;
create function private.org_access(p_org uuid) returns boolean language sql stable security definer set search_path='' as $$select auth.uid() is not null and (private.is_admin() or (private.has_role('mitra') and exists(select 1 from public.organization_members m join public.organizations o on o.id=m.organization_id where m.organization_id=p_org and m.user_id=auth.uid() and m.active and o.active and o.verified)))$$;
create function private.point_access(p_point uuid) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.collection_points p where p.id=p_point and private.org_access(p.organization_id))$$;
create function private.donation_access(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$select auth.uid() is not null and exists(select 1 from public.donations d where d.id=p_id and (d.donor_id=auth.uid() or private.is_admin() or private.point_access(d.point_id) or (private.has_role('relawan') and exists(select 1 from public.logistics_tasks t where t.donation_id=d.id and t.assigned_to=auth.uid() and t.status in ('assigned','accepted','in_progress')))))$$;
create function private.owns_draft(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$select auth.uid() is not null and exists(select 1 from public.donations where id=p_id and donor_id=auth.uid() and status in ('draft','needs_revision'))$$;
create function private.batch_access(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.inventory_batches b where b.id=p_id and private.point_access(b.point_id))$$;
create function private.need_access(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.needs n where n.id=p_id and private.org_access(n.organization_id))$$;
create function private.shipment_access(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$select auth.uid() is not null and exists(select 1 from public.shipments s where s.id=p_id and (private.point_access(s.source_point_id) or private.point_access(s.destination_point_id) or (s.assigned_to=auth.uid() and private.has_role('relawan'))))$$;

create function private.on_signup() returns trigger language plpgsql security definer set search_path='' as $$begin
insert into public.profiles(id,display_name) values(new.id,left(coalesce(new.raw_user_meta_data->>'display_name',''),100));
insert into public.user_roles(user_id,role) values(new.id,'donatur'); return new; end$$;
create trigger pk_on_signup after insert on auth.users for each row execute function private.on_signup();

create function private.set_role(p_user uuid,p_role public.app_role,p_grant boolean) returns void language plpgsql security definer set search_path='' as $$begin
if not private.is_admin() then raise exception 'FORBIDDEN' using errcode='42501'; end if;
perform pg_advisory_xact_lock(819901);
if not p_grant and p_role='admin' and (select count(*) from public.user_roles where role='admin')<=1 then raise exception 'Cannot remove last admin'; end if;
if p_grant then insert into public.user_roles(user_id,role,granted_by) values(p_user,p_role,auth.uid()) on conflict do nothing;
else delete from public.user_roles where user_id=p_user and role=p_role; end if;
insert into private.audit_logs(actor_id,action,entity_id,details) values(auth.uid(),'set_role',p_user,jsonb_build_object('role',p_role,'grant',p_grant));end$$;
create function public.admin_set_role(p_user uuid,p_role public.app_role,p_grant boolean) returns void language sql security invoker set search_path='' as $$select private.set_role(p_user,p_role,p_grant)$$;
create function public.my_access() returns jsonb language sql stable security invoker set search_path='' as $$select jsonb_build_object('roles',coalesce((select jsonb_agg(role) from public.user_roles where user_id=auth.uid()),'[]'::jsonb),'ui',case when private.is_admin() then 'admin' else 'user' end)$$;

create function private.submit_donation(p_id uuid) returns void language plpgsql security definer set search_path='' as $$declare d public.donations;begin
select * into d from public.donations where id=p_id for update;
if auth.uid() is null or d.donor_id is distinct from auth.uid() then raise exception 'FORBIDDEN' using errcode='42501';end if;
if d.status='submitted' then return;end if;
if d.status not in ('draft','needs_revision') or d.point_id is null or not(d.clean_check and d.intact_check and d.not_torn_check) then raise exception 'Incomplete donation';end if;
if not exists(select 1 from public.collection_points p join public.organizations o on o.id=p.organization_id where p.id=d.point_id and p.active and o.active and o.verified) then raise exception 'Point unavailable';end if;
if not exists(select 1 from public.donation_items where donation_id=p_id) then raise exception 'No items';end if;
if (select count(*) from public.donation_photos where donation_id=p_id) not between 1 and 5 then raise exception 'Need 1-5 photos';end if;
if exists(select 1 from public.donation_photos p where p.donation_id=p_id and not exists(select 1 from storage.objects o where o.bucket_id='donation-photos' and o.name=p.storage_path)) then raise exception 'Photo object missing';end if;
update public.donations set status='submitted' where id=p_id;
insert into public.donation_events(donation_id,event_type,summary,actor_id) values(p_id,'submitted','Donasi diajukan',auth.uid());end$$;
create function public.submit_donation(p_id uuid) returns void language sql security invoker set search_path='' as $$select private.submit_donation(p_id)$$;

create function private.curate(p_item uuid,p_passed integer,p_rejected integer,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$declare i public.donation_items; d public.donations; v uuid; b uuid;begin
select * into i from public.donation_items where id=p_item for update;select * into d from public.donations where id=i.donation_id;
if not(private.is_admin() or (private.has_role('relawan') and exists(select 1 from public.logistics_tasks t where t.donation_id=d.id and t.point_id=d.point_id and t.assigned_to=auth.uid() and t.kind='curation' and t.status in ('accepted','in_progress')))) then raise exception 'FORBIDDEN' using errcode='42501';end if;
if d.status not in ('received','curated') then raise exception 'Record physical arrival first';end if;
if p_passed is null or p_rejected is null or p_passed<0 or p_rejected<0 or p_passed+p_rejected<>i.quantity then raise exception 'Invalid quantities';end if;
select id into v from public.inspections where item_id=p_item;
if v is not null then raise exception 'Item already inspected';end if;
insert into public.inspections(item_id,point_id,inspector_id,passed_qty,rejected_qty,rejection_reason) values(p_item,d.point_id,auth.uid(),p_passed,p_rejected,p_reason) returning id into v;
if p_passed>0 then insert into public.inventory_batches(inspection_id,point_id,category,size_code,age_group,initial_qty,on_hand_qty) values(v,d.point_id,i.category,i.size_code,i.age_group,p_passed,p_passed) returning id into b;end if;
if p_rejected>0 then insert into public.recycling_referrals(inspection_id,quantity) values(v,p_rejected);end if;
if not exists(select 1 from public.donation_items di where di.donation_id=d.id and not exists(select 1 from public.inspections x where x.item_id=di.id)) then update public.donations set status='curated' where id=d.id;end if;
insert into public.donation_events(donation_id,event_type,summary,actor_id) values(d.id,'curated',format('%s layak, %s tidak layak',p_passed,p_rejected),auth.uid());return b;end$$;
create function public.record_inspection(p_item uuid,p_passed integer,p_rejected integer,p_reason text default null) returns uuid language sql security invoker set search_path='' as $$select private.curate(p_item,p_passed,p_rejected,p_reason)$$;

create function private.reserve(p_batch uuid,p_need_item uuid,p_qty integer,p_key uuid) returns uuid language plpgsql security definer set search_path='' as $$declare b public.inventory_batches; ni public.need_items;n public.needs; a public.allocations;used_qty bigint;v uuid;begin
if auth.uid() is null then raise exception 'FORBIDDEN' using errcode='42501';end if;
perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text||p_key::text,0));
select * into a from public.allocations where created_by=auth.uid() and request_key=p_key;
if a.id is not null then if a.batch_id<>p_batch or a.need_item_id<>p_need_item or a.quantity<>p_qty then raise exception 'Idempotency conflict';end if;return a.id;end if;
select * into ni from public.need_items where id=p_need_item for update;select * into b from public.inventory_batches where id=p_batch for update;
if not private.point_access(b.point_id) then raise exception 'FORBIDDEN' using errcode='42501';end if;
select * into n from public.needs where id=ni.need_id;
if n.id is null or n.status<>'open' or n.deadline_at<=now() then raise exception 'Need unavailable';end if;
if not exists(select 1 from public.organizations where id=n.organization_id and verified and active) then raise exception 'Recipient unavailable';end if;
if b.category<>ni.category or b.size_code<>ni.size_code or b.age_group<>ni.age_group then raise exception 'Variant mismatch';end if;
select coalesce(sum(quantity),0) into used_qty from public.allocations where need_item_id=p_need_item and status<>'cancelled';
if p_qty is null or p_qty<=0 or b.on_hand_qty-b.reserved_qty<p_qty or ni.requested_qty-used_qty<p_qty then raise exception 'Insufficient stock or need';end if;
update public.inventory_batches set reserved_qty=reserved_qty+p_qty where id=p_batch;
insert into public.allocations(batch_id,need_item_id,quantity,request_key,created_by) values(p_batch,p_need_item,p_qty,p_key,auth.uid()) returning id into v;
insert into private.audit_logs(actor_id,action,entity_id,details) values(auth.uid(),'reserve',v,jsonb_build_object('quantity',p_qty));return v;end$$;
create function public.reserve_allocation(p_batch uuid,p_need_item uuid,p_qty integer,p_key uuid) returns uuid language sql security invoker set search_path='' as $$select private.reserve(p_batch,p_need_item,p_qty,p_key)$$;

create function public.mark_notification_read(p_id uuid) returns void language sql security invoker set search_path='' as $$update public.notifications set read_at=coalesce(read_at,now()) where id=p_id and user_id=auth.uid()$$;

alter table public.profiles enable row level security;
revoke all on public.profiles from anon,authenticated;
grant select on public.profiles to authenticated;
create policy read_scoped on public.profiles for select to authenticated using (id=(select auth.uid()) or (select private.is_admin()));

alter table public.user_roles enable row level security;
revoke all on public.user_roles from anon,authenticated;
grant select on public.user_roles to authenticated;
create policy read_scoped on public.user_roles for select to authenticated using (user_id=(select auth.uid()) or (select private.is_admin()));

alter table public.organizations enable row level security;
revoke all on public.organizations from anon,authenticated;
grant select on public.organizations to authenticated;
create policy read_scoped on public.organizations for select to authenticated using ((verified and active) or private.org_access(id) or (select private.is_admin()));
grant insert,update,delete on public.organizations to authenticated;create policy admin_manage on public.organizations for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

alter table public.organization_members enable row level security;
revoke all on public.organization_members from anon,authenticated;
grant select on public.organization_members to authenticated;
create policy read_scoped on public.organization_members for select to authenticated using (user_id=(select auth.uid()) or private.org_access(organization_id));
grant insert,update,delete on public.organization_members to authenticated;create policy admin_manage on public.organization_members for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

alter table public.collection_points enable row level security;
revoke all on public.collection_points from anon,authenticated;
grant select on public.collection_points to authenticated;
create policy read_scoped on public.collection_points for select to authenticated using (active or private.org_access(organization_id));
grant insert,update,delete on public.collection_points to authenticated;create policy admin_manage on public.collection_points for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

alter table public.incidents enable row level security;
revoke all on public.incidents from anon,authenticated;
grant select on public.incidents to authenticated;
create policy read_scoped on public.incidents for select to authenticated using ((status='active' and starts_at<=now() and ends_at>now()) or private.org_access(organization_id));
grant insert,update,delete on public.incidents to authenticated;create policy admin_manage on public.incidents for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

alter table public.needs enable row level security;
revoke all on public.needs from anon,authenticated;
grant select on public.needs to authenticated;
create policy read_scoped on public.needs for select to authenticated using ((status='open' and exists(select 1 from public.organizations o where o.id=organization_id and o.verified and o.active)) or private.org_access(organization_id));
grant insert,update,delete on public.needs to authenticated;create policy admin_manage on public.needs for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

alter table public.need_items enable row level security;
revoke all on public.need_items from anon,authenticated;
grant select on public.need_items to authenticated;
create policy read_scoped on public.need_items for select to authenticated using (exists(select 1 from public.needs n where n.id=need_id));
grant insert,update,delete on public.need_items to authenticated;create policy admin_manage on public.need_items for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

alter table public.donations enable row level security;
revoke all on public.donations from anon,authenticated;
grant select on public.donations to authenticated;
create policy read_scoped on public.donations for select to authenticated using (private.donation_access(id));

alter table public.donation_items enable row level security;
revoke all on public.donation_items from anon,authenticated;
grant select on public.donation_items to authenticated;
create policy read_scoped on public.donation_items for select to authenticated using (private.donation_access(donation_id));

alter table public.donation_photos enable row level security;
revoke all on public.donation_photos from anon,authenticated;
grant select on public.donation_photos to authenticated;
create policy read_scoped on public.donation_photos for select to authenticated using (private.donation_access(donation_id));

alter table public.logistics_tasks enable row level security;
revoke all on public.logistics_tasks from anon,authenticated;
grant select on public.logistics_tasks to authenticated;
create policy read_scoped on public.logistics_tasks for select to authenticated using (private.point_access(point_id) or (assigned_to=(select auth.uid()) and private.has_role('relawan')));
grant insert,update,delete on public.logistics_tasks to authenticated;create policy admin_manage on public.logistics_tasks for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

alter table public.inspections enable row level security;
revoke all on public.inspections from anon,authenticated;
grant select on public.inspections to authenticated;
create policy read_scoped on public.inspections for select to authenticated using (exists(select 1 from public.donation_items i where i.id=item_id and private.donation_access(i.donation_id)));

alter table public.inventory_batches enable row level security;
revoke all on public.inventory_batches from anon,authenticated;
grant select on public.inventory_batches to authenticated;
create policy read_scoped on public.inventory_batches for select to authenticated using (private.point_access(point_id));

alter table public.allocations enable row level security;
revoke all on public.allocations from anon,authenticated;
grant select on public.allocations to authenticated;
create policy read_scoped on public.allocations for select to authenticated using (private.batch_access(batch_id) or exists(select 1 from public.need_items ni where ni.id=need_item_id and private.need_access(ni.need_id)));

alter table public.shipments enable row level security;
revoke all on public.shipments from anon,authenticated;
grant select on public.shipments to authenticated;
create policy read_scoped on public.shipments for select to authenticated using (private.shipment_access(id));

alter table public.shipment_items enable row level security;
revoke all on public.shipment_items from anon,authenticated;
grant select on public.shipment_items to authenticated;
create policy read_scoped on public.shipment_items for select to authenticated using (private.shipment_access(shipment_id));

alter table public.donation_events enable row level security;
revoke all on public.donation_events from anon,authenticated;
grant select on public.donation_events to authenticated;
create policy read_scoped on public.donation_events for select to authenticated using (private.donation_access(donation_id));

alter table public.notifications enable row level security;
revoke all on public.notifications from anon,authenticated;
grant select on public.notifications to authenticated;
create policy read_scoped on public.notifications for select to authenticated using (user_id=(select auth.uid()));

alter table public.recycling_referrals enable row level security;
revoke all on public.recycling_referrals from anon,authenticated;
grant select on public.recycling_referrals to authenticated;
create policy read_scoped on public.recycling_referrals for select to authenticated using (exists(select 1 from public.inspections i join public.donation_items di on di.id=i.item_id where i.id=inspection_id and private.donation_access(di.donation_id)));
grant insert,update,delete on public.recycling_referrals to authenticated;create policy admin_manage on public.recycling_referrals for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy mitra_insert on public.needs for insert to authenticated with check (private.org_access(organization_id));
create policy mitra_update on public.needs for update to authenticated using (private.org_access(organization_id)) with check (private.org_access(organization_id));
create policy mitra_insert on public.need_items for insert to authenticated with check (private.need_access(need_id));
create policy mitra_update on public.need_items for update to authenticated using (private.need_access(need_id)) with check (private.need_access(need_id));

grant update(display_name,avatar_path,area) on public.profiles to authenticated;
create policy self_profile on public.profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
grant insert,delete on public.donations to authenticated;
grant update(point_id,preferred_need_id,method,clean_check,intact_check,not_torn_check,scheduled_at) on public.donations to authenticated;
create policy create_own_draft on public.donations for insert to authenticated with check(donor_id=(select auth.uid()) and status='draft' and private.has_role('donatur'));
create policy edit_own_draft on public.donations for update to authenticated using(private.owns_draft(id)) with check(private.owns_draft(id));
create policy delete_own_draft on public.donations for delete to authenticated using(private.owns_draft(id));
grant insert,update,delete on public.donation_items,public.donation_photos to authenticated;
create policy own_items on public.donation_items for all to authenticated using(private.owns_draft(donation_id)) with check(private.owns_draft(donation_id));
create policy own_photos on public.donation_photos for all to authenticated using(private.owns_draft(donation_id)) with check(private.owns_draft(donation_id) and split_part(storage_path,'/',1)=(select auth.uid())::text and split_part(storage_path,'/',2)=donation_id::text);
grant update(read_at) on public.notifications to authenticated;
create policy read_notification on public.notifications for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
alter table private.donation_contacts enable row level security;
alter table private.audit_logs enable row level security;
revoke all on private.donation_contacts,private.audit_logs from public,anon,authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('donation-photos','donation-photos',false,1048576,array['image/jpeg','image/png','image/webp']) on conflict(id) do nothing;
create policy pk_photo_read on storage.objects for select to authenticated using(bucket_id='donation-photos' and exists(select 1 from public.donation_photos p where p.storage_path=name and private.donation_access(p.donation_id)));
create policy pk_photo_insert on storage.objects for insert to authenticated with check(bucket_id='donation-photos' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.donations d where d.id::text=(storage.foldername(name))[2] and private.owns_draft(d.id)));
create policy pk_photo_delete on storage.objects for delete to authenticated using(bucket_id='donation-photos' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.donations d where d.id::text=(storage.foldername(name))[2] and private.owns_draft(d.id)));

revoke execute on all functions in schema private from public,anon,authenticated;
grant execute on function private.has_role(public.app_role),private.is_admin(),private.org_access(uuid),private.point_access(uuid),private.donation_access(uuid),private.owns_draft(uuid),private.batch_access(uuid),private.need_access(uuid),private.shipment_access(uuid),private.set_role(uuid,public.app_role,boolean),private.submit_donation(uuid),private.curate(uuid,integer,integer,text),private.reserve(uuid,uuid,integer,uuid) to authenticated;
revoke execute on function public.admin_set_role(uuid,public.app_role,boolean),public.my_access(),public.submit_donation(uuid),public.record_inspection(uuid,integer,integer,text),public.reserve_allocation(uuid,uuid,integer,uuid),public.mark_notification_read(uuid) from public,anon;
grant execute on function public.admin_set_role(uuid,public.app_role,boolean),public.my_access(),public.submit_donation(uuid),public.record_inspection(uuid,integer,integer,text),public.reserve_allocation(uuid,uuid,integer,uuid),public.mark_notification_read(uuid) to authenticated;

create index idx_user_roles_granted_by on public.user_roles(granted_by);
create index idx_organization_members_user_id on public.organization_members(user_id);
create index idx_collection_points_organization_id on public.collection_points(organization_id);
create index idx_incidents_organization_id on public.incidents(organization_id);
create index idx_incidents_approved_by on public.incidents(approved_by);
create index idx_needs_organization_id on public.needs(organization_id);
create index idx_needs_point_id on public.needs(point_id);
create index idx_needs_incident_id on public.needs(incident_id);
create index idx_need_items_need_id on public.need_items(need_id);
create index idx_donations_donor_id on public.donations(donor_id);
create index idx_donations_point_id on public.donations(point_id);
create index idx_donations_preferred_need_id on public.donations(preferred_need_id);
create index idx_donation_items_donation_id on public.donation_items(donation_id);
create index idx_donation_photos_donation_id on public.donation_photos(donation_id);
create index idx_logistics_tasks_donation_id on public.logistics_tasks(donation_id);
create index idx_logistics_tasks_point_id on public.logistics_tasks(point_id);
create index idx_logistics_tasks_assigned_to on public.logistics_tasks(assigned_to);
create index idx_inspections_point_id on public.inspections(point_id);
create index idx_inspections_inspector_id on public.inspections(inspector_id);
create index idx_inventory_batches_point_id on public.inventory_batches(point_id);
create index idx_allocations_batch_id on public.allocations(batch_id);
create index idx_allocations_need_item_id on public.allocations(need_item_id);
create index idx_shipments_source_point_id on public.shipments(source_point_id);
create index idx_shipments_destination_point_id on public.shipments(destination_point_id);
create index idx_shipments_assigned_to on public.shipments(assigned_to);
create index idx_shipments_received_by on public.shipments(received_by);
create index idx_shipment_items_shipment_id on public.shipment_items(shipment_id);
create index idx_donation_events_donation_id on public.donation_events(donation_id);
create index idx_donation_events_actor_id on public.donation_events(actor_id);
create index idx_notifications_user_id on public.notifications(user_id);
create index idx_recycling_referrals_partner_id on public.recycling_referrals(partner_id);
create index idx_needs_status_deadline on public.needs(status,deadline_at);


-- Integrity guards apply even to admin UI operations.
create function private.guard_need() returns trigger language plpgsql security definer set search_path='' as $$begin
if not exists(select 1 from public.collection_points p where p.id=new.point_id and p.organization_id=new.organization_id) then raise exception 'Point must belong to organization';end if;
if new.incident_id is not null and not exists(select 1 from public.incidents i where i.id=new.incident_id and i.organization_id=new.organization_id) then raise exception 'Incident belongs to another organization';end if;
if tg_op='UPDATE' and exists(select 1 from public.need_items ni join public.allocations a on a.need_item_id=ni.id where ni.need_id=old.id) and (new.organization_id<>old.organization_id or new.point_id<>old.point_id) then raise exception 'Cannot move allocated need';end if;
return new;end$$;
create trigger guard_need before insert or update on public.needs for each row execute function private.guard_need();
create function private.guard_need_item() returns trigger language plpgsql security definer set search_path='' as $$declare used bigint;begin
if tg_op='UPDATE' then
 select coalesce(sum(quantity),0) into used from public.allocations where need_item_id=old.id and status<>'cancelled';
 if new.requested_qty<used or (used>0 and (new.need_id<>old.need_id or new.category<>old.category or new.size_code<>old.size_code or new.age_group<>old.age_group)) then raise exception 'Allocated need item cannot change variant or shrink below commitments';end if;
end if;return new;end$$;
create trigger guard_need_item before update on public.need_items for each row execute function private.guard_need_item();
alter table public.inspections add constraint rejection_reason_required check(rejected_qty=0 or coalesce(length(trim(rejection_reason)),0)>0);
alter table public.shipment_items add constraint receipt_complete check((received_good is null and rejected is null and missing is null) or (received_good is not null and rejected is not null and missing is not null and received_good>=0 and rejected>=0 and missing>=0 and received_good+rejected+missing=quantity));

create function private.advance_donation(p_id uuid,p_status text) returns void language plpgsql security definer set search_path='' as $$declare d public.donations;begin
select * into d from public.donations where id=p_id for update;
if not private.point_access(d.point_id) then raise exception 'FORBIDDEN' using errcode='42501';end if;
if not ((d.status='submitted' and p_status in ('needs_revision','scheduled','received')) or (d.status='scheduled' and p_status='received')) then raise exception 'Invalid status transition';end if;
update public.donations set status=p_status where id=p_id;
insert into public.donation_events(donation_id,event_type,summary,actor_id) values(p_id,p_status,'Status donasi: '||p_status,auth.uid());
end$$;
create function public.advance_donation(p_id uuid,p_status text) returns void language sql security invoker set search_path='' as $$select private.advance_donation(p_id,p_status)$$;

create function private.task_response(p_id uuid,p_status text) returns void language plpgsql security definer set search_path='' as $$declare t public.logistics_tasks;begin
select * into t from public.logistics_tasks where id=p_id for update;
if auth.uid() is null or t.assigned_to is distinct from auth.uid() or not private.has_role('relawan') then raise exception 'FORBIDDEN' using errcode='42501';end if;
if not ((t.status='assigned' and p_status in ('accepted','declined')) or (t.status='accepted' and p_status='in_progress') or (t.status='in_progress' and p_status in ('completed','failed'))) then raise exception 'Invalid task transition';end if;
update public.logistics_tasks set status=p_status where id=p_id;
end$$;
create function public.respond_task(p_id uuid,p_status text) returns void language sql security invoker set search_path='' as $$select private.task_response(p_id,p_status)$$;

-- MVP: one allocation per shipment; create once, dispatch once, one final receipt.
create function private.make_shipment(p_allocation uuid,p_volunteer uuid) returns uuid language plpgsql security definer set search_path='' as $$declare a public.allocations;b public.inventory_batches;n public.needs;v uuid;begin
select * into a from public.allocations where id=p_allocation for update;
select s.shipment_id into v from public.shipment_items s where allocation_id=p_allocation;if v is not null then
 if not private.shipment_access(v) then raise exception 'FORBIDDEN' using errcode='42501';end if;return v;end if;
select * into b from public.inventory_batches where id=a.batch_id;
if not private.point_access(b.point_id) then raise exception 'FORBIDDEN' using errcode='42501';end if;
if a.status<>'reserved' then raise exception 'Allocation not reserved';end if;
if not exists(select 1 from public.user_roles where user_id=p_volunteer and role='relawan') then raise exception 'Volunteer not verified';end if;
select nn.* into n from public.needs nn join public.need_items ni on ni.need_id=nn.id where ni.id=a.need_item_id;
insert into public.shipments(source_point_id,destination_point_id,assigned_to) values(b.point_id,n.point_id,p_volunteer) returning id into v;
insert into public.shipment_items(shipment_id,allocation_id,quantity) values(v,p_allocation,a.quantity);return v;end$$;
create function public.create_shipment(p_allocation uuid,p_volunteer uuid) returns uuid language sql security invoker set search_path='' as $$select private.make_shipment(p_allocation,p_volunteer)$$;

create function private.dispatch(p_id uuid) returns void language plpgsql security definer set search_path='' as $$declare s public.shipments;si public.shipment_items;a public.allocations;begin
select * into s from public.shipments where id=p_id for update;
if not (private.point_access(s.source_point_id) or (private.has_role('relawan') and s.assigned_to=auth.uid())) then raise exception 'FORBIDDEN' using errcode='42501';end if;
if s.status='in_transit' then return;end if;if s.status<>'ready' then raise exception 'Shipment not ready';end if;
select * into si from public.shipment_items where shipment_id=p_id;
select * into a from public.allocations where id=si.allocation_id for update;
if a.status<>'reserved' or a.quantity<>si.quantity then raise exception 'Invalid allocation';end if;
update public.inventory_batches set on_hand_qty=on_hand_qty-a.quantity,reserved_qty=reserved_qty-a.quantity where id=a.batch_id;
update public.allocations set status='dispatched' where id=a.id;
update public.shipments set status='in_transit',dispatched_at=now() where id=p_id;
end$$;
create function public.dispatch_shipment(p_id uuid) returns void language sql security invoker set search_path='' as $$select private.dispatch(p_id)$$;

create function private.receive(p_id uuid,p_good integer,p_rejected integer,p_missing integer) returns void language plpgsql security definer set search_path='' as $$declare s public.shipments;si public.shipment_items;did uuid;begin
select * into s from public.shipments where id=p_id for update;
if not private.point_access(s.destination_point_id) then raise exception 'FORBIDDEN' using errcode='42501';end if;
select * into si from public.shipment_items where shipment_id=p_id;
if s.status in ('received','disputed') then
 if si.received_good=p_good and si.rejected=p_rejected and si.missing=p_missing then return;end if;raise exception 'Receipt already final';end if;
if s.status<>'in_transit' or p_good is null or p_rejected is null or p_missing is null or least(p_good,p_rejected,p_missing)<0 or p_good+p_rejected+p_missing<>si.quantity then raise exception 'Invalid receipt';end if;
update public.shipment_items set received_good=p_good,rejected=p_rejected,missing=p_missing where id=si.id;
update public.allocations set status=case when p_rejected+p_missing>0 then 'disputed' else 'received' end where id=si.allocation_id;
update public.shipments set status=case when p_rejected+p_missing>0 then 'disputed' else 'received' end,received_by=auth.uid(),received_at=now() where id=p_id;
select di.donation_id into did from public.allocations a join public.inventory_batches b on b.id=a.batch_id join public.inspections i on i.id=b.inspection_id join public.donation_items di on di.id=i.item_id where a.id=si.allocation_id;
insert into public.donation_events(donation_id,event_type,summary,actor_id) values(did,'receipt',format('%s potong diterima baik; %s ditolak; %s kurang',p_good,p_rejected,p_missing),auth.uid());end$$;
create function public.confirm_receipt(p_id uuid,p_good integer,p_rejected integer,p_missing integer) returns void language sql security invoker set search_path='' as $$select private.receive(p_id,p_good,p_rejected,p_missing)$$;

create function private.save_contact(p_id uuid,p_address text,p_name text,p_phone text) returns void language plpgsql security definer set search_path='' as $$begin
if not private.owns_draft(p_id) then raise exception 'FORBIDDEN' using errcode='42501';end if;
insert into private.donation_contacts(donation_id,address,contact_name,phone) values(p_id,p_address,p_name,p_phone) on conflict(donation_id) do update set address=excluded.address,contact_name=excluded.contact_name,phone=excluded.phone;end$$;
create function public.save_donation_contact(p_id uuid,p_address text,p_name text,p_phone text) returns void language sql security invoker set search_path='' as $$select private.save_contact(p_id,p_address,p_name,p_phone)$$;
create function private.contact(p_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$begin
if not (private.is_admin() or exists(select 1 from public.donations where id=p_id and donor_id=auth.uid()) or (private.has_role('relawan') and exists(select 1 from public.logistics_tasks where donation_id=p_id and assigned_to=auth.uid() and status in ('accepted','in_progress')))) then raise exception 'FORBIDDEN' using errcode='42501';end if;
return (select jsonb_build_object('address',address,'contact_name',contact_name,'phone',phone) from private.donation_contacts where donation_id=p_id);end$$;
create function public.get_donation_contact(p_id uuid) returns jsonb language sql stable security invoker set search_path='' as $$select private.contact(p_id)$$;

revoke execute on function private.guard_need(),private.guard_need_item(),private.advance_donation(uuid,text),private.task_response(uuid,text),private.make_shipment(uuid,uuid),private.dispatch(uuid),private.receive(uuid,integer,integer,integer),private.save_contact(uuid,text,text,text),private.contact(uuid) from public,anon,authenticated;
grant execute on function private.advance_donation(uuid,text),private.task_response(uuid,text),private.make_shipment(uuid,uuid),private.dispatch(uuid),private.receive(uuid,integer,integer,integer),private.save_contact(uuid,text,text,text),private.contact(uuid) to authenticated;
revoke execute on function public.advance_donation(uuid,text),public.respond_task(uuid,text),public.create_shipment(uuid,uuid),public.dispatch_shipment(uuid),public.confirm_receipt(uuid,integer,integer,integer),public.save_donation_contact(uuid,text,text,text),public.get_donation_contact(uuid) from public,anon;
grant execute on function public.advance_donation(uuid,text),public.respond_task(uuid,text),public.create_shipment(uuid,uuid),public.dispatch_shipment(uuid),public.confirm_receipt(uuid,integer,integer,integer),public.save_donation_contact(uuid,text,text,text),public.get_donation_contact(uuid) to authenticated;



create policy mitra_request_incident on public.incidents for insert to authenticated with check(private.org_access(organization_id) and status='requested' and approved_by is null);
create policy admin_profile_update on public.profiles for update to authenticated using((select private.is_admin())) with check((select private.is_admin()));
create function private.guard_task() returns trigger language plpgsql security definer set search_path='' as $$begin
if new.assigned_to is not null and not exists(select 1 from public.user_roles where user_id=new.assigned_to and role='relawan') then raise exception 'Assignee must have relawan role';end if;
if new.donation_id is not null and not exists(select 1 from public.donations where id=new.donation_id and point_id=new.point_id) then raise exception 'Task point mismatch';end if;return new;end$$;
create trigger guard_task before insert or update on public.logistics_tasks for each row execute function private.guard_task();
create function private.audit_operation() returns trigger language plpgsql security definer set search_path='' as $$begin
insert into private.audit_logs(actor_id,action,entity_id) values(auth.uid(),tg_table_name||':'||tg_op,coalesce(new.id,old.id));
return coalesce(new,old);end$$;
create trigger audit_organizations after insert or update or delete on public.organizations for each row execute function private.audit_operation();
create trigger audit_programs after insert or update or delete on public.needs for each row execute function private.audit_operation();
create trigger audit_incidents after insert or update or delete on public.incidents for each row execute function private.audit_operation();
revoke execute on function private.guard_task(),private.audit_operation() from public,anon,authenticated;