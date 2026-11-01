-- Fully qualify object names: organization_applications also has a name column.
alter policy pk_verification_insert on storage.objects with check(
 bucket_id='verification-documents' and (storage.foldername(storage.objects.name))[1]=auth.uid()::text
 and exists(select 1 from public.organization_applications a
 where a.id::text=(storage.foldername(storage.objects.name))[2] and a.applicant_id=auth.uid() and a.status='draft')
);
alter policy pk_verification_read on storage.objects using(
 bucket_id='verification-documents' and exists(select 1 from public.organization_applications a
 where a.document_path=storage.objects.name and (a.applicant_id=auth.uid() or private.is_admin()))
);
alter policy pk_verification_delete on storage.objects using(
 bucket_id='verification-documents' and (storage.foldername(storage.objects.name))[1]=auth.uid()::text
 and exists(select 1 from public.organization_applications a
 where a.id::text=(storage.foldername(storage.objects.name))[2] and a.applicant_id=auth.uid() and a.status='draft')
);
