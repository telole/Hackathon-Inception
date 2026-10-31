import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_card.dart';
import '../../donation/application/donation_models.dart';
import '../../donation/application/donation_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _achievements = [
    _Achievement(
      title: 'Langkah Pertama',
      description: 'Catat donasi pertamamu.',
      threshold: 1,
      icon: Icons.waving_hand_outlined,
    ),
    _Achievement(
      title: 'Penyelamat 10 Baju',
      description: 'Berikan hidup baru untuk 10 pakaian.',
      threshold: 10,
      icon: Icons.checkroom_outlined,
    ),
    _Achievement(
      title: 'Sahabat Bumi',
      description: 'Selamatkan 25 pakaian dari limbah tekstil.',
      threshold: 25,
      icon: Icons.eco_outlined,
    ),
    _Achievement(
      title: 'Penggerak Kebaikan',
      description: 'Catat lima donasi untuk sesama.',
      threshold: 5,
      icon: Icons.volunteer_activism_outlined,
      countsDonations: true,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final donationsState = ref.watch(donationsProvider);
    if (donationsState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (donationsState.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: PkCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 36),
                  SizedBox(height: tokens.spaceSm),
                  Text(
                    'Profil belum dapat dimuat.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  TextButton(
                    onPressed: () => ref.invalidate(donationsProvider),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final donations = donationsState.value ?? const <DonationRecord>[];
    final donatedItems = donations.fold<int>(
      0,
      (total, donation) => total + donation.acceptedQuantity,
    );
    final user = ref.watch(authUserProvider).value;
    final metadataName = user?.userMetadata?['display_name'];
    final displayName = metadataName is String && metadataName.trim().isNotEmpty
        ? metadataName.trim()
        : user?.email?.split('@').first ?? 'Sahabat Pakaiankita';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceXl,
          ),
          children: [
            PkCard(
              color: tokens.deepGreen,
              stitchedBorder: true,
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: PkPalette.cream,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  SizedBox(width: tokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: PkPalette.cream,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? 'Donatur Pakaiankita',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: PkPalette.cream.withValues(alpha: 0.78),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined, color: tokens.orange),
                ],
              ),
            ),
            SizedBox(height: tokens.spaceMd),
            Row(
              children: [
                Expanded(
                  child: _ProfileMetric(
                    value: '${donations.length}',
                    label: 'donasi',
                    icon: Icons.favorite_border_rounded,
                  ),
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: _ProfileMetric(
                    value: '$donatedItems',
                    label: 'pakaian layak',
                    icon: Icons.checkroom_outlined,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceXl),
            Text(
              'Lencana kebaikan',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: tokens.spaceXs),
            Text(
              'Setiap langkah kecil pantas dirayakan.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: tokens.mutedText),
            ),
            SizedBox(height: tokens.spaceMd),
            for (final achievement in _achievements) ...[
              _AchievementCard(
                achievement: achievement,
                progress: achievement.countsDonations
                    ? donations.length
                    : donatedItems,
              ),
              SizedBox(height: tokens.spaceSm),
            ],
            SizedBox(height: tokens.spaceMd),
            PkCard(
              onTap: () => context.go('/tracking'),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: tokens.accentStrong,
                  ),
                  SizedBox(width: tokens.spaceMd),
                  Expanded(
                    child: Text(
                      'Lacak perjalanan donasi',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: tokens.mutedText),
                ],
              ),
            ),
            SizedBox(height: tokens.spaceSm),
            PkCard(
              onTap: () async {
                final client = ref.read(supabaseClientProvider);
                if (client == null) return;
                try {
                  await client.auth.signOut();
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text('Belum dapat keluar: $error')),
                    );
                }
              },
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: tokens.accentStrong),
                  SizedBox(width: tokens.spaceMd),
                  Expanded(
                    child: Text(
                      'Keluar dari akun',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: tokens.mutedText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return PkCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tokens.accentStrong),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: tokens.mutedText),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  const _Achievement({
    required this.title,
    required this.description,
    required this.threshold,
    required this.icon,
    this.countsDonations = false,
  });

  final String title;
  final String description;
  final int threshold;
  final IconData icon;
  final bool countsDonations;
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.progress});

  final _Achievement achievement;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final unlocked = progress >= achievement.threshold;
    return Semantics(
      label:
          'Lencana ${achievement.title}, ${unlocked ? 'terbuka' : 'belum terbuka'}. '
          '${achievement.description}',
      child: PkCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (unlocked ? tokens.accent : tokens.border).withValues(
                  alpha: 0.22,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                achievement.icon,
                color: unlocked ? tokens.accentStrong : tokens.mutedText,
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    achievement.description,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: tokens.mutedText),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$progress dari ${achievement.threshold}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tokens.accentStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              unlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
              color: unlocked ? tokens.accentStrong : tokens.mutedText,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}
