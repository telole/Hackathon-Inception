import 'dart:math' as math;

import 'package:flutter/material.dart';

enum StitchShape { roundedRect, horizontal, vertical, circle }

class StitchPainter extends CustomPainter {
  const StitchPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashLength = 6,
    this.gapLength = 5,
    this.progress = 1,
    this.radius = 24,
    this.shape = StitchShape.roundedRect,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double progress;
  final double radius;
  final StitchShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final bounds = Rect.fromLTWH(
      inset,
      inset,
      math.max(0, size.width - strokeWidth).toDouble(),
      math.max(0, size.height - strokeWidth).toDouble(),
    );
    final path = Path();

    switch (shape) {
      case StitchShape.roundedRect:
        path.addRRect(RRect.fromRectAndRadius(bounds, Radius.circular(radius)));
      case StitchShape.horizontal:
        path.moveTo(bounds.left, bounds.center.dy);
        path.lineTo(bounds.right, bounds.center.dy);
      case StitchShape.vertical:
        path.moveTo(bounds.center.dx, bounds.top);
        path.lineTo(bounds.center.dx, bounds.bottom);
      case StitchShape.circle:
        path.addOval(bounds);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final visibleFraction = progress.clamp(0.0, 1.0).toDouble();
    if (visibleFraction == 0) return;

    for (final metric in path.computeMetrics()) {
      final visibleLength = metric.length * visibleFraction;
      var start = 0.0;
      while (start < visibleLength) {
        final end = math.min(start + dashLength, visibleLength).toDouble();
        canvas.drawPath(metric.extractPath(start, end), paint);
        start += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant StitchPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength ||
        oldDelegate.progress != progress ||
        oldDelegate.radius != radius ||
        oldDelegate.shape != shape;
  }
}
