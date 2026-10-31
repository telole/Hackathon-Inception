import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../needs/models/need.dart';
import 'create_need_screen.dart';

class MitraSpaceScreen extends StatelessWidget {
  const MitraSpaceScreen({super.key});

  Future<void> _createNeed(BuildContext context) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CreateNeedScreen()),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kebutuhan baru sudah terbit untuk donatur.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final current = controller.context;
    final organization = current?.organization;

    if (current == null ||
        !current.isVerifiedMitra ||
        organization == null) {
      return PkScaffold(
        appBar: const PkAppBar(title: 'Ruang mitra', showBack: true),
        child: PkPage(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            PkEmptyState(
              title: 'Akses mitra belum aktif',
              message:
                  'Ruang mitra hanya terbuka untuk lembaga yang sudah diverifikasi admin. Kamu tetap bisa memakai akun sebagai donatur.',
              icon: Icons.lock_outline_rounded,
              action: PkButton(
                label: 'Kembali',
                variant: PkButtonVariant.secondary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      );
    }

    final needs = controller.repository.allNeeds
        .where((need) => need.organizationId == organization.id)
        .toList()
      ..sort((a, b) {
        final aOpen = a.isOpen ? 0 : 1;
        final bOpen = b.isOpen ? 0 : 1;
        if (aOpen != bOpen) return aOpen - bOpen;
        return a.deadline.compareTo(b.deadline);
      });
    final openCount = needs.where((need) => need.isOpen).length;
    final fulfilledCount =
        needs.where((need) => !need.isOpen).length;

    return PkScaffold(
      appBar: PkAppBar(
        title: 'Ruang mitra',
        showBack: true,
        actions: [
          IconButton(
            tooltip: 'Muat ulang data',
            onPressed: controller.refreshSession,
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          PkCard(
            color: AppColors.sage,
            borderColor: const Color(0xFFCFDCC8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            organization.name,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${organization.kind} · ${organization.area}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PkOrgBadge(),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        organization.pointAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        value: '$openCount',
                        label: 'Kebutuhan terbuka',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: const Color(0xFFCFDCC8),
                    ),
                    Expanded(
                      child: _MiniStat(
                        value: '$fulfilledCount',
                        label: 'Sudah tertutup',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          PkSectionHeader(
            title: 'Kebutuhan lembaga',
            subtitle: 'Hanya mitra terverifikasi yang bisa menerbitkan',
            actionLabel: 'Buat',
            onAction: () => _createNeed(context),
          ),
          const SizedBox(height: 10),
          if (needs.isEmpty)
            PkEmptyState(
              title: 'Belum ada kebutuhan',
              message:
                  'Terbitkan kebutuhan pertama agar donatur bisa melihat dan menyalurkan pakaian untuk lembaga ini.',
              icon: Icons.checkroom_outlined,
              action: PkButton(
                label: 'Buat kebutuhan',
                onPressed: () => _createNeed(context),
              ),
            )
          else
            for (final need in needs) ...[
              _MitraNeedCard(need: need),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 6),
          PkButton(
            label: 'Buat kebutuhan baru',
            icon: Icons.add_rounded,
            onPressed: () => _createNeed(context),
          ),
          const SizedBox(height: 10),
          Text(
            'Kebutuhan yang terbit langsung tampil di beranda donatur karena lembaga ini sudah terverifikasi.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _MitraNeedCard extends StatelessWidget {
  const _MitraNeedCard({required this.need});

  final Need need;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = need.isOpen ? PkStatusTone.success : PkStatusTone.neutral;
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  need.title,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              PkStatusChip(
                label: need.isOpen ? 'Terbuka' : need.status.label,
                tone: tone,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            need.itemSummary,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terkumpul ${need.receivedQty} dari ${need.requestedQty}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(
                need.isOpen ? 'Sisa ${need.remainingQty}' : 'Tercukupi',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: need.isOpen ? AppColors.forest : AppColors.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          PkProgressBar(value: need.progress),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                deadlineLabel(need.deadline),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
              if (need.urgent) ...[
                const SizedBox(width: 8),
                const PkStatusChip(
                  label: 'Mendesak',
                  tone: PkStatusTone.danger,
                  icon: Icons.priority_high_rounded,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
