-- =====================================================================
-- SEED DATA DEMO SINTETIS (hackathon-plan.md Section 5)
-- Platform: reSandang / PakaianKita
-- =====================================================================

-- 1. Organisasi Demo
insert into public.organizations (id, name, kind, area, verified, active)
values 
  ('11111111-1111-1111-1111-111111111111', 'Yayasan Sandang Lestari (Mitra Sumber)', 'social_institution', 'Jakarta Timur', true, true),
  ('22222222-2222-2222-2222-222222222222', 'Posko Bencana Serayu (Posko Tujuan)', 'disaster_post', 'Banyumas', true, true),
  ('33333333-3333-3333-3333-333333333333', 'Mitra Daur Ulang Tekstil Bersama', 'recycling_partner', 'Semarang', true, true)
on conflict (id) do update set 
  name = excluded.name, 
  kind = excluded.kind, 
  area = excluded.area, 
  verified = excluded.verified, 
  active = excluded.active;

-- 2. Titik Kumpul Demo
insert into public.collection_points (id, organization_id, name, public_address, latitude, longitude, opening_hours, capacity_pieces, active)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Titik Kumpul Utama Rawamangun (Titik A)', 'Jl. Pemuda No. 45, Rawamangun, Jakarta Timur', -6.1925, 106.8821, '08:00 - 17:00 WIB', 1500, true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Posko Bantuan Lapangan Banyumas', 'Jl. Raya Banyumas No. 10, Banyumas', -7.5167, 109.2944, '24 Jam (Siaga Bencana)', 2000, true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', 'Drop Point Harmoni', 'Jl. Hayam Wuruk No. 8, Gambir, Jakarta Pusat', -6.1667, 106.8167, '09:00 - 18:00 WIB', 800, true)
on conflict (id) do update set 
  name = excluded.name, 
  public_address = excluded.public_address, 
  latitude = excluded.latitude, 
  longitude = excluded.longitude, 
  opening_hours = excluded.opening_hours, 
  capacity_pieces = excluded.capacity_pieces, 
  active = excluded.active;

-- 3. Insiden Bencana Simulasi (Mode Bencana Demo)
insert into public.incidents (id, organization_id, title, area, status, starts_at, ends_at)
values
  ('99999999-9999-9999-9999-999999999999', '22222222-2222-2222-2222-222222222222', 'Banjir Luapan Sungai Serayu', 'Kecamatan Banyumas', 'active', now() - interval '1 day', now() + interval '14 days')
on conflict (id) do update set 
  title = excluded.title, 
  area = excluded.area, 
  status = excluded.status, 
  starts_at = excluded.starts_at, 
  ends_at = excluded.ends_at;

-- 4. Kebutuhan Rutin Demo (8 Potong Pakaian Anak Ukuran 7-8)
insert into public.needs (id, organization_id, point_id, incident_id, title, description, deadline_at, status)
values
  ('88888888-8888-8888-8888-888888888888', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', null, 'Pakaian Harian Anak Asuh Panti', 'Dibutuhkan pakaian santai dan bersih untuk anak usia sekolah dasar.', now() + interval '7 days', 'open')
on conflict (id) do update set 
  title = excluded.title, 
  description = excluded.description, 
  deadline_at = excluded.deadline_at, 
  status = excluded.status;

insert into public.need_items (id, need_id, category, size_code, age_group, requested_qty)
values
  ('88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888888', 'Kaos / Atasan', '7-8', 'anak', 8)
on conflict (id) do update set 
  category = excluded.category, 
  size_code = excluded.size_code, 
  age_group = excluded.age_group, 
  requested_qty = excluded.requested_qty;

-- 5. Kebutuhan Darurat Bencana Demo (10 Potong Pakaian Anak Ukuran 7-8)
insert into public.needs (id, organization_id, point_id, incident_id, title, description, deadline_at, status)
values
  ('77777777-7777-7777-7777-777777777777', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '99999999-9999-9999-9999-999999999999', 'Darurat: Sandang Hangat Pengungsi Anak', 'Bantuan darurat pakaian kering dan bersih untuk anak-anak terdampak banjir luapan sungai.', now() + interval '3 days', 'open')
on conflict (id) do update set 
  title = excluded.title, 
  description = excluded.description, 
  deadline_at = excluded.deadline_at, 
  status = excluded.status;

insert into public.need_items (id, need_id, category, size_code, age_group, requested_qty)
values
  ('77777777-7777-7777-7777-777777777701', '77777777-7777-7777-7777-777777777777', 'Kaos / Atasan', '7-8', 'anak', 10)
on conflict (id) do update set 
  category = excluded.category, 
  size_code = excluded.size_code, 
  age_group = excluded.age_group, 
  requested_qty = excluded.requested_qty;
