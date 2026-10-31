import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../models/need.dart';
import 'donation_sheet.dart';

class NeedDetailScreen extends StatelessWidget {
  const NeedDetailScreen({
    super.key,
    required this.need,
    this.onOpenDonations,
  });

  final Need need;
  final VoidCallback? onOpenDonations;

  Future<void> _openDonation(BuildContext context) async {
    final donated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (_) => DonationSheet(need: need),
    );
    if (donated == true && context.mounted) {
      Navigator.of(context).pop();
      onOpenDonations?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PkScaffold(
      appBar: const PkAppBar(title: 'Detail kebutuhan', showBack: true),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          need.organizationName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      const PkOrgBadge(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(need.title, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (need.urgent)
                        const PkStatusChip(
                          label: 'Mendesak',
                          tone: PkStatusTone.danger,
                          icon: Icons.priority_high_rounded,
                        ),
                      PkStatusChip(
                        label: need.items.first.category.label,
                        tone: PkStatusTone.info,
                        icon: Icons.checkroom_outlined,
                      ),
                      PkStatusChip(
                        label: need.items.first.sizeLabel,
                        tone: PkStatusTone.neutral,
                        icon: Icons.straighten_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    need.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PkCard(
                    color: AppColors.parchment,
                    borderColor: const Color(0xFFE7DDC8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _Stat(
                                value: '${need.receivedQty}',
                                label: 'Terkumpul',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color: const Color(0xFFE0D6C0),
                            ),
                            Expanded(
                              child: _Stat(
                                value: '${need.remainingQty}',
                                label: 'Sisa kebutuhan',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color: const Color(0xFFE0D6C0),
                            ),
                            Expanded(
                              child: _Stat(
                                value: formatDateShort(need.deadline),
                                label: 'Tenggat',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        PkProgressBar(value: need.progress),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const PkSectionHeader(title: 'Rincian kebutuhan'),
                  const SizedBox(height: 10),
                  PkCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < need.items.length; i++) ...[
                          if (i > 0) const Divider(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.sage,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.checkroom_outlined,
                                  size: 18,
                                  color: AppColors.forest,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      need.items[i].category.label,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${need.items[i].sizeLabel} · ${need.items[i].ageGroup}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${need.items[i].remainingQty} lagi',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.forest,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const PkSectionHeader(title: 'Titik kumpul'),
                  const SizedBox(height: 10),
                  PkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 18,
                              color: AppColors.forest,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                need.pointName,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          need.pointAddress,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(need.city, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 10),
                        Text(
                          'Alamat ini adalah titik kumpul publik mitra, bukan alamat penerima.',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const PkSectionHeader(title: 'Tentang mitra'),
                  const SizedBox(height: 10),
                  PkCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_outlined,
                            size: 21,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                need.organizationName,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Mitra penerima di ${need.city}. Legalitas sudah diperiksa admin.',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              const PkOrgBadge(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: PkButton(
              label: need.isOpen ? 'Donasikan pakaian' : 'Kebutuhan sudah tercukupi',
              icon: need.isOpen ? Icons.volunteer_activism_outlined : null,
              onPressed: need.isOpen ? () => _openDonation(context) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: AppTheme.displayFamily,
                color: AppColors.ink,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

