# Integrasi donatur, admin, mitra dan akun

Tanggal: 1 November 2026. Folder: `D:/PakaianKita_Review_Frontend`.
Dokumen ini memperbarui status nomor 2–5 pada task list sebelumnya.
Perubahan tetap lokal di branch `feat/supabase-api-integration`; tidak ada push/commit/PR.

## Fitur yang ditambahkan

### Donatur

- Tombol lanjutkan draft/perbaiki pengajuan membawa ID yang sama ke formulir.
- Data pakaian, titik, checklist, kontak privat dan foto lama dimuat dari Supabase.
- Repository menerima status `draft` dan `needs_revision`, lalu submit ulang melalui RPC yang sudah ada.
- Foto bisa diganti saat revisi; foto baru didaftarkan sebelum metadata lama dihapus. Retry upload menangani objek yang sudah tersimpan.
- Draft formulir dipersistenkan per akun dan per ID revisi menggunakan SharedPreferences. Termasuk foto (maksimal 1 MB) dan isian kontak; data ini disimpan lokal pada perangkat, bukan dianggap transaksi server yang telah berhasil.
- Draft dibersihkan setelah submit berhasil/logout; pembatalan mereset formulir agar tidak memakai ID yang dibatalkan.
- Pembatalan memakai `cancel_donation` hanya sebelum penerimaan fisik.
- Editor saat ini menangani satu item per donasi, sesuai formulir aplikasi. Pengajuan multi-item dari sumber lain ditolak editor dengan pesan, tidak dipangkas menjadi satu item.

### Admin

- Detail review menampilkan foto privat melalui signed URL, checklist, item dan timeline.
- Foto dapat diperbesar dan dimuat ulang bila URL kedaluwarsa.
- Catatan revisi wajib diisi dan disimpan sebagai event yang dapat dibaca donatur.
- RPC `request_donation_revision` memvalidasi admin, status, panjang catatan dan request key. Retry identik tidak menggandakan event; payload berbeda dengan key sama ditolak.
- Daftar tugas dan penugasan ulang menggunakan ID tugas lama melalui `assign_logistics_task`.
- Penugasan ulang dibatasi tahap assigned/declined/cancelled/failed sesuai kontrak server. Tugas yang sudah diterima/dikerjakan tidak dipindahkan diam-diam.

### Mitra

- Daftar program dibatasi lembaga yang dapat dikelola.
- Tambah/edit program dengan beberapa baris kebutuhan, ukuran, usia, target, titik tujuan dan deadline.
- Simpan draft, publikasikan, jeda, tutup dan hapus memakai RPC backend. Program yang punya dependensi tidak dipaksa dihapus; UI menyarankan menutup.
- Upload/ganti/hapus banner melalui bucket privat `program-banners`, validasi JPG/PNG/WebP maksimal 1 MB.
- Nama mitra berasal dari organisasi server. Banner tersimpan ditampilkan pula di daftar/detail program donatur.
- Form publikasi membutuhkan banner dan deadline yang belum lewat. Persyaratan banner ini masih diperiksa di UI; RPC `set_need_status` lama tetap dapat membuka program tanpa banner melalui klien lain.
- Jika upload gagal setelah draft dibuat, ID program dipertahankan untuk retry.

### Akun

- Edit nama/wilayah pada tabel profiles; nama profil dan beranda membaca sumber server yang sama.
- Akses pengaturan dan logout tetap tersedia saat riwayat donasi gagal dimuat.
- Ubah password memakai Supabase Auth.
- Halaman lupa password mengirim permintaan pemulihan dan mendukung verifikasi tautan/kode dari email, lalu penggantian password.
- Email recovery belum diuji pengirimannya karena SMTP belum disiapkan. Aplikasi tidak menyatakan email pasti terkirim. Tautan recovery saat ini dapat disalin dari email ke aplikasi; alur klik tautan langsung/deep link belum dikonfigurasi.

## Perubahan Supabase aktual

- Migration `member_workflows`: kolom `needs.banner_path`, bucket/policy banner privat, validasi referensi banner, dan RPC revisi dengan idempotency.
- Migration `assigned_volunteer_receipt`: relawan yang ditugaskan dan aktif boleh mencatat penerimaan. Relawan tidak mendapat izin penjadwalan atau akses donasi lain.
- Salinan SQL ada di `supabase/migrations` pada folder kerja frontend. Satukan dengan migration backend ketika integrasi Git diminta.

## Bukti pengujian

- Analyzer bersih sebelum pemeriksaan akhir.
- Tes widget/kontrak lokal meliputi isolasi dan persistensi draft, format banner, validasi formulir akun/program, parameter RPC, guard izin, form stok dan navigasi yang sudah ada.
- `supabase/tests/member_workflows.sql`: PASS pada database aktual, meliputi banner, catatan revisi idempoten, edit dan submit ulang, serta seluruh alur stok/pengiriman. Semua fixture SQL di-rollback.
- `supabase/tests/assigned_volunteer_receipt.sql`: PASS; relawan lain ditolak, actor aktif boleh menerima, tidak boleh menjadwalkan, dan retry tidak menggandakan event.
- `tool/live_member_integration.py` diuji melalui HTTP ke proyek aktual dengan empat akun QA sementara: login password semua peran; update profil; buat program; upload banner dan pembacaan signed image oleh donatur; upload foto donasi; submit; revisi idempoten; edit dan resubmit; jadwal; penugasan; penerimaan dan kurasi oleh relawan; alokasi; dispatch; receipt; saldo akhir; pembatalan; ubah password dan login kembali. Semua PASS.
- Akun QA dibuat sebagai fixture terkonfirmasi, sehingga tes ini membuktikan login Auth, bukan alur pendaftaran/email konfirmasi.
- Seluruh file Storage, akun, data bisnis, audit dan kredensial sementara dibersihkan sesudah tes. Pemeriksaan akhir: QA users=0, QA organizations=0, QA banner objects=0.

## Batas yang masih perlu dicoba

- Pemeriksaan visual/interaksi di HP: galeri, keyboard, koneksi terputus dan pemulihan setelah proses aplikasi dihentikan. Tes persistensi lokal tidak menggantikan pemeriksaan proses Android.
- Register akun nyata tim, konfirmasi kebijakan Auth aktual, dan pengiriman email recovery setelah layanan email tersedia.
- Daftar operasional dibatasi 50/100 baris; pagination dan realtime belum ditambahkan.
- Penggantian banner/foto atau penghapusan program dapat meninggalkan object tak terpakai bila pembersihan Storage gagal. UI tidak lagi mereferensikannya; pekerjaan pembersihan orphan belum dibuat.
- APK dari batch sebelumnya belum memuat perubahan dokumen ini. Build berikutnya menggunakan `lib/main.dart --dart-define-from-file=env.json`; build tidak diulang pada batch ini agar pengerjaan lebih cepat.

Jalankan versi kode terbaru melalui `./run-supabase.ps1`. Jangan memasukkan service-role key ke Flutter atau Git.
