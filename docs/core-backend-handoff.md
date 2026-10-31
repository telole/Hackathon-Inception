# Backend alur inti: kontrak dan cara menjalankan

## Status

Flutter menyediakan service untuk Auth, draft/item/foto, kebutuhan, penjadwalan, penugasan, kurasi, stok, reservasi, pengiriman dan penerimaan. UI tetap pekerjaan frontend. Gunakan client JWT pengguna; tidak ada service_role di aplikasi.

Perubahan database tambahan sudah diterapkan ke proyek `tiekssrrvsyossageoiu` melalui MCP. Migrasi lama dipertahankan. Versi file sesuai migration history remote; jangan menjalankan ulang SQL migrasi secara manual.

## Service untuk frontend

| Service | Pemakaian |
|---|---|
| AuthService + AuthStateNotifier | Daftar/login/logout, akses role, event sesi, awaiting email confirmation |
| AuthRecoveryService | Kirim ulang konfirmasi, reset password, simpan password setelah recovery link |
| DonationService | Buat draft, tambah item, checklist, kontak privat, submit, riwayat |
| DonationEditorService | Baca detail, edit draft/item, hapus item, upload/hapus foto, signed URL, hapus draft murni, batalkan donasi |
| WorkflowService | Simpan kebutuhan beserta item secara atomik, publish/pause/close/fulfilled, hapus kebutuhan tanpa dependensi, konfirmasi jadwal, assign/reassign pickup/curation, daftar operasional |
| OrganizationService | Admin mengelola organisasi, verifikasi, anggota, titik dan daftar profil |
| LogisticsService | Respond task, penerimaan fisik, kurasi, reserve, create shipment, dispatch, confirm receipt |
| NeedsService | Baca kebutuhan aktif dengan filter pada server dan pagination |

`NeedItem.id=''` berarti item baru saat saveNeed; gunakan ID aktual untuk edit. Seluruh daftar item yang dipertahankan harus dikirim. Penghapusan item beralokasi ditolak FK; pengubahan varian atau penyusutan di bawah komitmen ditolak guard. Seluruh saveNeed rollback jika satu item gagal. `setNeedStatus('fulfilled')` memerlukan jumlah penerimaan baik yang mencukupi.

Gunakan `PageRequest(offset:0,size:30)`, lalu offset berikutnya +size, maksimal size=100. Daftar dapat berubah di antara request; lakukan refresh saat mutasi. Pencarian varian difilter sebelum pagination di NeedsService. Query stok/tugas lama tetap tersedia; gunakan daftar operasional WorkflowService untuk halaman pengelola.

## Upload foto privat

1. Panggil `DonationEditorService.uploadPhoto(donationId, bytes)`. Client memeriksa batas 1 MB dan signature JPEG/PNG/WebP; Storage tetap memvalidasi policy/MIME/ukuran.
2. Service mengunggah objek ke `{user_uuid}/{donation_uuid}/{photo_uuid}.ext`, lalu mendaftarkan baris foto dengan UUID yang sama. Trigger database menolak objek yang belum ada dan foto keenam.
3. Jika muncul `PhotoRegistrationPending`, persist `exception.photo` (id, donationId, storagePath). Retry `registerPhoto(receipt)`; jangan upload ulang atau hapus objek pada timeout yang statusnya belum diketahui. Recovery perlu dipanggil frontend setelah koneksi pulih.
4. Tampilkan foto melalui signed URL singkat; bucket tetap privat. Jangan simpan signed URL sebagai storage_path.
5. Penghapusan Storage dan database adalah dua request. Jika terputus, retry penghapusan sebelum submit. Objek yang belum terdaftar dapat tersisa; daftar path pending perlu dipertahankan aplikasi untuk rekonsiliasi.

Draft murni boleh dihapus setelah foto dibersihkan. Donasi yang sudah diajukan/direvisi/dijadwalkan dibatalkan lewat `cancelDonation`; riwayat tidak dihapus. Pembatalan setelah barang diterima fisik ditolak.

## Urutan demo

1. Daftarkan akun `admin@gmail.com` yang dipilih pemilik, verifikasi email. Jalankan `supabase/bootstrap_admin.sql` melalui SQL Editor pemilik proyek. Script menolak akun yang belum terkonfirmasi dan tidak menyediakan endpoint bootstrap publik.
2. `supabase/seed_demo.sql` sudah dijalankan: dua organisasi/titik dan satu kebutuhan berlabel DEMO. Script dapat dijalankan ulang tanpa menambah duplikat pada penggunaan berurutan. Tidak membuat akun/password atau mengaku sebagai organisasi nyata.
3. Daftarkan akun Donatur, Relawan, Mitra. Admin memberi role melalui admin_set_role dan mengaktifkan keanggotaan Mitra pada organisasi yang tepat. Untuk demo sederhana, satu Mitra dapat menjadi anggota kedua organisasi.
4. Donatur membuat draft, menambahkan item `kaos/M/anak`, upload foto, isi checklist dan kontak, lalu submit.
5. Admin/pengelola titik memakai scheduleDonation; assignTask untuk pickup/curation. Pengelola mencatat kedatangan fisik lewat advanceDonation('received').
6. Relawan menerima tugas dan recordInspection. Backend menciptakan stok layak dan rujukan pakaian ditolak.
7. Pengelola sumber melakukan reserveAllocation dengan UUID request yang sama untuk retry, lalu createShipment(alokasi,relawan). Relawan assigned/pengelola sumber memberangkatkan dengan dispatchShipment.
8. Mitra tujuan confirmReceipt. Total baik+ditolak+kurang harus sama dengan jumlah kiriman. Retry identik tidak menggandakan stok/penerimaan. Donatur membaca timeline sendiri.

## Supabase Auth yang memerlukan konfigurasi akun

Allow-list redirect `com.resandang.resandang://auth-callback` di Auth URL Configuration. Callback sudah didaftarkan pada Android/iOS dan dipakai signup/recovery service. SDK Supabase menangani link; frontend perlu menampilkan layar recovery saat passwordRecovery. Daftar, verifikasi email, password recovery dan perpindahan aplikasi perlu diuji pada perangkat.

Custom SMTP memerlukan kredensial penyedia email. Kredensial tersebut tidak tersedia dalam repo atau sesi ini; konfigurasi SMTP dan pengiriman email sungguhan belum diverifikasi. Jangan mematikan verifikasi atau membuat password bersama untuk menyamarkan kekurangan ini.

## Verifikasi dan batas

- Unit tests lama dan tambahan dijalankan lewat Flutter SDK lokal.
- `core_workflow_http_test.dart` menggunakan SDK Supabase asli dengan HTTP transport uji; memeriksa event login, payload RPC, upload multipart privat, dan retry pendaftaran foto. Ini bukan pengiriman email/objek ke server produksi.
- `supabase/tests/core_workflow.sql` dijalankan pada database Supabase nyata dengan empat role. Membuat fixture termasuk metadata Storage dalam transaksi, menguji submit sampai receipt/fulfilled, kemudian rollback. Tidak menghasilkan file Storage sungguhan atau akun demo permanen.
- `supabase/tests/rbac_flow.sql` juga dijalankan kembali. Test SQL bukan simulasi beban concurrency penuh.
- Periksa Security Advisor setelah migrasi. Hasil bersih bukan bukti semua alur telah diuji pengguna.

Penyelesaian sengketa/retur fisik, pembatalan reservasi sesudah alokasi, push, AI dan laporan dampak penuh tetap di luar implementasi alur inti ini. Kiriman bermasalah tetap disputed; jangan membuka update counter stok dari client untuk menyelesaikannya. UI 20 layar belum terintegrasi.

## Referensi

- https://supabase.com/docs/reference/dart/auth-onauthstatechange
- https://supabase.com/docs/guides/auth/native-mobile-deep-linking
- https://supabase.com/docs/guides/auth/auth-smtp
