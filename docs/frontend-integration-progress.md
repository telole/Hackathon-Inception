# Integrasi frontend — 1 November 2026

Folder kerja: `D:/PakaianKita_Review_Frontend`, branch `feat/supabase-api-integration`.
Perubahan masih lokal. Tidak ada commit, push, PR, atau branch baru.

## Batch terbaru

- Halaman baru: `/operations/schedule`, `/operations/schedule/:id`, `/operations/allocate`, `/operations/shipments/new`.
- Penjadwalan memakai `schedule_donation`; assignment memakai `assign_logistics_task`.
- Reservasi memakai `reserve_allocation` dengan request key yang tetap ketika retry.
- Kiriman dibuat melalui `create_shipment`, dispatch dan receipt memakai RPC aktual.
- Akses memakai `my_access` dan membership aktif pada organisasi terverifikasi.
- Tugas dibaca dari `logistics_tasks`, dibatasi `assigned_to` akun sesi. Kontak diambil terpisah melalui `get_donation_contact` ketika tugas aktif.
- Stok dibaca dari `inventory_batches`; available dihitung on_hand dikurangi reserved untuk tampilan, validasi transaksi tetap di server.
- Join profil/peran menggunakan FK `user_roles_user_id_fkey` agar tidak ambigu dengan granted_by.
- Review mengarah ke detail jadwal. Permintaan revisi memakai `advance_donation`; catatan alasan revisi belum tersedia pada kontrak backend, sehingga form catatan lama dihapus.
- Verifikasi organisasi memakai update yang dilindungi RLS admin; tidak memanggil `approve_verification` yang belum ada.
- Siklus tugas memakai `respond_task`: accepted, declined, in_progress, completed, failed. Tombol selesai ditampilkan setelah penerimaan/kurasi sesuai tugas.
- Relawan dapat membuka kiriman yang ditugaskan. Tombol dispatch/receipt mengikuti titik sumber/tujuan dan actor; RPC tetap memeriksa akses.

## Perubahan database yang benar-benar diterapkan

Proyek Supabase `pakaiankita` / `tiekssrrvsyossageoiu`.
Migration `operational_volunteer_directory`: RPC `list_assignable_volunteers` mengembalikan ID dan display_name relawan kepada admin atau mitra dengan membership terverifikasi aktif. Tidak membuka SELECT semua profil, email, alamat, atau nomor telepon. Salinan migration ada di `supabase/migrations` pada folder kerja ini untuk dipindahkan/disatukan ke backend saat integrasi Git diminta.

## Menjalankan aplikasi terhubung Supabase

`env.json` lokal sudah diisi URL proyek dan client publishable/anon key, diabaikan oleh Git. Tidak berisi service-role key.

```powershell
cd D:/PakaianKita_Review_Frontend
./run-supabase.ps1
```

Script menjalankan `lib/main.dart`, bukan entry point demo. Tambahkan `-d chrome` atau ID perangkat jika perlu.
SDK yang dipakai Flutter 3.47.7 / Dart 3.13.5 dari cache Shorebird. SDK Flutter 3.29.2 milik pengguna dipertahankan; tidak memenuhi constraint Dart proyek saat ini.

## Verifikasi

- Flutter analyzer bersih dan suite 24 tes lulus sebelum pemeriksaan akhir siklus tugas.
- Tes HTTP lokal memeriksa endpoint/parameter Supabase, scope tugas/membership, penghitungan stok, dan propagasi konflik reservasi. Ini bukan pengganti login perangkat ke server nyata.
- Tes `core_workflow.sql` dari backend dijalankan pada database aktual: PASS untuk kebutuhan, ownership, penolakan foto hilang, submit, jadwal, tugas, kurasi, reservasi, dispatch retry, receipt retry, fulfilment, dan saldo stok.
- Tes `supabase/tests/volunteer_directory.sql`: PASS; donor ditolak dan mitra terverifikasi dapat memilih relawan.
- Seluruh fixture SQL di-rollback. Tidak ada akun/data demo permanen yang ditambahkan.
- Akses HTTP anonim ke tabel ditolak 401/42501, sesuai database yang mengharuskan autentikasi.
- APK debug entry point Supabase berhasil dibangun; lokasi standar `build/app/outputs/flutter-apk/app-debug.apk`.

## Masih diperlukan

- Saat pemeriksaan terdapat 0 akun Auth dan 0 profil di proyek aktual. Akun tim perlu register sebelum uji login nyata dan pemberian role; pilihan admin sebelumnya `admin@gmail.com` belum dapat diberi role karena akunnya belum ada.
- Uji lengkap Flutter di perangkat dengan akun donor/admin/relawan/mitra, terutama Auth dan upload Storage melalui HTTP. SQL menguji metadata Storage, bukan upload file HTTP.
- Review foto rinci, alasan revisi tersimpan, reassignment tugas aktif, dan pagination daftar operasional.
- Form program mitra dan pengelolaan banner belum dibuat pada batch ini.
- Edit/pemulihan draft, cancel dari UI donatur, edit profil dan pemulihan password masih belum lengkap.
- Reservasi dibatasi stok dan target pada UI; sisa kebutuhan setelah alokasi lain tetap diputuskan atomik oleh RPC. Konflik server harus ditangani pengguna dengan refresh/pilihan baru.
- Mode demo lama terpisah; fixture empat halaman baru belum dilengkapi. Pengembangan batch ini berfokus pada repository Supabase.

Jangan menyatakan seluruh aplikasi selesai hanya dari tes widget atau keberhasilan build.
