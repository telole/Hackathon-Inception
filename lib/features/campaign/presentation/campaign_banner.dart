import 'package:flutter/material.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../home/application/home_models.dart';

/// Uses a neutral illustration until the backend supplies a banner URL.
class CampaignBanner extends StatelessWidget {
  const CampaignBanner({required this.campaign, super.key});
  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    Widget placeholder() => ColoredBox(
      color: tokens.deepGreen,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.category.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PkPalette.cream,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pakaian layak, manfaat baru.',
                    style: TextStyle(color: PkPalette.cream, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(campaign.icon, size: 54, color: PkPalette.cream),
          ],
        ),
      ),
    );
    final url = campaign.bannerUrl;
    return Semantics(
      image: true,
      label: 'Banner ${campaign.title}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusControl),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: url == null || url.isEmpty
              ? placeholder()
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : placeholder(),
                  errorBuilder: (context, error, stack) => placeholder(),
                ),
        ),
      ),
    );
  }
}
