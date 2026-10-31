import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../donations/models/donation.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final current = controller.context;
    if (current == null) return const SizedBox.shrink();

    final donations = controller.repository.donationsFor(current.userId);
    final inProgress = donations
        .where((donation) => donation.status != DonationStatus.received)
        .length;
    final received = donations
        .where((donation) => donation.status == DonationStatus.received)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Donasiku', style: theme.textTheme.displaySmall),
        const SizedBox(height: 3),
        Text(
          'Pantau pakaian yang sudah kamu salurkan.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        if (donations.isEmpty)
          PkEmptyState(
            title: 'Belum ada donasi',
            message:
                'Pilih kebutuhan dari mitra terverifikasi, lalu catat pakaian yang ingin kamu salurkan.',
            icon: Icons.inventory_2_outlined,
            action: PkButton(
              label: 'Cari kebutuhan',
              onPressed: onExplore,
            ),
          )
        else ...[
          PkCard(
            color: AppColors.parchment,
            borderColor: const Color(0xFFE7DDC8),
            child: Row(
              children: [
                Expanded(
                  child: _Sum(
                    value: '$inProgress',
                    label: 'Dalam proses',
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: const Color(0xFFE0D6C0),
                ),
                Expanded(
                  child: _Sum(
                    value: '$received',
                    label: 'Diterima mitra',
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: const Color(0xFFE0D6C0),
                ),
                Expanded(
                  child: _Sum(
                    value: '${donations.length}',
                    label: 'Total donasi',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data simulasi. Status diperbarui oleh relawan dan mitra.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 18),
          for (final donation in donations) ...[
            _DonationCard(donation: donation),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah donasi'),
          ),
        ],
      ],
    );
  }
}

class _Sum extends StatelessWidget {
  const _Sum({required this.value, required this.label});

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
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.donation});

  final Donation donation;

  (PkStatusTone, IconData) get _tone {
    switch (donation.status) {
      case DonationStatus.submitted:
        return (PkStatusTone.warning, Icons.schedule_rounded);
      case DonationStatus.curated:
        return (PkStatusTone.info, Icons.fact_check_outlined);
      case DonationStatus.shipped:
        return (PkStatusTone.info, Icons.local_shipping_outlined);
      case DonationStatus.received:
        return (PkStatusTone.success, Icons.check_circle_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (tone, icon) = _tone;
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  donation.organizationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PkStatusChip(
                label: donation.status.label,
                tone: tone,
                icon: icon,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            donation.needTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            donation.itemSummary,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _DonationSteps(status: donation.status),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                donation.method == DonationMethod.pickup
                    ? Icons.local_shipping_outlined
                    : Icons.storefront_outlined,
                size: 15,
                color: AppColors.muted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  donation.method.label,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                ),
              ),
              Text(
                '${relativeDay(donation.scheduledAt)} · ${formatDateShort(donation.scheduledAt)}',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
              ),
            ],
          ),
          if (donation.note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'Catatan: ${donation.note}',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DonationSteps extends StatelessWidget {
  const _DonationSteps({required this.status});

  final DonationStatus status;

  static const _labels = ['Diajukan', 'Kurasi', 'Dikirim', 'Diterima'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = DonationStatus.values.indexOf(status);
    return Semantics(
      label: 'Status donasi: ${status.label}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: i == 0
                              ? Colors.transparent
                              : i <= index
                                  ? AppColors.forest
                                  : AppColors.line,
                        ),
                      ),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= index
                              ? AppColors.forest
                              : AppColors.surface,
                          border: Border.all(
                            color: i <= index
                                ? AppColors.forest
                                : AppColors.line,
                            width: 1.4,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: i == _labels.length - 1
                              ? Colors.transparent
                              : i < index
                                  ? AppColors.forest
                                  : AppColors.line,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9.5,
                      color: i <= index ? AppColors.ink : AppColors.muted,
                      fontWeight:
                          i == index ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
