import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../mitra/models/mitra_application.dart';
import '../../needs/models/need.dart';
import 'verification_detail_screen.dart';
import 'verification_queue_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onOpenQueue,
    required this.onOpenOperasional,
    required this.onOpenPrograms,
  });

  final VoidCallback onOpenQueue;
  final VoidCallback onOpenOperasional;
  final VoidCallback onOpenPrograms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final current = controller.context;
    if (current == null) return const SizedBox.shrink();
    final repository = controller.repository;
    final applications = repository.applications;
    final pending =
        applications.where((application) => application.status.isPending).toList();
    final recentNeeds = repository.allNeeds.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      children: [
        Text(
          '${greetingFor(DateTime.now())}, ${current.firstName}',
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: 3),
        Text(formatDateLong(DateTime.now()), style: theme.textTheme.bodySmall),
        const SizedBox(height: 18),
        const PkBanner(
          tone: PkBannerTone.simulation,
          label: 'Data simulasi',
          message:
              'Semua angka di halaman ini dihitung dari repository demo, bukan data produksi.',
        ),
        const SizedBox(height: 16),
        PkCard(
          onTap: onOpenOperasional,
          color: pending.isEmpty ? AppColors.sage : AppColors.parchment,
          borderColor: pending.isEmpty
              ? const Color(0xFFCFDCC8)
              : const Color(0xFFE7DDC8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: pending.isEmpty
                      ? AppColors.forest
                      : const Color(0xFF7A5A1F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  pending.isEmpty
                      ? Icons.check_circle_outline_rounded
                      : Icons.fact_check_outlined,
                  size: 21,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending.isEmpty
                          ? 'Tidak ada pengajuan menunggu'
                          : '${pending.length} pengajuan menunggu',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pending.isEmpty
                          ? 'Antrean verifikasi mitra sedang kosong.'
                          : 'Periksa legalitas sebelum memberi akses mitra.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.ink,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (pending.isNotEmpty)
          PkButton(
            label: 'Tinjau pengajuan',
            icon: Icons.fact_check_outlined,
            onPressed: onOpenQueue,
          )
        else
          PkButton(
            label: 'Buka antrean verifikasi',
            variant: PkButtonVariant.secondary,
            onPressed: onOpenQueue,
          ),
        const SizedBox(height: 22),
        PkCard(
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  value: '${repository.verifiedOrganizationCount}',
                  label: 'Mitra terverifikasi',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: AppColors.line,
              ),
              Expanded(
                child: _Stat(
                  value: '${repository.openNeedCount}',
                  label: 'Kebutuhan terbuka',
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: AppColors.line,
              ),
              Expanded(
                child: _Stat(
                  value: '${repository.accounts.length}',
                  label: 'Akun terdaftar',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        PkSectionHeader(
          title: 'Menunggu tinjauan',
          subtitle: pending.isEmpty
              ? 'Tidak ada pengajuan menunggu.'
              : 'Diurutkan dari pengajuan terbaru.',
          actionLabel: pending.isEmpty ? null : 'Lihat antrean',
          onAction: onOpenOperasional,
        ),
        const SizedBox(height: 10),
        if (pending.isEmpty)
          PkCard(
            color: AppColors.sage,
            borderColor: const Color(0xFFCFDCC8),
            child: Row(
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 19,
                  color: AppColors.forest,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Semua pengajuan sudah diputuskan. Antrean baru muncul saat akun mengirim pengajuan mitra.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.forest,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ApplicationList(
            applications: pending.take(3).toList(),
            onTap: (application) => _openDetail(context, application),
          ),
        const SizedBox(height: 22),
        PkSectionHeader(
          title: 'Program terbaru',
          subtitle: 'Kebutuhan yang tercatat di sistem',
          actionLabel: 'Semua program',
          onAction: onOpenPrograms,
        ),
        const SizedBox(height: 10),
        PkCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < recentNeeds.length; i++) ...[
                if (i > 0) const Divider(indent: 14, endIndent: 14),
                _ProgramRow(
                  need: recentNeeds[i],
                  onTap: () => _showProgramDetail(context, recentNeeds[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Dashboard admin tidak menampilkan grafik dekoratif. Angka berasal dari kebutuhan, organisasi, dan akun yang ada di repository.',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, MitraApplication application) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            VerificationDetailScreen(applicationId: application.id),
      ),
    );
  }

  void _showProgramDetail(BuildContext context, Need need) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  PkStatusChip(
                    label: need.isOpen ? 'Terbuka' : need.status.label,
                    tone: need.isOpen
                        ? PkStatusTone.success
                        : PkStatusTone.neutral,
                  ),
                  const Spacer(),
                  if (need.urgent)
                    const PkStatusChip(
                      label: 'Mendesak',
                      tone: PkStatusTone.danger,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(need.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                need.organizationName,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                need.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              PkCard(
                child: Column(
                  children: [
                    PkKeyValue(
                      label: 'Rincian',
                      value: need.items
                          .map((item) =>
                              '${item.category.label} · ${item.sizeLabel} · ${item.ageGroup}')
                          .join('\n'),
                    ),
                    PkKeyValue(
                      label: 'Terkumpul',
                      value:
                          '${need.receivedQty} dari ${need.requestedQty} pakaian',
                    ),
                    PkKeyValue(
                      label: 'Tenggat',
                      value: formatDate(need.deadline),
                    ),
                    PkKeyValue(
                      label: 'Titik kumpul',
                      value: '${need.pointName}\n${need.pointAddress}',
                    ),
                    PkKeyValue(
                      label: 'Visibilitas',
                      value: need.organizationVerified
                          ? 'Tampil ke donatur'
                          : 'Tersembunyi sampai organisasi terverifikasi',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
        ),
      ],
    );
  }
}

class _ProgramRow extends StatelessWidget {
  const _ProgramRow({required this.need, required this.onTap});

  final Need need;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.checkroom_outlined,
                  size: 19,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      need.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${need.organizationName} · ${need.remainingQty} sisa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PkStatusChip(
                    label: need.organizationVerified
                        ? 'Terverifikasi'
                        : 'Mitra baru',
                    tone: need.organizationVerified
                        ? PkStatusTone.success
                        : PkStatusTone.warning,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deadlineLabel(need.deadline),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 9.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
