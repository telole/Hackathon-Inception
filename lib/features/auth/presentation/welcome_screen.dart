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
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const PkLogo(size: 18),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.parchment,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DEMO',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9.5,
                            color: const Color(0xFF6B5526),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const ShirtIllustration(height: 238),
                  const SizedBox(height: 26),
                  Text(
                    'PAKAIAN LAYAK PAKAI',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pakaianmu masih\npunya cerita.',
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Temukan kebutuhan nyata di sekitarmu. Salurkan pakaian layak pakai lewat mitra yang sudah diverifikasi admin.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 15,
                        color: AppColors.forest,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Setiap mitra melewati verifikasi legalitas.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PkButton(
                    label: 'Mulai',
                    onPressed: onStart,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun?',
                        style: theme.textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: onSignIn,
                        child: const Text('Masuk'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mode simulasi · tidak terhubung ke server',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
