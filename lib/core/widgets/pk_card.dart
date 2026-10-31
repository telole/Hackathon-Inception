import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';
import 'stitch_painter.dart';

class PkCard extends StatelessWidget {
  const PkCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
    this.stitchedBorder = false,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool stitchedBorder;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final radius = borderRadius ?? BorderRadius.circular(tokens.radiusCard);
    final card = Material(
      color: color ?? tokens.surface,
      elevation: 1.5,
      shadowColor: tokens.cardShadow.color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: stitchedBorder
            ? BorderSide.none
            : BorderSide(color: tokens.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (!stitchedBorder) return card;
    return CustomPaint(
      foregroundPainter: StitchPainter(
        color: tokens.stitch,
        shape: StitchShape.roundedRect,
        radius: tokens.radiusCard,
      ),
      child: card,
    );
  }
}
