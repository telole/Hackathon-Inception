# Rencana Pembangunan dan Demo Hackathon

Versi 1.0 · 30 Oktober 2026

## 1. Tujuan demonstrasi

Tunjukkan bahwa donasi mengikuti kebutuhan nyata, kualitas diperiksa sebelum penyaluran, dan penerimaan dapat dibuktikan. Mode Bencana memperlihatkan pemanfaatan stok yang sudah terkurasi. UI menarik mendukung cerita ini; bukti utamanya adalah perubahan data yang konsisten di tiga peran.

Tidak ada rincian durasi atau rubric resmi lomba dalam berkas yang digunakan. Rencana 48 jam, tiga orang, serta demo lima menit berikut merupakan asumsi kerja yang dapat disesuaikan setelah aturan penyelenggara tersedia.

## 2. Prioritas pengerjaan

### P0 Wajib sebelum demo utama

Auth dan akun demo per peran; papan kebutuhan/detail; draft donasi dengan upload/checklist; review dan penyerahan; kurasi 10 menjadi 8 layak + 2 rujukan; batch stok; reserve; pengiriman; konfirmasi penerimaan; timeline dan dampak. RLS, authorization RPC, dan transaksi jumlah termasuk P0 agar demo menunjukkan sistem yang nyata.

### P1 Pembeda hackathon

Mode Bencana dengan admin approval dan stok terdekat; matching berbasis aturan dengan alasan; Realtime terbatas; penerimaan selisih; daftar/peta titik. Untuk cerita demo, Mode Bencana diprioritaskan setelah alur rutin berhasil dan sebelum polishing tambahan.

### P2 Sesudah alur stabil

AI provider nyata setelah validasi vision, QR scan, push notification, survei pra/pasca, perluasan iOS, dan otomasi slot kapasitas. AI manual fallback wajib tetap tersedia. Proposal tetap menyebut AI sebagai arah pengembangan; presenter menyatakan dengan jelas jika integrasi belum aktif.

## 3. Pembagian pekerjaan tim

- **Anggota A — Flutter dan UX:** tema, auth shell, papan kebutuhan, wizard donasi, timeline, error/empty/offline. Mengacu design.md dan typed DTO.
- **Anggota B — Supabase dan integritas:** migrasi, RLS, RPC, Storage policy, katalog, seed, dan kontrak API. Menjaga invariants saldo serta hak akses.
- **Anggota C — Operasional dan demo:** layar relawan/mitra/admin, Mode Bencana, integrasi matching, skenario end-to-end, aset dan materi presentasi. Integrasi AI setelah alur inti siap.

Pembagian ini adalah saran kerja untuk tim proposal, bukan penugasan atau pesan yang telah dikirim ke anggota. Sepakati nama operasi dan DTO terlebih dahulu agar Flutter dan SQL bisa dikerjakan bersamaan.

## 4. Jadwal asumsi 24 jam

<!-- - **Jam 0–2:** sepakati scope P0, diagram data, layar utama, katalog ukuran, branch, dan kontrak API.
- **Jam 3–10:** bootstrap Flutter/Supabase, auth, schema, policy dasar, seed; layout kebutuhan dan wizard.
- **Jam 10–20:** submit donasi, upload, penyerahan, kurasi, batch, serta akses lintas akun.
- **Jam 20–30:** reserve, shipment, dispatch, receipt, ledger dan timeline; selesaikan satu alur nyata.
- **Jam 30–36:** Mode Bencana, matching, skenario selisih, Realtime opsional, AI hanya bila tidak menghambat.
- **Jam 36–42:** pemeriksaan integrasi, race condition, duplicate request, error handling, tampilan perangkat demo.
- **Jam 42–46:** freeze fitur, build APK, seed ulang terkontrol, latihan presentasi/video sesuai aturan lomba.
- **Jam 46–48:** perbaikan kritis saja, salin artefak final, persiapkan cadangan video/demo.

Jika waktu lebih pendek, kurangi QR, peta, dan AI terlebih dahulu. Tetap pertahankan cerita tiga peran dan konfirmasi penerimaan yang nyata. Jangan menghapus pembatasan akses demi mengejar demo. -->

## 5. Data demo sintetis

Semua nama titik, organisasi, kejadian, dan angka di bagian ini adalah contoh. Jangan menampilkan sebagai mitra resmi atau bencana aktif sebenarnya.

- Satu Donatur Demo, satu Relawan Demo, satu Mitra Sumber Demo, satu Posko Tujuan Demo, satu Admin Demo. Akun menggunakan email yang dikuasai tim dan password disimpan secara aman di luar repo/dokumen.
- Titik Kumpul Demo A memiliki stok awal terkurasi 12 potong pakaian anak ukuran 7–8, diturunkan dari donasi dan inspection seed yang lengkap.
- Kebutuhan Rutin Demo: 8 potong kategori sama.
- Kebutuhan Darurat Simulasi: 10 potong kategori sama, aktif setelah disahkan.
- Donasi baru: 10 potong, 8 layak, 2 ditolak karena kondisi, berakhir sebagai rujukan menunggu mitra.
- Foto menggunakan aset milik tim atau berlisensi; jangan menggunakan dokumen identitas asli dalam verifikasi demo.

Seed bukan mengisi counter stok tanpa provenance. Buat donation → items → inspection → batch → movement agar laporan dampak dan audit konsisten. Pisahkan dataset latihan dari dataset presentasi sehingga kebutuhan tidak terlanjur penuh saat demo.

## 6. Alur demo lima menit

1. **0:00–0:35 — Masalah dan kebutuhan.** Tampilkan papan kebutuhan dengan jenis/ukuran spesifik. Sebut angka pilot sebagai target proposal, bukan traction nyata.
2. **0:35–1:25 — Donatur.** Pilih kebutuhan rutin, ajukan 10 potong, foto/checklist, metode penyerahan. Tampilkan kode dan belum diterima.
3. **1:25–2:10 — Sahabat Sandang.** Gunakan akun relawan, konfirmasi penyerahan melalui kedua pihak, kurasi 8 layak dan 2 rujukan. Stok layak bertambah 8, bukan 10.
4. **2:10–3:10 — Rutin selesai.** Mitra sumber reserve 8 ke kebutuhan rutin, buat shipment, relawan dispatch, penerima konfirmasi 8 baik. Kebutuhan rutin terpenuhi dan dampak donatur menjadi 8.
5. **3:10–4:20 — Bencana.** Admin mengaktifkan kejadian simulasi. Matching menemukan stok awal 12 di titik A, reserve 10 ke kebutuhan darurat. Tunjukkan prioritas dan alasan kecocokan; tidak harus mengulang semua layar pengiriman.
6. **4:20–5:00 — Bukti dan penutup.** Timeline, pemisahan jumlah teralokasi/diterima, tiga peran, serta roadmap pilot. Jika AI ditampilkan, jelaskan apakah provider nyata atau fixture/manual fallback.

Sisa stok akhir skenario: awal 12 + kurasi 8 − pengiriman rutin 8 = on_hand 12; reserve darurat 10 menghasilkan reserved 10 dan available 2. Dampak terkonfirmasi 8; angka 10 darurat belum dihitung diterima sebelum receipt. Gunakan persamaan ini untuk memastikan presentasi tidak bertentangan dengan database.

## 7. Kasus penerimaan minimum

Checklist ini adalah rencana verifikasi implementasi, bukan hasil pengujian yang sudah dijalankan.

- Donatur A tidak dapat membaca alamat/foto donatur B dengan mengganti UUID.
- Relawan tanpa tugas tidak dapat membaca kontak atau mencatat inspeksi.
- Mitra A tidak dapat mengonfirmasi kiriman untuk Mitra B.
- Pengguna biasa tidak dapat memberi dirinya role admin/volunteer aktif.
- Dua reserve bersamaan pada stok 8 masing-masing 6: hanya satu berhasil, saldo tidak negatif.
- Retry submit/dispatch/receipt dengan key sama tidak menggandakan row atau saldo.
- Key sama dengan payload berbeda menghasilkan conflict.
- Kurasi 8 layak + 2 tidak layak dari 10 membuat stok 8 dan rujukan 2.
- Pengajuan dan alokasi tidak menaikkan angka diterima.
- Receipt good 6 + rejected 1 + missing 1 dari kiriman 8 membuka held_dispute 2.
- Penyelesaian selisih tidak menciptakan stok gudang tanpa barang kembali dan inspeksi.
- Need deadline lewat atau incident berakhir tidak menerima prioritas/reserve baru.
- AI timeout, lokasi ditolak, upload gagal, dan jaringan putus mempunyai jalur UI yang jelas.
- Signed URL/media privat tidak dapat diakses akun yang tidak berizin.
- Layar di perangkat demo tetap terbaca ketika teks diperbesar dan keyboard aktif.

## 8. Risiko dan fallback presentasi

Jika internet bermasalah, tampilkan rekaman alur yang disiapkan sebelumnya dan jelaskan itu rekaman; jangan mengaku melakukan mutasi live. Cache hanya untuk melihat data/draft. Jika peta gagal, gunakan daftar titik. Jika AI gagal, gunakan pemeriksaan manual. Jika scan QR gagal, ketik kode. Simpan APK dan video pada perangkat yang dipakai tim sebelum presentasi.

Reset dataset hanya pada proyek demo dan oleh petugas yang memahami data. Skrip reset tidak ditautkan dari UI umum dan tidak pernah diarahkan ke produksi. Hindari menggunakan service role dalam APK demo.

## 9. Deliverable tim

Source Flutter dan konfigurasi tanpa secret; lockfile; migrations/RLS/RPC; seed sintetis; APK demo; README setup; video sesuai aturan resmi; deck singkat masalah → solusi → demo → arsitektur → target pilot. Sertakan daftar fitur selesai dan fitur roadmap agar klaim proposal tetap akurat.

Paket dokumen saat ini berisi rancangan. Pembuatan aplikasi, SQL executable, build APK, deployment Supabase, dan pengujian sistem merupakan pekerjaan implementasi berikutnya.
