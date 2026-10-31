# Product Requirements Document PakaianKita

**Versi:** 2.0 — penyelarasan proposal  
**Tanggal:** 30 Oktober 2026  
**Status:** Draft kebutuhan untuk implementasi dan validasi pilot  
**Sumber utama:** `draftProposal(2)(1).docx`, folder Downloads  
**Dokumen asal:** `PRD(3).md`, ReSandang versi 1.0.0  
**Platform usulan:** Aplikasi seluler Android dan iOS melalui Flutter, meneruskan pilihan PRD awal. Proposal belum menetapkan platform maupun kerangka kerja aplikasi.

Dokumen ini menerjemahkan draft proposal PakaianKita menjadi kebutuhan produk yang dapat diimplementasikan. Jika terdapat perbedaan dengan PRD awal, arah produk mengikuti proposal. Rincian aturan status, hak akses, data, dan kriteria penerimaan di bawah merupakan turunan desain untuk menjalankan alur proposal; rincian tersebut bukan klaim bahwa seluruh keputusan teknis telah disetujui.

## 1. Ringkasan dan tujuan produk

PakaianKita menghubungkan donatur, relawan Sahabat Sandang, dan penerima untuk memulihkan nilai guna pakaian layak pakai melalui penyaluran rutin serta bantuan kemanusiaan darurat. Penerima meliputi posko bencana, lembaga sosial, dan kelompok rentan. Mitra penerima juga dapat mengelola titik pengumpulan dan penyaluran resmi.

Produk harus memudahkan donatur menemukan kebutuhan nyata, memastikan kelayakan pakaian sebelum penyaluran, mencocokkan donasi dengan permintaan, mengelola logistik relawan, dan menyediakan riwayat yang dapat ditelusuri sampai penerima mengonfirmasi barang. Stok terkurasi di titik kumpul dapat dialihkan saat kebutuhan bencana muncul.

Manfaat lingkungan utama adalah memperpanjang masa guna pakaian. Barang tidak layak dipisahkan untuk jalur daur ulang melalui mitra; sistem tidak menganggap pengalihan tersebut sebagai bukti bahwa barang telah selesai didaur ulang.

## 2. Masalah yang diselesaikan

1. Pakaian yang masih layak menumpuk karena pemilik kesulitan menemukan saluran donasi.
2. Donatur tidak memiliki informasi jenis, ukuran, jumlah, kelompok usia, dan tenggat kebutuhan di lapangan.
3. Donasi tidak terkurasi membebani relawan dan titik bantuan dengan pekerjaan sortir.
4. Pengumpulan rutin dan respons bencana belum terhubung sehingga stok yang tersedia sulit dimobilisasi.
5. Donatur kesulitan memastikan posisi, hasil verifikasi, serta penerimaan donasinya.

Angka latar belakang limbah tekstil dan bencana dalam proposal diperlakukan sebagai klaim sumber proposal. Penyelarasan ini tidak melakukan verifikasi eksternal atas angka atau daftar pustaka tersebut dan tidak menjadikannya hasil pengukuran produk.

## 3. Pengguna dan hak akses

### 3.1 Donatur

Individu, rumah tangga, komunitas, UMKM konveksi, dan usaha thrift yang memiliki pakaian layak pakai. Donatur dapat menelusuri kebutuhan, mengajukan donasi, mengunggah foto dan pemeriksaan mandiri, menerima rekomendasi pencocokan, memilih metode penyerahan, serta mengikuti laporan donasinya.

UMKM konveksi pada proposal berperan sebagai sumber pakaian layak pakai. Peran ini tidak otomatis mencakup layanan pengangkutan limbah perca industri berkarung sebagaimana PRD lama.

### 3.2 Relawan Sahabat Sandang

Relawan terdaftar dari mahasiswa, karang taruna, atau komunitas lokal. Relawan memeriksa kelayakan, mencatat hasil pemeriksaan, menerima tugas penjemputan/pengantaran, dan memperbarui status tugas. Relawan hanya dapat mengakses alamat dan kontak yang diperlukan untuk tugasnya.

### 3.3 Penerima dan pengelola titik kumpul

Posko bencana dan lembaga sosial terverifikasi memublikasikan kebutuhan, mengelola stok serta kapasitas titik kumpul, menerima penyaluran, dan mengonfirmasi barang. Kelompok rentan dapat tercatat sebagai penerima manfaat melalui mitra. Mekanisme akun mandiri bagi penerima individu masih perlu ditetapkan sebelum dibuka untuk publik.

### 3.4 Hak operasional admin

Admin merupakan hak pengelolaan internal, di luar tiga peran utama ekosistem. Sebagai turunan desain, admin memverifikasi mitra/relawan, mengelola titik resmi, menangani sengketa, dan mengawasi aktivasi Mode Bencana. Admin tidak boleh mengubah hasil penyaluran tanpa alasan dan catatan audit.

## 4. Ruang lingkup

### 4.1 Ruang lingkup inti

- Pendaftaran dan verifikasi peran.
- Papan Kebutuhan untuk kebutuhan rutin dan darurat.
- Pengajuan donasi pakaian dengan foto dan daftar periksa.
- Kurasi oleh relawan serta rujukan barang tidak layak ke daur ulang.
- Pencocokan berdasarkan jenis, ukuran, dan lokasi.
- Titik pengumpulan resmi, pencatatan stok, dan penugasan logistik.
- Mode Bencana dengan pengalihan stok terkurasi.
- Kode pelacakan unik, konfirmasi penerimaan, dan laporan jumlah serta lokasi penyaluran.
- Bantuan klasifikasi gambar dengan LLM sesuai arah proposal, setelah kelayakan teknis divalidasi.

### 4.2 Fitur lama yang tidak menjadi komitmen pilot

Donajuna, Donatu sebagai layanan terpisah, donasi sepatu, Eco-Poin, katalog voucher, kalkulator air/karbon, pengangkutan rutin limbah industri, serta sensor kapasitas drop box tidak tercantum sebagai fitur inti proposal. Fitur tersebut dikeluarkan dari kebutuhan pilot. Penambahan kembali memerlukan keputusan ruang lingkup berikutnya.

Panti asuhan tetap dapat menjadi mitra lembaga sosial; sasaran produk diperluas ke posko dan kelompok rentan. Peta berfokus pada titik resmi yang dikelola mitra, bukan mengasumsikan keberadaan jaringan drop box otomatis.

## 5. Kebutuhan fungsional

### FR-01 Pendaftaran dan verifikasi

Sistem mendukung akun Donatur, Relawan, dan Penerima. Mitra penerima dan relawan harus diverifikasi sebelum memublikasikan kebutuhan resmi atau menjalankan tugas. Profil mitra mencatat nama, jenis lembaga/posko, wilayah layanan, kontak penanggung jawab, serta titik yang dikelola. Data pendukung verifikasi tidak dipublikasikan seluruhnya.

**Kriteria penerimaan:** akun belum terverifikasi tidak dapat mengaktifkan kebutuhan resmi; pengguna tidak dapat mengakses fungsi peran lain tanpa hak yang sesuai.

### FR-02 Beranda dan navigasi sesuai peran

Beranda menampilkan kebutuhan rutin, kebutuhan darurat aktif, status donasi/tugas, dan akses titik kumpul. Aksi utama donatur adalah Cari Kebutuhan, Donasikan Pakaian, Titik Kumpul, dan Lacak Donasi. Relawan mendapat daftar tugas dan pemeriksaan; penerima mendapat pengelolaan kebutuhan, stok, dan penerimaan.

Navigasi usulan donatur: Beranda, Kebutuhan, Donasiku, Aktivitas, Profil. Label serta susunan layar merupakan usulan implementasi, bukan desain UI yang telah disahkan proposal.

**Kriteria penerimaan:** setiap peran dapat menemukan aksi utamanya; kebutuhan darurat terlihat jelas tanpa membocorkan data pribadi penerima manfaat.

### FR-03 Papan Kebutuhan

Penerima memublikasikan jenis pakaian, ukuran, jumlah, kelompok usia, batas waktu, titik tujuan, dan tingkat prioritas rutin/darurat. Kebutuhan dapat dibuka, dihentikan sementara, dipenuhi, ditutup, atau kedaluwarsa. Donatur dapat memfilter berdasarkan jenis, ukuran, lokasi, dan prioritas.

Tampilkan jumlah dibutuhkan, jumlah yang telah dialokasikan, dan jumlah diterima secara terpisah. Pengajuan donatur belum dihitung sebagai penerimaan barang.

**Kriteria penerimaan:** kebutuhan tanpa data wajib ditolak; kebutuhan ditutup/kedaluwarsa tidak menerima alokasi baru; angka diterima bertambah setelah konfirmasi barang.

### FR-04 Pengajuan donasi dan pemeriksaan mandiri

Donatur mencatat jenis pakaian, ukuran, jumlah potong, kelompok usia, kondisi, lokasi asal, foto, serta pilihan antar sendiri atau dijemput. Donatur wajib mencentang bahwa pakaian bersih, utuh, dan tidak robek. Foto menjadi bahan pemeriksaan awal, bukan pengganti pemeriksaan fisik.

Donasi dapat diajukan untuk kebutuhan tertentu atau untuk rekomendasi sistem/titik kumpul yang masih memiliki kapasitas. Jika belum ada kecocokan, tampilkan status menunggu dan pilihan yang benar-benar tersedia.

**Kriteria penerimaan:** pengajuan tanpa foto atau daftar periksa belum lengkap tidak dikirim ke tahap verifikasi; setiap pengajuan tersimpan memperoleh identitas unik.

### FR-05 Kurasi kelayakan oleh relawan

Relawan memeriksa foto dan data sebelum penugasan logistik disetujui. Pemeriksaan fisik dicatat pada saat pengambilan atau penerimaan di titik kumpul, sebelum barang masuk stok layak kirim. Hasil per item/batch meliputi jumlah layak, jumlah tidak layak, alasan, pemeriksa, dan waktu.

Jika satu paket bercampur, pisahkan jumlah layak dan tidak layak. Barang tidak layak diarahkan ke mitra daur ulang dan tidak diteruskan ke posko bantuan sebagai donasi sandang.

**Kriteria penerimaan:** barang yang belum lolos pemeriksaan fisik tidak dapat berstatus siap salur; hasil penolakan menampilkan alasan kepada donatur; paket campuran tidak dihitung seluruhnya layak.

### FR-06 Bantuan klasifikasi gambar

Proposal menyebut LLM/DeepSeek API untuk klasifikasi gambar dan verifikasi kelayakan. Implementasi perlu terlebih dahulu memastikan model serta endpoint yang dipilih menerima masukan gambar dan dapat digunakan untuk tugas ini. Nama penyedia dalam proposal belum membuktikan kemampuan teknis atau akurasi model tertentu.

Sebagai aturan implementasi, hasil AI berupa saran kategori/kondisi untuk ditinjau relawan. AI tidak menyelesaikan verifikasi fisik. Simpan versi model, waktu analisis, hasil saran, dan koreksi relawan. Jika layanan gagal atau gambar tidak dapat dinilai, lanjutkan pemeriksaan manual dan tampilkan statusnya.

**Kriteria penerimaan:** kegagalan AI tidak memblokir pengajuan; relawan dapat mengoreksi hasil; keluaran model tidak langsung mengubah stok menjadi layak kirim. Kredensial layanan hanya disimpan pada server.

### FR-07 Pencocokan otomatis

Sistem menyaring berdasarkan jenis dan ukuran, lalu mempertimbangkan lokasi, jumlah yang masih dibutuhkan, tenggat, dan prioritas kebutuhan aktif. Usia digunakan untuk membantu konsistensi kategori bila tersedia. Gunakan aturan deterministik pada pilot; proposal tidak mensyaratkan model pembelajaran mesin untuk pencocokan.

Rekomendasi menjelaskan alasan kecocokan. Donasi yang belum diverifikasi dapat memperoleh rekomendasi sementara, tetapi alokasi pengiriman hanya memakai stok layak yang tersedia. Donatur/mitra mengonfirmasi tujuan sesuai alur yang berlaku.

**Kriteria penerimaan:** stok sama tidak dapat dialokasikan dua kali; kebutuhan yang sudah penuh tidak menerima alokasi tambahan; jika tidak cocok, sistem tidak memaksakan ukuran/jenis yang salah.

### FR-08 Titik pengumpulan dan stok

Peta menampilkan titik resmi terverifikasi beserta alamat, koordinat, jam operasional, kontak operasional, dan kapasitas yang diperbarui pengelola. Sediakan tampilan daftar jika izin lokasi ditolak. Stok mencatat jenis, ukuran, kelompok usia, jumlah, asal donasi, hasil kurasi, lokasi penyimpanan, dan jumlah tersedia/dialokasikan/disalurkan.

Kapasitas berasal dari pembaruan pengelola; tidak diasumsikan berasal dari sensor. Jadwal penyerahan harus mengikuti jam serta daya tampung mitra.

**Kriteria penerimaan:** titik nonaktif tidak menerima jadwal baru; stok belum dikurasi terpisah dari stok layak; perubahan kuantitas mempunyai alasan dan pelaku.

### FR-09 Penugasan logistik Sahabat Sandang

Sistem membuat tugas pengambilan atau pengiriman dengan titik asal/tujuan, jadwal, jumlah paket/potong, status, dan relawan penanggung jawab. Relawan dapat menerima atau menolak tugas; penolakan/pembatalan mengembalikan tugas ke antrean penugasan. Serah terima dicatat pada setiap perpindahan tanggung jawab.

**Kriteria penerimaan:** tugas hanya ditangani relawan berwenang; tugas tidak dapat selesai tanpa catatan serah terima; keterlambatan dan kegagalan pengambilan memiliki status serta alasan. Biaya logistik belum ditetapkan proposal dan tidak boleh otomatis diasumsikan gratis atau berbayar.

### FR-10 Mode Bencana

Posko terverifikasi mengajukan kebutuhan darurat dan wilayah tujuan. Sebagai kontrol operasional usulan, admin atau penanggung jawab mitra berwenang mengesahkan aktivasi beserta masa berlakunya. Sistem menonjolkan permintaan tersebut dan mencari stok terkurasi di titik terdekat.

Pengalihan stok harus memastikan jenis/ukuran cocok, stok tersedia, kapasitas tujuan cukup, dan pengiriman dapat ditugaskan. Stok yang sudah dialokasikan ke penerima lain tidak dipindahkan diam-diam: perubahan memerlukan keputusan petugas berwenang, alasan, pembaruan alokasi, dan pemberitahuan pihak terdampak.

**Kriteria penerimaan:** pengguna umum tidak dapat mengaktifkan prioritas resmi; alokasi darurat terlacak sampai posko; akhir masa aktif menghentikan prioritas baru tanpa menghapus riwayat.

### FR-11 Pelacakan dan konfirmasi dua arah

Setiap donasi memperoleh kode pelacakan unik. QR merupakan opsi antarmuka dari PRD awal, bukan syarat tersendiri dalam proposal. Riwayat mencatat pengajuan, pemeriksaan, pengambilan/penyerahan, kurasi fisik, alokasi, pengiriman, dan penerimaan.

Donatur mengonfirmasi penyerahan kepada relawan/titik kumpul; penerima mengonfirmasi jumlah dan kondisi saat tiba. Relawan mencatat perpindahan barang. Ketidaksesuaian jumlah/kondisi masuk penanganan selisih dan tidak langsung ditandai selesai. Bukti dapat berupa catatan serah terima serta foto yang tidak mengekspos identitas penerima manfaat tanpa izin.

**Kriteria penerimaan:** pengiriman tidak otomatis menjadi diterima; penerima tidak dapat mengonfirmasi donasi di luar kewenangannya; status selesai mensyaratkan kurasi dan konfirmasi penerimaan yang sesuai.

### FR-12 Laporan dampak dan evaluasi

Donatur dapat melihat jumlah potong yang benar-benar diterima serta lokasi mitra penyaluran. Pengelola dapat merekap per periode: pengajuan, hasil kurasi, penyaluran, rujukan daur ulang, waktu proses, dan selisih. Satu potong hanya dihitung sekali sebagai tersalurkan meskipun melewati beberapa titik.

Sistem menyediakan pengumpulan survei sebelum dan sesudah penggunaan untuk menilai pemahaman donasi layak dan tepat sasaran. Estimasi air/karbon dan reward bukan bagian laporan inti proposal.

**Kriteria penerimaan:** laporan memakai kejadian penerimaan terkonfirmasi; klaim rujukan daur ulang dibedakan dari penyelesaian daur ulang; data survei agregat tidak membuka jawaban pribadi.

## 6. Alur dan aturan status

### 6.1 Alur rutin

1. Penerima terverifikasi memublikasikan kebutuhan.
2. Donatur memilih kebutuhan atau mendapat rekomendasi, mengisi data/foto dan daftar periksa.
3. Relawan meninjau data awal dan menyiapkan pengambilan atau penyerahan langsung.
4. Pada pengambilan/titik kumpul, relawan memeriksa fisik serta memisahkan barang tidak layak.
5. Stok layak dicocokkan/dialokasikan untuk kebutuhan yang masih aktif.
6. Relawan mengantar, penerima mengonfirmasi jumlah/kondisi, dan sistem memperbarui laporan.

### 6.2 Alur darurat

Posko memublikasikan kebutuhan prioritas → petugas berwenang mengaktifkan Mode Bencana → sistem mengusulkan stok layak terdekat → petugas mengesahkan alokasi/pengalihan → relawan menjalankan pengiriman → posko mengonfirmasi penerimaan.

### 6.3 Model status usulan

Status donasi: `draft`, `diajukan`, `ditinjau`, `menunggu_penyerahan`, `diterima_titik`, `dikurasi`, `dialokasikan`, `dikirim`, `diterima`, `selesai`. Cabang pengecualian: `perlu_perbaikan_data`, `dibatalkan`, `bermasalah`. Barang tidak layak memiliki hasil kurasi dan alur rujukan sendiri: `menunggu_mitra_daur_ulang`, `diserahkan_ke_mitra`, `selesai_didaur_ulang` hanya jika ada konfirmasi mitra.

Status donasi, tugas logistik, dan stok disimpan terpisah agar satu paket yang dipilah atau dikirim sebagian tetap akurat. Transisi memerlukan pelaku berwenang, waktu, dan syarat sebelumnya. Pembatalan melepaskan reservasi; pengulangan permintaan tidak boleh menggandakan stok atau penerimaan.

## 7. Kebutuhan data minimum

- **Akun dan verifikasi:** identitas akun, peran, status verifikasi, organisasi terkait, kontak privat.
- **Mitra dan titik kumpul:** penanggung jawab, lokasi, jam operasi, kapasitas, status aktif.
- **Kebutuhan:** mitra pemilik, kategori, ukuran, usia, kuantitas, tenggat, prioritas, status.
- **Donasi dan item:** donatur, foto, pemeriksaan mandiri, jumlah per kategori/ukuran, kode unik.
- **Kurasi:** item/batch, pemeriksa, hasil fisik, kuantitas layak/tidak layak, alasan, saran AI bila ada.
- **Stok dan alokasi:** asal item, titik penyimpanan, jumlah tersedia, reservasi, tujuan, riwayat mutasi.
- **Logistik dan serah terima:** tugas, relawan, jadwal, asal/tujuan, konfirmasi pengirim/penerima, selisih.
- **Kejadian bencana:** kebutuhan terkait, wilayah, pengesah, masa aktif, alasan pengalihan.
- **Rujukan daur ulang:** jumlah ditolak, mitra tujuan, status penyerahan dan konfirmasi pengolahan bila tersedia.
- **Audit dan survei:** perubahan penting, pelaku/waktu, respons evaluasi dengan akses terbatas.

## 8. Kebutuhan nonfungsional

1. **Keamanan dan privasi:** komunikasi HTTPS, kontrol akses per peran/organisasi, foto serta dokumen verifikasi melalui akses terbatas. Alamat donatur hanya terlihat bagi petugas yang memerlukan. Log tidak menyimpan kunci API.
2. **Integritas data:** alokasi dan konfirmasi penerimaan diproses atomik; jumlah stok tidak boleh negatif dan penerimaan tidak melebihi jumlah kiriman tanpa penyelesaian selisih.
3. **Konektivitas:** simpan draft serta riwayat yang sudah dimuat secara lokal; pembaruan stok dan penerimaan memerlukan konfirmasi server. Tampilkan data belum tersinkron agar tidak disalahartikan sebagai status terbaru.
4. **Performa:** target usulan halaman utama/papan kebutuhan dapat digunakan dalam 3 detik pada perangkat dan jaringan pilot yang disepakati. Uji pada perangkat nyata sebelum menjadi komitmen layanan; target cold start 2 detik pada PRD lama tidak dianggap terbukti.
5. **Media:** kompres gambar sambil menjaga detail pemeriksaan; batas jumlah/ukuran disetel berdasarkan uji lapangan. Foto gagal unggah dapat dicoba ulang tanpa menduplikasi donasi.
6. **Aksesibilitas:** label dan status mudah dibaca, prioritas tidak hanya dibedakan dengan warna, tampilan daftar tersedia sebagai alternatif peta.
7. **Keandalan operasional:** audit perubahan stok/status, pencadangan, dan jalur pemeriksaan manual saat layanan AI/peta tidak tersedia.

## 9. Arah teknis dan batas keputusan

Flutter, Supabase/PostgreSQL, RLS, serta PostGIS merupakan kandidat dari PRD lama yang dapat diteruskan setelah validasi kebutuhan tim. Proposal tidak menetapkan teknologi tersebut sebagai keputusan final. Pencocokan pilot dapat diimplementasikan dengan filter kategori/ukuran dan pengurutan jarak/prioritas.

Integrasi klasifikasi LLM dipanggil melalui backend. Pemilihan model harus melalui pemeriksaan dukungan gambar, biaya, kebijakan pemrosesan data, dan evaluasi terhadap foto uji yang representatif. Tidak ada klaim akurasi yang ditetapkan sebelum evaluasi. Keputusan kelayakan operasional tetap dicatat oleh relawan.

## 10. Target pilot dan pengukuran

Target berikut berasal dari proposal dan merupakan proyeksi awal, bukan capaian yang telah terjadi.

- **Wilayah:** 2–3 kecamatan di Jawa Tengah; kecamatan dan durasi pilot belum ditentukan.
- **Donatur:** 50–75 rumah tangga dan 15–20 UMKM konveksi/thrift yang mengikuti onboarding.
- **Relawan:** 10–15 Sahabat Sandang aktif; definisi aktif usulan adalah telah terverifikasi dan menyelesaikan minimal satu tugas selama periode pilot.
- **Mitra:** 3–5 lembaga sosial/posko terverifikasi yang bersedia menjadi titik kumpul/penyaluran.
- **Kapasitas:** perkiraan 100–150 potong/hari/titik pada jam sibuk 08.00–11.00 sebagai acuan proposal; perlu diukur terhadap personel, kapasitas simpan, dan permintaan nyata, bukan dipaksakan sebagai volume minimum.
- **Kelayakan di posko:** proposal menargetkan pakaian tidak layak yang menumpuk di posko mencapai 0%. Untuk pengukuran, laporkan jumlah/rasio item tidak layak yang lolos ke posko dan kasus penumpukan; nilai nol adalah sasaran, bukan jaminan.
- **Transparansi:** target proposal 100% pengiriman memiliki kode unik dan riwayat. Ukur pengiriman dengan kode serta rangkaian kejadian wajib lengkap dibagi seluruh pengiriman pada periode yang sama.
- **Kesadaran:** bandingkan skor survei pra/pasca dengan pertanyaan yang sama, jumlah responden, dan tingkat respons. Proposal belum memberi ambang peningkatan numerik.

Target lama 10 ton/6 bulan, pemenuhan wishlist 80% dalam 30 hari, dan CSAT 4,5 tidak diteruskan sebagai komitmen proposal. Tim dapat menetapkan sasaran tambahan setelah baseline pilot tersedia.

## 11. Tahapan implementasi

1. **Pengembangan sistem:** membangun alur tiga peran, papan kebutuhan, kurasi, stok, logistik, pelacakan, dan Mode Bencana; memvalidasi integrasi klasifikasi gambar. Gerbang selesai: alur rutin/darurat dapat dijalankan dari pengajuan hingga konfirmasi tanpa penggandaan stok.
2. **Sosialisasi dan mitra:** onboarding rumah tangga/UMKM, perekrutan relawan, verifikasi mitra, dan penetapan tata kerja titik kumpul. Gerbang selesai: titik, kapasitas, jadwal, serta petugas siap dicatat.
3. **Pilot:** pelaksanaan di 2–3 kecamatan dengan 3–5 mitra; catat kuantitas, waktu proses, kegagalan logistik, dan ketidaksesuaian hasil kurasi.
4. **Evaluasi dan iterasi:** evaluasi kecocokan, kapasitas aktual, kelengkapan pelacakan, dan perubahan pemahaman pengguna. Gunakan hasil untuk memperbaiki proses serta menetapkan target lanjutan.

Proposal belum menetapkan tanggal dan durasi tahap. Jadwal rinci disusun setelah kapasitas tim serta kesiapan mitra diketahui.

## 12. Keputusan yang masih perlu ditetapkan sebelum pilot

- Wilayah tepat, lama pilot, jam operasi, dan kapasitas tiap mitra.
- Dokumen verifikasi mitra/relawan serta aturan akun penerima individu.
- Mitra daur ulang, jenis barang yang diterima, dan bukti penyelesaian pengolahan.
- Penanggung jawab serta aturan otorisasi Mode Bencana dan pengalihan stok.
- Biaya/dukungan transportasi, batas cakupan, dan penanganan tugas gagal.
- Kategori/standar ukuran, pemeriksaan kebersihan, dan penanganan paket campuran.
- Model gambar yang kompatibel, batas biaya, retensi foto, dan pengujian akurasi.
- Platform final serta kebijakan penyimpanan/penghapusan data pribadi.

Keputusan terbuka tersebut tidak menghalangi penyusunan prototipe, tetapi tidak boleh ditampilkan sebagai layanan atau kemitraan yang sudah tersedia.

## 13. Jejak penyelarasan

- **Judul Produk, Tujuan, dan Target Pengguna proposal:** ReSandang diubah menjadi PakaianKita; tiga peran ditetapkan, penerima diperluas dari panti ke posko/lembaga sosial/kelompok rentan.
- **Fitur Inti dan Alur Kerja Sistem:** ditambahkan papan kebutuhan lengkap, kurasi sebelum penyaluran, pencocokan, stok titik kumpul, tugas Sahabat Sandang, Mode Bencana, serta pelacakan dan konfirmasi.
- **Spesifikasi Tools dan Implementasi tahap 1:** kebutuhan klasifikasi gambar LLM dicatat dengan validasi model serta pemeriksaan relawan.
- **Target Hasil dan Indikator Keberhasilan:** KPI lama diganti dengan cakupan dan sasaran pilot proposal, dengan definisi ukur dan batas proyeksi.
- **Fitur PRD lama di luar proposal:** Donajuna/Donatu, sepatu, reward, estimasi karbon/air, dan angkutan limbah industri dikeluarkan dari pilot.
- **Detail operasional tambahan:** status, transaksi stok, privasi, dan kriteria penerimaan ditambahkan sebagai usulan implementasi agar kebutuhan proposal dapat dikerjakan dan diperiksa.

Salinan PRD awal disimpan sebagai `PRD(3)_sebelum_penyesuaian_20261030.md`. Proposal sumber tidak diubah.
