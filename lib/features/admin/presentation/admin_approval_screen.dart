import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/models/onboarding_models.dart';
import '../../onboarding/services/mock_onboarding_store.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  int _selectedTab = 0; // 0: Pending, 1: Approved

  void _showDocumentPreview(BuildContext context, MitraLegalSubmission submission) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.picture_as_pdf_rounded, color: AppColors.emergency),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pratinjau Dokumen Legalitas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_outlined, size: 48, color: AppColors.primary),
                    const SizedBox(height: 10),
                    Text(
                      submission.documentFileName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nomor SK: ${submission.legalNumber}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tercatat di Ditjen AHU Kemenkumham RI',
                      style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Lembaga: ${submission.orgName}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              Text(
                'PIC: ${submission.picName} (${submission.picPhone})',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _handleApprove(BuildContext context, String submissionId, String orgName) {
    final store = MockOnboardingStore();
    store.approveSubmission(submissionId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil! "$orgName" kini aktif sebagai Mitra Terverifikasi.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleReject(BuildContext context, String submissionId, String orgName) {
    final reasonController = TextEditingController(text: 'Dokumen SK buram / masa berlaku habis');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tolak Pengajuan Mitra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tulis alasan penolakan untuk $orgName:'),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(hintText: 'Alasan penolakan...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final store = MockOnboardingStore();
                store.rejectSubmission(submissionId, reasonController.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengajuan ditolak dengan catatan revisi.'),
                    backgroundColor: AppColors.emergency,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergency),
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = MockOnboardingStore();

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final pendingList = store.submissions.where((s) => s.status == LegalStatus.pending).toList();
        final approvedList = store.submissions.where((s) => s.status == LegalStatus.approved).toList();
        final activeList = _selectedTab == 0 ? pendingList : approvedList;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Panel Admin • Verifikasi Mitra'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Segmented Tabs
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? AppColors.primaryLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Perlu Tinjauan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedTab == 0 ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                                if (pendingList.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${pendingList.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? AppColors.successLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedTab == 1 ? AppColors.success : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Telah Disahkan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedTab == 1 ? AppColors.success : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${approvedList.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _selectedTab == 1 ? AppColors.success : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Submissions List
                Expanded(
                  child: activeList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedTab == 0 ? Icons.check_circle_outline : Icons.inbox_outlined,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedTab == 0
                                    ? 'Semua pengajuan mitra telah divalidasi!'
                                    : 'Belum ada mitra terverifikasi.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: activeList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = activeList[index];
                            final isPending = item.status == LegalStatus.pending;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isPending ? AppColors.warningLight : AppColors.successLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isPending ? Icons.pending_actions_rounded : Icons.verified_rounded,
                                          color: isPending ? AppColors.warning : AppColors.success,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.orgName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.orgCategory,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20, color: AppColors.border),

                                  // Legal Number & File
                                  Row(
                                    children: [
                                      const Icon(Icons.badge_outlined, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'SK Kemenkumham: ${item.legalNumber}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'PIC: ${item.picName} (${item.picPhone})',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // File Document Button
                                  OutlinedButton.icon(
                                    onPressed: () => _showDocumentPreview(context, item),
                                    icon: const Icon(Icons.visibility_outlined, size: 16),
                                    label: Text(
                                      'Periksa Berkas: ${item.documentFileName}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 38),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                  ),

                                  if (isPending) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _handleReject(context, item.id, item.orgName),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.emergency,
                                              side: const BorderSide(color: AppColors.emergency),
                                              minimumSize: const Size(double.infinity, 42),
                                            ),
                                            child: const Text('Tolak'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _handleApprove(context, item.id, item.orgName),
                                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                            label: const Text('Setujui Mitra'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              minimumSize: const Size(double.infinity, 42),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

