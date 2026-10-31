-- Isolated SQL integration test: fixtures and Storage metadata are rolled back.
-- This tests real RPC/RLS transactions, not email delivery or Storage HTTP uploads.
begin;
do $$
declare a uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); v uuid:=gen_random_uuid(); m uuid:=gen_random_uuid();
 o1 uuid;o2 uuid;p1 uuid;p2 uuid;n uuid;ni uuid;d uuid;di uuid;t uuid;b uuid;al uuid;sh uuid; cancelled uuid;
 path text; denied boolean;
begin
 insert into auth.users(id,email,raw_user_meta_data) values
 (a,a||'@example.test','{}'),(u,u||'@example.test','{}'),(v,v||'@example.test','{}'),(m,m||'@example.test','{}');
 insert into public.user_roles(user_id,role) values(a,'admin'),(v,'relawan'),(m,'mitra');
 insert into public.organizations(name,kind,verified) values('TEST source','social_institution',true) returning id into o1;
 insert into public.organizations(name,kind,verified) values('TEST target','disaster_post',true) returning id into o2;
 insert into public.organization_members(organization_id,user_id) values(o1,m),(o2,m);
 insert into public.collection_points(organization_id,name,public_address) values(o1,'TEST source','Simulation') returning id into p1;
 insert into public.collection_points(organization_id,name,public_address) values(o2,'TEST target','Simulation') returning id into p2;
 perform set_config('request.jwt.claim.sub',m::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',m,'role','authenticated')::text,true);
 perform set_config('role','authenticated',true);
 n:=public.save_need(null,o2,p2,'Kaos anak',null,now()+interval '2 days',null,
   '[{"category":"kaos","size_code":"M","age_group":"anak","requested_qty":6}]');
 perform public.set_need_status(n,'open');
 select id into ni from public.need_items where need_id=n;
 perform set_config('request.jwt.claim.sub',u::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated')::text,true);
 denied:=false;
 begin perform public.set_need_status(n,'closed'); exception when insufficient_privilege then denied:=true; end;
 if not denied then raise exception 'FAIL donor manages need'; end if;
 insert into public.donations(donor_id,point_id) values(u,p1) returning id into cancelled;
 perform public.cancel_donation(cancelled);perform public.cancel_donation(cancelled);
 if (select status from public.donations where id=cancelled)<>'cancelled' then raise exception 'FAIL cancellation';end if;
 insert into public.donations(donor_id,point_id) values(u,p1) returning id into d;
 denied:=false;
 begin insert into public.donation_items(donation_id,category,size_code,age_group,quantity)
 values(d,'','M','anak',10);exception when check_violation then denied:=true;end;
 if not denied then raise exception 'FAIL blank variant accepted';end if;
 insert into public.donation_items(donation_id,category,size_code,age_group,quantity)
 values(d,'kaos','M','anak',10) returning id into di;
 path:=u||'/'||d||'/photo.png';
 denied:=false;
 begin insert into public.donation_photos(donation_id,storage_path) values(d,path);
 exception when others then if sqlerrm='Photo object missing' then denied:=true;else raise;end if;end;
 if not denied then raise exception 'FAIL missing object accepted';end if;
 perform set_config('role','postgres',true);
 -- Metadata-only fixture: no actual object is uploaded by this SQL test.
 insert into storage.objects(bucket_id,name,metadata) values('donation-photos',path,'{"size":100,"mimetype":"image/png"}');
 perform set_config('role','authenticated',true);
 insert into public.donation_photos(donation_id,storage_path) values(d,path);
 update public.donations set clean_check=true,intact_check=true,not_torn_check=true where id=d;
 update public.donations set method='pickup' where id=d;
 denied:=false;
 begin perform public.submit_donation(d);exception when others then
 if sqlerrm='Pickup requires address and contact' then denied:=true;else raise;end if;end;
 if not denied then raise exception 'FAIL pickup without contact';end if;
 perform public.save_donation_contact(d,'Alamat simulasi','Pengguna uji','080000000');
 perform public.submit_donation(d);
 denied:=false;
 begin update public.donation_items set quantity=20 where id=di;
 exception when others then if sqlerrm='Donation is no longer editable' then denied:=true;else raise;end if;end;
 -- RLS may instead hide the row (zero updates); either way it must stay 10.
 if (select quantity from public.donation_items where id=di)<>10 then raise exception 'FAIL submitted item edited';end if;
 perform set_config('request.jwt.claim.sub',a::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated')::text,true);
 perform public.schedule_donation(d,now()+interval '1 day');
 t:=public.assign_logistics_task(null,d,p1,v,'curation',now()+interval '1 day',null);
 perform public.advance_donation(d,'received');
 perform set_config('request.jwt.claim.sub',v::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',v,'role','authenticated')::text,true);
 perform public.respond_task(t,'accepted');
 b:=public.record_inspection(di,8,2,'Robek');
 perform set_config('request.jwt.claim.sub',u::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated')::text,true);
 denied:=false;
 begin perform public.cancel_donation(d);exception when others then
 if sqlerrm='Cannot cancel after physical arrival' then denied:=true;else raise;end if;end;
 if not denied then raise exception 'FAIL physical donation cancelled';end if;
 perform set_config('request.jwt.claim.sub',m::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',m,'role','authenticated')::text,true);
 al:=public.reserve_allocation(b,ni,6,gen_random_uuid());
 sh:=public.create_shipment(al,v);
 denied:=false;
 begin perform public.delete_need(n);exception when others then
 if sqlerrm='Need has dependencies; close it instead' then denied:=true;else raise;end if;end;
 if not denied then raise exception 'FAIL allocated need deleted';end if;
 perform set_config('request.jwt.claim.sub',v::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',v,'role','authenticated')::text,true);
 perform public.dispatch_shipment(sh);perform public.dispatch_shipment(sh);
 denied:=false;
 begin perform public.confirm_receipt(sh,6,0,0);exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'FAIL volunteer can receive';end if;
 perform set_config('request.jwt.claim.sub',m::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',m,'role','authenticated')::text,true);
 perform public.confirm_receipt(sh,6,0,0);perform public.confirm_receipt(sh,6,0,0);
 perform public.set_need_status(n,'fulfilled');
 if (select on_hand_qty from public.inventory_batches where id=b)<>2 then raise exception 'FAIL stock';end if;
 if (select status from public.needs where id=n)<>'fulfilled' then raise exception 'FAIL fulfilment';end if;
 perform set_config('role','postgres',true);
 perform set_config('pk.core_test','PASS: needs RPC, ownership, missing photo rejection, donor submit, scheduling, task assignment, volunteer curation, reserve, dispatch retry, recipient receipt retry, fulfilment, stock=2',true);
end $$;
select current_setting('pk.core_test') as result;
rollback;
