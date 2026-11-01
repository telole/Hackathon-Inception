begin;
do $$
declare owner_id uuid:=gen_random_uuid(); volunteer uuid:=gen_random_uuid(); other_volunteer uuid:=gen_random_uuid();
org uuid; point uuid; donation uuid; denied boolean;
begin
 insert into auth.users(id,email,raw_user_meta_data) values
 (owner_id,owner_id||'@example.test','{}'),(volunteer,volunteer||'@example.test','{}'),(other_volunteer,other_volunteer||'@example.test','{}');
 insert into public.user_roles(user_id,role) values(volunteer,'relawan'),(other_volunteer,'relawan');
 insert into public.organizations(name,kind,verified) values('Receipt QA','social_institution',true) returning id into org;
 insert into public.collection_points(organization_id,name,public_address) values(org,'Receipt QA','Fixture') returning id into point;
 insert into public.donations(donor_id,point_id,status) values(owner_id,point,'scheduled') returning id into donation;
 insert into public.logistics_tasks(donation_id,point_id,assigned_to,kind,status) values(donation,point,volunteer,'curation','accepted');
 perform set_config('role','authenticated',true);
 perform set_config('request.jwt.claim.sub',other_volunteer::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',other_volunteer,'role','authenticated')::text,true);
 denied:=false;
 begin perform public.advance_donation(donation,'received'); exception when insufficient_privilege then denied:=true; end;
 if not denied then raise exception 'FAIL unassigned volunteer can receive'; end if;
 perform set_config('request.jwt.claim.sub',volunteer::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',volunteer,'role','authenticated')::text,true);
 denied:=false;
 begin perform public.advance_donation(donation,'scheduled'); exception when insufficient_privilege then denied:=true; end;
 if not denied then raise exception 'FAIL volunteer can schedule'; end if;
 perform public.advance_donation(donation,'received');
 perform public.advance_donation(donation,'received');
 if (select count(*) from public.donation_events where donation_id=donation and event_type='received')<>1 then raise exception 'FAIL receive retry duplicated'; end if;
 perform set_config('role','postgres',true);
end $$;
select 'PASS: only active assignee receives, no scheduling privilege, retry creates one event' as result;
rollback;
