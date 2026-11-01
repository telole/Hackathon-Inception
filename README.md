# PakaianKita

Aplikasi Flutter + Supabase untuk pengajuan donasi, kurasi fisik, kebutuhan, stok dan penyaluran pakaian.

## APK presentasi

[Unduh APK ARM64](artifacts/apk/PakaianKita-arm64-v8a.apk) (pilih Download / View raw).
[Alur dan akun demo](docs/presentation-demo.md). Password demo dibagikan terpisah kepada tim, bukan disimpan di Git.

## Menjalankan kode

Diperlukan Dart ^3.13.4. Verifikasi memakai Flutter 3.47.7 / Dart 3.13.5; Flutter 3.29.2 belum memenuhi constraint proyek.

```sh
flutter pub get
# Salin env.example.json ke env.json; isi URL dan client publishable/anon key.
flutter run -t lib/main.dart --dart-define-from-file=env.json
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
flutter build apk --release --target-platform android-arm64 --split-per-abi -t lib/main.dart --dart-define-from-file=env.json
```

Jangan memasukkan service-role key ke Flutter. env.json diabaikan Git. lib/main_demo.dart adalah entry point fixture terpisah; APK presentasi menggunakan lib/main.dart.

## Cakupan

- Donatur: program/banner, foto dan pengajuan, draft lokal, revisi, pembatalan, riwayat dan tracking.
- Relawan: tugas, penerimaan fisik, kurasi dan kiriman.
- Mitra: program/banner, stok, reservasi, pengiriman dan penerimaan.
- Admin: review foto/catatan, jadwal, penugasan ulang dan izin.
- Pengajuan relawan/lembaga, dokumen privat, keanggotaan dan titik layanan.
- Notifikasi dalam aplikasi, unread/read, Realtime dan pagination. Tanpa FCM.
- Edit profil dan perubahan password. Pemulihan password/email tidak diaktifkan pada rilis ini.

## Database dan verifikasi

Migration berurutan di supabase/migrations/ adalah kontrak database yang dipakai UI. schema.sql dan [ringkasan backend lama](docs/backend-legacy-overview.md) dipertahankan sebagai referensi historis.

Hasil gabungan: 66 tes lulus, dua pemeriksaan opsional memerlukan konfigurasi/akun uji. Tes HTTP/Storage dan Realtime juga telah dijalankan terhadap Supabase. [Tes lama dengan sumber yang tidak tersedia](test/legacy_unavailable_sources/README.md) dipertahankan sebagai arsip.

## Batas rilis hackathon

Perlu pemeriksaan UX di HP tim. Angka lolos kurasi berbeda dari barang yang diterima penerima akhir; sertifikat/progres dampak belum menjadi bukti penyaluran final. Draft lokal tidak tersinkron antargawai. Konfirmasi email untuk registrasi baru masih mengikuti konfigurasi proyek; akun presentasi sudah dikonfirmasi.

Spesifikasi: [PRD](docs/plan/PRD_PakaianKita_v2.md), [desain](docs/plan/design.md), [arsitektur](docs/plan/architecture.md).
