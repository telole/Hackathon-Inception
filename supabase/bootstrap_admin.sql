-- Run only through the project owner's SQL Editor after registration + confirmation.
-- User-selected email; no passwords, public bootstrap endpoint or automatic escalation.
begin;
do $$
declare target uuid;
begin
 perform pg_advisory_xact_lock(819901);
 select id into strict target from auth.users
 where lower(email)='admin@gmail.com' and email_confirmed_at is not null;
 if exists(select 1 from public.user_roles where role='admin' and user_id<>target) then
   raise exception 'An admin already exists; use admin_set_role';end if;
 insert into public.user_roles(user_id,role) values(target,'admin') on conflict do nothing;
 insert into private.audit_logs(actor_id,action,entity_id,details)
 values(target,'bootstrap_admin',target,'{"source":"owner_sql_editor"}');
end $$;
commit;
