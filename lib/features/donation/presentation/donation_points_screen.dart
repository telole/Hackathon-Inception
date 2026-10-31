import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_card.dart';
import '../application/donation_models.dart';
import '../application/donation_providers.dart';

class DonationPointsScreen extends ConsumerStatefulWidget {
  const DonationPointsScreen({super.key});

  @override
  ConsumerState<DonationPointsScreen> createState() =>
      _DonationPointsScreenState();
}

class _DonationPointsScreenState extends ConsumerState<DonationPointsScreen> {
  double _radiusKm = 10;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final pointsState = ref.watch(donationPointsProvider);

    return pointsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Titik donasi')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Titik donasi')),
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
                    'Titik donasi belum dapat dimuat.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  PkButton(
                    label: 'Coba lagi',
                    onPressed: () => ref.invalidate(donationPointsProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (allPoints) {
        final hasDistance = allPoints.any((point) => point.distanceKm != null);
        final points = allPoints.where((point) {
          final distance = point.distanceKm;
          return distance == null || distance <= _radiusKm;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Titik donasi'),
            centerTitle: false,
            leading: IconButton(
              onPressed: () => context.pop(),
              tooltip: 'Kembali ke donasi',
              icon: const Icon(Icons.arrow_back_rounded),
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            ),
          ),
          body: SafeArea(
            top: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceLg,
                    tokens.spaceSm,
                    tokens.spaceLg,
                    tokens.spaceXl,
                  ),
                  sliver: SliverList.list(
                    children: [
                      Text(
                        'Pilih tempat untuk menitipkan kebaikanmu.',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: tokens.mutedText),
                      ),
                      SizedBox(height: tokens.spaceMd),
                      _MapPlaceholder(points: points),
                      SizedBox(height: tokens.spaceLg),
                      if (hasDistance) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Jarak dari lokasimu',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '${_radiusKm.round()} km',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: tokens.accentStrong,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _radiusKm,
                          min: 2,
                          max: 20,
                          divisions: 9,
                          label: '${_radiusKm.round()} km',
                          onChanged: (value) =>
                              setState(() => _radiusKm = value),
                        ),
                      ] else
                        Text(
                          'Titik resmi aktif. Jarak tidak ditampilkan tanpa lokasi pengguna.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: tokens.mutedText),
                        ),
                      SizedBox(height: tokens.spaceSm),
                      Text(
                        '${points.length} titik donasi aktif',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: tokens.mutedText),
                      ),
                      SizedBox(height: tokens.spaceSm),
                      if (points.isEmpty)
                        PkCard(
                          child: Text(
                            hasDistance
                                ? 'Belum ada titik dalam radius ini. Coba perluas jarak pencarian.'
                                : 'Belum ada titik donasi aktif yang tersedia saat ini.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      else
                        for (final point in points) ...[
                          _DonationPointCard(
                            point: point,
                            onTap: () => context.pop(point),
                          ),
                          SizedBox(height: tokens.spaceSm),
                        ],
                    ],
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

class _DonationPointCard extends StatelessWidget {
  const _DonationPointCard({required this.point, required this.onTap});

  final DonationPoint point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Semantics(
      button: true,
      label:
          '${point.name}, ${point.distanceKm == null ? '' : '${point.distanceKm!.toStringAsFixed(1)} kilometer, '}'
          '${point.area}',
      child: PkCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(point.icon, color: tokens.accentStrong),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.name,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    point.area.isEmpty
                        ? point.address
                        : '${point.address}, ${point.area}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: tokens.mutedText),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    point.openingHours,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: tokens.mutedText),
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            if (point.distanceKm != null)
              Column(
                children: [
                  Icon(
                    Icons.near_me_outlined,
                    color: tokens.accentStrong,
                    size: 19,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${point.distanceKm!.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tokens.accentStrong,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.points});

  final List<DonationPoint> points;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Semantics(
      image: true,
      label: 'Peta skematis titik donasi aktif',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusCard),
        child: SizedBox(
          height: 206,
          width: double.infinity,
          child: CustomPaint(
            painter: _MapPlaceholderPainter(
              background: tokens.surface,
              road: tokens.border,
              accent: tokens.accentStrong,
              muted: tokens.mutedText,
              pointCount: points.length,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 17,
                          color: tokens.accentStrong,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Titik donasi aktif',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  const _MapPlaceholderPainter({
    required this.background,
    required this.road,
    required this.accent,
    required this.muted,
    required this.pointCount,
  });

  final Color background;
  final Color road;
  final Color accent;
  final Color muted;
  final int pointCount;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(background, BlendMode.src);

    final parkPaint = Paint()..color = accent.withValues(alpha: 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.16, 92, 48),
        const Radius.circular(18),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.68, size.height * 0.12, 72, 36),
        const Radius.circular(14),
      ),
      parkPaint,
    );

    final roadPaint = Paint()
      ..color = road.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final roads = [
      Path()
        ..moveTo(size.width * 0.04, size.height * 0.72)
        ..cubicTo(
          size.width * 0.28,
          size.height * 0.45,
          size.width * 0.56,
          size.height * 0.9,
          size.width * 0.98,
          size.height * 0.38,
        ),
      Path()
        ..moveTo(size.width * 0.35, 0)
        ..cubicTo(
          size.width * 0.43,
          size.height * 0.3,
          size.width * 0.3,
          size.height * 0.7,
          size.width * 0.42,
          size.height,
        ),
      Path()
        ..moveTo(size.width * 0.75, 0)
        ..cubicTo(
          size.width * 0.68,
          size.height * 0.34,
          size.width * 0.82,
          size.height * 0.7,
          size.width * 0.7,
          size.height,
        ),
    ];
    for (final path in roads) {
      canvas.drawPath(path, roadPaint);
    }

    final positions = [
      Offset(size.width * 0.28, size.height * 0.42),
      Offset(size.width * 0.58, size.height * 0.32),
      Offset(size.width * 0.78, size.height * 0.63),
    ];
    for (
      var index = 0;
      index < math.min(pointCount, positions.length);
      index++
    ) {
      final center = positions[index];
      canvas.drawCircle(
        center,
        16,
        Paint()..color = accent.withValues(alpha: 0.14),
      );
      canvas.drawCircle(center, 9, Paint()..color = accent);
      canvas.drawCircle(center, 3, Paint()..color = background);
    }
    canvas.drawCircle(
      Offset(size.width * 0.48, size.height * 0.62),
      7,
      Paint()..color = muted.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _MapPlaceholderPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.road != road ||
        oldDelegate.accent != accent ||
        oldDelegate.muted != muted ||
        oldDelegate.pointCount != pointCount;
  }
}
