import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../core/models/app_context.dart';
import '../core/models/app_role.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../features/donations/models/donation.dart';
import '../features/donations/repositories/donations_repository.dart';
import '../features/mitra/models/mitra_application.dart';
import '../features/mitra/repositories/mitra_verification_repository.dart';
import '../features/needs/models/need.dart';
import '../features/needs/repositories/needs_repository.dart';
import 'demo_account.dart';

/// Backend simulasi untuk seluruh alur demo.
/// Semua data hidup di memori dan tidak menyentuh Supabase.
class DemoRepository extends ChangeNotifier
    implements
        AuthRepository,
        MitraVerificationRepository,
        NeedsRepository,
        DonationsRepository {
  DemoRepository.seeded() {
    _seed();
  }

  final Map<String, DemoAccount> _accounts = {};
  final Map<String, Organization> _organizations = {};
  final Map<String, MitraApplication> _applications = {};
  final List<Need> _needs = [];
  final List<Donation> _donations = [];

  String? _currentUserId;
  int _counter = 0;

  static const demoPassword = 'demo1234';

  // ---------------------------------------------------------------------------
  // Getter untuk UI
  // ---------------------------------------------------------------------------

  String? get currentUserId => _currentUserId;

  List<DemoAccount> get accounts {
    final list = _accounts.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(list);
  }

  List<Organization> get organizations {
    final list = _organizations.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(list);
  }

  List<Need> get allNeeds => List.unmodifiable(_needs);

  List<Need> get publishedNeeds {
    final list = _needs
        .where(
          (need) =>
              need.isOpen &&
              need.organizationVerified &&
              (_organizations[need.organizationId]?.active ?? false),
        )
        .toList();
    list.sort((a, b) {
      if (a.urgent != b.urgent) return a.urgent ? -1 : 1;
      return a.deadline.compareTo(b.deadline);
    });
    return List.unmodifiable(list);
  }

  List<MitraApplication> get applications {
    final list = _applications.values.toList();
    list.sort(_sortApplications);
    return List.unmodifiable(list);
  }

  int get pendingVerificationCount => _applications.values
      .where((application) => application.status.isPending)
      .length;

  int get verifiedOrganizationCount =>
      _organizations.values.where((org) => org.verified && org.active).length;

  int get openNeedCount => publishedNeeds.length;

  List<Donation> donationsFor(String userId) {
    final list = _donations.where((donation) => donation.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  Organization? organizationById(String? id) =>
      id == null ? null : _organizations[id];

  /// Konteks sinkron untuk listener lokal, tanpa menunggu jaringan.
  AppContext? peekAccess(String userId) {
    final account = _accounts[userId];
    return account == null ? null : _contextFor(account);
  }

  MitraApplication? applicationFor(String userId) {
    final list = _applications.values
        .where((application) => application.userId == userId)
        .toList();
    if (list.isEmpty) return null;
    list.sort(_sortApplications);
    return list.first;
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  @override
  Future<AppContext> signIn({
    required String email,
    required String password,
  }) async {
    await _latency();
    final normalized = email.trim().toLowerCase();
    DemoAccount? account;
    for (final candidate in _accounts.values) {
      if (candidate.email.toLowerCase() == normalized) {
        account = candidate;
        break;
      }
    }
    if (account == null || account.password != password) {
      throw const AppException('Email atau kata sandi tidak cocok.');
    }
    _currentUserId = account.id;
    notifyListeners();
    return _contextFor(account);
  }

  @override
  Future<AppContext> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _latency();
    final normalized = email.trim().toLowerCase();
    if (_accounts.values.any((account) => account.email.toLowerCase() == normalized)) {
      throw const AppException('Email sudah digunakan. Coba masuk atau pakai email lain.');
    }
    final account = DemoAccount(
      id: _nextId('user'),
      name: name.trim(),
      email: normalized,
      password: password,
      roles: {AppRole.donatur},
      onboardingCompleted: false,
    );
    _accounts[account.id] = account;
    _currentUserId = account.id;
    notifyListeners();
    return _contextFor(account);
  }

  @override
  Future<AppContext> signInWithGoogle() async {
    await _latency();
    var account = _accounts.values
        .where((candidate) => candidate.email == 'google@pakaiankita.id')
        .firstOrNull;
    if (account == null) {
      account = DemoAccount(
        id: _nextId('user'),
        name: 'Pengguna Google',
        email: 'google@pakaiankita.id',
        password: demoPassword,
        roles: {AppRole.donatur},
        onboardingCompleted: false,
      );
      _accounts[account.id] = account;
    }
    _currentUserId = account.id;
    notifyListeners();
    return _contextFor(account);
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    notifyListeners();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _latency();
    if (!_isEmail(email.trim())) {
      throw const AppException('Format email belum benar.');
    }
  }

  @override
  Future<AppContext> loadAccess(String userId) async {
    final account = _accounts[userId];
    if (account == null) {
      throw const AppException('Sesi tidak ditemukan. Silakan masuk lagi.');
    }
    return _contextFor(account);
  }

  @override
  Future<AppContext> chooseRole({
    required String userId,
    required RoleIntent intent,
  }) async {
    final account = _accounts[userId];
    if (account == null) {
      throw const AppException('Akun tidak ditemukan.');
    }
    account.onboardingCompleted = true;
    account.roleIntent = intent;
    account.roles.add(AppRole.donatur);
    notifyListeners();
    return _contextFor(account);
  }

  // ---------------------------------------------------------------------------
  // Verifikasi mitra
  // ---------------------------------------------------------------------------

  @override
  Future<MitraApplication?> getMine(String userId) async => applicationFor(userId);

  @override
  Future<MitraApplication> saveDraft(MitraApplication application) async {
    await _latency(short: true);
    final account = _accounts[application.userId];
    if (account == null) {
      throw const AppException('Sesi tidak ditemukan. Silakan masuk lagi.');
    }
    final id = application.id.isEmpty ? _nextId('app') : application.id;
    final stored = application.copyWith(id: id, status: MitraApplicationStatus.draft);
    _applications[id] = stored;
    account.onboardingCompleted = true;
    account.roleIntent = RoleIntent.mitra;
    notifyListeners();
    return stored;
  }

  @override
  Future<MitraApplication> submit(MitraApplication application) async {
    await _latency(short: true);
    final account = _accounts[application.userId];
    if (account == null) {
      throw const AppException('Sesi tidak ditemukan. Silakan masuk lagi.');
    }
    if (application.documents.isEmpty) {
      throw const AppException('Unggah minimal satu dokumen legalitas.');
    }
    if (application.organizationName.trim().isEmpty ||
        application.legalNumber.trim().isEmpty ||
        application.legalIssuedAt == null) {
      throw const AppException('Lengkapi data lembaga dan legalitas terlebih dahulu.');
    }

    final existing = applicationFor(application.userId);
    if (existing?.status.isApproved ?? false) {
      throw const AppException('Pengajuan ini sudah disetujui.');
    }

    var organizationId = application.organizationId;
    if (organizationId == null || !_organizations.containsKey(organizationId)) {
      organizationId = _nextId('org');
    }
    final previousOrg = _organizations[organizationId];
    final organization = Organization(
      id: organizationId,
      name: application.organizationName.trim(),
      kind: application.organizationKind,
      area: application.area.trim(),
      pointAddress: application.pointAddress.trim(),
      contactName: application.contactName.trim(),
      contactPhone: application.contactPhone.trim(),
      verified: previousOrg?.verified ?? false,
      active: previousOrg?.active ?? true,
    );
    _organizations[organizationId] = organization;

    final id = application.id.isEmpty ? _nextId('app') : application.id;
    final stored = application.copyWith(
      id: id,
      status: MitraApplicationStatus.submitted,
      reviewNote: null,
      reviewedAt: null,
      submittedAt: DateTime.now(),
      organizationId: organizationId,
    );
    _applications[id] = stored;
    account.onboardingCompleted = true;
    account.roleIntent = RoleIntent.mitra;
    notifyListeners();
    return stored;
  }

  @override
  Future<List<MitraApplication>> list({MitraApplicationStatus? status}) async {
    final filtered = applications
        .where((application) => status == null || application.status == status)
        .toList();
    return filtered;
  }

  @override
  Future<void> approve(String applicationId, {required String adminId}) async {
    await _latency(short: true);
    _requireAdmin(adminId);
    final application = _applications[applicationId];
    if (application == null) {
      throw const AppException('Pengajuan tidak ditemukan.');
    }
    if (application.userId == adminId) {
      throw const AppException('Admin tidak dapat menyetujui pengajuannya sendiri.');
    }
    if (application.status.isApproved) return;

    final organizationId = application.organizationId ?? _nextId('org');
    final previousOrg = _organizations[organizationId];
    final organization = Organization(
      id: organizationId,
      name: application.organizationName.trim(),
      kind: application.organizationKind,
      area: application.area.trim(),
      pointAddress: application.pointAddress.trim(),
      contactName: application.contactName.trim(),
      contactPhone: application.contactPhone.trim(),
      verified: true,
      active: previousOrg?.active ?? true,
    );
    _organizations[organizationId] = organization;

    _applications[applicationId] = application.copyWith(
      status: MitraApplicationStatus.approved,
      reviewedAt: DateTime.now(),
      organizationId: organizationId,
    );

    final account = _accounts[application.userId];
    if (account != null) {
      account.roles.addAll({AppRole.donatur, AppRole.mitra});
      account.organizationId = organizationId;
      account.roleIntent = RoleIntent.mitra;
      account.onboardingCompleted = true;
    }

    for (var index = 0; index < _needs.length; index++) {
      final need = _needs[index];
      if (need.organizationId == organizationId) {
        _needs[index] = need.copyWith(
          organizationName: organization.name,
          organizationVerified: true,
        );
      }
    }
    notifyListeners();
  }

  @override
  Future<void> reject(
    String applicationId, {
    required String adminId,
    required String reason,
  }) async {
    await _latency(short: true);
    _requireAdmin(adminId);
    final application = _applications[applicationId];
    if (application == null) {
      throw const AppException('Pengajuan tidak ditemukan.');
    }
    if (application.userId == adminId) {
      throw const AppException('Admin tidak dapat meninjau pengajuannya sendiri.');
    }
    final trimmed = reason.trim();
    if (trimmed.length < 10) {
      throw const AppException('Alasan penolakan minimal 10 karakter.');
    }
    _applications[applicationId] = application.copyWith(
      status: MitraApplicationStatus.rejected,
      reviewNote: trimmed,
      reviewedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Kebutuhan
  // ---------------------------------------------------------------------------

  @override
  Future<List<Need>> listPublished() async => publishedNeeds;

  @override
  Future<List<Need>> listAll() async => allNeeds;

  @override
  Future<List<Need>> listForOrganization(String organizationId) async {
    final list = _needs
        .where((need) => need.organizationId == organizationId)
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    return List.unmodifiable(list);
  }

  @override
  Future<Need> createNeed(Need need) async {
    await _latency(short: true);
    final account = _currentUserId == null ? null : _accounts[_currentUserId];
    final organization = _organizations[need.organizationId];
    if (account == null ||
        !account.roles.contains(AppRole.mitra) ||
        organization == null ||
        !organization.verified ||
        !organization.active) {
      throw const AppException(
        'Hanya mitra terverifikasi yang dapat membuat kebutuhan.',
      );
    }
    final stored = Need(
      id: need.id.isEmpty ? _nextId('need') : need.id,
      organizationId: organization.id,
      organizationName: organization.name,
      organizationVerified: organization.verified,
      title: need.title,
      description: need.description,
      city: organization.area,
      pointName: need.pointName,
      pointAddress: need.pointAddress,
      deadline: need.deadline,
      items: need.items,
      createdAt: DateTime.now(),
      status: NeedStatus.open,
      urgent: need.urgent,
    );
    _needs.insert(0, stored);
    notifyListeners();
    return stored;
  }

  // ---------------------------------------------------------------------------
  // Donasi
  // ---------------------------------------------------------------------------

  @override
  Future<List<Donation>> listMine(String userId) async => donationsFor(userId);

  @override
  Future<Donation> createDonation(Donation donation) async {
    await _latency(short: true);
    if (_currentUserId == null || donation.userId != _currentUserId) {
      throw const AppException('Sesi tidak cocok. Silakan masuk lagi.');
    }
    final stored = Donation(
      id: donation.id.isEmpty ? _nextId('donation') : donation.id,
      userId: donation.userId,
      needId: donation.needId,
      needTitle: donation.needTitle,
      organizationName: donation.organizationName,
      category: donation.category,
      sizeLabel: donation.sizeLabel,
      quantity: donation.quantity,
      method: donation.method,
      scheduledAt: donation.scheduledAt,
      status: DonationStatus.submitted,
      createdAt: DateTime.now(),
      note: donation.note,
    );
    _donations.insert(0, stored);
    notifyListeners();
    return stored;
  }

  // ---------------------------------------------------------------------------
  // Demo control
  // ---------------------------------------------------------------------------

  void reset() {
    _seed();
    _currentUserId = null;
    notifyListeners();
  }

  AppContext _contextFor(DemoAccount account) {
    final application = applicationFor(account.id);
    return AppContext(
      userId: account.id,
      displayName: account.name,
      email: account.email,
      roles: {...account.roles},
      ui: account.ui,
      onboardingCompleted: account.onboardingCompleted,
      roleIntent: account.roleIntent,
      mitraApplication: application,
      organization: _organizations[account.organizationId],
    );
  }

  void _requireAdmin(String adminId) {
    final account = _accounts[adminId];
    if (account == null ||
        !account.roles.contains(AppRole.admin) ||
        account.ui != AppUiShell.admin) {
      throw const AppException('Aksi ini hanya untuk admin.');
    }
  }

  Future<void> _latency({bool short = false}) =>
      Future<void>.delayed(Duration(milliseconds: short ? 180 : 420));

  String _nextId(String prefix) {
    _counter += 1;
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-$_counter';
  }

  bool _isEmail(String value) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(value);

  int _sortApplications(MitraApplication a, MitraApplication b) {
    final aPending = a.status.isPending ? 0 : 1;
    final bPending = b.status.isPending ? 0 : 1;
    if (aPending != bPending) return aPending - bPending;
    final aDate = a.submittedAt ?? DateTime(2000);
    final bDate = b.submittedAt ?? DateTime(2000);
    return bDate.compareTo(aDate);
  }

  // ---------------------------------------------------------------------------
  // Seed
  // ---------------------------------------------------------------------------

  void _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _accounts.clear();
    _organizations.clear();
    _applications.clear();
    _needs.clear();
    _donations.clear();
    _counter = 0;

    const donatur = RoleIntent.donatur;
    const mitra = RoleIntent.mitra;

    _accounts['u-donatur'] = DemoAccount(
      id: 'u-donatur',
      name: 'Sari Wulandari',
      email: 'donatur@pakaiankita.id',
      password: demoPassword,
      roles: {AppRole.donatur},
      onboardingCompleted: true,
      roleIntent: donatur,
    );
    _accounts['u-mitra'] = DemoAccount(
      id: 'u-mitra',
      name: 'Ahmad Fauzi',
      email: 'mitra@pakaiankita.id',
      password: demoPassword,
      roles: {AppRole.donatur, AppRole.mitra},
      onboardingCompleted: true,
      roleIntent: mitra,
      organizationId: 'org-sahabat',
    );
    _accounts['u-pending'] = DemoAccount(
      id: 'u-pending',
      name: 'Nadia Putri',
      email: 'pending@pakaiankita.id',
      password: demoPassword,
      roles: {AppRole.donatur},
      onboardingCompleted: true,
      roleIntent: mitra,
    );
    _accounts['u-ditolak'] = DemoAccount(
      id: 'u-ditolak',
      name: 'Rizky Hidayat',
      email: 'ditolak@pakaiankita.id',
      password: demoPassword,
      roles: {AppRole.donatur},
      onboardingCompleted: true,
      roleIntent: mitra,
    );
    _accounts['u-usulan'] = DemoAccount(
      id: 'u-usulan',
      name: 'Maya Lestari',
      email: 'usulan@pakaiankita.id',
      password: demoPassword,
      roles: {AppRole.donatur},
      onboardingCompleted: true,
      roleIntent: mitra,
    );
    _accounts['u-admin'] = DemoAccount(
      id: 'u-admin',
      name: 'Admin PakaianKita',
      email: 'admin@pakaiankita.id',
      password: demoPassword,
      roles: {AppRole.donatur, AppRole.admin},
      ui: AppUiShell.admin,
      onboardingCompleted: true,
      roleIntent: donatur,
    );
    _accounts['u-google'] = DemoAccount(
      id: 'u-google',
      name: 'Pengguna Google',
      email: 'google@pakaiankita.id',
      password: demoPassword,
      roles: {AppRole.donatur},
      onboardingCompleted: false,
    );

    _organizations['org-sahabat'] = const Organization(
      id: 'org-sahabat',
      name: 'Yayasan Sahabat Sandang',
      kind: 'Lembaga sosial',
      area: 'Jakarta Selatan',
      pointAddress: 'Jl. Cempaka Putih No. 14, Tebet',
      contactName: 'Ahmad Fauzi',
      contactPhone: '0812 3456 7890',
      verified: true,
      active: true,
    );
    _organizations['org-pesisir'] = const Organization(
      id: 'org-pesisir',
      name: 'Posko Peduli Pesisir',
      kind: 'Posko bencana',
      area: 'Surabaya',
      pointAddress: 'Jl. Tambaksari No. 8',
      contactName: 'Rani Kusuma',
      contactPhone: '0813 2233 4455',
      verified: true,
      active: true,
    );
    _organizations['org-tunas'] = const Organization(
      id: 'org-tunas',
      name: 'Panti Asuhan Tunas Harapan',
      kind: 'Panti asuhan',
      area: 'Bandung',
      pointAddress: 'Jl. Cikutra No. 102',
      contactName: 'Sri Handayani',
      contactPhone: '0821 1122 3344',
      verified: true,
      active: true,
    );
    _organizations['org-bumi'] = const Organization(
      id: 'org-bumi',
      name: 'Rumah Singgah Bumi',
      kind: 'Komunitas',
      area: 'Yogyakarta',
      pointAddress: 'Jl. Suryodiningratan No. 21',
      contactName: 'Dimas Prakoso',
      contactPhone: '0857 8899 0011',
      verified: true,
      active: true,
    );
    _organizations['org-komunitas'] = const Organization(
      id: 'org-komunitas',
      name: 'Komunitas Langkah Baru',
      kind: 'Komunitas',
      area: 'Bekasi',
      pointAddress: 'Jl. Harapan Baru No. 7',
      contactName: 'Nadia Putri',
      contactPhone: '0812 9000 1122',
      verified: false,
      active: true,
    );
    _organizations['org-cintakasih'] = const Organization(
      id: 'org-cintakasih',
      name: 'Lembaga Cinta Kasih',
      kind: 'Lembaga sosial',
      area: 'Depok',
      pointAddress: 'Jl. Margonda Raya No. 45',
      contactName: 'Maya Lestari',
      contactPhone: '0813 7000 8899',
      verified: false,
      active: true,
    );
    _organizations['org-cahaya'] = const Organization(
      id: 'org-cahaya',
      name: 'Yayasan Cahaya Ibu',
      kind: 'Panti asuhan',
      area: 'Semarang',
      pointAddress: 'Jl. Pandanaran No. 3',
      contactName: 'Rizky Hidayat',
      contactPhone: '0856 4433 2211',
      verified: false,
      active: true,
    );

    _needs.addAll([
      Need(
        id: 'need-anak',
        organizationId: 'org-sahabat',
        organizationName: 'Yayasan Sahabat Sandang',
        organizationVerified: true,
        title: 'Pakaian harian anak',
        description:
            'Pakaian bersih dan utuh untuk anak usia 7–8 tahun di binaan yayasan. Kaos dan celana berbahan nyaman paling dibutuhkan.',
        city: 'Jakarta Selatan',
        pointName: 'Posko Tebet',
        pointAddress: 'Jl. Cempaka Putih No. 14, Tebet',
        deadline: today.add(const Duration(days: 7)),
        items: const [
          NeedItem(
            category: NeedCategory.anak,
            sizeLabel: '7–8 tahun',
            ageGroup: 'Anak',
            requestedQty: 8,
            receivedQty: 5,
          ),
        ],
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      Need(
        id: 'need-seragam',
        organizationId: 'org-pesisir',
        organizationName: 'Posko Peduli Pesisir',
        organizationVerified: true,
        title: 'Seragam sekolah layak pakai',
        description:
            'Anak-anak di kawasan pesisir membutuhkan seragam sekolah untuk semester baru. Warna bebas, kondisi masih layak.',
        city: 'Surabaya',
        pointName: 'Posko Tambaksari',
        pointAddress: 'Jl. Tambaksari No. 8',
        deadline: today.add(const Duration(days: 4)),
        items: const [
          NeedItem(
            category: NeedCategory.sekolah,
            sizeLabel: '8–10 tahun',
            ageGroup: 'Anak',
            requestedQty: 12,
            receivedQty: 4,
          ),
        ],
        createdAt: today.subtract(const Duration(days: 1)),
        urgent: true,
      ),
      Need(
        id: 'need-jaket',
        organizationId: 'org-tunas',
        organizationName: 'Panti Asuhan Tunas Harapan',
        organizationVerified: true,
        title: 'Jaket dan selimut dewasa',
        description:
            'Menjelang musim hujan, panti membutuhkan jaket dan selimut layak pakai untuk penghuni dewasa.',
        city: 'Bandung',
        pointName: 'Aula Panti Cikutra',
        pointAddress: 'Jl. Cikutra No. 102',
        deadline: today.add(const Duration(days: 10)),
        items: const [
          NeedItem(
            category: NeedCategory.dewasa,
            sizeLabel: 'L–XL',
            ageGroup: 'Dewasa',
            requestedQty: 20,
            receivedQty: 6,
          ),
        ],
        createdAt: today.subtract(const Duration(days: 3)),
        urgent: true,
      ),
      Need(
        id: 'need-kemeja',
        organizationId: 'org-bumi',
        organizationName: 'Rumah Singgah Bumi',
        organizationVerified: true,
        title: 'Kemeja kerja untuk warga binaan',
        description:
            'Kemeja lengan panjang untuk warga binaan yang sedang mencari kerja. Warna netral lebih membantu.',
        city: 'Yogyakarta',
        pointName: 'Rumah Singgah Bumi',
        pointAddress: 'Jl. Suryodiningratan No. 21',
        deadline: today.add(const Duration(days: 14)),
        items: const [
          NeedItem(
            category: NeedCategory.dewasa,
            sizeLabel: 'M–L',
            ageGroup: 'Dewasa',
            requestedQty: 10,
            receivedQty: 7,
          ),
        ],
        createdAt: today.subtract(const Duration(days: 4)),
      ),
      Need(
        id: 'need-bayi',
        organizationId: 'org-komunitas',
        organizationName: 'Komunitas Langkah Baru',
        organizationVerified: false,
        title: 'Pakaian bayi 0–2 tahun',
        description:
            'Kebutuhan pakaian bayi untuk keluarga dampingan di Bekasi. Menunggu verifikasi lembaga sebelum tampil ke donatur.',
        city: 'Bekasi',
        pointName: 'Sekretariat Langkah Baru',
        pointAddress: 'Jl. Harapan Baru No. 7',
        deadline: today.add(const Duration(days: 12)),
        items: const [
          NeedItem(
            category: NeedCategory.bayi,
            sizeLabel: '0–2 tahun',
            ageGroup: 'Bayi',
            requestedQty: 15,
            receivedQty: 0,
          ),
        ],
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      Need(
        id: 'need-kaos',
        organizationId: 'org-cintakasih',
        organizationName: 'Lembaga Cinta Kasih',
        organizationVerified: false,
        title: 'Kaos kaki dan pakaian dalam',
        description:
            'Perlengkapan dasar untuk paket bantuan bulanan keluarga dampingan.',
        city: 'Depok',
        pointName: 'Gudang Cinta Kasih',
        pointAddress: 'Jl. Margonda Raya No. 45',
        deadline: today.add(const Duration(days: 9)),
        items: const [
          NeedItem(
            category: NeedCategory.dewasa,
            sizeLabel: 'All size',
            ageGroup: 'Dewasa',
            requestedQty: 30,
            receivedQty: 2,
          ),
        ],
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      Need(
        id: 'need-koko',
        organizationId: 'org-sahabat',
        organizationName: 'Yayasan Sahabat Sandang',
        organizationVerified: true,
        title: 'Baju koko untuk pesantren',
        description: 'Kebutuhan sudah tercukupi lewat donasi sebelumnya.',
        city: 'Jakarta Selatan',
        pointName: 'Posko Tebet',
        pointAddress: 'Jl. Cempaka Putih No. 14, Tebet',
        deadline: today.add(const Duration(days: 2)),
        items: const [
          NeedItem(
            category: NeedCategory.dewasa,
            sizeLabel: 'L–XL',
            ageGroup: 'Dewasa',
            requestedQty: 25,
            receivedQty: 25,
          ),
        ],
        createdAt: today.subtract(const Duration(days: 15)),
        status: NeedStatus.fulfilled,
      ),
      Need(
        id: 'need-selimut',
        organizationId: 'org-pesisir',
        organizationName: 'Posko Peduli Pesisir',
        organizationVerified: true,
        title: 'Selimut untuk posko',
        description:
            'Stok selimut posko menipis setelah banjir. Bantu lengkapi kebutuhan warga di pengungsian.',
        city: 'Surabaya',
        pointName: 'Posko Tambaksari',
        pointAddress: 'Jl. Tambaksari No. 8',
        deadline: today.add(const Duration(days: 5)),
        items: const [
          NeedItem(
            category: NeedCategory.dewasa,
            sizeLabel: 'All size',
            ageGroup: 'Dewasa',
            requestedQty: 18,
            receivedQty: 3,
          ),
        ],
        createdAt: today.subtract(const Duration(days: 5)),
      ),
    ]);

    _applications['app-mitra-01'] = MitraApplication(
      id: 'app-mitra-01',
      userId: 'u-mitra',
      applicantName: 'Ahmad Fauzi',
      applicantEmail: 'mitra@pakaiankita.id',
      organizationName: 'Yayasan Sahabat Sandang',
      organizationKind: 'Lembaga sosial',
      area: 'Jakarta Selatan',
      pointAddress: 'Jl. Cempaka Putih No. 14, Tebet',
      contactName: 'Ahmad Fauzi',
      contactPhone: '0812 3456 7890',
      beneficiaryEstimate: 120,
      legalNumber: 'AHU-0012345.AH.01.07.TAHUN 2021',
      legalIssuer: 'Kementerian Hukum dan HAM RI',
      legalIssuedAt: DateTime(2021, 6, 14),
      documents: const [
        MitraDocument(
          name: 'SK-Kemenkumham-Sahabat-Sandang.pdf',
          sizeBytes: 842 * 1024,
          mimeType: 'application/pdf',
          isSample: true,
        ),
      ],
      status: MitraApplicationStatus.approved,
      submittedAt: today.subtract(const Duration(days: 40)),
      reviewedAt: today.subtract(const Duration(days: 39)),
      organizationId: 'org-sahabat',
    );
    _applications['app-komunitas-01'] = MitraApplication(
      id: 'app-komunitas-01',
      userId: 'u-pending',
      applicantName: 'Nadia Putri',
      applicantEmail: 'pending@pakaiankita.id',
      organizationName: 'Komunitas Langkah Baru',
      organizationKind: 'Komunitas',
      area: 'Bekasi',
      pointAddress: 'Jl. Harapan Baru No. 7',
      contactName: 'Nadia Putri',
      contactPhone: '0812 9000 1122',
      beneficiaryEstimate: 45,
      legalNumber: 'AHU-0098765.AH.01.07.TAHUN 2023',
      legalIssuer: 'Kementerian Hukum dan HAM RI',
      legalIssuedAt: DateTime(2023, 2, 21),
      documents: const [
        MitraDocument(
          name: 'SK-Kemenkumham-Langkah-Baru.pdf',
          sizeBytes: 1_204 * 1024,
          mimeType: 'application/pdf',
          isSample: true,
        ),
        MitraDocument(
          name: 'Akta-Notaris-Langkah-Baru.jpg',
          sizeBytes: 640 * 1024,
          mimeType: 'image/jpeg',
          isSample: true,
        ),
      ],
      status: MitraApplicationStatus.submitted,
      submittedAt: today.subtract(const Duration(days: 2)),
      organizationId: 'org-komunitas',
    );
    _applications['app-kasih-01'] = MitraApplication(
      id: 'app-kasih-01',
      userId: 'u-usulan',
      applicantName: 'Maya Lestari',
      applicantEmail: 'usulan@pakaiankita.id',
      organizationName: 'Lembaga Cinta Kasih',
      organizationKind: 'Lembaga sosial',
      area: 'Depok',
      pointAddress: 'Jl. Margonda Raya No. 45',
      contactName: 'Maya Lestari',
      contactPhone: '0813 7000 8899',
      beneficiaryEstimate: 80,
      legalNumber: '188/KS/2022',
      legalIssuer: 'Dinas Sosial Kota Depok',
      legalIssuedAt: DateTime(2022, 8, 3),
      documents: const [
        MitraDocument(
          name: 'Surat-Rekomendasi-Dinsos-Depok.pdf',
          sizeBytes: 510 * 1024,
          mimeType: 'application/pdf',
          isSample: true,
        ),
      ],
      status: MitraApplicationStatus.underReview,
      submittedAt: today.subtract(const Duration(days: 1)),
      organizationId: 'org-cintakasih',
    );
    _applications['app-ditolak-01'] = MitraApplication(
      id: 'app-ditolak-01',
      userId: 'u-ditolak',
      applicantName: 'Rizky Hidayat',
      applicantEmail: 'ditolak@pakaiankita.id',
      organizationName: 'Yayasan Cahaya Ibu',
      organizationKind: 'Panti asuhan',
      area: 'Semarang',
      pointAddress: 'Jl. Pandanaran No. 3',
      contactName: 'Rizky Hidayat',
      contactPhone: '0856 4433 2211',
      beneficiaryEstimate: 60,
      legalNumber: '45/YCI/2020',
      legalIssuer: 'Notaris Andini S.H.',
      legalIssuedAt: DateTime(2020, 11, 12),
      documents: const [
        MitraDocument(
          name: 'Akta-Yayasan-Cahaya-Ibu.jpg',
          sizeBytes: 320 * 1024,
          mimeType: 'image/jpeg',
          isSample: true,
        ),
      ],
      status: MitraApplicationStatus.rejected,
      reviewNote:
          'Hasil pindai dokumen terlalu buram untuk membaca nomor akta. Unggah ulang dokumen yang memuat nomor dan tanggal dengan jelas.',
      submittedAt: today.subtract(const Duration(days: 7)),
      reviewedAt: today.subtract(const Duration(days: 5)),
      organizationId: 'org-cahaya',
    );

    _donations.addAll([
      Donation(
        id: 'donation-01',
        userId: 'u-donatur',
        needId: 'need-jaket',
        needTitle: 'Jaket dan selimut dewasa',
        organizationName: 'Panti Asuhan Tunas Harapan',
        category: 'Jaket',
        sizeLabel: 'L',
        quantity: 4,
        method: DonationMethod.pickup,
        scheduledAt: today.subtract(const Duration(days: 2)),
        status: DonationStatus.curated,
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      Donation(
        id: 'donation-02',
        userId: 'u-donatur',
        needId: 'need-anak',
        needTitle: 'Pakaian harian anak',
        organizationName: 'Yayasan Sahabat Sandang',
        category: 'Pakaian anak',
        sizeLabel: '7–8 tahun',
        quantity: 6,
        method: DonationMethod.dropOff,
        scheduledAt: today.subtract(const Duration(days: 9)),
        status: DonationStatus.received,
        createdAt: today.subtract(const Duration(days: 10)),
      ),
    ]);
  }
}
