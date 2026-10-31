import 'package:flutter_test/flutter_test.dart';
import 'package:resandang/core/errors/app_exception.dart';
import 'package:resandang/core/models/app_role.dart';
import 'package:resandang/demo/demo_repository.dart';
import 'package:resandang/features/mitra/models/mitra_application.dart';

void main() {
  group('DemoRepository verifikasi mitra', () {
    test('kebutuhan organisasi belum terverifikasi tidak terbit', () {
      final repository = DemoRepository.seeded();
      addTearDown(repository.dispose);

      expect(
        repository.publishedNeeds.map((need) => need.id),
        isNot(containsAll(['need-bayi', 'need-kaos'])),
      );
      expect(repository.publishedNeeds, hasLength(5));
    });

    test('approval mengaktifkan role mitra dan menerbitkan kebutuhan', () async {
      final repository = DemoRepository.seeded();
      addTearDown(repository.dispose);

      await repository.approve('app-komunitas-01', adminId: 'u-admin');

      final application = repository.applications
          .firstWhere((item) => item.id == 'app-komunitas-01');
      expect(application.status, MitraApplicationStatus.approved);
      expect(repository.pendingVerificationCount, 1);

      final access = repository.peekAccess('u-pending');
      expect(access, isNotNull);
      expect(access!.roles, containsAll([AppRole.donatur, AppRole.mitra]));
      expect(access.isVerifiedMitra, isTrue);
      expect(access.organization?.verified, isTrue);

      expect(repository.publishedNeeds.map((need) => need.id), contains('need-bayi'));
      expect(repository.publishedNeeds, hasLength(6));
    });

    test('non-admin tidak bisa menyetujui pengajuan', () async {
      final repository = DemoRepository.seeded();
      addTearDown(repository.dispose);

      await expectLater(
        repository.approve('app-komunitas-01', adminId: 'u-donatur'),
        throwsA(isA<AppException>()),
      );
      expect(repository.pendingVerificationCount, 2);
    });

    test('penolakan wajib memakai alasan minimal 10 karakter', () async {
      final repository = DemoRepository.seeded();
      addTearDown(repository.dispose);

      await expectLater(
        repository.reject(
          'app-kasih-01',
          adminId: 'u-admin',
          reason: 'buram',
        ),
        throwsA(isA<AppException>()),
      );

      await repository.reject(
        'app-kasih-01',
        adminId: 'u-admin',
        reason: 'Dokumen buram dan nomor akta tidak terbaca.',
      );

      final application = repository.applications
          .firstWhere((item) => item.id == 'app-kasih-01');
      expect(application.status, MitraApplicationStatus.rejected);
      expect(application.reviewNote, contains('tidak terbaca'));
    });

    test('submit tanpa dokumen ditolak repository', () async {
      final repository = DemoRepository.seeded();
      addTearDown(repository.dispose);

      final access = await repository.signIn(
        email: 'pending@pakaiankita.id',
        password: DemoRepository.demoPassword,
      );
      final draft = MitraApplication(
        id: '',
        userId: access.userId,
        applicantName: access.displayName,
        applicantEmail: access.email,
        organizationName: 'Komunitas Uji',
        organizationKind: 'Komunitas',
        area: 'Bekasi',
        pointAddress: 'Jl. Uji No. 2',
        contactName: access.displayName,
        contactPhone: '081234567890',
        legalNumber: 'AHU-001',
        legalIssuer: 'Kementerian Hukum dan HAM RI',
        legalIssuedAt: DateTime(2022, 1, 1),
        documents: const [],
      );

      await expectLater(
        repository.submit(draft),
        throwsA(isA<AppException>()),
      );
    });
  });
}
