import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/pk_widgets.dart';

class SessionErrorScreen extends StatelessWidget {
  const SessionErrorScreen({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PkScaffold(
      child: PkPage(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        gap: 16,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.alertSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_outlined,
              size: 26,
              color: AppColors.clay,
            ),
          ),
          Text('Sesi tidak dapat dimuat', style: theme.textTheme.displaySmall),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.muted),
          ),
          const PkBanner(
            tone: PkBannerTone.warning,
            label: 'Data tetap aman',
            message:
                'Mode simulasi menyimpan data di perangkat ini. Kamu bisa mencoba memuat ulang atau keluar lalu masuk lagi.',
          ),
          const SizedBox(height: 8),
          PkButton(
            label: 'Coba lagi',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
          PkButton(
            label: 'Keluar',
            variant: PkButtonVariant.ghost,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}
