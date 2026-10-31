alter table public.donation_items add constraint donation_variant_not_blank check (length(trim(category))>0 and length(trim(size_code))>0 and length(trim(age_group))>0);
alter table public.need_items add constraint need_variant_not_blank check (length(trim(category))>0 and length(trim(size_code))>0 and length(trim(age_group))>0);
alter table public.needs add constraint need_title_not_blank check(length(trim(title))>0);
create function private.guard_pickup_contact() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.status='submitted' and new.method='pickup' and not exists(
  select 1 from private.donation_contacts c where c.donation_id=new.id and
  nullif(trim(c.address),'') is not null and nullif(trim(c.contact_name),'') is not null and nullif(trim(c.phone),'') is not null
 ) then raise exception 'Pickup requires address and contact';end if;
 return new;
end $$;
create trigger guard_pickup_contact before insert or update on public.donations for each row execute function private.guard_pickup_contact();
revoke all on function private.guard_pickup_contact() from public,anon,authenticated;
