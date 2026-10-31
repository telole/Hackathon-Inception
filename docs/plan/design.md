# Desain Produk PakaianKita

Versi 1.0 · 30 Oktober 2026 · Rancangan UI dan UX untuk Flutter

## 1. Tujuan pengalaman pengguna

Donatur dapat menjawab tiga hal dalam beberapa detik: pakaian apa yang diperlukan, bagaimana menyerahkannya, dan apakah pakaian telah diterima. Relawan dapat melihat tugas berikutnya dan menilai pakaian tanpa mencari data di banyak halaman. Mitra dapat mengontrol kebutuhan, stok, dan penerimaan.

Pengalaman demo utama: kebutuhan terverifikasi → donasi → penyerahan → kurasi → alokasi → pengiriman → penerimaan. Mode Bencana menunjukkan kemampuan memanfaatkan stok yang sudah tersedia. Hindari menjanjikan peta pergerakan kurir langsung; pelacakan MVP berupa perubahan status dan waktu kejadian.

## 2. Identitas dan arah visual

Karakter: hangat, dapat dipercaya, praktis, dan dekat dengan aktivitas gotong royong. Gunakan latar putih hangat, hijau tua sebagai aksi utama, dan aksen terakota untuk darurat. Foto berfokus pada pakaian serta aktivitas relawan dengan persetujuan; jangan memakai foto korban sebagai dekorasi.

Nama di seluruh layar adalah **PakaianKita**. Istilah utama: Donatur, Sahabat Sandang, Mitra, Titik Kumpul, Kebutuhan, Donasi, dan Kurasi. Gunakan “potong” untuk kuantitas. “Dialokasikan” berbeda dari “Diterima”.

### Token warna

| Token | Nilai | Penggunaan |
|---|---|---|
| primary | #145A46 | Tombol utama dan navigasi aktif |
| onPrimary | #FFFFFF | Teks di atas primary |
| primaryContainer | #E4F2EA | Latar ikon dan ringkasan biasa |
| background | #FAFAF7 | Latar halaman |
| surface | #FFFFFF | Form, kartu, bottom sheet |
| textPrimary | #172D25 | Judul dan isi |
| textSecondary | #4B6157 | Keterangan |
| outline | #D8E0DA | Pemisah nonteks |
| emergency | #A33120 | Tombol/banner darurat, bersama label |
| emergencyContainer | #FFF0EA | Latar kebutuhan darurat |
| warning | #765000 | Teks perlu perhatian |
| warningContainer | #FFF4CF | Latar peringatan |
| error | #B3261E | Kesalahan validasi |
| success | #16603B | Penerimaan terkonfirmasi |

Nilai ini adalah spesifikasi awal. Periksa kontras teks normal minimal 4,5:1 serta teks besar 3:1 ketika tema Flutter diimplementasikan. Border pucat tidak menjadi satu-satunya penanda input aktif atau kesalahan.

### Tipografi dan ukuran

Gunakan Inter yang dibundel sebagai aset dengan lisensi yang sesuai; fallback sans-serif sistem. Tidak perlu mengunduh font saat demo.

- Display 28/36, semibold untuk judul beranda.
- Title large 24/32, semibold untuk judul layar.
- Title medium 18/26, semibold untuk bagian.
- Body 16/24, regular untuk isi dan input.
- Label 14/20, medium untuk tombol dan status.
- Caption 12/18 untuk waktu; informasi penting tidak hanya memakai caption.

Ukuran dalam logical pixel Flutter. Skala jarak: 4, 8, 12, 16, 24, 32, 48. Margin layar 20, jarak kartu 12, padding kartu 16. Radius input/tombol 12 dan kartu 16. Tombol utama tinggi minimal 52; target sentuh minimal 48×48. Elevasi rendah, jangan memakai bayangan berat pada setiap komponen.

## 3. Tata letak dan navigasi

Rancang pada lebar 390 logical pixel dan periksa rentang 360–430. Gunakan SafeArea, konten dapat digulir, dan bottom CTA yang tetap terlihat saat keyboard dibuka. Pada tablet ≥600 gunakan NavigationRail serta lebar konten form maksimal 640. Detail berdampingan hanya jika ruang cukup.

### Donatur

Tab: Beranda, Kebutuhan, Donasiku, Aktivitas, Profil. Tombol “Donasikan pakaian” di beranda dan detail kebutuhan. Layar Donasiku memakai filter Aktif, Selesai, Perlu tindakan.

### Sahabat Sandang

Tab: Ringkasan, Tugas, Kurasi, Aktivitas, Profil. Detail tugas menampilkan alamat privat hanya setelah relawan mendapat penugasan. Riwayat tugas tetap terlihat tanpa mempertahankan akses alamat lengkap setelah tugas selesai.

### Mitra penerima

Tab: Ringkasan, Kebutuhan, Stok, Penerimaan, Profil. Aksi “Buat kebutuhan” berada di kebutuhan; “Ajukan Mode Bencana” di ringkasan. Mitra pengelola beberapa titik memilih titik aktif dengan dropdown.

Admin membuka menu Operasional dari profil, dengan antrean verifikasi dan pengesahan bencana. Memilih peran di UI hanya mengganti konteks; izin tetap diperiksa server. Pengguna yang memiliki beberapa peran dapat berpindah peran terverifikasi lewat profil.

## 4. Komponen yang harus konsisten

| Komponen Flutter usulan | Isi dan perilaku |
|---|---|
| NeedCard | Nama kebutuhan, badge terverifikasi, jenis/ukuran, titik, tenggat, diterima/target, alokasi terpisah, CTA detail |
| EmergencyBanner | Ikon peringatan, label simulasi bila demo, wilayah, masa aktif, CTA lihat kebutuhan |
| DonationSummary | Kode, jumlah diajukan, layak, disalurkan, status ringkas |
| QuantityField | Angka bulat positif, satuan potong, tombol +/− dengan label aksesibel |
| SizePicker | Kategori ukuran terkontrol; jangan mencampur ukuran anak dan dewasa |
| QualityChecklist | Bersih, utuh, tidak robek; wajib dicentang sebelum kirim |
| PhotoUploader | Thumbnail, hapus sebelum dikirim, progress upload, coba lagi per file |
| MatchReason | “Jenis dan ukuran sesuai · 2,4 km dari titik kumpul”; jarak contoh hanya pada seed |
| TrackingTimeline | Langkah selesai/aktif/bermasalah, waktu, pelaku organisasi; tidak menampilkan data privat |
| TaskCard | Jenis tugas, waktu, jumlah, titik ringkas, tombol detail |
| VerificationBadge | Label terverifikasi; tap menjelaskan verifikasi akun bukan jaminan kualitas semua barang |
| AsyncContent | Loading skeleton, empty state, error beserta retry, dan waktu pembaruan |
| EvidencePanel | Jumlah dikirim, diterima baik, ditolak, belum ditemukan, catatan; konfirmasi terpisah |

Progress utama menghitung `received_good / requested_qty`; alokasi ditampilkan sebagai teks “8 potong dalam proses”, tidak digabung sebagai barang diterima. Hindari progress persentase yang melebihi 100%.

## 5. Spesifikasi layar

### S01 Masuk dan onboarding

Logo, penjelasan satu kalimat, email, kata sandi, tombol masuk/daftar, dan pemulihan kata sandi. Akun demo dipersiapkan sebelum presentasi. Pendaftaran umum tetap memakai verifikasi email sesuai konfigurasi Supabase. Jangan mematikan keamanan akun produksi untuk mempercepat demo.

Setelah masuk, pengguna melengkapi nama dan memilih tujuan. Donatur langsung memakai fitur; calon relawan/mitra melihat status pengajuan verifikasi. Teks status: “Akunmu sedang diperiksa. Kamu tetap dapat melihat kebutuhan.”

### S02 Beranda donatur

Urutan: salam dan wilayah pilihan → banner darurat bila aktif → CTA donasi → maksimal tiga kebutuhan terdekat → aktivitas donasi terbaru → panduan pakaian layak. Tidak menampilkan angka dampak yang berasal dari pengajuan belum diterima.

Wireframe konseptual:

```text
PakaianKita                  [Aktivitas]
Temukan kebutuhan di [Wilayah v]
[Darurat aktif · Lihat kebutuhan >]
Pakaianmu bisa kembali bermanfaat
[ Donasikan pakaian ]
Kebutuhan terdekat             Lihat semua
[Mitra A · Pakaian anak M             ]
[12/20 diterima · 4 dialokasikan      ]
Donasimu [Dalam kurasi · PK-...       ]
[Beranda][Kebutuhan][Donasiku][Aktivitas][Profil]
```

### S03 Papan kebutuhan

Pencarian judul/mitra, chip Rutin/Darurat, filter jenis/ukuran/usia/wilayah. Sorting default darurat aktif yang relevan lalu kedekatan dan tenggat. Filter selalu bisa direset. Jika lokasi ditolak, pengguna memilih wilayah manual.

### S04 Detail kebutuhan

Judul, mitra terverifikasi, jenis/ukuran/kelompok usia, jumlah target, diterima, sisa belum dialokasikan, tenggat, alamat publik titik, jam buka, dan syarat kelayakan. CTA “Penuhi kebutuhan ini”. Kebutuhan penuh/ditutup menampilkan alasan dan tautan kebutuhan lain.

### S05 Wizard donasi

Empat langkah dengan draft lokal:

1. **Pakaian:** kategori, ukuran, kelompok usia, jumlah. Tambah baris untuk variasi; satu baris tidak memuat ukuran campuran.
2. **Foto dan kondisi:** 1–5 foto per donasi sebagai batas MVP usulan, kompres target ≤1 MB/foto, checklist wajib. Ukuran dan MIME divalidasi server juga. AI berjalan setelah upload; pengguna tidak wajib menunggu jika layanan gagal.
3. **Penyerahan:** antar sendiri atau minta jemput, titik/jadwal, alamat privat jika jemput, serta kebutuhan tujuan opsional. Belum ada slot berarti belum ada janji penjemputan.
4. **Tinjau:** ringkasan, panduan kemasan, tujuan yang diusulkan, metode, dan tombol “Ajukan donasi”. Gunakan idempotency key untuk mencegah ketukan ganda.

Sesudah berhasil: kode pelacakan dan CTA “Lihat perjalanan donasi”. Jika salah satu foto gagal unggah, pertahankan draft dan tawarkan coba lagi; jangan membuat donasi baru diam-diam.

### S06 Rekomendasi pencocokan

Daftar kebutuhan yang cocok dengan alasan: kategori, ukuran, jarak antar titik, sisa kebutuhan, prioritas. Tampilkan “Rekomendasi sementara” sebelum kurasi. Konfirmasi tujuan tidak berarti stok langsung diterima penerima. Jika tidak cocok: “Belum ada kebutuhan yang sesuai. Simpan donasi di titik yang tersedia atau ubah pencarian.”

### S07 Detail dan pelacakan donasi

Kode unik, item, jumlah diajukan/layak/diterima, status, timeline, dan langkah berikutnya. Paket campuran menampilkan “8 layak · 2 perlu jalur daur ulang”. Pengiriman sebagian menjadi daftar pengiriman, bukan satu status palsu bahwa semua selesai.

Status yang disederhanakan untuk donatur: Diajukan, Dijadwalkan, Dalam kurasi, Siap disalurkan, Dikirim sebagian/seluruhnya, Diterima sebagian/seluruhnya, Perlu tindakan. Tap detail membuka status operasional.

### S08 Titik kumpul

Toggle Daftar/Peta, wilayah, jam, kapasitas tersisa perkiraan dari catatan pengelola, dan waktu diperbarui. Detail titik memuat alamat publik, keterangan akses, serta CTA pilih titik. Tampilkan “Kapasitas diperbarui pengelola”, bukan kapasitas sensor.

### S09 Daftar dan detail tugas relawan

Pisahkan Ditugaskan, Berjalan, Selesai. Detail berisi tujuan, jadwal, paket, kontak seperlunya, dan tombol Terima tugas/Tolak dengan alasan. Setelah diterima: Mulai → Catat serah terima → Selesaikan langkah. Donatur mengonfirmasi penyerahan dari akunnya; relawan tidak menggantikannya dengan satu ketukan.

### S10 Kurasi fisik

Kode manual sebagai fallback QR, foto awal, item diajukan, hasil AI berlabel saran, input jumlah layak/tidak layak, alasan penolakan, dan catatan kondisi. Jumlah hasil wajib sama dengan jumlah yang diperiksa; sisa belum diperiksa tetap terlihat. Simpan final setelah petugas memeriksa ringkasan. Item yang ditolak masuk rujukan, tidak menambah stok layak.

### S11 Dashboard mitra dan papan kebutuhan

Ringkasan stok tersedia/dipesan/dalam perjalanan, kebutuhan terbuka, dan antrean konfirmasi. Form kebutuhan memuat judul, titik tujuan, baris kategori/ukuran/usia/kuantitas, tenggat, serta konteks rutin/darurat. Tenggat lampau ditolak saat publikasi.

### S12 Stok dan alokasi

Daftar batch menampilkan asal donasi, kategori, ukuran, jumlah fisik, reserved, dan tersedia. Petugas memilih kebutuhan → melihat rekomendasi batch → memasukkan jumlah → meninjau → mengalokasikan. Konflik stok memberi pesan “Stok berubah. Jumlah tersedia sekarang 6 potong” lalu refresh, tanpa menimpa alokasi orang lain.

### S13 Mode Bencana

Mitra mengisi nama kejadian, wilayah, titik penerima, kebutuhan, periode, dan alasan. Admin melihat permintaan pengesahan. Setelah disetujui tampil banner dan urutan prioritas baru. Pengalihan alokasi lama membutuhkan layar perbandingan tujuan asal/baru, jumlah, alasan, dan konfirmasi berwenang. Demo mengutamakan stok bebas agar alur mudah dipahami.

### S14 Penerimaan dan selisih

Tampilkan kuantitas per item dikirim, input diterima baik, ditolak karena kondisi, dan belum ditemukan. Ketiganya harus sama dengan jumlah dikirim. Jika semua baik, tombol “Konfirmasi penerimaan”; jika ada selisih, “Kirim laporan selisih” membuka kasus. Riwayat tidak boleh ditutup sebagai sukses penuh sebelum penyelesaian.

### S15 Aktivitas, dampak, dan profil

Aktivitas berupa notifikasi dalam aplikasi yang menuju objek sesuai izin. Dampak menghitung jumlah diterima baik dan lokasi mitra, dengan label data simulasi pada proyek demo. Profil memuat peran, status verifikasi, pilihan wilayah, akses keluar, serta pengajuan penghapusan akun sebagai alur lanjutan pilot.

## 6. Keadaan sistem dan microcopy

- Loading awal: skeleton stabil; tombol submit menunjukkan progress tanpa menggeser layout.
- Empty state kebutuhan: “Belum ada kebutuhan sesuai filter. Coba wilayah atau ukuran lain.”
- Offline: “Koneksi terputus. Data terakhir diperbarui pukul …”; draft bisa disimpan, konfirmasi stok dinonaktifkan.
- Sesi berakhir: arahkan masuk kembali dan pertahankan draft tanpa foto privat di log.
- Belum terverifikasi: jelaskan tindakan yang menunggu verifikasi dan tampilkan status permohonan.
- AI gagal: “Foto tetap tersimpan. Sahabat Sandang akan memeriksa secara manual.”
- Konflik jumlah: tampilkan kuantitas terbaru dan minta tinjau ulang; jangan retry otomatis dengan jumlah lebih kecil.
- Izin kamera/lokasi ditolak: pemilih galeri dan pilihan wilayah manual.
- Aksi berisiko: dialog menyebut objek dan akibat, misalnya “Alihkan 5 potong dari kebutuhan A ke B?”

## 7. Aksesibilitas dan gerak

Gunakan Semantics untuk badge, tombol ikon, gambar, dan progress. Urutan pembaca layar mengikuti urutan visual. Dukung pembesaran teks 200%, keyboard form yang sesuai, focus error pertama, dan error inline. Status memakai ikon serta teks. Transisi 150–250 ms untuk perubahan layar; hormati preferensi pengurangan animasi. Tidak perlu carousel otomatis atau animasi confetti pada konfirmasi bantuan.

## 8. Inventaris aset dan handoff

Siapkan wordmark sederhana, ikon kategori pakaian, ilustrasi kosong, foto contoh yang boleh digunakan, serta avatar mitra demo. Seluruh aset penting dibundel lokal. Nama komponen dan token di dokumen ini diterapkan di `core/theme` dan `core/widgets`; layar per fitur memakai komponen itu, bukan menyalin styling.

Checklist desain selesai: tiap peran punya layar utama, setiap operasi async punya loading/error/empty, angka stok konsisten, navigasi back tidak menghapus draft, layar darurat berlabel jelas, serta tidak ada alamat privat di kartu publik.
