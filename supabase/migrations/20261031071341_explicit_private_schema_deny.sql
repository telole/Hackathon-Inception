create policy deny_direct_access on private.audit_logs for all to authenticated using(false) with check(false);
create policy deny_direct_access on private.donation_contacts for all to authenticated using(false) with check(false);

