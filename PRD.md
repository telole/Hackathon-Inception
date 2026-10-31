# PRODUCT REQUIREMENTS DOCUMENT (PRD)
# Proyek: ReSandang (Mobile App)
**Versi:** 1.0.0  
**Tanggal:** 9 Oktober 2026  
**Status:** Approved for Architecture & Development  
**Platform Target:** Mobile Application (Android & iOS) via Flutter  


---

## 1. Executive Summary & Visi Produk
**ReSandang** adalah platform aplikasi seluler sirkularitas sandang (*circular fashion & textile waste management*) pertama di Indonesia yang mengintegrasikan ekosistem donasi pakaian layak pakai, penyaluran kebutuhan sandang panti asuhan, dan daur ulang limbah kain perca rumah tangga maupun industri tekstil.

### Visi
Mewujudkan Indonesia bebas timbulan sampah sandang di TPA dengan mengubah pakaian yang menumpuk di lemari menjadi berkah bagi mereka yang membutuhkan, serta mendaur ulang serat kain yang rusak menjadi sumber daya bernilai guna.

### Nilai Utama (Core Values)
1. **Mudah & Cepat (Frictionless):** Ibu rumah tangga dan masyarakat dapat menyalurkan pakaian tanpa ribet dengan opsi penjemputan dari rumah atau drop-box terdekat.
2. **Tepat Sasaran (Needs-Driven):** Panti asuhan dan lembaga sosial tidak lagi menerima baju tak layak atau ukuran yang salah, melainkan menerima sandang sesuai kebutuhan riil anak-anak.
3. **Sirkular Penuh (Zero Waste):** Pakaian layak pakai didonasikan (Donajuna & Donatu), sedangkan pakaian rusak parah dan sisa kain industri didaur ulang.
4. **Terbuka & Akuntabel (Transparency):** Donatur dapat melacak perjalanan pakaiannya secara real-time hingga foto serah terima di panti asuhan.

---

## 2. Problem Statement
1. **Timbulan Sampah Sandang Meningkat:** Tren *fast fashion* menyebabkan konsumsi pakaian melonjak. Di Indonesia, ribuan ton pakaian bekas berakhir di TPA setiap tahun karena minimnya fasilitas pemilahan tekstil rumah tangga.
2. **Donasi yang Tidak Tepat Sasaran:** Banyak warga mendonasikan pakaian secara acak ke panti asuhan atau posko bencana sehingga pakaian sering menumpuk tidak terpakai karena ukuran atau jenisnya tidak sesuai kebutuhan anak panti.
3. **Limbah Konveksi & Perca Terbuang:** Usaha konveksi dan pabrik tekstil kesulitan membuang sisa potongan kain (*perca*) secara ramah lingkungan dan sering membakarnya.
4. **Hambatan Logistik Donatur:** Ibu rumah tangga sering berniat membersihkan lemari pakaian (*decluttering*), namun enggan mendonasikan karena tidak memiliki waktu mengantarkannya ke yayasan.

---

## 3. Target User Personas

### Persona 1: Ibu Rina (38 Tahun) - Ibu Rumah Tangga & Donatur Aktif
* **Perilaku:** Rutin menyortir lemari anak-anaknya yang cepat tumbuh besar setiap 6 bulan. Memiliki banyak baju dan sepatu yang masih sangat bagus.
* **Kebutuhan:** Ingin pakaian anaknya bermanfaat bagi anak panti tanpa harus repot mencari panti asuhan dan mengantar sendiri ke lokasi.
* **Fitur Utama:** Donajuna, Donatu, Penjemputan ke Rumah, Pelacakan Status Donasi.

### Persona 2: Ustadz Ahmad (45 Tahun) - Pengurus Panti Asuhan
* **Perilaku:** Mengasuh 40 anak usia SD hingga SMA. Kerap kekurangan seragam sekolah, pakaian dalam baru, dan baju harian yang pas.
* **Kebutuhan:** Membutuhkan wadah resmi untuk mempublikasikan daftar kebutuhan sandang yang spesifik (misal: butuh 20 stel seragam pramuka ukuran SMP).
* **Fitur Utama:** Dashboard Mitra Panti, Buat Wishlist Kebutuhan, Verifikasi & Konfirmasi Serah Terima.

### Persona 3: Pak Budi (42 Tahun) - Pemilik Usaha Konveksi & Garmen
* **Perilaku:** Menghasilkan 50–200 kg kain perca sisa pemotongan pola setiap minggu.
* **Kebutuhan:** Memerlukan jasa penjemputan limbah kain secara rutin agar tidak memenuhi gudang workshop dan tidak mencemari lingkungan.
* **Fitur Utama:** Form Setor Limbah Tekstil (B2B), Penjadwalan Armada Angkut Karungan.

### Persona 4: Tim Logistik & Admin ReSandang
* **Perilaku:** Mengelola gudang sortir, armada kurir penjemputan, dan distribusi ke panti mitra.
* **Kebutuhan:** Manajemen data donasi, verifikasi drop point boks, pelacakan barcode/QR donasi.

---

## 4. Fitur Utama & Kebutuhan Fungsional (Functional Requirements)

### 4.1. Dashboard Utama (Sesuai Referensi Gambar UI)
* **FR-01: Top App Bar:** Menampilkan identitas logo ReSandang, search bar pencarian dinamis (pencarian panti asuhan, jenis pakaian, atau lokasi drop point), dan ikon tas/keranjang donasi saya.
* **FR-02: Hero Banner Carousel:** Slider gambar edukasi, kampanye darurat sandang panti, dan tips memilih pakaian layak. Dilengkapi dot indicator aktif.
* **FR-03: Quick Action Grid (2 Baris):** Tombol aksi cepat dengan ikon tematik:
  1. **Donajuna:** Masuk ke alur donasi baju & celana layak pakai.
  2. **Donatu:** Masuk ke alur donasi sepatu layak pakai.
  3. **Panti Asuhan:** Direktori panti asuhan terverifikasi dan wishlist kebutuhan.
  4. **Setor Limbah:** Formulir daur ulang kain perca & pakaian rusak.
  5. **Drop Point:** Peta lokasi kotak boks pakaian terdekat.
  6. **Jemput Donasi:** Pemesanan kurir jemput pakaian ke rumah.
  7. **Eco-Poin:** Halaman tukar poin reward.
  8. **Semua:** Menu panduan, FAQ, dan informasi regulasi donasi.
* **FR-04: Section Rekomendasi Panti Asuhan:** Menampilkan daftar panti asuhan yang mendesak membutuhkan sandang, lengkap dengan progress bar pencapaian kebutuhan (contoh: *35/50 Seragam Terkumpul*).
* **FR-05: Bottom Navigation Bar:** Navigasi 5 tab utama: Beranda, Donasiku, Eco-Tracker, Aktivitas, Profil.

### 4.2. Fitur "Donajuna" (Donasi Baju & Celana)
* **FR-06: Formulir Wizard Donasi Baju:**
  * Langkah 1: Pilih kategori sandang (Pakaian Anak, Pria Dewasa, Wanita Dewasa, Seragam Sekolah, Pakaian Bayi).
  * Langkah 2: Input estimasi jumlah helai atau berat perkiraan (kantong kresek kecil / besar).
  * Langkah 3: Unggah foto pakaian (maksimal 5 foto per paket donasi).
  * Langkah 4: Pilih tujuan penyaluran: **Otomatis Disalurkan Sistem** ATAU **Pilih Panti Asuhan Spesifik**.
  * Langkah 5: Pilih metode logistik: **Jemput ke Rumah** ATAU **Antar ke Drop Point**.
* **FR-07: Kode QR & Label Paket:** Sistem menghasilkan kode resi unik berformat QR Code yang dapat ditempelkan di kantong donasi untuk pelacakan.

### 4.3. Fitur "Donatu" (Donasi Sepatu)
* **FR-08: Formulir Khusus Sepatu:**
  * Pilihan kategori: Sepatu Sekolah (Hitam polos), Sepatu Olahraga/Kets, Sandal, Sepatu Formal.
  * Pilihan ukuran (EU Size 28 s/d 44).
  * Verifikasi kelayakan (kondisi sol tidak terlepas, tidak robek parah).

### 4.4. Halaman Khusus Panti Asuhan (Kebutuhan & Wishlist)
* **FR-09: Direktori Panti Asuhan Terverifikasi:**
  * Profil panti: foto panti, nama pimpinan, izin dinas sosial, jumlah anak asuh, alamat lengkap, dan koordinat GPS.
* **FR-10: Manajemen Wishlist Kebutuhan (Khusus Akun Panti):**
  * Panti asuhan dapat menambah daftar kebutuhan: jenis pakaian, rentang usia, gender, target kuantitas.
  * Sistem otomatis memperbarui progress bar saat donatur mengarahkan paket ke panti tersebut.
* **FR-11: Konfirmasi Serah Terima:**
  * Pengurus panti mengonfirmasi penerimaan paket via scan QR dan mengunggah 1 foto bukti serah terima yang otomatis terkirim ke donatur sebagai laporan transparansi.

### 4.5. Fitur Setor Limbah Tekstil & Kain Perca (Daur Ulang)
* **FR-12: Formulir Limbah Rumah Tangga & B2B:**
  * Pengguna memilih status pengirim: *Rumah Tangga (1-10 kg)* ATAU *Pabrik / Konveksi (>20 kg - Karungan)*.
  * Jenis serat limbah: Katun, Denim/Jeans, Poliester/Sintetis, Campuran Perca.
  * Penjadwalan tanggal dan jam penjemputan armada logistik ReSandang.

### 4.6. Fitur Peta Drop Point (Drop Box Terdekat)
* **FR-13: Peta Interaktif & Radius Geospasial:**
  * Menampilkan peta dengan pin lokasi boks pengumpulan pakaian terdekat.
  * Menampilkan jarak tempuh, jam operasional boks, foto lokasi fisik boks, dan indikator kapasitas boks (tersedia / penuh).

### 4.7. Gamifikasi: Eco-Tracker & Eco-Poin
* **FR-14: Kalkulator Dampak Lingkungan (Eco-Impact):**
  * Akumulasi total kilogram tekstil yang didonasikan dan didaur ulang.
  * Estimasi penyelamatan air bersih (*Liters of Water Saved*) dan pengurangan jejak karbon (*kg CO2 Reduced*).
* **FR-15: Katalog Reward Eco-Poin:**
  * Poin diperoleh setiap kali donasi terverifikasi oleh tim sortir (misal 1 kg pakaian layak = 100 poin, 1 kg limbah perca = 50 poin).
  * Poin dapat ditukarkan dengan voucher diskon sembako, voucher belanja minimarket, atau merchandise ramah lingkungan.

---

## 5. Kebutuhan Non-Fungsional (Non-Functional Requirements)

1. **Performa:** Waktu pemuatan halaman awal (Cold Start) < 2 detik. Scroll animasi pada dashboard dan katalog panti berjalan mulus di 60 FPS pada perangkat Android mid-range.
2. **Offline Resilience:** Riwayat donasi dan lokasi drop-point yang pernah dimuat disimpan secara lokal menggunakan database lokal perangkat (*caching*).
3. **Kompresi Gambar:** Semua foto yang diambil dari kamera ponsel otomatis dikompresi ke format WebP (< 500 KB) sebelum diunggah ke server storage untuk menghemat kuota donatur.
4. **Keamanan Data:** Enkripsi transmisi data menggunakan TLS 1.3 (HTTPS). Otentikasi sesi menggunakan token JWT aman dan aturan Row Level Security (RLS) di database PostgreSQL Supabase.
5. **Akurasi Geospasial:** Pencarian drop point memanfaatkan query spasial PostGIS untuk menghitung jarak akurat dalam radius kilometer dari koordinat GPS ponsel pengguna.

---

## 6. Metrik Keberhasilan Produk (KPI)
1. **Total Timbulan Tekstil Terselamatkan:** Target 10 ton limbah sandang tersalurkan/didaur ulang dalam 6 bulan pertama.
2. **Rasio Pemenuhan Kebutuhan Panti Asuhan:** > 80% daftar wishlist pakaian panti asuhan terpenuhi dalam waktu kurang dari 30 hari.
3. **Tingkat Kepuasan Donatur (CSAT):** > 4.5/5.0 terhadap kemudahan proses penjemputan dan transparansi laporan foto serah terima.
