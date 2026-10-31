import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/pk_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PkLogo(size: 18),
              const Spacer(),
              const ShirtIllustration(height: 210),
              const SizedBox(height: 26),
              Text(
                'Pakaian layak pakai,\nsampai ke yang membutuhkan.',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Menghubungkan donatur dengan mitra yang sudah diverifikasi admin.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Menyiapkan data simulasi',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'PAKAIANKITA · DEMO HACKATHON',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                  fontFamily: AppTheme.uiFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
