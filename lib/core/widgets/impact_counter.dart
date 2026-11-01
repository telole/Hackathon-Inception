import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ImpactCounter extends StatefulWidget {
  const ImpactCounter({
    required this.value,
    required this.label,
    super.key,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1200),
    this.style,
  });

  final int value;
  final String label;
  final String suffix;
  final Duration duration;
  final TextStyle? style;

  @override
  State<ImpactCounter> createState() => _ImpactCounterState();
}

class _ImpactCounterState extends State<ImpactCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _count;
  bool _animationsDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _count = _makeAnimation();
  }

  Animation<double> _makeAnimation({int start = 0}) {
    return Tween<double>(
      begin: start.toDouble(),
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == disabled && _controller.isAnimating) return;
    _animationsDisabled = disabled;
    if (disabled) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ImpactCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    final start = _count.value.round();
    _controller.duration = widget.duration;
    _count = _makeAnimation(start: start);
    if (_animationsDisabled) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('id_ID');
    final semanticsLabel =
        '${formatter.format(widget.value)}${widget.suffix} ${widget.label}';

    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Text(
                '${formatter.format(_count.value.round())}${widget.suffix}',
                style:
                    widget.style ??
                    Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
