import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';
import 'stitch_painter.dart';

class StitchDivider extends StatelessWidget {
  const StitchDivider({
    super.key,
    this.progress = 1,
    this.color,
    this.width,
    this.height = 2,
    this.dashLength = 6,
    this.gapLength = 5,
  });

  final double progress;
  final Color? color;
  final double? width;
  final double height;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final lineWidth =
            width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : 0.0);
        return CustomPaint(
          size: Size(lineWidth, height),
          painter: StitchPainter(
            color: color ?? tokens.stitch,
            shape: StitchShape.horizontal,
            progress: progress,
            strokeWidth: height,
            dashLength: dashLength,
            gapLength: gapLength,
          ),
        );
      },
    );
  }
}
