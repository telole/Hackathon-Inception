import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../models/need.dart';

class NeedCard extends StatelessWidget {
  const NeedCard({
    super.key,
    required this.need,
    required this.onTap,
  });

  final Need need;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label:
          '${need.title}. ${need.organizationName}. Sisa ${need.remainingQty} dari ${need.requestedQty}. ${deadlineLabel(need.deadline)}.',
      child: PkCard(
        onTap: onTap,
        borderColor: need.urgent ? AppColors.claySoft : AppColors.line,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    need.organizationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (need.organizationVerified)
                  const PkOrgBadge()
                else
                  const PkStatusChip(
                    label: 'Belum terverifikasi',
                    tone: PkStatusTone.warning,
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              need.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 9),
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
                _MetaChip(label: need.items.first.category.label),
                _MetaChip(label: need.items.first.sizeLabel),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              need.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
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
                  'Sisa ${need.remainingQty}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            PkProgressBar(value: need.progress),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 5),
                Text(
                  deadlineLabel(need.deadline),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                ),
                const Spacer(),
                Text(
                  'Lihat',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.forest,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTheme.uiFamily,
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: AppColors.forest,
        ),
      ),
    );
  }
}
