alter table public.needs add column if not exists banner_path text;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('program-banners','program-banners',false,1048576,array['image/jpeg','image/png','image/webp']) on conflict(id) do nothing;

create policy pk_banner_insert on storage.objects for insert to authenticated
with check(bucket_id='program-banners' and (storage.foldername(name))[1]=auth.uid()::text
and exists(select 1 from public.needs n where n.id::text=(storage.foldername(name))[2] and private.org_access(n.organization_id)));
create policy pk_banner_read on storage.objects for select to authenticated
using(bucket_id='program-banners' and exists(select 1 from public.needs n where
 (n.banner_path=name or (n.id::text=(storage.foldername(name))[2] and private.org_access(n.organization_id)))));
create policy pk_banner_delete on storage.objects for delete to authenticated
using(bucket_id='program-banners' and not exists(select 1 from public.needs n where n.banner_path=name)
and exists(select 1 from public.needs n where n.id::text=(storage.foldername(name))[2] and private.org_access(n.organization_id)));

create function private.guard_program_banner() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.banner_path is not null and (tg_op='INSERT' or new.banner_path is distinct from old.banner_path) then
   if not private.org_access(new.organization_id) or split_part(new.banner_path,'/',2)<>new.id::text
     or not exists(select 1 from storage.objects where bucket_id='program-banners' and name=new.banner_path)
     then raise exception 'Invalid banner'; end if;
 end if;
 return new;
end $$;
revoke all on function private.guard_program_banner() from public,anon,authenticated;
create trigger guard_program_banner before insert or update of banner_path on public.needs
for each row execute function private.guard_program_banner();

create table private.revision_requests(actor_id uuid not null, request_key uuid not null,
donation_id uuid not null, note text not null, primary key(actor_id,request_key));
revoke all on private.revision_requests from public,anon,authenticated;
create function public.request_donation_revision(p_id uuid,p_note text,p_key uuid) returns void
language plpgsql security definer set search_path='' as $$
declare d public.donations; previous private.revision_requests;
begin
 if auth.uid() is null or not private.is_admin() then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if p_key is null or nullif(trim(p_note),'') is null or length(p_note)>1000 then raise exception 'Revision reason required (max 1000)'; end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text||p_key::text,0));
 select * into previous from private.revision_requests where actor_id=auth.uid() and request_key=p_key;
 if found then
   if previous.donation_id<>p_id or previous.note<>trim(p_note) then raise exception 'Idempotency conflict'; end if;
   return;
 end if;
 select * into d from public.donations where id=p_id for update;
 if not found or d.status<>'submitted' then raise exception 'Donation is no longer awaiting review'; end if;
 update public.donations set status='needs_revision' where id=p_id;
 insert into public.donation_events(donation_id,event_type,summary,actor_id)
 values(p_id,'needs_revision',trim(p_note),auth.uid());
 insert into private.revision_requests values(auth.uid(),p_key,p_id,trim(p_note));
end $$;
revoke all on function public.request_donation_revision(uuid,text,uuid) from public,anon;
grant execute on function public.request_donation_revision(uuid,text,uuid) to authenticated;
