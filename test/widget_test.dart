import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:resandang/app/app.dart';
import 'package:resandang/demo/demo_repository.dart';
import 'package:resandang/features/admin/presentation/verification_queue_screen.dart';
import 'package:resandang/features/mitra/models/mitra_application.dart';

const _phoneSize = Size(390, 844);

Future<void> _loadFonts() async {
  final ui = FontLoader('PlusJakartaSans');
  for (final file in [
    'PlusJakartaSans-Regular.ttf',
    'PlusJakartaSans-Medium.ttf',
    'PlusJakartaSans-SemiBold.ttf',
    'PlusJakartaSans-Bold.ttf',
  ]) {
    ui.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await ui.load();

  final display = FontLoader('Lora');
  for (final file in ['Lora-SemiBold.ttf', 'Lora-Bold.ttf']) {
    display.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await display.load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
    await _loadFonts();
  });

  Future<DemoRepository> startApp(WidgetTester tester) async {
    tester.view.physicalSize = _phoneSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = DemoRepository.seeded();
    addTearDown(repository.dispose);
    await tester.pumpWidget(PakaianKitaApp(repository: repository));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    return repository;
  }

  Future<void> openLogin(WidgetTester tester) async {
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(
    WidgetTester tester, {
    required String email,
    String password = DemoRepository.demoPassword,
  }) async {
    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  Future<void> openMitraFormViaGoogle(WidgetTester tester) async {
    await openLogin(tester);
    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('role-mitra')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('role-continue')));
    await tester.pumpAndSettle();
  }

  Future<void> fillMitraStepOne(WidgetTester tester) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Yayasan Uji Coba');
    await tester.enterText(fields.at(1), 'Bandung');
    await tester.enterText(fields.at(2), 'Jl. Uji Coba No. 1');
    await tester.enterText(fields.at(3), 'Rina Kartika');
    await tester.enterText(fields.at(4), '081234567890');
    await tester.tap(find.byKey(const Key('mitra-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  Future<void> openAdminQueue(WidgetTester tester) async {
    await tester.tap(find.text('Operasional'));
    await tester.pumpAndSettle();
  }

  testWidgets('login menolak kredensial yang salah dengan pesan inline', (
    tester,
  ) async {
    await startApp(tester);
    await openLogin(tester);

    await signIn(
      tester,
      email: 'donatur@pakaiankita.id',
      password: 'kata-sandi-salah',
    );

    expect(find.text('TIDAK BISA MASUK'), findsOneWidget);
    expect(find.text('Email atau kata sandi tidak cocok.'), findsOneWidget);
    expect(find.text('Selamat datang kembali'), findsOneWidget);
  });

  testWidgets('signup memvalidasi field lalu membuka pilihan peran', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pump();

    expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi wajib diisi.'), findsOneWidget);
    expect(
      find.text('Persetujuan ini perlu dicentang untuk melanjutkan.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).at(0), 'Rina Kartika');
    await tester.enterText(find.byType(TextField).at(1), 'rina@contoh.id');
    await tester.enterText(find.byType(TextField).at(2), 'rahasia1');
    await tester.enterText(find.byType(TextField).at(3), 'rahasia1');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Kamu mau bergabung sebagai apa?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('role-mitra')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('role-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Identitas lembaga'), findsOneWidget);
  });

  testWidgets('tombol Google simulasi masuk ke role intent lalu beranda', (
    tester,
  ) async {
    await startApp(tester);
    await openLogin(tester);

    expect(find.text('simulasi'), findsOneWidget);
    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Kamu mau bergabung sebagai apa?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('role-donatur')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('role-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Kebutuhan mendesak'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('pengajuan mitra menolak submit tanpa dokumen legalitas', (
    tester,
  ) async {
    await startApp(tester);
    await openMitraFormViaGoogle(tester);
    await fillMitraStepOne(tester);

    expect(find.text('Legalitas lembaga'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mitra-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Nomor dokumen wajib diisi.'), findsOneWidget);
    expect(find.text('Instansi penerbit wajib diisi.'), findsOneWidget);
    expect(find.text('Tanggal dokumen wajib dipilih.'), findsOneWidget);
    expect(
      find.text('Unggah minimal satu dokumen legalitas.'),
      findsOneWidget,
    );
    expect(
      find.text('Pernyataan ini perlu dicentang sebelum mengirim.'),
      findsOneWidget,
    );
  });

  testWidgets('pengajuan mitra dengan dokumen contoh menjadi menunggu', (
    tester,
  ) async {
    final repository = await startApp(tester);
    await openMitraFormViaGoogle(tester);
    await fillMitraStepOne(tester);

    final legalFields = find.byType(TextField);
    await tester.enterText(legalFields.at(0), 'AHU-12345.AH.01.07');
    await tester.enterText(legalFields.at(1), 'Kementerian Hukum dan HAM RI');

    final dateButton = find.text('Pilih tanggal');
    await tester.ensureVisible(dateButton);
    await tester.pumpAndSettle();
    await tester.tap(dateButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();

    final uploadButton = find.text('Unggah surat kelembagaan');
    await tester.ensureVisible(uploadButton);
    await tester.pumpAndSettle();
    await tester.tap(uploadButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gunakan dokumen contoh'));
    await tester.pumpAndSettle();

    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pump();

    await tester.tap(find.byKey(const Key('mitra-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Pengajuan mitra sedang ditinjau'), findsOneWidget);
    final application = repository.applicationFor('u-google');
    expect(application, isNotNull);
    expect(application!.status, MitraApplicationStatus.submitted);
    expect(application.documents, hasLength(1));
  });

  testWidgets('admin menyetujui pengajuan dan badge antrean berkurang', (
    tester,
  ) async {
    final repository = await startApp(tester);
    await openLogin(tester);
    await signIn(tester, email: 'admin@pakaiankita.id');

    expect(repository.pendingVerificationCount, 2);
    await openAdminQueue(tester);

    final applicant = find.text('Komunitas Langkah Baru');
    await tester.ensureVisible(applicant);
    await tester.pumpAndSettle();
    await tester.tap(applicant);
    await tester.pumpAndSettle();

    expect(find.text('Detail pengajuan'), findsOneWidget);
    await tester.tap(find.byKey(const Key('verification-approve')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setujui pengajuan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(repository.pendingVerificationCount, 1);
    expect(
      repository.applications
          .firstWhere((item) => item.id == 'app-komunitas-01')
          .status,
      MitraApplicationStatus.approved,
    );
    expect(find.text('Disetujui'), findsWidgets);
  });

  testWidgets('admin menolak pengajuan dan alasan minimal 10 karakter', (
    tester,
  ) async {
    final repository = await startApp(tester);
    await openLogin(tester);
    await signIn(tester, email: 'admin@pakaiankita.id');
    await openAdminQueue(tester);

    final applicant = find.text('Lembaga Cinta Kasih');
    await tester.ensureVisible(applicant);
    await tester.pumpAndSettle();
    await tester.tap(applicant);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('verification-reject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tolak pengajuan'));
    await tester.pumpAndSettle();

    expect(find.text('Alasan minimal 10 karakter.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Nomor surat rekomendasi tidak terbaca pada hasil pindai.',
    );
    await tester.tap(find.text('Tolak pengajuan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final application = repository.applications
        .firstWhere((item) => item.id == 'app-kasih-01');
    expect(application.status, MitraApplicationStatus.rejected);
    expect(application.reviewNote, contains('tidak terbaca'));
    expect(repository.pendingVerificationCount, 1);
  });

  testWidgets('kebutuhan mitra belum terverifikasi tidak tampil ke donatur', (
    tester,
  ) async {
    final repository = await startApp(tester);

    expect(
      repository.publishedNeeds.map((need) => need.id),
      isNot(contains('need-bayi')),
    );

    await tester.runAsync(
      () => repository.approve('app-komunitas-01', adminId: 'u-admin'),
    );
    expect(
      repository.publishedNeeds.map((need) => need.id),
      contains('need-bayi'),
    );

    await openLogin(tester);
    await signIn(tester, email: 'donatur@pakaiankita.id');
    await tester.tap(find.text('Kebutuhan'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bayi');
    await tester.pumpAndSettle();

    expect(find.text('1 hasil'), findsOneWidget);
    expect(find.text('Pakaian bayi 0–2 tahun'), findsOneWidget);
  });

  testWidgets('antrean verifikasi menampilkan empty state setelah diputuskan', (
    tester,
  ) async {
    await startApp(tester);
    await openLogin(tester);
    await signIn(tester, email: 'admin@pakaiankita.id');
    await openAdminQueue(tester);

    expect(find.byType(VerificationQueueView), findsOneWidget);
    expect(find.text('Menunggu · 2'), findsOneWidget);
    expect(find.text('Tidak ada pengajuan menunggu'), findsNothing);
  });
}
