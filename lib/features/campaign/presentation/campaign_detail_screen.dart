import 'campaign_banner.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_card.dart';
import '../../../core/widgets/stitch_painter.dart';
import '../../home/application/home_providers.dart';

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final campaignState = ref.watch(campaignProvider(campaignId));

    return campaignState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Kampanye')),
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
                    'Kampanye belum dapat dimuat.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  PkButton(
                    label: 'Coba lagi',
                    onPressed: () =>
                        ref.invalidate(campaignProvider(campaignId)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (campaign) {
        if (campaign == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kampanye')),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded, size: 40),
                    SizedBox(height: tokens.spaceMd),
                    Text(
                      'Kampanye tidak ditemukan atau sudah ditutup.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: tokens.spaceMd),
                    PkButton(
                      label: 'Kembali ke beranda',
                      onPressed: () => context.go('/home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final remainingItems = campaign.receivedItems == null
            ? null
            : (campaign.requestedItems - campaign.receivedItems!).clamp(
                0,
                campaign.requestedItems,
              );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cerita kampanye'),
            actions: [
              IconButton(
                onPressed: () => context.go('/home'),
                tooltip: 'Kembali ke beranda',
                icon: const Icon(Icons.close_rounded),
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              ),
            ],
          ),
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
                CampaignBanner(campaign: campaign),
                const SizedBox(height: 16),
                PkCard(
                  color: tokens.deepGreen,
                  stitchedBorder: true,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Hero(
                            tag: 'campaign-hero-${campaign.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  campaign.icon,
                                  color: PkPalette.cream,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.location_on_outlined,
                            color: tokens.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          if (campaign.distanceKm != null)
                            Text(
                              '${campaign.distanceKm!.toStringAsFixed(1)} km',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: PkPalette.cream,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        campaign.category.label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tokens.orange,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        campaign.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: PkPalette.cream,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${campaign.partner} · ${campaign.location}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PkPalette.cream.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: tokens.spaceLg),
                Text(
                  'Sedikit dari lemari, berarti banyak.',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  campaign.story,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: tokens.mutedText, height: 1.65),
                ),
                SizedBox(height: tokens.spaceLg),
                PkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              'Kebutuhan pakaian',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (campaign.progress != null)
                            Text(
                              '${(campaign.progress! * 100).round()}%',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: tokens.accentStrong,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                        ],
                      ),
                      if (campaign.progress != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          label:
                              'Progres kebutuhan kampanye ${(campaign.progress! * 100).round()} persen',
                          child: SizedBox(
                            height: 8,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CustomPaint(
                                  painter: StitchPainter(
                                    color: tokens.border,
                                    shape: StitchShape.horizontal,
                                    strokeWidth: 3,
                                    dashLength: 6,
                                    gapLength: 4,
                                  ),
                                ),
                                CustomPaint(
                                  painter: StitchPainter(
                                    color: tokens.accent,
                                    shape: StitchShape.horizontal,
                                    strokeWidth: 3,
                                    dashLength: 6,
                                    gapLength: 4,
                                    progress: campaign.progress!,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        remainingItems == null
                            ? 'Target ${campaign.requestedItems} potong. '
                                  'Data penerimaan belum tersedia untuk donatur.'
                            : '${campaign.receivedItems} dari ${campaign.requestedItems} potong terkumpul · '
                                  '$remainingItems lagi dibutuhkan',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: tokens.mutedText),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: tokens.spaceLg),
                PkButton(
                  label: 'Donasi untuk kebutuhan ini',
                  icon: Icons.volunteer_activism_rounded,
                  expanded: true,
                  onPressed: () => context.go(
                    Uri(
                      path: '/donate',
                      queryParameters: {
                        'kategori': campaign.category.id,
                        'kebutuhan': campaign.id,
                      },
                    ).toString(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
