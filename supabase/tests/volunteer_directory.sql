begin;
do $$
declare donor uuid:=gen_random_uuid(); volunteer uuid:=gen_random_uuid();
manager uuid:=gen_random_uuid(); org uuid; denied boolean:=false;
begin
  insert into auth.users(id,email,raw_user_meta_data) values
    (donor,donor||'@example.test','{}'),(volunteer,volunteer||'@example.test','{}'),
    (manager,manager||'@example.test','{}');
  insert into public.user_roles(user_id,role) values(volunteer,'relawan'),(manager,'mitra');
  insert into public.organizations(name,kind,verified,active)
    values('Temporary directory test','social_institution',true,true) returning id into org;
  insert into public.organization_members(organization_id,user_id,active) values(org,manager,true);
  perform set_config('request.jwt.claim.sub',donor::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',donor,'role','authenticated')::text,true);
  perform set_config('role','authenticated',true);
  begin perform * from public.list_assignable_volunteers(); exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'FAIL donor can enumerate volunteers'; end if;
  perform set_config('request.jwt.claim.sub',manager::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',manager,'role','authenticated')::text,true);
  if not exists(select 1 from public.list_assignable_volunteers() where user_id=volunteer) then
    raise exception 'FAIL verified manager cannot assign volunteer';
  end if;
  perform set_config('role','postgres',true);
end $$;
select 'PASS: donor denied, verified manager can read minimal volunteer directory' as result;
rollback;
