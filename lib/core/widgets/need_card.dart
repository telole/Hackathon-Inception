import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';
import 'status_badge.dart';

class NeedCard extends StatelessWidget {
  final String title;
  final String organizationName;
  final String category;
  final String sizeCode;
  final String ageGroup;
  final int requestedQty;
  final int receivedQty;
  final int allocatedQty;
  final String deadlineText;
  final bool isEmergency;
  final VoidCallback? onTap;

  const NeedCard({
    super.key,
    required this.title,
    required this.organizationName,
    required this.category,
    required this.sizeCode,
    required this.ageGroup,
    required this.requestedQty,
    required this.receivedQty,
    this.allocatedQty = 0,
    required this.deadlineText,
    this.isEmergency = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = requestedQty > 0 ? (receivedQty / requestedQty).clamp(0.0, 1.0) : 0.0;
    final isFulfilled = receivedQty >= requestedQty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organizationName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isEmergency)
                    const StatusBadge(
                      label: 'Darurat',
                      icon: Icons.priority_high_rounded,
                      variant: BadgeVariant.emergency,
                    )
                  else if (isFulfilled)
                    const StatusBadge(
                      label: 'Terpenuhi',
                      icon: Icons.check_circle_outline_rounded,
                      variant: BadgeVariant.success,
                    )
                  else
                    const StatusBadge(
                      label: 'Rutin',
                      variant: BadgeVariant.info,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tag(context, category),
                  _tag(context, 'Ukuran $sizeCode'),
                  _tag(context, ageGroup),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isEmergency ? AppColors.emergency : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$receivedQty dari $requestedQty potong diterima',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Tenggat $deadlineText',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              if (allocatedQty > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '• $allocatedQty potong sedang diproses/dikirim',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
