import 'package:flutter/foundation.dart';
import '../models/onboarding_models.dart';
import '../../../core/models/app_role.dart';

class MockOnboardingStore extends ChangeNotifier {
  static final MockOnboardingStore _instance = MockOnboardingStore._internal();
  factory MockOnboardingStore() => _instance;
  MockOnboardingStore._internal();

  AppRole _currentActiveRole = AppRole.donatur;
  AppRole get currentActiveRole => _currentActiveRole;

  void setActiveRole(AppRole role) {
    _currentActiveRole = role;
    notifyListeners();
  }

  // List of Mitra Legal Submissions
  final List<MitraLegalSubmission> _submissions = [
    MitraLegalSubmission(
      id: 'sub-001',
      orgName: 'Yayasan Insan Kasih Nusantara',
      orgCategory: 'Yayasan Dhuafa & Anak Yatim',
      legalNumber: 'AHU-0012489.AH.01.04.Tahun 2023',
      documentFileName: 'SK_KEMENKUMHAM_INSAN_KASIH.pdf',
      picName: 'H. Budi Santoso, S.Sos',
      picPhone: '081234567890',
      submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: LegalStatus.pending,
    ),
    MitraLegalSubmission(
      id: 'sub-000',
      orgName: 'Posko PMI Tanggap Bencana',
      orgCategory: 'Posko Kemanusiaan & Bencana',
      legalNumber: 'SK-PMI-JATENG-2024-089',
      documentFileName: 'LEGALITAS_PMI_RESMI.pdf',
      picName: 'dr. Sarah Wijaya',
      picPhone: '081122334455',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      status: LegalStatus.approved,
    ),
  ];

  List<MitraLegalSubmission> get submissions => List.unmodifiable(_submissions);

  MitraLegalSubmission? get latestUserSubmission {
    if (_submissions.isEmpty) return null;
    return _submissions.first;
  }

  // Active verified campaigns visible to Donatur
  final List<CampaignNeed> _campaigns = [
    const CampaignNeed(
      id: 'camp-01',
      orgName: 'Posko PMI Tanggap Bencana',
      orgVerified: true,
      title: 'Bantuan 150 Pakaian Hangat Korban Banjir Demak',
      description: 'Dibutuhkan jaket, sweater, dan selimut tebal layak pakai untuk warga terdampak genangan banjir luapan tanggul.',
      category: 'Pakaian Hangat & Jaket',
      requestedQty: 150,
      collectedQty: 92,
      location: 'Kec. Karanganyar, Kab. Demak',
      isEmergency: true,
      deadline: '2 Hari lagi',
      imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=400',
    ),
    const CampaignNeed(
      id: 'camp-02',
      orgName: 'Lazismu Peduli Sandang',
      orgVerified: true,
      title: 'Sandang Sekolah Layak Pakai Anak Dhuafa',
      description: 'Pakaian seragam putih merah, putih biru, serta kemeja harian anak usia 6-12 tahun di pelosok desa.',
      category: 'Pakaian Anak & Seragam',
      requestedQty: 100,
      collectedQty: 64,
      location: 'Kab. Pacitan, Jawa Timur',
      isEmergency: false,
      deadline: '5 Hari lagi',
      imageUrl: 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?auto=format&fit=crop&q=80&w=400',
    ),
    const CampaignNeed(
      id: 'camp-03',
      orgName: 'Panti Sosial Tresna Werdha',
      orgVerified: true,
      title: 'Kebutuhan Kaos Katun dan Daster Nyaman Lansia',
      description: 'Pakaian bahan katun yang lembut dan mudah dicuci untuk 40 kakek dan nenek penghuni panti.',
      category: 'Pakaian Santai Dewasa',
      requestedQty: 80,
      collectedQty: 35,
      location: 'Surabaya, Jawa Timur',
      isEmergency: false,
      deadline: '10 Hari lagi',
      imageUrl: 'https://images.unsplash.com/photo-1523381294911-8d3cead13475?auto=format&fit=crop&q=80&w=400',
    ),
  ];

  List<CampaignNeed> get campaigns => List.unmodifiable(_campaigns);

  // Submit legal document from Mitra
  void submitMitraLegal({
    required String orgName,
    required String orgCategory,
    required String legalNumber,
    required String documentFileName,
    required String picName,
    required String picPhone,
  }) {
    final newSub = MitraLegalSubmission(
      id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      orgName: orgName,
      orgCategory: orgCategory,
      legalNumber: legalNumber,
      documentFileName: documentFileName,
      picName: picName,
      picPhone: picPhone,
      submittedAt: DateTime.now(),
      status: LegalStatus.pending,
    );

    _submissions.insert(0, newSub);
    notifyListeners();
  }

  // Admin approves a submission
  void approveSubmission(String submissionId) {
    final index = _submissions.indexWhere((s) => s.id == submissionId);
    if (index != -1) {
      final existing = _submissions[index];
      _submissions[index] = existing.copyWith(
        status: LegalStatus.approved,
        adminNotes: 'Dokumen legalitas SK Kemenkumham & Izin Dinsos valid.',
      );

      // Also create an initial campaign by this approved mitra to demonstrate output
      _campaigns.insert(
        0,
        CampaignNeed(
          id: 'camp-${DateTime.now().millisecondsSinceEpoch}',
          orgName: existing.orgName,
          orgVerified: true,
          title: 'Program Bantuan Pakaian Bayi & Balita Layak Pakai',
          description: 'Penyaluran pakaian bayi baru lahir sampai balita yang dikelola resmi oleh ${existing.orgName}.',
          category: 'Pakaian Bayi & Balita',
          requestedQty: 100,
          collectedQty: 12,
          location: 'Surabaya & Sekitarnya',
          isEmergency: false,
          deadline: '7 Hari lagi',
          imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&q=80&w=400',
        ),
      );

      notifyListeners();
    }
  }

  // Admin rejects a submission
  void rejectSubmission(String submissionId, String reason) {
    final index = _submissions.indexWhere((s) => s.id == submissionId);
    if (index != -1) {
      final existing = _submissions[index];
      _submissions[index] = existing.copyWith(
        status: LegalStatus.rejected,
        adminNotes: reason,
      );
      notifyListeners();
    }
  }
}

