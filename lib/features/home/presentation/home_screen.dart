import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/impact_counter.dart';
import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_card.dart';
import '../../../core/widgets/pk_logo.dart';
import '../../../core/widgets/stitch_painter.dart';
import '../application/home_models.dart';
import '../application/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final home = ref.watch(homeSnapshotProvider);

    return home.when(
      loading: () => Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Center(
              child: PkCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 36),
                    SizedBox(height: tokens.spaceSm),
                    Text(
                      'Beranda belum dapat dimuat.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: tokens.spaceSm),
                    Text(
                      'Periksa koneksi dan konfigurasi Supabase, lalu coba lagi.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: tokens.mutedText),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: tokens.spaceMd),
                    PkButton(
                      label: 'Coba lagi',
                      onPressed: () => ref.invalidate(homeSnapshotProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      data: (snapshot) => _HomeContent(snapshot: snapshot),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.snapshot});

  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final campaigns = snapshot.campaigns;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLg,
                tokens.spaceMd,
                tokens.spaceLg,
                tokens.spaceXl,
              ),
              sliver: SliverList.list(
                children: [
                  _HomeHeader(displayName: snapshot.displayName),
                  SizedBox(height: tokens.spaceLg),
                  _ImpactCard(stats: snapshot.impact),
                  SizedBox(height: tokens.spaceMd),
                  PkButton(
                    label: 'Donasi Pakaian',
                    icon: Icons.volunteer_activism_rounded,
                    expanded: true,
                    onPressed: () => context.go('/donate'),
                  ),
                  SizedBox(height: tokens.spaceXl),
                  _SectionHeading(
                    title: 'Pilih kategori',
                    subtitle: 'Setiap jenis punya cerita baru.',
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _CategoryGrid(
                    onSelected: (category) => context.go(
                      Uri(
                        path: '/donate',
                        queryParameters: {'kategori': category.id},
                      ).toString(),
                    ),
                  ),
                  SizedBox(height: tokens.spaceXl),
                  _SectionHeading(
                    title: 'Kebutuhan terbuka',
                    subtitle: 'Kebutuhan dari mitra terverifikasi.',
                    actionLabel: 'Lihat semua',
                    onAction: () => context.go('/donate'),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  if (campaigns.isEmpty)
                    PkCard(
                      child: Text(
                        'Belum ada kebutuhan terbuka. Coba kembali nanti.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else ...[
                    _CampaignCard(
                      campaign: campaigns.first,
                      featured: true,
                      onTap: () =>
                          context.push('/campaign/${campaigns.first.id}'),
                    ),
                    if (campaigns.length > 1) ...[
                      SizedBox(height: tokens.spaceMd),
                      for (final campaign in campaigns.skip(1).take(2)) ...[
                        _CampaignCard(
                          campaign: campaign,
                          onTap: () => context.push('/campaign/${campaign.id}'),
                        ),
                        SizedBox(height: tokens.spaceSm),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Row(
      children: [
        const PkLogoMark(size: 48),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $displayName',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Kebaikanmu terus bertumbuh.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: tokens.mutedText),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Buka profil',
          child: IconButton(
            onPressed: () => context.go('/profile'),
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline_rounded),
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: tokens.surface,
              side: BorderSide(color: tokens.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.stats});

  final ImpactStats stats;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    return PkCard(
      color: tokens.deepGreen,
      padding: const EdgeInsets.all(22),
      stitchedBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dampak Kamu',
                  style: textTheme.titleMedium?.copyWith(
                    color: PkPalette.cream,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.eco_outlined, color: tokens.orange, size: 23),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kebaikan kecil, perubahan nyata.',
            style: textTheme.bodySmall?.copyWith(
              color: PkPalette.cream.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ImpactMetric(
                  value: stats.receivedItems,
                  label: 'pakaian layak',
                ),
              ),
              Expanded(
                child: _ImpactMetric(
                  value: stats.submittedDonations,
                  label: 'donasi diajukan',
                ),
              ),
              Expanded(
                child: _ImpactMetric(
                  value: stats.curatedDonations,
                  label: 'dikurasi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  const _ImpactMetric({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ImpactCounter(
      value: value,
      label: label,
      style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(color: PkPalette.cream, fontWeight: FontWeight.w700),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: tokens.mutedText),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: tokens.accentStrong,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onSelected});

  final ValueChanged<DonationCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - tokens.spaceSm) / 2;
        return Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceSm,
          children: [
            for (final category in DonationCategory.values)
              SizedBox(
                width: itemWidth,
                child: _CategoryTile(
                  category: category,
                  onTap: () => onSelected(category),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final DonationCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return PkCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(category.icon, color: tokens.accentStrong, size: 21),
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Text(
              category.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.onTap,
    this.featured = false,
  });

  final Campaign campaign;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final foreground = featured ? PkPalette.cream : tokens.onSurface;
    final secondary = featured
        ? PkPalette.cream.withValues(alpha: 0.76)
        : tokens.mutedText;

    return PkCard(
      onTap: onTap,
      color: featured ? tokens.deepGreen : tokens.surface,
      padding: EdgeInsets.all(featured ? 20 : 15),
      stitchedBorder: featured,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  featured ? 'KEBUTUHAN TERBUKA' : campaign.category.label,
                  style: textTheme.labelSmall?.copyWith(
                    color: featured ? tokens.orange : tokens.accentStrong,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              Icon(Icons.arrow_outward_rounded, color: secondary, size: 18),
            ],
          ),
          SizedBox(height: featured ? 13 : 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  campaign.title,
                  maxLines: featured ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (featured ? textTheme.titleLarge : textTheme.titleSmall)
                          ?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                ),
              ),
              const SizedBox(width: 8),
              Hero(
                tag: 'campaign-hero-${campaign.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Icon(
                    campaign.icon,
                    color: featured ? PkPalette.cream : tokens.accentStrong,
                    size: featured ? 30 : 24,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: featured ? 8 : 10),
          Text(
            featured
                ? '${campaign.partner} · ${campaign.location}'
                : '${campaign.partner} · ${campaign.location}',
            maxLines: featured ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: secondary),
          ),
          SizedBox(height: featured ? 16 : 14),
          if (campaign.progress != null)
            _StitchedMeter(
              progress: campaign.progress!,
              color: featured ? tokens.orange : tokens.accent,
              track: featured
                  ? PkPalette.cream.withValues(alpha: 0.24)
                  : tokens.border,
            ),
          const SizedBox(height: 8),
          Text(
            campaign.receivedItems == null
                ? 'Target ${campaign.requestedItems} potong'
                : '${campaign.receivedItems} dari ${campaign.requestedItems} potong',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(color: secondary),
          ),
        ],
      ),
    );
  }
}

class _StitchedMeter extends StatelessWidget {
  const _StitchedMeter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: StitchPainter(
              color: track,
              shape: StitchShape.horizontal,
              strokeWidth: 2,
              dashLength: 4,
              gapLength: 3,
            ),
          ),
          CustomPaint(
            painter: StitchPainter(
              color: color,
              shape: StitchShape.horizontal,
              strokeWidth: 2,
              dashLength: 4,
              gapLength: 3,
              progress: progress,
            ),
          ),
        ],
      ),
    );
  }
}
