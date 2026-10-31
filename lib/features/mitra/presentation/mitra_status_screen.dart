import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../models/mitra_application.dart';

class MitraStatusScreen extends StatefulWidget {
  const MitraStatusScreen({super.key});

  @override
  State<MitraStatusScreen> createState() => _MitraStatusScreenState();
}

class _MitraStatusScreenState extends State<MitraStatusScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final controller = AppScope.read(context);
    await controller.refreshSession();
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status pengajuan dimuat ulang.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final current = controller.context;
    final application = current?.mitraApplication;
    if (current == null || application == null) {
      return PkScaffold(
        child: PkPage(
          children: [
            const SizedBox(height: 40),
            PkEmptyState(
              title: 'Belum ada pengajuan',
              message:
                  'Mulai pengajuan mitra dari halaman profil agar dokumen lembaga bisa diverifikasi admin.',
              icon: Icons.assignment_outlined,
              action: PkButton(
                label: 'Kembali ke beranda',
                onPressed: controller.continueAsDonor,
              ),
            ),
          ],
        ),
      );
    }

    final rejected = application.status.isRejected;
    final approved = application.status.isApproved;
    final draft = application.status == MitraApplicationStatus.draft;

    final title = approved
        ? 'Lembaga kamu sudah terverifikasi'
        : rejected
            ? 'Pengajuan perlu diperbaiki'
            : draft
                ? 'Lanjutkan pengajuan mitra'
                : 'Pengajuan mitra sedang ditinjau';

    final subtitle = approved
        ? 'Akses mitra sudah aktif pada akun ini. Kamu bisa mengelola kebutuhan lembaga.'
        : rejected
            ? 'Admin mengembalikan pengajuan dengan catatan. Perbaiki lalu kirim ulang.'
            : draft
                ? 'Draft pengajuan masih tersimpan. Lengkapi dokumen agar bisa dikirim ke admin.'
                : 'Admin sedang memeriksa legalitas lembaga. Kamu tetap bisa memakai akun sebagai donatur.';

    return PkScaffold(
      child: PkPage(
        gap: 16,
        children: [
          Row(
            children: [
              const PkLogo(size: 17),
              const Spacer(),
              IconButton(
                tooltip: 'Muat ulang status',
                onPressed: _refreshing ? null : _refresh,
                icon: _refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 21),
                color: AppColors.ink,
              ),
              TextButton(
                onPressed: controller.signOut,
                child: const Text('Keluar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rejected
                  ? AppColors.alertSurface
                  : approved
                      ? AppColors.sage
                      : AppColors.parchment,
              shape: BoxShape.circle,
            ),
            child: Icon(
              approved
                  ? Icons.verified_outlined
                  : rejected
                      ? Icons.error_outline_rounded
                      : Icons.hourglass_top_rounded,
              size: 26,
              color: rejected
                  ? AppColors.clay
                  : approved
                      ? AppColors.forest
                      : const Color(0xFF7A5A1F),
            ),
          ),
          const SizedBox(height: 2),
          PkStatusChip(
            label: application.status.label,
            tone: rejected
                ? PkStatusTone.danger
                : approved
                    ? PkStatusTone.success
                    : PkStatusTone.warning,
          ),
          Text(title, style: theme.textTheme.displaySmall),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.muted),
          ),
          if (rejected && application.reviewNote != null) ...[
            PkBanner(
              tone: PkBannerTone.error,
              label: 'Catatan admin',
              message: application.reviewNote!,
            ),
          ],
          if (!rejected && !approved)
            const PkBanner(
              message:
                  'Admin tidak memberikan estimasi waktu. Kamu bisa memeriksa status kapan saja dari halaman ini.',
            ),
          PkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ringkasan pengajuan', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                PkKeyValue(
                  label: 'Lembaga',
                  value: application.organizationName,
                ),
                PkKeyValue(
                  label: 'Jenis',
                  value: application.organizationKind,
                ),
                PkKeyValue(label: 'Wilayah', value: application.area),
                PkKeyValue(
                  label: 'Diajukan',
                  value: application.submittedAt == null
                      ? 'Belum dikirim'
                      : formatDate(application.submittedAt!),
                ),
                PkKeyValue(
                  label: 'Dokumen',
                  value: '${application.documents.length} berkas',
                ),
              ],
            ),
          ),
          PkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Perjalanan pengajuan', style: theme.textTheme.titleSmall),
                const SizedBox(height: 14),
                PkTimeline(
                  steps: [
                    PkTimelineStep(
                      title: 'Diajukan',
                      description: application.submittedAt == null
                          ? 'Belum dikirim'
                          : formatDateTime(application.submittedAt!),
                      state: PkStepState.done,
                    ),
                    PkTimelineStep(
                      title: 'Diverifikasi admin',
                      description: rejected
                          ? 'Pengajuan dikembalikan untuk diperbaiki.'
                          : approved
                              ? 'Dokumen lembaga dinyatakan lengkap.'
                              : 'Admin sedang memeriksa dokumen lembaga.',
                      state: rejected
                          ? PkStepState.error
                          : approved
                              ? PkStepState.done
                              : PkStepState.current,
                    ),
                    PkTimelineStep(
                      title: 'Hasil',
                      description: approved
                          ? 'Akses mitra aktif.'
                          : rejected
                              ? 'Kirim ulang setelah dokumen diperbaiki.'
                              : 'Hasil muncul di akun ini.',
                      state: approved
                          ? PkStepState.done
                          : rejected
                              ? PkStepState.upcoming
                              : PkStepState.upcoming,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (rejected) ...[
            PkButton(
              label: 'Perbaiki pengajuan',
              icon: Icons.edit_outlined,
              onPressed: () => controller.reviseMitraApplication(),
            ),
            PkButton(
              label: 'Ke beranda donatur',
              variant: PkButtonVariant.secondary,
              onPressed: controller.continueAsDonor,
            ),
          ] else if (draft) ...[
            PkButton(
              label: 'Lanjutkan pengajuan',
              onPressed: () => controller.reviseMitraApplication(),
            ),
            PkButton(
              label: 'Ke beranda donatur',
              variant: PkButtonVariant.secondary,
              onPressed: controller.continueAsDonor,
            ),
          ] else if (approved) ...[
            PkButton(
              label: 'Buka beranda',
              onPressed: controller.continueAsDonor,
            ),
          ] else ...[
            PkButton(
              label: 'Ke beranda donatur',
              onPressed: controller.continueAsDonor,
            ),
            PkButton(
              label: 'Keluar',
              variant: PkButtonVariant.ghost,
              onPressed: controller.signOut,
            ),
          ],
          Text(
            'Data pengajuan hanya dipakai untuk verifikasi lembaga.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
