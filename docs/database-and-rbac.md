# PakaianKita Supabase schema aktif

Proyek `pakaiankita`, ref `tiekssrrvsyossageoiu`, Singapura. Diterapkan 31 Oktober 2026. File dalam supabase/migrations mencerminkan dua migrasi remote yang sudah berhasil dijalankan. Jangan menjalankan ulang migrasi yang sama pada proyek ini.

## Role dan UI

Empat nilai app_role: donatur, relawan, mitra, admin. Tiga role pertama berbagi UI User; Admin memakai UI Admin. UI tidak menentukan izin. Fungsi my_access() mengembalikan daftar role milik sesi dan ui=user/admin.

- Donatur: akun baru otomatis mendapat role ini dari trigger signup. Dapat membuat/mengedit/menghapus draft milik sendiri, upload foto privat, mengajukan donasi dan membaca timeline milik sendiri.
- Relawan: role diberikan Admin. Dapat membaca donasi yang ditugaskan, merespons tugas, melakukan kurasi fisik saat tugas kurasi aktif, dispatch shipment yang ditugaskan. Kontak privat hanya untuk tugas accepted/in_progress.
- Mitra: memerlukan role mitra dan organization_members aktif pada organisasi terverifikasi. Mengelola kebutuhan organisasi, membaca stok titiknya, mengalokasikan stok sumbernya, menyiapkan pengiriman, mengonfirmasi penerimaan di titik tujuan.
- Admin: kontrol operasional lintas organisasi; menerbitkan role, mengelola organisasi/anggota/titik/program/tugas, mengesahkan incident, menjalankan operasi stok lewat RPC. Riwayat audit dan constraint tetap berlaku.

Tidak ada role yang diambil dari user_metadata. Metadata signup hanya dipakai untuk nama tampilan. Pengguna tidak mendapat hak Admin dengan mengubah profil atau JWT user_metadata.

## Tabel

20 tabel public: profiles, user_roles, organizations, organization_members, collection_points, incidents, needs, need_items, donations, donation_items, donation_photos, logistics_tasks, inspections, inventory_batches, allocations, shipments, shipment_items, donation_events, notifications, recycling_referrals.

2 tabel private: donation_contacts dan audit_logs. Semua tabel memakai RLS. Akses langsung ke dua tabel private ditolak; fungsi terotorisasi mengelola kontak/audit. Bucket donation-photos privat, maksimal 1 MB/file, JPEG/PNG/WebP, folder `{donor_uuid}/{donation_uuid}/{photo_name}`.

## RPC aplikasi

- my_access(): konteks role dan UI pengguna.
- admin_set_role(p_user,p_role,p_grant): Admin memberi/mencabut role; admin terakhir dilindungi.
- submit_donation(p_id): memvalidasi checklist, item, 1–5 foto Storage dan titik aktif.
- advance_donation(p_id,p_status): Admin/pengelola titik memproses pengajuan hingga received; catat penerimaan fisik dengan benar.
- respond_task(p_id,p_status): relawan assigned menerima/menolak/memperbarui tugas.
- record_inspection(p_item,p_passed,p_rejected,p_reason): satu hasil final per item. Membuat batch layak dan rujukan tidak layak atomik.
- reserve_allocation(p_batch,p_need_item,p_qty,p_key): variant harus sama, kebutuhan aktif, stok cukup, idempotent per actor+request key.
- create_shipment(p_allocation,p_volunteer): satu alokasi per pengiriman pada MVP, assigned_to harus relawan.
- dispatch_shipment(p_id): kurangi stok satu kali.
- confirm_receipt(p_id,p_good,p_rejected,p_missing): satu konfirmasi final per shipment; penerima tujuan berwenang, jumlah wajib sesuai. Retry identik tidak menggandakan hasil.
- save_donation_contact(p_id,p_address,p_name,p_phone), get_donation_contact(p_id): kontak privat dibatasi kepemilikan/penugasan aktif/Admin.
- mark_notification_read(p_id): tandai notifikasi sendiri.

Nama parameter merupakan kontrak aktual. Flutter memanggil public RPC menggunakan JWT pengguna; private functions bukan endpoint Data API. Grant EXECUTE dibatasi. Seluruh fungsi privileged memakai search_path kosong dan auth.uid untuk actor.

## Admin pertama

Saat migrasi selesai belum ada akun Auth, sehingga belum ada assignment Admin nyata. Daftarkan akun melalui aplikasi/Supabase Auth dahulu. Pemilik proyek kemudian menentukan akun mana yang menjadi Admin pertama melalui akses database tepercaya. Tidak ada endpoint bootstrap publik dan tidak ada password contoh. Admin berikutnya dikelola melalui admin_set_role.

## Verifikasi yang sudah dijalankan

supabase/tests/rbac_flow.sql menguji signup Donatur, penolakan eskalasi role dari metadata dan RPC/direct write, isolasi profil/donasi, penolakan kurasi Donatur dan akses relawan tanpa tugas, kurasi 8/2, reserve berulang, penolakan stok berlebih, dispatch berulang, penolakan receipt oleh relawan, receipt berulang oleh Mitra tujuan, stok akhir 2 dan dampak 6.

Semua assertion lulus. Transaksi pengujian diakhiri ROLLBACK, akun simulasi tidak tertinggal. Pemeriksaan akhir auth_users=0, role_assignments=0. Security Advisor setelah migrasi: lints kosong. Ini pengujian SQL database, bukan pengujian UI Flutter atau simulasi beban concurrency penuh.

## Batas MVP

Satu pemeriksaan final per item, satu allocation per shipment, satu receipt final per shipment. Kiriman ditolak/kurang menjadi disputed dan tetap menahan komitmen kebutuhan; penyelesaian sengketa, retur, pembatalan reservasi dan pengalihan ke kebutuhan lain memerlukan migrasi/RPC lanjutan. Jangan update counter stok langsung lewat client.

Pencocokan/rekomendasi otomatis, notifikasi push/Realtime, pengiriman notification otomatis, AI gambar, dan survey belum diimplementasikan oleh migrasi ini. Tabel notifications tersedia untuk integrasi berikutnya. Desain Flutter masih perlu dihubungkan ke schema aktual.

Dokumen ini menjelaskan schema PakaianKita yang sudah diterapkan. PRD.md di root masih menggambarkan ReSandang versi lama; penyelarasan PRD dan integrasi Flutter merupakan pekerjaan terpisah.

