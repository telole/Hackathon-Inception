import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/models/onboarding_models.dart';
import '../../onboarding/services/mock_onboarding_store.dart';
import '../../admin/presentation/admin_approval_screen.dart';
import 'mitra_dashboard_screen.dart';

class MitraPendingScreen extends StatelessWidget {
  const MitraPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MockOnboardingStore();

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final submission = store.latestUserSubmission;
        final isApproved = submission?.status == LegalStatus.approved;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Status Pendaftaran Mitra'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // State Illustration & Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isApproved ? AppColors.successLight : AppColors.warningLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isApproved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                        size: 44,
                        color: isApproved ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    isApproved
                        ? 'Selamat! Mitra Terverifikasi Resmi'
                        : 'Menunggu Validasi Dokumen Legal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isApproved ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    isApproved
                        ? 'Admin PakaianKita telah menyetujui legalitas lembaga Anda. Akses penuh role Mitra sekarang aktif!'
                        : 'Permohonan kemitraan Anda telah masuk ke antrean verifikasi Admin PakaianKita. Admin sedang memeriksa SK Kemenkumham & izin resmi lembaga.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Verification Timeline Steps
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tahapan Verifikasi',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TimelineStep(
                          stepNumber: '1',
                          title: 'Pengajuan Berkas Terkirim',
                          subtitle: 'Formulir dan SK resmi berhasil diunggah.',
                          isCompleted: true,
                        ),
                        _TimelineStep(
                          stepNumber: '2',
                          title: 'Pemeriksaan Legalitas oleh Admin',
                          subtitle: isApproved
                              ? 'SK Kemenkumham dan PIC terbukti sah.'
                              : 'Admin memvalidasi nomor izin di database Dinsos.',
                          isCompleted: isApproved,
                          isInProgress: !isApproved,
                        ),
                        _TimelineStep(
                          stepNumber: '3',
                          title: 'Penerbitan Akses Dashboard Mitra',
                          subtitle: isApproved
                              ? 'Akses siap digunakan untuk buka donasi.'
                              : 'Menunggu persetujuan final dari Admin.',
                          isCompleted: isApproved,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submitted Data Card
                  if (submission != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Pengajuan yang Diajukan',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Divider(height: 20, color: AppColors.border),
                          _DetailRow(label: 'Lembaga', value: submission.orgName),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Jenis', value: submission.orgCategory),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Nomor SK', value: submission.legalNumber),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Berkas', value: submission.documentFileName),
                          const SizedBox(height: 8),
                          _DetailRow(label: 'PIC', value: '${submission.picName} (${submission.picPhone})'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Button
                  if (isApproved) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => MitraDashboardScreen(
                              orgName: submission?.orgName ?? 'Lembaga Mitra',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.dashboard_rounded),
                      label: const Text('Buka Dashboard Mitra Sekarang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ] else ...[
                    // Demo Helper Button for Hackathon Live Demo
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AdminApprovalScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.secondary),
                      label: const Text(
                        'Demo Juri: Buka Panel Admin (Verifikasi Dokumen Ini)',
                        style: TextStyle(color: AppColors.secondary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.secondary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isInProgress;
  final bool isLast;

  const _TimelineStep({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.isInProgress = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    Color circleColor = Colors.grey.shade300;
    Color textColor = AppColors.textSecondary;

    if (isCompleted) {
      circleColor = AppColors.success;
      textColor = AppColors.textPrimary;
    } else if (isInProgress) {
      circleColor = AppColors.warning;
      textColor = AppColors.textPrimary;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        stepNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isCompleted ? AppColors.success : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

