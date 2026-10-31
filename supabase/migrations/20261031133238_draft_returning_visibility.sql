-- Owner predicate must use the current row so INSERT ... RETURNING sees a new draft.
alter policy read_scoped on public.donations using (donor_id=(select auth.uid()) or private.donation_access(id));
