
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

-- =====================================================================
-- KONTRAK API & RPC EXTENSIONS (api-contracts.md)
-- SQLSTATE mapping:
-- P1001: AUTH_REQUIRED
-- P1002: FORBIDDEN
-- P1003: VALIDATION_ERROR
-- P1004: VERSION_CONFLICT
-- P1005: STOCK_CONFLICT
-- P1006: NEED_CLOSED
-- P1007: INVALID_TRANSITION
-- P1008: IDEMPOTENCY_CONFLICT
-- P1009: ALREADY_CONFIRMED
-- =====================================================================

-- 1. get_my_context
create or replace function public.get_my_context() returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_uid uuid := auth.uid();
  v_prof record;
  v_roles jsonb;
  v_memberships jsonb;
  v_ui text;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED' using errcode='P1001';
  end if;
  
  select * into v_prof from public.profiles where id = v_uid;
  select coalesce(jsonb_agg(role), '[]'::jsonb) into v_roles from public.user_roles where user_id = v_uid;
  select coalesce(jsonb_agg(jsonb_build_object('organization_id', m.organization_id, 'org_name', o.name, 'kind', o.kind, 'verified', o.verified, 'active', m.active)), '[]'::jsonb)
    into v_memberships
    from public.organization_members m
    join public.organizations o on o.id = m.organization_id
    where m.user_id = v_uid and m.active and o.active;
    
  v_ui := case when private.is_admin() then 'admin' else 'user' end;

  return jsonb_build_object(
    'user_id', v_uid,
    'profile', jsonb_build_object('display_name', coalesce(v_prof.display_name, ''), 'avatar_path', v_prof.avatar_path, 'area', v_prof.area),
    'roles', v_roles,
    'memberships', v_memberships,
    'ui', v_ui
  );
end$$;

-- 2. list_needs
create or replace function public.list_needs(
  p_category text default null,
  p_size text default null,
  p_age_group text default null,
  p_area text default null,
  p_emergency boolean default null,
  p_limit integer default 20,
  p_offset integer default 0
) returns jsonb language plpgsql stable security invoker set search_path='' as $$
begin
  return coalesce((
    select jsonb_agg(row_to_json(n)) from (
      select 
        n.id,
        n.organization_id,
        o.name as organization_name,
        o.area as organization_area,
        n.point_id,
        p.name as point_name,
        p.public_address as point_address,
        n.incident_id,
        i.title as incident_title,
        n.title,
        n.description,
        n.deadline_at,
        n.status,
        n.created_at,
        (
          select coalesce(jsonb_agg(jsonb_build_object(
            'id', ni.id,
            'category', ni.category,
            'size_code', ni.size_code,
            'age_group', ni.age_group,
            'requested_qty', ni.requested_qty,
            'reserved_qty', coalesce((select sum(a.quantity) from public.allocations a where a.need_item_id = ni.id and a.status = 'reserved'), 0),
            'dispatched_qty', coalesce((select sum(a.quantity) from public.allocations a where a.need_item_id = ni.id and a.status = 'dispatched'), 0),
            'received_qty', coalesce((select sum(si.received_good) from public.shipment_items si join public.allocations a on a.id = si.allocation_id where a.need_item_id = ni.id), 0),
            'remaining_qty', greatest(0, ni.requested_qty - coalesce((select sum(a.quantity) from public.allocations a where a.need_item_id = ni.id and a.status in ('reserved', 'dispatched', 'received')), 0))
          )), '[]'::jsonb)
          from public.need_items ni
          where ni.need_id = n.id
          and (p_category is null or ni.category ilike p_category)
          and (p_size is null or ni.size_code ilike p_size)
          and (p_age_group is null or ni.age_group ilike p_age_group)
        ) as lines
      from public.needs n
      join public.organizations o on o.id = n.organization_id
      join public.collection_points p on p.id = n.point_id
      left join public.incidents i on i.id = n.incident_id
      where n.status = 'open'
        and o.verified = true
        and o.active = true
        and (p_area is null or o.area ilike '%' || p_area || '%' or p.public_address ilike '%' || p_area || '%')
        and (p_emergency is null or (p_emergency = true and n.incident_id is not null) or (p_emergency = false and n.incident_id is null))
        and (
          p_category is null and p_size is null and p_age_group is null
          or exists (
            select 1 from public.need_items ni 
            where ni.need_id = n.id 
              and (p_category is null or ni.category ilike p_category)
              and (p_size is null or ni.size_code ilike p_size)
              and (p_age_group is null or ni.age_group ilike p_age_group)
          )
        )
      order by (n.incident_id is not null) desc, n.deadline_at asc, n.created_at desc
      limit p_limit offset p_offset
    ) n
  ), '[]'::jsonb);
end$$;

-- 3. get_need_detail
create or replace function public.get_need_detail(p_need_id uuid) returns jsonb language plpgsql stable security invoker set search_path='' as $$
declare
  v_res jsonb;
begin
  select row_to_json(r)::jsonb into v_res from (
    select 
      n.id,
      n.organization_id,
      o.name as organization_name,
      o.kind as organization_kind,
      o.area as organization_area,
      n.point_id,
      p.name as point_name,
      p.public_address as point_address,
      p.opening_hours as point_opening_hours,
      n.incident_id,
      i.title as incident_title,
      n.title,
      n.description,
      n.deadline_at,
      n.status,
      n.created_at,
      (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', ni.id,
          'category', ni.category,
          'size_code', ni.size_code,
          'age_group', ni.age_group,
          'requested_qty', ni.requested_qty,
          'reserved_qty', coalesce((select sum(a.quantity) from public.allocations a where a.need_item_id = ni.id and a.status = 'reserved'), 0),
          'dispatched_qty', coalesce((select sum(a.quantity) from public.allocations a where a.need_item_id = ni.id and a.status = 'dispatched'), 0),
          'received_qty', coalesce((select sum(si.received_good) from public.shipment_items si join public.allocations a on a.id = si.allocation_id where a.need_item_id = ni.id), 0),
          'remaining_qty', greatest(0, ni.requested_qty - coalesce((select sum(a.quantity) from public.allocations a where a.need_item_id = ni.id and a.status in ('reserved', 'dispatched', 'received')), 0))
        )), '[]'::jsonb)
        from public.need_items ni
        where ni.need_id = n.id
      ) as lines
    from public.needs n
    join public.organizations o on o.id = n.organization_id
    join public.collection_points p on p.id = n.point_id
    left join public.incidents i on i.id = n.incident_id
    where n.id = p_need_id
  ) r;
  
  return v_res;
end$$;

-- 4. find_matches (deterministic candidate matching)
create or replace function public.find_matches(
  p_category text,
  p_size_code text,
  p_age_group text,
  p_limit integer default 5
) returns jsonb language plpgsql stable security invoker set search_path='' as $$
begin
  return coalesce((
    select jsonb_agg(row_to_json(m)) from (
      select 
        n.id as need_id,
        ni.id as need_item_id,
        n.title as need_title,
        o.name as organization_name,
        p.name as point_name,
        ni.category,
        ni.size_code,
        ni.age_group,
        ni.requested_qty,
        greatest(0, ni.requested_qty - coalesce((select sum(a.quantity) from public.allocations a where a.need_item_id = ni.id and a.status in ('reserved', 'dispatched', 'received')), 0)) as remaining_qty,
        case 
          when n.incident_id is not null then 'Kebutuhan Posko Darurat Bencana (Prioritas Utama)'
          when n.deadline_at < now() + interval '3 days' then 'Tenggat Waktu Mendesak (< 3 Hari)'
          else 'Kesesuaian Spesifikasi Pakaian Terverifikasi'
        end as match_reason,
        (n.incident_id is not null) as is_emergency
      from public.need_items ni
      join public.needs n on n.id = ni.need_id
      join public.organizations o on o.id = n.organization_id
      join public.collection_points p on p.id = n.point_id
      where n.status = 'open'
        and n.deadline_at > now()
        and o.verified = true
        and o.active = true
        and ni.category ilike p_category
        and ni.size_code ilike p_size_code
        and ni.age_group ilike p_age_group
        and ni.requested_qty > coalesce((select sum(a.quantity) from public.allocations a where a.need_item_id = ni.id and a.status in ('reserved', 'dispatched', 'received')), 0)
      order by (n.incident_id is not null) desc, n.deadline_at asc, n.created_at asc
      limit p_limit
    ) m
  ), '[]'::jsonb);
end$$;

-- 5. list_points
create or replace function public.list_points(p_area text default null) returns jsonb language sql stable security invoker set search_path='' as $$
  select coalesce(jsonb_agg(row_to_json(pt)), '[]'::jsonb) from (
    select 
      cp.id,
      cp.organization_id,
      o.name as organization_name,
      cp.name,
      cp.public_address,
      cp.latitude,
      cp.longitude,
      cp.opening_hours,
      cp.capacity_pieces,
      cp.active
    from public.collection_points cp
    join public.organizations o on o.id = cp.organization_id
    where cp.active = true and o.verified = true and o.active = true
      and (p_area is null or cp.public_address ilike '%' || p_area || '%' or o.area ilike '%' || p_area || '%')
    order by cp.name asc
  ) pt;
$$;

-- 6. list_my_tasks
create or replace function public.list_my_tasks(p_status text default null) returns jsonb language plpgsql stable security invoker set search_path='' as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED' using errcode='P1001';
  end if;
  return coalesce((
    select jsonb_agg(row_to_json(t)) from (
      select 
        lt.id,
        lt.donation_id,
        d.tracking_code,
        lt.point_id,
        cp.name as point_name,
        cp.public_address as point_address,
        lt.kind,
        lt.status,
        lt.scheduled_at,
        lt.notes,
        lt.created_at,
        case 
          when lt.status in ('accepted', 'in_progress') then (
            select jsonb_build_object('address', dc.address, 'contact_name', dc.contact_name, 'phone', dc.phone)
            from private.donation_contacts dc where dc.donation_id = lt.donation_id
          )
          else null
        end as contact_info
      from public.logistics_tasks lt
      join public.collection_points cp on cp.id = lt.point_id
      left join public.donations d on d.id = lt.donation_id
      where lt.assigned_to = auth.uid()
        and (p_status is null or lt.status = p_status)
      order by lt.created_at desc
    ) t
  ), '[]'::jsonb);
end$$;

-- 7. list_inventory
create or replace function public.list_inventory(
  p_point_id uuid,
  p_category text default null,
  p_size_code text default null
) returns jsonb language plpgsql stable security invoker set search_path='' as $$
begin
  if not private.point_access(p_point_id) and not private.is_admin() then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;
  return coalesce((
    select jsonb_agg(row_to_json(b)) from (
      select 
        ib.id,
        ib.point_id,
        ib.category,
        ib.size_code,
        ib.age_group,
        ib.initial_qty,
        ib.on_hand_qty,
        ib.reserved_qty,
        (ib.on_hand_qty - ib.reserved_qty) as available_qty,
        ib.inspection_id
      from public.inventory_batches ib
      where ib.point_id = p_point_id
        and (p_category is null or ib.category ilike p_category)
        and (p_size_code is null or ib.size_code ilike p_size_code)
      order by ib.category, ib.size_code
    ) b
  ), '[]'::jsonb);
end$$;

-- 8. get_my_impact
create or replace function public.get_my_impact() returns jsonb language plpgsql stable security invoker set search_path='' as $$
declare
  v_uid uuid := auth.uid();
  v_total_donated integer := 0;
  v_received_good integer := 0;
  v_recycling_count integer := 0;
  v_destinations jsonb;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED' using errcode='P1001';
  end if;

  select coalesce(sum(di.quantity), 0) into v_total_donated
  from public.donations d
  join public.donation_items di on di.donation_id = d.id
  where d.donor_id = v_uid and d.status <> 'cancelled';

  select coalesce(sum(si.received_good), 0) into v_received_good
  from public.donations d
  join public.donation_items di on di.donation_id = d.id
  join public.inspections i on i.item_id = di.id
  join public.inventory_batches b on b.inspection_id = i.id
  join public.allocations a on a.batch_id = b.id
  join public.shipment_items si on si.allocation_id = a.id
  where d.donor_id = v_uid;

  select coalesce(sum(rr.quantity), 0) into v_recycling_count
  from public.donations d
  join public.donation_items di on di.donation_id = d.id
  join public.inspections i on i.item_id = di.id
  join public.recycling_referrals rr on rr.inspection_id = i.id
  where d.donor_id = v_uid;

  select coalesce(jsonb_agg(distinct jsonb_build_object('partner_name', o.name, 'area', o.area, 'kind', o.kind)), '[]'::jsonb)
  into v_destinations
  from public.donations d
  join public.donation_items di on di.donation_id = d.id
  join public.inspections i on i.item_id = di.id
  join public.inventory_batches b on b.inspection_id = i.id
  join public.allocations a on a.batch_id = b.id
  join public.need_items ni on ni.id = a.need_item_id
  join public.needs n on n.id = ni.need_id
  join public.organizations o on o.id = n.organization_id
  where d.donor_id = v_uid;

  return jsonb_build_object(
    'total_donated_pieces', v_total_donated,
    'received_good_pieces', v_received_good,
    'recycling_referred_pieces', v_recycling_count,
    'destination_partners', v_destinations
  );
end$$;

-- 9. create_donation_draft
create or replace function public.create_donation_draft(p_request_key uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
  v_tracking text;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED' using errcode='P1001';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_uid::text || p_request_key::text, 0));

  v_tracking := 'PK-' || upper(replace(gen_random_uuid()::text, '-', ''));
  insert into public.donations(donor_id, tracking_code, status)
  values (v_uid, v_tracking, 'draft')
  returning id into v_id;

  insert into private.audit_logs(actor_id, action, entity_id, details)
  values (v_uid, 'create_donation_draft', v_id, jsonb_build_object('request_key', p_request_key));

  return jsonb_build_object(
    'donation_id', v_id,
    'tracking_code', v_tracking,
    'status', 'draft',
    'request_key', p_request_key
  );
end$$;

-- 10. save_donation_draft
create or replace function public.save_donation_draft(
  p_id uuid,
  p_point_id uuid,
  p_method text,
  p_clean_check boolean,
  p_intact_check boolean,
  p_not_torn_check boolean,
  p_preferred_need_id uuid default null,
  p_items jsonb default '[]'::jsonb,
  p_address text default null,
  p_contact_name text default null,
  p_phone text default null,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
declare
  v_uid uuid := auth.uid();
  v_item jsonb;
begin
  if not private.owns_draft(p_id) then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  if p_method not in ('dropoff', 'pickup') then
    raise exception 'VALIDATION_ERROR: Invalid handover method' using errcode='P1003';
  end if;

  update public.donations set
    point_id = p_point_id,
    method = p_method,
    clean_check = coalesce(p_clean_check, false),
    intact_check = coalesce(p_intact_check, false),
    not_torn_check = coalesce(p_not_torn_check, false),
    preferred_need_id = p_preferred_need_id
  where id = p_id;

  -- Replace items atomically
  delete from public.donation_items where donation_id = p_id;
  for v_item in select * from jsonb_array_elements(p_items) loop
    insert into public.donation_items(donation_id, category, size_code, age_group, quantity)
    values (
      p_id,
      v_item->>'category',
      v_item->>'size_code',
      v_item->>'age_group',
      (v_item->>'quantity')::integer
    );
  end loop;

  -- Update contact if provided or pickup
  if p_method = 'pickup' or p_address is not null then
    insert into private.donation_contacts(donation_id, address, contact_name, phone)
    values (p_id, p_address, p_contact_name, p_phone)
    on conflict (donation_id) do update set
      address = excluded.address,
      contact_name = excluded.contact_name,
      phone = excluded.phone;
  end if;
end$$;

-- 11. register_donation_photo
create or replace function public.register_donation_photo(
  p_donation_id uuid,
  p_storage_path text,
  p_request_key uuid default null
) returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_id uuid;
begin
  if not private.owns_draft(p_donation_id) then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  if (select count(*) from public.donation_photos where donation_id = p_donation_id) >= 5 then
    raise exception 'VALIDATION_ERROR: Maximum 5 photos allowed' using errcode='P1003';
  end if;

  insert into public.donation_photos(donation_id, storage_path)
  values (p_donation_id, p_storage_path)
  returning id into v_id;

  return v_id;
end$$;

-- 12. review_donation
create or replace function public.review_donation(
  p_donation_id uuid,
  p_decision text,
  p_note text default null,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
declare
  d public.donations;
begin
  select * into d from public.donations where id = p_donation_id for update;
  if not (private.is_admin() or private.point_access(d.point_id)) then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  if d.status <> 'submitted' then
    raise exception 'INVALID_TRANSITION' using errcode='P1007';
  end if;

  if p_decision = 'approve' then
    update public.donations set status = 'scheduled' where id = p_donation_id;
    insert into public.donation_events(donation_id, event_type, summary, actor_id)
    values (p_donation_id, 'scheduled', coalesce(p_note, 'Donasi disetujui untuk penyerahan / penjemputan'), auth.uid());
  elsif p_decision = 'request_revision' then
    update public.donations set status = 'needs_revision' where id = p_donation_id;
    insert into public.donation_events(donation_id, event_type, summary, actor_id)
    values (p_donation_id, 'needs_revision', coalesce(p_note, 'Memerlukan perbaikan data / foto'), auth.uid());
  else
    raise exception 'VALIDATION_ERROR: Invalid decision' using errcode='P1003';
  end if;
end$$;

-- 13. save_need
create or replace function public.save_need(
  p_need_id uuid,
  p_organization_id uuid,
  p_point_id uuid,
  p_title text,
  p_description text,
  p_deadline_at timestamptz,
  p_incident_id uuid default null,
  p_lines jsonb default '[]'::jsonb,
  p_request_key uuid default null
) returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_id uuid := p_need_id;
  v_item jsonb;
begin
  if not private.org_access(p_organization_id) then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  if v_id is null then
    insert into public.needs(organization_id, point_id, incident_id, title, description, deadline_at, status)
    values (p_organization_id, p_point_id, p_incident_id, p_title, p_description, p_deadline_at, 'draft')
    returning id into v_id;
  else
    update public.needs set
      point_id = p_point_id,
      incident_id = p_incident_id,
      title = p_title,
      description = p_description,
      deadline_at = p_deadline_at
    where id = v_id and organization_id = p_organization_id;
  end if;

  -- Replace lines
  delete from public.need_items where need_id = v_id;
  for v_item in select * from jsonb_array_elements(p_lines) loop
    insert into public.need_items(need_id, category, size_code, age_group, requested_qty)
    values (
      v_id,
      v_item->>'category',
      v_item->>'size_code',
      v_item->>'age_group',
      (v_item->>'requested_qty')::integer
    );
  end loop;

  return v_id;
end$$;

-- 14. publish_need
create or replace function public.publish_need(
  p_need_id uuid,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
declare
  n public.needs;
begin
  select * into n from public.needs where id = p_need_id for update;
  if not private.org_access(n.organization_id) then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  if n.status <> 'draft' and n.status <> 'paused' then
    raise exception 'INVALID_TRANSITION' using errcode='P1007';
  end if;

  if n.deadline_at <= now() then
    raise exception 'VALIDATION_ERROR: Deadline must be in the future' using errcode='P1003';
  end if;

  if not exists(select 1 from public.need_items where need_id = p_need_id) then
    raise exception 'VALIDATION_ERROR: Need must have at least one item' using errcode='P1003';
  end if;

  update public.needs set status = 'open' where id = p_need_id;
end$$;

-- 15. change_need_status
create or replace function public.change_need_status(
  p_need_id uuid,
  p_status text,
  p_reason text default null,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
declare
  n public.needs;
begin
  select * into n from public.needs where id = p_need_id for update;
  if not (private.is_admin() or private.org_access(n.organization_id)) then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  if p_status not in ('open', 'paused', 'closed') then
    raise exception 'VALIDATION_ERROR: Invalid status' using errcode='P1003';
  end if;

  update public.needs set status = p_status where id = p_need_id;
end$$;

-- 16. request_role (volunteer)
create or replace function public.request_role(
  p_role public.app_role,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED' using errcode='P1001';
  end if;
  if p_role = 'admin' then
    raise exception 'FORBIDDEN: Cannot request admin role' using errcode='P1002';
  end if;

  insert into private.audit_logs(actor_id, action, entity_id, details)
  values (v_uid, 'request_role', v_uid, jsonb_build_object('role', p_role, 'request_key', p_request_key));
end$$;

-- 17. request_organization
create or replace function public.request_organization(
  p_name text,
  p_kind text,
  p_area text,
  p_request_key uuid default null
) returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_uid uuid := auth.uid();
  v_org_id uuid;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED' using errcode='P1001';
  end if;

  if p_kind not in ('social_institution', 'disaster_post', 'recycling_partner') then
    raise exception 'VALIDATION_ERROR: Invalid organization kind' using errcode='P1003';
  end if;

  insert into public.organizations(name, kind, area, verified, active)
  values (p_name, p_kind, p_area, false, true)
  returning id into v_org_id;

  insert into public.organization_members(organization_id, user_id, active)
  values (v_org_id, v_uid, true);

  insert into private.audit_logs(actor_id, action, entity_id, details)
  values (v_uid, 'request_organization', v_org_id, jsonb_build_object('name', p_name, 'request_key', p_request_key));

  return v_org_id;
end$$;

-- 18. approve_verification
create or replace function public.approve_verification(
  p_target_type text,
  p_target_id uuid,
  p_decision text,
  p_reason text default null,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  if p_target_type = 'organization' then
    if p_decision = 'approve' then
      update public.organizations set verified = true where id = p_target_id;
    else
      update public.organizations set active = false where id = p_target_id;
    end if;
  elsif p_target_type = 'volunteer' then
    if p_decision = 'approve' then
      insert into public.user_roles(user_id, role, granted_by)
      values (p_target_id, 'relawan', auth.uid())
      on conflict do nothing;
    end if;
  else
    raise exception 'VALIDATION_ERROR: Target type must be organization or volunteer' using errcode='P1003';
  end if;

  insert into private.audit_logs(actor_id, action, entity_id, details)
  values (auth.uid(), 'approve_verification', p_target_id, jsonb_build_object('type', p_target_type, 'decision', p_decision, 'reason', p_reason));
end$$;

-- 19. assign_task
create or replace function public.assign_task(
  p_donation_id uuid,
  p_point_id uuid,
  p_volunteer_id uuid,
  p_kind text,
  p_scheduled_at timestamptz default null,
  p_notes text default null,
  p_request_key uuid default null
) returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_task_id uuid;
begin
  if not (private.is_admin() or private.point_access(p_point_id)) then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  if not exists(select 1 from public.user_roles where user_id = p_volunteer_id and role = 'relawan') then
    raise exception 'VALIDATION_ERROR: Target is not a verified volunteer' using errcode='P1003';
  end if;

  insert into public.logistics_tasks(donation_id, point_id, assigned_to, kind, status, scheduled_at, notes)
  values (p_donation_id, p_point_id, p_volunteer_id, p_kind, 'assigned', p_scheduled_at, p_notes)
  returning id into v_task_id;

  return v_task_id;
end$$;

-- 20. cancel_allocation
create or replace function public.cancel_allocation(
  p_allocation_id uuid,
  p_reason text default null,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
declare
  a public.allocations;
  b public.inventory_batches;
begin
  select * into a from public.allocations where id = p_allocation_id for update;
  if not (private.is_admin() or a.created_by = auth.uid()) then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  if a.status <> 'reserved' then
    raise exception 'INVALID_TRANSITION: Only reserved allocations can be cancelled' using errcode='P1007';
  end if;

  update public.inventory_batches
  set reserved_qty = greatest(0, reserved_qty - a.quantity)
  where id = a.batch_id;

  update public.allocations set status = 'cancelled' where id = p_allocation_id;

  insert into private.audit_logs(actor_id, action, entity_id, details)
  values (auth.uid(), 'cancel_allocation', p_allocation_id, jsonb_build_object('reason', p_reason));
end$$;

-- 21. resolve_dispute
create or replace function public.resolve_dispute(
  p_dispute_id uuid,
  p_accepted_late_qty integer,
  p_released_need_qty integer,
  p_reason text,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  insert into private.audit_logs(actor_id, action, entity_id, details)
  values (auth.uid(), 'resolve_dispute', p_dispute_id, jsonb_build_object(
    'accepted_late', p_accepted_late_qty,
    'released_need', p_released_need_qty,
    'reason', p_reason
  ));
end$$;

-- 22. request_incident
create or replace function public.request_incident(
  p_org_id uuid,
  p_title text,
  p_area text,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_request_key uuid default null
) returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_id uuid;
begin
  if not private.org_access(p_org_id) then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  if p_ends_at <= p_starts_at then
    raise exception 'VALIDATION_ERROR: End time must be after start time' using errcode='P1003';
  end if;

  insert into public.incidents(organization_id, title, area, status, starts_at, ends_at)
  values (p_org_id, p_title, p_area, 'requested', p_starts_at, p_ends_at)
  returning id into v_id;

  return v_id;
end$$;

-- 23. activate_incident
create or replace function public.activate_incident(
  p_incident_id uuid,
  p_reason text default null,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  update public.incidents
  set status = 'active', approved_by = auth.uid()
  where id = p_incident_id;

  insert into private.audit_logs(actor_id, action, entity_id, details)
  values (auth.uid(), 'activate_incident', p_incident_id, jsonb_build_object('reason', p_reason));
end$$;

-- 24. close_incident
create or replace function public.close_incident(
  p_incident_id uuid,
  p_reason text default null,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  update public.incidents set status = 'closed' where id = p_incident_id;

  insert into private.audit_logs(actor_id, action, entity_id, details)
  values (auth.uid(), 'close_incident', p_incident_id, jsonb_build_object('reason', p_reason));
end$$;

-- 25. update_recycling_referral
create or replace function public.update_recycling_referral(
  p_referral_id uuid,
  p_partner_id uuid default null,
  p_status text default null,
  p_evidence text default null,
  p_request_key uuid default null
) returns void language plpgsql security definer set search_path='' as $$
begin
  if not (private.is_admin() or private.has_role('relawan')) then
    raise exception 'FORBIDDEN' using errcode='P1002';
  end if;

  update public.recycling_referrals set
    partner_id = coalesce(p_partner_id, partner_id),
    status = coalesce(p_status, status),
    evidence_path = coalesce(p_evidence, evidence_path)
  where id = p_referral_id;
end$$;

-- Grant execute permissions to authenticated
grant execute on function 
  public.get_my_context(),
  public.list_needs(text, text, text, text, boolean, integer, integer),
  public.get_need_detail(uuid),
  public.find_matches(text, text, text, integer),
  public.list_points(text),
  public.list_my_tasks(text),
  public.list_inventory(uuid, text, text),
  public.get_my_impact(),
  public.create_donation_draft(uuid),
  public.save_donation_draft(uuid, uuid, text, boolean, boolean, boolean, uuid, jsonb, text, text, text, uuid),
  public.register_donation_photo(uuid, text, uuid),
  public.review_donation(uuid, text, text, uuid),
  public.save_need(uuid, uuid, uuid, text, text, timestamptz, uuid, jsonb, uuid),
  public.publish_need(uuid, uuid),
  public.change_need_status(uuid, text, text, uuid),
  public.request_role(public.app_role, uuid),
  public.request_organization(text, text, text, uuid),
  public.approve_verification(text, uuid, text, text, uuid),
  public.assign_task(uuid, uuid, uuid, text, timestamptz, text, uuid),
  public.cancel_allocation(uuid, text, uuid),
  public.resolve_dispute(uuid, integer, integer, text, uuid),
  public.request_incident(uuid, text, text, timestamptz, timestamptz, uuid),
  public.activate_incident(uuid, text, uuid),
  public.close_incident(uuid, text, uuid),
  public.update_recycling_referral(uuid, uuid, text, text, uuid)
to authenticated;