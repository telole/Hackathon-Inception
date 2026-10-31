-- Explicit demo data, safe to rerun. No accounts/passwords or production claims.
-- Run through the project owner's SQL Editor. Uses generated IDs, never fixture UUIDs.
begin;
do $$
declare source_org uuid; target_org uuid; source_point uuid; target_point uuid; n uuid;
begin
 select id into source_org from public.organizations where name='DEMO — Sandang Solo' limit 1;
 if source_org is null then
 insert into public.organizations(name,kind,area,verified) values('DEMO — Sandang Solo','social_institution','Surakarta',true) returning id into source_org;end if;
 select id into target_org from public.organizations where name='DEMO — Posko Demak' limit 1;
 if target_org is null then
 insert into public.organizations(name,kind,area,verified) values('DEMO — Posko Demak','disaster_post','Demak',true) returning id into target_org;end if;
 select id into source_point from public.collection_points where organization_id=source_org and name='DEMO — Titik Solo' limit 1;
 if source_point is null then
 insert into public.collection_points(organization_id,name,public_address,opening_hours,capacity_pieces)
 values(source_org,'DEMO — Titik Solo','Alamat simulasi, Surakarta','Senin–Sabtu 08.00–16.00',100) returning id into source_point;end if;
 select id into target_point from public.collection_points where organization_id=target_org and name='DEMO — Titik Demak' limit 1;
 if target_point is null then
 insert into public.collection_points(organization_id,name,public_address,opening_hours,capacity_pieces)
 values(target_org,'DEMO — Titik Demak','Alamat simulasi, Demak','Senin–Sabtu 08.00–16.00',100) returning id into target_point;end if;
 select id into n from public.needs where organization_id=target_org and title='DEMO — Kaos anak M' limit 1;
 if n is null then
 insert into public.needs(organization_id,point_id,title,description,deadline_at,status)
 values(target_org,target_point,'DEMO — Kaos anak M','Data simulasi hackathon; bukan permintaan bantuan nyata.',now()+interval '14 days','open') returning id into n;
 insert into public.need_items(need_id,category,size_code,age_group,requested_qty) values(n,'kaos','M','anak',10);
 end if;
end $$;
commit;
