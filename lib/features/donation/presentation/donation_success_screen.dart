import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_card.dart';
import '../../../core/widgets/stitch_painter.dart';
import '../application/donation_models.dart';

class DonationSuccessScreen extends ConsumerWidget {
  const DonationSuccessScreen({super.key, this.donation});

  final DonationRecord? donation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final currentDonation = donation;

    if (currentDonation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Donasi berhasil')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volunteer_activism_outlined, size: 42),
                SizedBox(height: tokens.spaceMd),
                Text(
                  'Belum ada donasi untuk ditampilkan.',
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

    final user = ref.watch(authUserProvider).value;
    final metadataName = user?.userMetadata?['display_name'];
    final donorName =
        currentDonation.donorName ??
        (metadataName is String ? metadataName : null) ??
        user?.email?.split('@').first ??
        'Sahabat Pakaiankita';
    final certificateText = _certificateText(currentDonation, donorName);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satu kebaikan baru'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          tooltip: 'Kembali ke beranda',
          icon: const Icon(Icons.close_rounded),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        ),
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
            const Center(child: _ConfettiBurst()),
            Text(
              'Terima kasih, $donorName.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              '${currentDonation.quantity} pakaianmu kini punya kesempatan '
              'untuk menghangatkan hari seseorang.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: tokens.mutedText, height: 1.5),
            ),
            SizedBox(height: tokens.spaceLg),
            _ImpactCertificate(donation: currentDonation, donorName: donorName),
            SizedBox(height: tokens.spaceMd),
            PkButton(
              label: 'Bagikan sertifikat dampak',
              icon: Icons.ios_share_rounded,
              expanded: true,
              onPressed: () => _shareCertificate(context, certificateText),
            ),
            SizedBox(height: tokens.spaceSm),
            PkButton(
              label: 'Lacak perjalanan donasi',
              variant: PkButtonVariant.secondary,
              icon: Icons.local_shipping_outlined,
              expanded: true,
              onPressed: () => context.go('/tracking'),
            ),
            SizedBox(height: tokens.spaceSm),
            Center(
              child: TextButton(
                onPressed: () => context.go('/home'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: tokens.accentStrong,
                ),
                child: const Text('Kembali ke beranda'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _certificateText(DonationRecord donation, String donorName) {
    return 'SERTIFIKAT DAMPAK PAKAIANKITA\n\n'
        'Diberikan kepada $donorName atas kebaikan berbagi '
        '${donation.quantity} pakaian kategori ${donation.category.label}.\n'
        'Donasi ${donation.trackingCode ?? donation.id} ikut memperpanjang usia pakaian dan '
        'mendukung gerakan sirkular di Indonesia.\n\n'
        'Satu pakaian layak, satu cerita baru.';
  }

  static Future<void> _shareCertificate(
    BuildContext context,
    String certificateText,
  ) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: certificateText,
          subject: 'Sertifikat Dampak Pakaiankita',
        ),
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Sertifikat belum dapat dibagikan: ${error.message}'),
          ),
        );
    }
  }
}

class _ImpactCertificate extends StatelessWidget {
  const _ImpactCertificate({required this.donation, required this.donorName});

  final DonationRecord donation;
  final String donorName;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Semantics(
      label:
          'Sertifikat dampak untuk ${donation.quantity} pakaian, kode ${donation.id}',
      child: PkCard(
        color: tokens.deepGreen,
        stitchedBorder: true,
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(Icons.eco_rounded, color: tokens.orange, size: 30),
            const SizedBox(height: 8),
            Text(
              'SERTIFIKAT DAMPAK',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.orange,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Satu pakaian layak,\nsatu cerita baru.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: PkPalette.cream,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 4,
              width: 100,
              child: CustomPaint(
                painter: StitchPainter(
                  color: tokens.orange,
                  shape: StitchShape.horizontal,
                  strokeWidth: 2,
                  dashLength: 5,
                  gapLength: 4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${donation.quantity} pakaian · ${donation.category.label}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PkPalette.cream,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$donorName · ${donation.trackingCode ?? donation.id}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: PkPalette.cream.withValues(alpha: 0.76)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiBurst extends StatelessWidget {
  const _ConfettiBurst();

  static const _colors = [
    PkPalette.teal,
    PkPalette.orange,
    PkPalette.terracotta,
  ];

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: disabled ? Duration.zero : const Duration(milliseconds: 900),
      builder: (context, progress, child) => CustomPaint(
        size: const Size(220, 110),
        painter: _ConfettiPainter(progress: progress, colors: _colors),
        child: child,
      ),
      child: const SizedBox(
        width: 220,
        height: 110,
        child: Center(
          child: Icon(
            Icons.check_circle_rounded,
            size: 58,
            color: PkPalette.teal,
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  static const _pieces = [
    (x: 0.13, y: 0.2, angle: -0.5, width: 7.0, height: 12.0),
    (x: 0.25, y: 0.12, angle: 0.8, width: 6.0, height: 9.0),
    (x: 0.39, y: 0.22, angle: 1.3, width: 7.0, height: 11.0),
    (x: 0.61, y: 0.14, angle: -0.9, width: 6.0, height: 10.0),
    (x: 0.75, y: 0.25, angle: 0.5, width: 7.0, height: 12.0),
    (x: 0.87, y: 0.16, angle: 1.0, width: 6.0, height: 9.0),
    (x: 0.18, y: 0.65, angle: 1.0, width: 6.0, height: 10.0),
    (x: 0.34, y: 0.77, angle: -0.4, width: 7.0, height: 11.0),
    (x: 0.66, y: 0.74, angle: 0.7, width: 6.0, height: 9.0),
    (x: 0.82, y: 0.64, angle: -1.2, width: 7.0, height: 11.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final easedProgress = Curves.easeOutCubic.transform(progress);
    for (var index = 0; index < _pieces.length; index++) {
      final piece = _pieces[index];
      final start = Offset(size.width * 0.5, size.height * 0.5);
      final end = Offset(size.width * piece.x, size.height * piece.y);
      final center = Offset.lerp(start, end, easedProgress)!;
      final paint = Paint()
        ..color = colors[index % colors.length].withValues(
          alpha: (1 - (progress * 0.35)).clamp(0, 1),
        );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(piece.angle + (1 - progress) * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.width,
            height: piece.height,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}
