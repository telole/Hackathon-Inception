import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';

enum BadgeVariant {
  neutral,
  success,
  warning,
  emergency,
  info,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BadgeVariant variant;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = BadgeVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      BadgeVariant.success => (
        AppColors.successContainer,
        AppColors.success,
        const Color(0xFFB7E4C7),
      ),
      BadgeVariant.warning => (
        AppColors.warningContainer,
        AppColors.warning,
        const Color(0xFFF3DE97),
      ),
      BadgeVariant.emergency => (
        AppColors.emergencyContainer,
        AppColors.emergency,
        const Color(0xFFFFC7B8),
      ),
      BadgeVariant.info => (
        AppColors.primaryContainer,
        AppColors.primary,
        const Color(0xFFC0E0CE),
      ),
      BadgeVariant.neutral => (
        AppColors.surfaceVariant,
        AppColors.textSecondary,
        AppColors.outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
