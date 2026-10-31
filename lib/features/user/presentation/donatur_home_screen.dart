import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../needs/models/need.dart';
import '../../needs/presentation/need_card.dart';

class DonaturHomeScreen extends StatelessWidget {
  const DonaturHomeScreen({
    super.key,
    required this.onOpenNeeds,
    required this.onOpenNeed,
    required this.onOpenMitra,
    required this.onOpenMitraStatus,
    required this.onOpenDonations,
  });

  final VoidCallback onOpenNeeds;
  final ValueChanged<Need> onOpenNeed;
  final VoidCallback onOpenMitra;
  final VoidCallback onOpenMitraStatus;
  final VoidCallback onOpenDonations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final current = controller.context;
    if (current == null) return const SizedBox.shrink();

    final needs = controller.repository.publishedNeeds;
    final urgent = needs.where((need) => need.urgent).take(2).toList();
    final regular = needs.where((need) => !need.urgent).toList();
    final hasMitraAccess = current.isVerifiedMitra;
    final hasApplication =
        current.hasPendingMitra || current.hasRejectedMitra;

    return RefreshIndicator(
      color: AppColors.forest,
      onRefresh: controller.refreshSession,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${greetingFor(DateTime.now())}, ${current.firstName}',
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDateLong(DateTime.now()),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.science_outlined,
                      size: 13,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'DATA SIMULASI',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (hasMitraAccess) ...[
            PkCard(
              onTap: onOpenMitra,
              color: AppColors.sage,
              borderColor: const Color(0xFFCFDCC8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
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
                          'Ruang mitra',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          current.organization?.name ??
                              'Kelola kebutuhan lembaga',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.forest,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else if (hasApplication) ...[
            PkCard(
              onTap: onOpenMitraStatus,
              color: current.hasRejectedMitra
                  ? AppColors.alertSurface
                  : AppColors.parchment,
              borderColor: current.hasRejectedMitra
                  ? const Color(0xFFF0C9BD)
                  : const Color(0xFFE7DDC8),
              child: Row(
                children: [
                  Icon(
                    current.hasRejectedMitra
                        ? Icons.error_outline_rounded
                        : Icons.hourglass_top_rounded,
                    size: 20,
                    color: current.hasRejectedMitra
                        ? AppColors.clay
                        : const Color(0xFF7A5A1F),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.hasRejectedMitra
                              ? 'Pengajuan mitra perlu diperbaiki'
                              : 'Pengajuan mitra sedang ditinjau',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lihat catatan admin dan status pengajuan.',
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
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kebutuhan mendesak',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              if (needs.isNotEmpty)
                TextButton(
                  onPressed: onOpenNeeds,
                  child: Text('Lihat ${needs.length} kebutuhan'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (needs.isEmpty)
            PkEmptyState(
              title: 'Belum ada kebutuhan terbuka',
              message:
                  'Mitra terverifikasi belum menerbitkan kebutuhan baru. Coba lagi nanti.',
              icon: Icons.checkroom_outlined,
              action: PkButton(
                label: 'Muat ulang',
                variant: PkButtonVariant.secondary,
                onPressed: controller.refreshSession,
              ),
            )
          else ...[
            if (urgent.isEmpty)
              PkCard(
                color: AppColors.sage,
                borderColor: const Color(0xFFCFDCC8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 19,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Semua kebutuhan yang tampil berasal dari mitra terverifikasi admin.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final need in urgent) ...[
                NeedCard(need: need, onTap: () => onOpenNeed(need)),
                const SizedBox(height: 12),
              ],
            if (regular.isNotEmpty) ...[
              const SizedBox(height: 12),
              const PkSectionHeader(
                title: 'Kebutuhan terbaru',
                subtitle: 'Diterbitkan mitra terverifikasi',
              ),
              const SizedBox(height: 10),
              for (final need in regular) ...[
                NeedCard(need: need, onTap: () => onOpenNeed(need)),
                const SizedBox(height: 12),
              ],
            ],
            const SizedBox(height: 8),
            PkButton(
              label: 'Donasikan pakaian',
              icon: Icons.volunteer_activism_outlined,
              onPressed: onOpenNeeds,
            ),
            if (hasMitraAccess)
              TextButton(
                onPressed: onOpenDonations,
                child: const Text('Lihat riwayat donasiku'),
              ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: AppColors.muted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Kontak dan alamat penerima tidak ditampilkan.',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
