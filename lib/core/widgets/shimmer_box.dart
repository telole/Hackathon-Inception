import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _animationsDisabled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == disabled) return;
    _animationsDisabled = disabled;
    if (disabled) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final base = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.border,
        borderRadius: widget.borderRadius,
      ),
      child: SizedBox(width: widget.width, height: widget.height),
    );

    if (_animationsDisabled == true) return base;
    return AnimatedBuilder(
      animation: _controller,
      child: base,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(-1.5 + 3 * _controller.value, 0),
          end: Alignment(-0.5 + 3 * _controller.value, 0),
          colors: [tokens.border, tokens.surface, tokens.border],
          stops: const [0.35, 0.5, 0.65],
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}
