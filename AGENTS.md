# AGENTS.md — PakaianKita (Flutter Frontend)

Panduan kerja untuk agent yang membangun APK PakaianKita. Dokumen ini menggabungkan kontrak handoff, keputusan auth/role terbaru, sistem desain, dan gate verifikasi. Baca sampai habis sebelum menyentuh kode.

Aturan pertama: **ini bukan proyek OOTD, bukan ReSandang baru, dan bukan aplikasi donasi generik.** Produk ini PakaianKita: penyaluran pakaian layak pakai dari donatur ke mitra/posko terverifikasi, dengan relawan dan admin.

---

## 0. Identitas dan sumber kebenaran

| Item | Nilai |
| --- | --- |
| Produk | PakaianKita |
| Repo | `https://github.com/telole/Hackathon-Inception` |
| Folder lokal | `C:\Users\Asus\PakaianKita` |
| Branch saat ini | `main`, commit `3ac7606 first commit: initialize flutter project and prd` |
| Package Dart | `resandang` (jangan diganti tanpa koordinasi) |
| applicationId Android | `com.resandang.resandang` (jangan diganti; mengubahnya memutus OAuth dan data install) |
| Label Android | masih `resandang`; ubah label saja menjadi `PakaianKita` |
| Framework | Flutter 3.47.6 / Dart 3.13.5, Material 3 |
| Backend target | Supabase (sudah diterapkan pemilik backend) |
| Backend tahap ini | **Mock lokal** (keputusan pengguna) |
| Desain | 20 layar di `C:\Users\Asus\PakaianKita_HANDOFF\PakaianKita_Frontend_Handoff\design\` |

Paket handoff hasil ekstrak:

```text
C:\Users\Asus\PakaianKita_HANDOFF\PakaianKita_Frontend_Handoff\
  START_HERE.md
  docs\01_TUGAS_FRONTEND.md
  docs\02_ROLE_DAN_NAVIGASI.md
  docs\03_KONTRAK_DATA_DAN_RPC.md
  docs\04_GIT_DAN_PROMPT_AI.md
  docs\05_DATABASE_AKTUAL.md
  docs\PRD_REFERENSI.md
  mock\frontend_fixture.json
  design\PakaianKita_20_Layar.pdf
  design\01_10_overview.png
  design\11_20_overview.png
```

Baca minimal `START_HERE.md`, `01_TUGAS_FRONTEND.md`, `02_ROLE_DAN_NAVIGASI.md`, dan `03_KONTRAK_DATA_DAN_RPC.md` sebelum coding. Jika berbeda, keputusan di dokumen ini yang dipakai untuk auth/role; untuk database/RPC, `05_DATABASE_AKTUAL.md` yang berlaku.

### Kondisi repo saat ini (jangan ditebak)

- Isi `lib/` hanya `main.dart` berupa counter app Flutter default (122 baris).
- `test/widget_test.dart` masih menguji counter `MyApp`.
- Dependency hanya `cupertino_icons` dan `flutter_lints`. Belum ada Supabase, state management, router, atau font.
- `android/app/build.gradle.kts` memakai debug signing untuk release.
- `android/app/src/main/AndroidManifest.xml` belum punya permission internet/kamera.
- Artinya: fondasi harus dibangun dari nol. Jangan menganggap layar sudah ada.

---

## 1. Lingkungan dan build APK

Semua perintah dijalankan dari `C:\Users\Asus\PakaianKita`.

### 1.1 Environment mesin ini

```text
ANDROID_HOME=D:\hackathon\android-sdk
ANDROID_SDK_ROOT=D:\hackathon\android-sdk
GRADLE_USER_HOME=D:\hackathon\.gradle
PUB_CACHE=D:\hackathon\.pub-cache
JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot
FLUTTER_ROOT=D:\flutter
```

`PUB_CACHE` di drive `D:` sedangkan project di `C:` memicu bug Kotlin incremental cache (`this and base files have different roots`). Selalu build dengan flag berikut:

```powershell
--android-project-arg=kotlin.incremental=false
```

### 1.2 Perintah wajib

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --android-project-arg=kotlin.incremental=false
flutter build apk --release --android-project-arg=kotlin.incremental=false
flutter build apk --release --split-per-abi --android-project-arg=kotlin.incremental=false
```

Output:

```text
build\app\outputs\flutter-apk\app-debug.apk
build\app\outputs\flutter-apk\app-release.apk
build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
build\app\outputs\flutter-apk\app-x86_64-release.apk
```

Untuk HP Android modern bagikan `app-arm64-v8a-release.apk`. Universal hanya cadangan.

### 1.3 Disk C: hampir penuh

`C:` adalah drive sistem dan ruangnya sangat terbatas. Build bisa gagal dengan:

```text
FileSystemException: writeFrom failed ... app.dill (OS Error: not enough space on the disk, errno = 112)
```

Sebelum build, pastikan minimal 3 GB kosong:

```powershell
Get-PSDrive C | Select-Object Name, @{n='FreeGB';e={[math]::Round($_.Free/1GB,2)}}
```

Jika penuh, bersihkan artefak build proyek lain dengan `flutter clean` (bukan menghapus source). Jangan menghapus folder pengguna tanpa izin.

### 1.4 Install dan jalankan

`adb` tidak ada di PATH:

```powershell
$adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
& $adb devices
& $adb install -r "build\app\outputs\flutter-apk\app-debug.apk"
& $adb shell monkey -p com.resandang.resandang -c android.intent.category.LAUNCHER 1
& $adb logcat -s flutter
```

Emulator yang tersedia:

```powershell
flutter emulators
flutter emulators --launch PakaianKita_API35
flutter run -d emulator-5554
```

### 1.5 Fakta Android

- `minSdk` mengikuti Flutter (24), `targetSdk`/`compileSdk` 36.
- Release memakai debug key. Bisa di-install untuk demo, tidak layak Play Store.
- Tambahkan `INTERNET` di manifest saat integrasi backend. Untuk mock tidak wajib.
- `image_picker` butuh `CAMERA` hanya jika memakai kamera; galeri memakai photo picker tanpa permission storage.
- Google OAuth terikat ke `applicationId` + SHA-1. Jangan ganti keduanya setelah OAuth dibuat.
- SHA-1 debug key:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### 1.6 Troubleshooting

| Gejala | Penyebab | Tindakan |
| --- | --- | --- |
| `this and base files have different roots` | `PUB_CACHE` di `D:`, project di `C:` | Pakai `kotlin.incremental=false`, `flutter clean`, build ulang |
| `errno = 112` / not enough space | `C:` penuh | `flutter clean` proyek lain, cek free space |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Signing/applicationId berbeda | `adb uninstall com.resandang.resandang` lalu install |
| `flutter.sdk not set` | `android/local.properties` basi | Hapus `local.properties`; Flutter menulis ulang dari environment |
| Gradle download lambat | Cache kosong | Butuh internet pada build pertama |
| Teks aneh `Ã¢â‚¬â„¢` / kotak | File Dart double-encoded | Simpan UTF-8 tanpa BOM; jangan pakai `Set-Content` default |

---

## 2. Alur auth dan role (keputusan terbaru)

Ini bagian yang paling sering salah. Ikuti persis.

### 2.1 Prinsip

1. **Role bukan hadiah dari UI.** Frontend hanya mengirim *niat* (intent). Role mitra/relawan/admin diberikan server setelah validasi.
2. **Akun baru otomatis Donatur.** Signup tidak boleh membuat role mitra dari client.
3. **Mitra wajib diverifikasi admin.** Sebelum disetujui, akun tetap bisa dipakai sebagai Donatur, tetapi aksi mitra terkunci.
4. **Satu akun, bukan akun baru.** Persetujuan admin memberi role `mitra` + keanggotaan organisasi ke akun yang sama.
5. **Google login tidak boleh dipalsukan.** Selama backend mock, tombol Google adalah simulasi dan harus berlabel jelas.

### 2.2 Peta navigasi

```text
AuthGate
├── initializing           → SplashScreen
├── signedOut              → WelcomeScreen
│                             ├── LoginScreen
│                             ├── SignupScreen
│                             └── ForgotPasswordScreen
├── needsRole              → RoleIntentScreen
│                             ├── Donatur  → UserShell
│                             └── Mitra    → MitraApplicationScreen
│                                            └── MitraStatusScreen
├── pendingMitra           → MitraStatusScreen (pending / rejected)
├── authenticated
│   ├── ui=user            → UserShell
│   │                        Beranda · Kebutuhan · Donasiku · Aktivitas · Profil
│   └── ui=admin           → AdminShell
│                            Dashboard · Program · Operasional · Pengguna · Pengaturan
└── failure                → SessionErrorScreen (retry / keluar)
```

`needsRole` hanya muncul **sekali per akun**, yaitu setelah signup pertama. Login berikutnya langsung ke shell sesuai konteks. Jika pengguna ingin menjadi mitra di kemudian hari, sediakan pintu di Profil: "Ajukan sebagai mitra".

### 2.3 Welcome / onboarding

Layar pertama sebelum login. Isi:

- Wordmark `PakaianKita` di kiri atas.
- Headline serif 2 baris: "Pakaianmu masih punya cerita."
- Satu paragraf 2 baris: "Temukan kebutuhan nyata di sekitarmu. Salurkan pakaian layak pakai lewat mitra terverifikasi."
- CTA primer full-width: "Mulai".
- Tautan sekunder: "Sudah punya akun? Masuk".
- Blok ilustrasi sederhana (kemeja garis) di atas atau samping headline, mengikuti desain layar 01.

Jangan memakai carousel, tiga kartu fitur, slogan bahasa Inggris, atau angka dampak palsu.

### 2.4 Login

Layar mengikuti desain 11, ditambah tombol Google.

Urutan elemen:

1. Tombol back.
2. Judul serif: "Selamat datang kembali".
3. Subjudul: "Masuk untuk melanjutkan donasi dan memantau penyaluran."
4. Field Email.
5. Field Kata sandi dengan ikon tampil/sembunyi.
6. Tautan "Lupa kata sandi?" rata kanan.
7. CTA "Masuk" full-width 52.
8. Divider "atau".
9. Tombol outlined "Lanjut dengan Google" dengan logo G resmi.
10. Footer: "Belum punya akun? Daftar".

Aturan:

- Validasi inline di bawah field, bukan hanya SnackBar.
- Error kredensial: "Email atau kata sandi tidak cocok." Jangan membocorkan mana yang salah.
- Tombol masuk `busy` saat proses; jangan bisa ditekan ganda.
- Keyboard tidak menutup CTA: gunakan `SingleChildScrollView` + `viewInsets`.
- Di mode mock, tampilkan banner tipis "MODE SIMULASI" dan hint akun demo. Banner tidak boleh muncul di build produksi nyata.

### 2.5 Signup

Field:

- Nama lengkap.
- Email.
- Kata sandi (minimal 8 karakter, ada huruf dan angka).
- Konfirmasi kata sandi.
- Checkbox: "Saya bersedia data saya digunakan untuk keperluan penyaluran donasi." Tanpa tautan palsu.

CTA: "Buat akun". Footer: "Sudah punya akun? Masuk".

Setelah signup sukses → `RoleIntentScreen`.

Error yang harus ditangani: email sudah dipakai, format email salah, password lemah, konfirmasi tidak sama, jaringan/timeout.

### 2.6 Login dengan Google

**Tahap mock (sekarang):**

- Tombol tetap ada di Login dan Signup.
- `MockAuthRepository.signInWithGoogle()` mengembalikan akun demo.
- Label wajib: "Lanjut dengan Google" + chip kecil "simulasi" selama belum terhubung.
- Jika akun demo belum punya role intent → `RoleIntentScreen`; jika sudah → shell.
- Jangan mengklaim "Terhubung ke Google" di UI atau pitch.

**Saat backend siap:**

- `google_sign_in` + Supabase `signInWithIdToken`.
- Buat OAuth client Android untuk package `com.resandang.resandang` dan SHA-1 debug/release.
- Aktifkan provider Google di Supabase.
- Hapus label simulasi hanya setelah login nyata diuji di perangkat.
- Jangan menaruh client secret di Flutter.

### 2.7 Role intent

Judul: "Kamu mau bergabung sebagai apa?"

Dua pilihan berupa kartu radio besar, bukan grid ikon:

| Pilihan | Deskripsi | Konsekuensi |
| --- | --- | --- |
| Donatur | "Donasikan pakaian layak pakai dan ikuti perjalanannya." | Langsung masuk Beranda |
| Mitra | "Lembaga sosial atau posko yang menyalurkan bantuan." | Lanjut formulir verifikasi |

- CTA "Lanjut" aktif setelah satu pilihan dipilih.
- Catatan kecil: "Kamu bisa menjadi donatur dulu dan mengajukan mitra nanti."
- Relawan **tidak** dipilih di sini. Role relawan diberikan admin (sesuai handoff).
- Jangan menampilkan pilihan Admin.

### 2.8 Pengajuan mitra

Form 2 langkah dengan progress "1 dari 2". Draft harus bertahan saat back.

**Langkah 1 — Identitas lembaga**

- Nama lembaga.
- Jenis: Lembaga sosial, Posko bencana, Panti asuhan, Komunitas, Lainnya.
- Wilayah layanan (kota/kecamatan).
- Alamat titik kumpul.
- Nama penanggung jawab.
- Nomor WhatsApp penanggung jawab.
- Perkiraan jumlah penerima manfaat (opsional, jangan dikarang).

**Langkah 2 — Legalitas**

- Nomor dokumen (SK Kemenkumham, akta notaris, atau surat rekomendasi).
- Instansi penerbit.
- Tanggal dokumen.
- Unggah minimal 1 dokumen: JPG/PNG/PDF, maksimal 5 MB per file (batas mock; kontrak backend menyesuaikan).
- File kedua opsional.
- Checkbox: "Saya menyatakan dokumen ini asli dan berhak mewakili lembaga."
- CTA "Kirim pengajuan".

Komponen file wajib menampilkan: nama file, ukuran, thumbnail untuk gambar, tombol ganti/hapus, status upload, dan error yang bisa diulang. Jangan memakai tombol upload tanpa umpan balik.

Validasi:

- Semua field wajib kecuali yang ditandai opsional.
- Nomor WhatsApp minimal 9 digit.
- Tanggal tidak boleh di masa depan.
- Submit idempotent: busy state + request key; cegah pengajuan ganda.

Setelah submit → `MitraStatusScreen`.

### 2.9 Status pengajuan mitra

Status: `draft`, `submitted`, `under_review`, `approved`, `rejected`.

Layar pending:

- Judul: "Pengajuan mitra sedang ditinjau".
- Ringkasan lembaga + tanggal pengajuan.
- Timeline 3 langkah: Diajukan → Diverifikasi admin → Hasil.
- "Sambil menunggu, kamu tetap bisa memakai akun sebagai donatur."
- CTA "Ke beranda donatur".
- Tautan "Keluar".
- Jangan menulis estimasi waktu yang tidak dijamin.

Layar ditolak:

- Judul: "Pengajuan perlu diperbaiki".
- Alasan penolakan dari admin, ditampilkan apa adanya.
- CTA "Perbaiki pengajuan" (prefill draft).
- Jangan menyembunyikan alasan.

Layar disetujui:

- "Lembaga kamu sudah terverifikasi."
- CTA "Buka ruang mitra".
- Role dan membership sudah aktif di sesi.

### 2.10 Admin memvalidasi

Admin shell punya:

- **Notifikasi** lonceng dengan badge jumlah pengajuan `submitted`/`under_review`.
- **Verifikasi mitra** di Operasional: filter Menunggu / Disetujui / Ditolak, pencarian nama lembaga.
- **Detail pengajuan**: identitas pemohon, data lembaga, nomor & instansi dokumen, preview dokumen, tombol Setujui / Tolak.
- **Setujui** membuka dialog konfirmasi: "Setujui {nama}? Akun akan mendapat akses mitra untuk organisasi ini." Aksi menulis: status approved, role mitra, membership aktif, organisasi verified.
- **Tolak** wajib alasan minimal 10 karakter.
- Setelah aksi: antrean dan badge diperbarui; pemohon melihat hasilnya.
- Empty state: "Tidak ada pengajuan menunggu."
- Jangan menampilkan statistik dekoratif; angka harus berasal dari repository.

Admin tidak boleh menyetujui pengajuannya sendiri. Mock tetap menegakkan ini.

### 2.11 Donatur setelah login

Donatur langsung masuk `UserShell` → Beranda, tanpa layar peran tambahan setelah intent tersimpan.

Beranda hanya menampilkan kebutuhan dari organisasi **verified && active** dan status `open`:

- Header: "Selamat pagi, {nama}" + tanggal.
- Kebutuhan mendesak (jika ada), lalu kebutuhan terbaru.
- Kartu: judul, organisasi + badge "Mitra terverifikasi", kategori/ukuran, sisa kebutuhan, tenggat.
- CTA "Donasikan pakaian".
- Filter sederhana: kategori, ukuran, wilayah.
- Empty state: "Belum ada kebutuhan terbuka. Coba lagi nanti."
- Jangan menampilkan kebutuhan dari mitra yang belum diverifikasi, walau statusnya open.
- Jangan menampilkan kontak/alamat privat penerima.

### 2.12 State sesi dan error

`SessionState`: `initializing`, `signedOut`, `needsRole`, `pendingMitra`, `authenticated`, `failure`.

Wajib ditangani:

- Session expired → kembali ke Login dengan pesan "Sesi berakhir. Silakan masuk lagi."
- Forbidden → pesan + refresh konteks; jangan hanya menyembunyikan tombol.
- Timeout → tombol coba lagi.
- Upload gagal → file tetap ada, bisa ulang.
- Approval dari admin saat mitra membuka app → status diperbarui saat refresh/fokus, bukan memaksa restart.

---

## 3. Kontrak data dan repository (mock dulu)

Frontend tidak boleh memanggil Supabase langsung dari widget. Semua lewat repository.

### 3.1 Interface minimal

```dart
abstract class AuthRepository {
  Stream<AuthSession?> watchSession();
  Future<AuthSession> signIn({required String email, required String password});
  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<AuthSession> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<AppContext> loadAccess();
}
```

```dart
abstract class MitraVerificationRepository {
  Future<MitraApplication?> getMine(String userId);
  Future<MitraApplication> saveDraft(MitraApplication application);
  Future<MitraApplication> submit(String applicationId);
  Future<List<MitraApplication>> list({MitraApplicationStatus? status});
  Future<void> approve(String applicationId, {required String adminId});
  Future<void> reject(
    String applicationId, {
    required String adminId,
    required String reason,
  });
}
```

```dart
abstract class NotificationRepository {
  Stream<int> watchUnreadCount(String userId);
  Future<List<AppNotification>> list(String userId);
  Future<void> markRead(String notificationId);
}
```

`NeedsRepository`, `DonationsRepository`, `OperationsRepository`, `TrackingRepository`, dan `AdminRepository` mengikuti `03_KONTRAK_DATA_DAN_RPC.md`.

### 3.2 Model baru (usulan, belum ada di database)

```dart
enum MitraApplicationStatus { draft, submitted, underReview, approved, rejected }

class MitraApplication {
  final String id;
  final String userId;
  final String organizationName;
  final String organizationKind;
  final String area;
  final String pointAddress;
  final String contactName;
  final String contactPhone;
  final String legalNumber;
  final String legalIssuer;
  final DateTime legalIssuedAt;
  final List<String> documentPaths;
  final MitraApplicationStatus status;
  final String? reviewNote;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
}
```

```dart
class AppContext {
  final String userId;
  final String displayName;
  final Set<Role> roles;      // donatur, relawan, mitra, admin
  final UiShell ui;           // user | admin
  final bool onboardingCompleted;
  final MitraApplicationStatus? mitraStatus;
  final List<Membership> memberships;
}
```

**Penting:** tabel `mitra_verifications` dan RPC approval **belum ada** di schema Supabase. Jangan menjalankan migrasi. Kontrak ini usulan frontend; pemilik backend harus membuat tabel/RPC dan memperbarui `05_DATABASE_AKTUAL.md` sebelum integrasi nyata. Sampai itu terjadi, implementasi hanya di `lib/demo/`.

### 3.3 Mock yang harus disediakan

Akun demo (password semua `demo1234`, hanya ditampilkan di banner simulasi):

| Akun | Role | UI | Kondisi |
| --- | --- | --- | --- |
| `donatur@pakaiankita.id` | donatur | user | onboarding selesai |
| `mitra@pakaiankita.id` | donatur, mitra | user | organisasi terverifikasi |
| `pending@pakaiankita.id` | donatur | user | pengajuan submitted |
| `admin@pakaiankita.id` | donatur, admin | admin | punya 2 pengajuan menunggu |

Seed juga:

- 1 pengajuan mitra yang ditolak dengan alasan (untuk menguji revisi).
- 6 kebutuhan: 4 dari organisasi verified, 2 dari organisasi pending (tidak boleh muncul di Beranda donatur).
- 1 incident aktif (mode bencana) untuk layar lain.
- Fixture mengikuti `mock/frontend_fixture.json` dan diberi label "DATA SIMULASI".

Mock harus:

- Menolak `approve/reject` jika aktor bukan admin.
- Mengubah `AppContext` setelah approval.
- Menghitung badge notifikasi dari status, bukan konstanta.
- Tidak menyimpan dokumen asli; gunakan gambar dummy.

### 3.4 Sumber data nyata (untuk nanti)

- `my_access()` mengembalikan `roles` dan `ui`; jangan ambil role dari `user_metadata`.
- Akun baru otomatis Donatur.
- Mitra butuh role `mitra` + `organization_members` aktif pada organisasi `verified`.
- Foto donasi privat, bucket `donation-photos`, maksimal 1 MB.
- Jangan menambah query/RPC baru tanpa pemilik backend.

---

## 4. Desain anti-slop

### 4.1 Arah visual

Satu kalimat pengikat:

> Katalog bantuan yang tenang: kertas hangat, hijau hutan, serif editorial, dan informasi yang bisa ditindaklanjuti.

Desain 20 layar sudah kuat. Jangan menggantinya dengan template AI. Yang boleh: merapikan, menambah state, menyatukan shell. Yang tidak boleh: mengganti palet, menambah gradient, atau membuat ulang dengan gaya "startup SaaS".

### 4.2 Token warna (diambil dari desain)

| Token | Hex | Fungsi |
| --- | --- | --- |
| `paper` | `#FAFAF7` | Latar layar |
| `surface` | `#FFFFFF` | Kartu, input, sheet |
| `parchment` | `#F2EDDF` | Blok highlight, ilustrasi, ringkasan |
| `sage` | `#E8EFE5` | Chip lembut, status netral, progress track |
| `forest` | `#145A46` | Aksi primer, tautan, status positif |
| `ink` | `#172D25` | Teks utama, judul |
| `muted` | `#5C6B63` | Teks sekunder (bukan `#88938E` untuk body) |
| `line` | `#DDE6D4` | Border hairline, divider |
| `alertSurface` | `#FFF0EA` | Latar peringatan/darurat |
| `clay` | `#A33120` | Teks/ikon peringatan, aksi destruktif |
| `claySoft` | `#BA6052` | Aksen sekunder, badge darurat |
| `sand` | `#B48B62` | Ilustrasi saja, jangan untuk teks |

Aturan:

- Satu aksen utama (`forest`) maksimal 10% layar.
- `clay` hanya untuk risiko/penolakan/darurat, selalu dengan teks atau ikon.
- Jangan memakai ungu, pink, cyan, gradient tiga warna, atau glassmorphism.
- Kontras body minimal 4.5:1. `muted` di atas `paper` hanya untuk teks ≥18px.

### 4.3 Tipografi

- Display: **Lora** 600/700 (serif). Fallback `serif`.
- UI/body: **Plus Jakarta Sans** 400/500/600/700. Fallback sans default.
- Bundle `.ttf` di `assets/fonts/` dan deklarasikan di `pubspec.yaml`. Jangan memakai `google_fonts` runtime karena app harus jalan offline.
- Jangan memakai Poppins atau Inter untuk seluruh teks.

Skala:

| Peran | Ukuran/line-height | Weight |
| --- | --- | --- |
| Display | 30–32 / 38 | 600 |
| H1 | 24 / 32 | 600 |
| H2 | 20 / 28 | 600 |
| Body | 15 / 22 | 400 |
| Body kecil | 13 / 18 | 400 |
| Label | 11 / 14, tracking 0.08em, uppercase | 600 |
| Tombol | 15 / 20 | 600 |
| Caption | 12 / 16 | 400 |

Angka jumlah memakai `FontFeature.tabularFigures()`.

### 4.4 Spacing, radius, elevasi

- Grid 4pt: 4, 8, 12, 16, 20, 24, 32, 48.
- Gutter layar 20; jarak antar section 28–32; padding kartu 16; gap grid 12.
- Radius: kartu 12, tombol/input 10, chip 6, bottom sheet 20 (atas).
- Target sentuh minimal 48dp; jarak antar target minimal 8dp.
- Kartu memakai border 1px `line`, elevation 0. Shadow hanya untuk sheet/dialog/menu.
- Tidak ada Card di dalam Card.

### 4.5 Komponen wajib

Buat di `core/widgets/`:

- `PkScaffold` — background paper, SafeArea, gutter 20.
- `PkButton` — primary/secondary/ghost/danger; tinggi 52; busy state; label tidak bergeser.
- `PkTextField` — label di atas, helper/error di bawah, tinggi minimal 48.
- `PkStatusChip` — teks + ikon, bukan warna saja.
- `PkCard` — border hairline, radius 12, tanpa shadow.
- `PkSectionHeader` — judul + aksi opsional.
- `PkAsyncView<T>` — loading/error/empty/data dengan retry.
- `PkStepHeader` — "1 dari 2" + progress.
- `PkFileField` — nama file, ukuran, preview, ganti/hapus, progress.
- `PkTimeline` — vertikal, 3–5 langkah.
- `PkOrgBadge` — "Mitra terverifikasi" dengan ikon centang.
- `PkBanner` — simulasi/offline/peringatan.

### 4.6 Motion

| Kejadian | Durasi | Curve |
| --- | --- | --- |
| Press | 90 ms, scale 0.98 | easeOut |
| Ganti tab/segment | 160 ms | easeOutCubic |
| Konten masuk | 200 ms, fade + 8px | easeOutCubic |
| Pindah halaman | 220 ms | easeInOutCubic |
| Bottom sheet | 280 ms | easeOutCubic |

Hormati `MediaQuery.disableAnimations`. Tidak ada confetti, parallax, animasi loop, atau stagger berlebihan.

### 4.7 Copy

- Bahasa Indonesia, sapaan "kamu", sentence case, tanpa tanda seru, tanpa emoji.
- Gunakan istilah produk: "kebutuhan", "mitra", "donasi", "kurasi", "titik kumpul".
- Jangan memakai "Elevate", "Seamless", "Unleash", "AI-powered", "Welcome back!".
- Error menyebut tindakan: "Dokumen gagal diunggah. Coba lagi."
- Status memakai kalimat manusia: "Menunggu verifikasi admin", bukan "PENDING_APPROVAL".
- Angka dampak harus diberi label "Data simulasi" selama mock.

### 4.8 Resep layar auth

**Welcome**
- Wordmark 18/24 bold.
- Blok parchment 16:9 dengan ilustrasi kemeja sederhana.
- Headline serif 2 baris, body 2 baris.
- CTA 52 full-width di bawah; tautan masuk di bawahnya.
- Tidak ada navbar.

**Login**
- Back arrow 48dp.
- Judul serif + subjudul.
- Dua field, satu tautan lupa sandi, CTA, divider, Google outlined.
- Jarak field 16; jarak CTA 24.
- Error field menggeser layout, jangan menutupi tombol.

**Signup**
- Empat field; helper password 12/16.
- CTA di bawah; keyboard-safe.
- Tanpa ilustrasi besar; fokus ke form.

**Role intent**
- Dua kartu radio tinggi 96–112, judul 16/24, deskripsi 13/18.
- Kartu terpilih: border `forest` 1.5px + latar `sage` 40%.
- CTA di bawah, bukan di dalam kartu.

**Mitra form**
- Stepper 2 langkah; back tidak menghapus draft.
- Field group diberi judul section, bukan Card bertumpuk.
- Upload field full-width, border dashed hanya jika konsisten; lebih baik border solid `line`.
- CTA "Kirim pengajuan" di bawah, dengan ringkasan kecil di atasnya.

**Pending**
- Ikon status 48, judul serif, body.
- Timeline dengan garis vertikal `line`, titik `forest`/`clay`.
- CTA sekunder "Ke beranda donatur" dan tautan keluar.

**Admin verification**
- Daftar berupa baris, bukan kartu besar: nama lembaga, jenis, tanggal, chip status.
- Detail: dua kolom label/nilai; dokumen preview 16:9.
- Aksi Setujui/Tolak menempel di bawah, aman dari keyboard.
- Dialog konfirmasi memuat konsekuensi, bukan hanya "Ya/Tidak".

### 4.9 Dilarang

- Gradient ungu/pink/cyan, blob, glassmorphism, noise dekoratif.
- Emoji sebagai ikon.
- Tiga kartu fitur sejajar dengan teks tengah.
- Shadow di setiap kartu.
- Radius 20+ di semua komponen.
- Statistik/testimoni/angka dampak palsu.
- Tombol atau ikon yang tidak melakukan apa-apa.
- Data mock yang dilabeli "live" atau "terverifikasi" tanpa status.
- Menampilkan dokumen legalitas mitra ke publik.
- Role selector yang benar-benar mengubah hak di build nyata.

### 4.10 Aksesibilitas

- Uji lebar 360, 390, 430 dan font scale 1.3 serta 2.0.
- Jangan memakai tinggi tetap untuk teks.
- Status selalu teks + ikon.
- `Semantics` untuk badge, progress, dan tombol ikon.
- Dokumen upload bisa diakses TalkBack; tombol hapus punya label.
- Form error diumumkan (`SemanticsService.announce` atau `liveRegion`).
- Edge-to-edge: status bar transparan, `SafeArea`.
- Uji tombol back Android di setiap langkah form.

---

## 5. Arsitektur dan konvensi

### 5.1 Struktur

```text
lib/
  app/
    app.dart
    auth_gate.dart
    routes.dart
  core/
    theme/app_theme.dart
    theme/app_tokens.dart
    widgets/
    utils/
  features/
    auth/
      models/
      repositories/
      presentation/
        welcome_screen.dart
        login_screen.dart
        signup_screen.dart
        forgot_password_screen.dart
        role_intent_screen.dart
    mitra/
      models/
      repositories/
      presentation/
        mitra_application_screen.dart
        mitra_status_screen.dart
    admin/
      presentation/
        verification_queue_screen.dart
        verification_detail_screen.dart
    needs/
    donations/
    operations/
    tracking/
  demo/
    mock_auth_repository.dart
    mock_mitra_repository.dart
    mock_notification_repository.dart
    demo_seed.dart
```

### 5.2 Keputusan teknis

- **State management:** `ChangeNotifier` + `InheritedNotifier` (`AppScope`). Tanpa package tambahan. Jika tim memilih lain, sepakati sebelum coding; jangan pasang dua.
- **Routing:** `AuthGate` sebagai root; `Navigator` + named routes sederhana. Jangan menambah `go_router` kecuali deep link benar-benar dibutuhkan.
- **Dependency yang boleh ditambah sekarang:** `image_picker` (dokumen/foto), `intl` (tanggal `id_ID`). Jangan menambah `google_fonts`, `provider`, `riverpod`, `bloc`, atau `get` tanpa keputusan tim.
- **Repository nyata** nanti memakai `supabase_flutter`, hanya di `features/*/data/`.
- **Jangan** menaruh query Supabase di widget.
- **Jangan** mengubah `applicationId`, nama package, schema, RLS, atau RPC.

### 5.3 Konvensi Flutter 3.47

- `withValues(alpha:)`, bukan `withOpacity`.
- `toARGB32()`, bukan `.value`.
- `RadioGroup`, bukan `Radio.groupValue/onChanged`.
- Dispose semua controller, `FocusNode`, dan `ChangeNotifier`.
- `const` di mana memungkinkan.
- Import relatif seperti gaya repo.
- `debugPrint` di debug; jangan `print` di release.
- Jangan menampilkan `$e` mentah ke pengguna.

### 5.4 Test minimal

- Login: kredensial salah → error inline; sukses → shell.
- Signup: email invalid, password lemah, konfirmasi beda.
- Role intent: pilih mitra → form; pilih donatur → home.
- Mitra: submit tanpa dokumen ditolak; submit valid → pending.
- Admin: approve mengubah status + badge; reject butuh alasan.
- Donatur home: hanya menampilkan kebutuhan organisasi verified.
- Widget test memakai mock repository, bukan Supabase.

---

## 6. Urutan kerja

Kerjakan per slice. Setiap slice harus menghasilkan build yang bisa di-install.

### Phase 0 — Fondasi (wajib)

- Hapus counter app dan test counter.
- `app_tokens.dart`, `app_theme.dart`, font bundle, komponen dasar.
- `AuthGate` + `SessionState` + splash/loading.
- Ganti label Android menjadi `PakaianKita`.
- Acceptance: `flutter analyze` 0 error, test lulus, APK debug ter-install, tidak ada layar ungu default.

### Phase 1 — Auth

- Welcome, Login, Signup, Forgot Password.
- Mock `AuthRepository`, validasi, error, busy state.
- Tombol Google simulasi.
- Session persisten selama app berjalan.
- Acceptance: alur login/signup/keluar berjalan; test auth lulus.

### Phase 2 — Role dan verifikasi mitra

- Role intent.
- Form mitra 2 langkah + upload dokumen + draft.
- Status pending/rejected/approved.
- Admin: badge notifikasi, antrean, detail, approve/reject.
- Sinkronisasi status ke sesi mitra.
- Acceptance: skenario end-to-end donatur → mitra → admin → approved berjalan dengan mock.

### Phase 3 — Beranda donatur dan kebutuhan

- Beranda hanya menampilkan kebutuhan mitra verified.
- Daftar + filter + detail.
- Loading/empty/error.
- Acceptance: organisasi pending tidak pernah muncul.

### Phase 4 — Wizard donasi

- Mengikuti desain 05, 06, 12, 13, 14.
- Draft, item baris, foto, checklist, jadwal, tinjauan, sukses.
- Acceptance: submit tidak ganda; draft bertahan saat back.

### Phase 5 — Relawan dan mitra

- Tugas saya, kurasi, stok, alokasi, penerimaan.
- Aksi sesuai permission, bukan tab terpisah.
- Acceptance: angka kurasi dan penerimaan konsisten.

### Phase 6 — Admin dan polish

- Dashboard operasional, pengguna, organisasi/titik, insiden.
- Empty/error/forbidden.
- Release build, uji perangkat, rekam demo.

---

## 7. Gate verifikasi

```powershell
flutter analyze
flutter test
flutter build apk --debug --android-project-arg=kotlin.incremental=false
flutter build apk --release --android-project-arg=kotlin.incremental=false
```

Target:

- `flutter analyze`: 0 error. 0 warning untuk file yang diubah.
- `flutter test`: lulus.
- Build debug/release sukses, path dan ukuran dicatat.
- APK ter-install di emulator/perangkat bersih.
- Tidak ada layar putih kosong saat cold start.
- Tidak ada teks mojibake, placeholder, error mentah, atau tombol mati.

### 7.1 Skenario demo 3 menit

1. Fresh install → Welcome.
2. Login admin → badge notifikasi 1 → buka pengajuan mitra → setujui.
3. Logout → login akun mitra → status berubah menjadi terverifikasi → aksi mitra muncul.
4. Logout → login donatur → Beranda hanya menampilkan kebutuhan mitra terverifikasi.
5. Signup akun baru → pilih Mitra → unggah dokumen dummy → pending.
6. Login admin → pengajuan baru muncul di antrean.
7. Tombol Google simulasi → masuk ke role intent.
8. Airplane mode: mock tetap berjalan; label simulasi terlihat.

### 7.2 Checklist

- [ ] Login, signup, lupa sandi, Google simulasi.
- [ ] Role intent hanya sekali per akun.
- [ ] Mitra belum terverifikasi tidak bisa mengelola kebutuhan.
- [ ] Admin melihat pengajuan dan menyetujui/menolak dengan alasan.
- [ ] Donatur melihat hanya output mitra verified.
- [ ] Draft mitra bertahan saat back.
- [ ] Submit tidak ganda.
- [ ] Font scale 1.3/2.0, lebar 360.
- [ ] Tidak ada dokumen asli di repo/mock.
- [ ] Tidak ada klaim live/AI/Google nyata.

---

## 8. Batas dan larangan

- Jangan mengubah schema, RLS, RPC, atau menjalankan migrasi.
- Jangan memakai `service_role` di Flutter.
- Jangan mengganti `applicationId` atau package `resandang`.
- Jangan membuat akun Admin bootstrap atau password di kode.
- Jangan memberi role dari client; approval hanya simulasi di mock.
- Jangan menampilkan dokumen legalitas ke publik.
- Jangan mengklaim Google login nyata sebelum OAuth diuji.
- Jangan menambah fitur di luar MVP: reward, voucher, pembayaran, kalkulator karbon, AI gambar.
- Jangan menghapus aset/desain/docs tanpa konfirmasi.
- Jangan commit `local.properties`, keystore, atau file machine-specific.

Format laporan akhir:

```text
## Ringkasan
## File berubah
## Verifikasi
- flutter analyze: ...
- flutter test: ...
- flutter build apk: ... (path, ukuran)
- Screenshot: ...
## Kontrak yang perlu disepakati backend
## Risiko / sisa
```

---

## 9. Prompt siap pakai

```text
Kamu mengerjakan FRONTEND Flutter PakaianKita di C:\Users\Asus\PakaianKita.
Baca AGENTS.md ini, lalu START_HERE.md dan docs/01–03 di
C:\Users\Asus\PakaianKita_HANDOFF\PakaianKita_Frontend_Handoff\.
Muat skill anti-ai-slop-mobile jika tersedia.

Tugas: [Phase 1 / Phase 2 / ...].
Batasan:
- Backend masih mock. Jangan menghubungi Supabase, jangan ubah schema/RLS/RPC.
- Jangan ganti applicationId com.resandang.resandang atau package resandang.
- Jangan menambah state management/router/font runtime.
- Jangan mengklaim Google login, verifikasi mitra, atau angka dampak sebagai nyata.
- Semua data mock diberi label "DATA SIMULASI".
- UI mengikuti palet dan tipografi di AGENTS.md; jangan memakai gradient ungu/pink.
- Simpan file sebagai UTF-8.

Selesai jika:
- flutter analyze 0 error
- flutter test lulus
- flutter build apk --debug --android-project-arg=kotlin.incremental=false sukses
- screenshot 360x800 dan 390x844 terlampir
- laporan memakai format di AGENTS.md §8
```

---

## 10. Risiko yang harus dilaporkan, bukan disembunyikan

1. **Tabel verifikasi mitra belum ada.** Mock tidak membuktikan RLS atau approval server.
2. **Google OAuth belum dikonfigurasi.** Tombol hanya simulasi.
3. **Admin dashboard belum ada desainnya.** Bangun dari spesifikasi, bukan mengarang grafik.
4. **Desain 20 layar belum mencakup signup, role intent, dan verifikasi mitra.** Ikuti resep di §4.8.
5. **Repo masih default counter.** Fondasi belum ada.
6. **Disk C: terbatas.** Build bisa gagal ENOSPC.
7. **Release memakai debug signing.** Jangan klaim siap Play Store.
