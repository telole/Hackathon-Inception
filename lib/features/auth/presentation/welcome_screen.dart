import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pk_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onStart,
    required this.onSignIn,
  });

  final VoidCallback onStart;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PkScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Brand & Demo badge
              Row(
                children: [
                  Text(
                    'PAKAIANKITA',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.parchment,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      'DEMO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Headline (Modern Neo-Grotesque Sans-Serif)
              Text(
                'Salurkan pakaian,\npulihkan martabat',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  height: 1.15,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Gotong royong sandang layak pakai untuk saudara kita yang membutuhkan, langsung melalui jaringan lembaga kemanusiaan terverifikasi.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.55,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 28),

              // Trust indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.forest.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Setiap mitra melewati verifikasi legalitas resmi.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary CTA
              PkButton(
                label: 'Mulai',
                height: 56,
                onPressed: onStart,
              ),
              const SizedBox(height: 14),

              // Secondary action (Text Link)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontSize: 14.5,
                      ),
                    ),
                    TextButton(
                      onPressed: onSignIn,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Masuk',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Disclaimer
              Text(
                'Mode simulasi · tidak terhubung ke server',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
