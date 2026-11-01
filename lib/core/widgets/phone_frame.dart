import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';

class PhoneFrame extends StatelessWidget {
  const PhoneFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 600) return child;
        final frameHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(0.0, 844.0).toDouble()
            : 844.0;

        return ColoredBox(
          color: tokens.background,
          child: Center(
            child: Container(
              width: 390,
              height: frameHeight,
              decoration: BoxDecoration(
                color: tokens.background,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: tokens.border),
                boxShadow: [tokens.cardShadow],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
