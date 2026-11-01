import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';

enum PkButtonVariant { primary, secondary, text }

class PkButton extends StatefulWidget {
  const PkButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = PkButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PkButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  @override
  State<PkButton> createState() => _PkButtonState();
}

class _PkButtonState extends State<PkButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final disabledAnimations = MediaQuery.disableAnimationsOf(context);
    final background = switch (widget.variant) {
      PkButtonVariant.primary => tokens.accentStrong,
      PkButtonVariant.secondary => tokens.surface,
      PkButtonVariant.text => Colors.transparent,
    };
    final foreground = switch (widget.variant) {
      PkButtonVariant.primary => tokens.onAccent,
      PkButtonVariant.secondary || PkButtonVariant.text => tokens.accentStrong,
    };
    final border = widget.variant == PkButtonVariant.secondary
        ? BorderSide(color: tokens.border)
        : BorderSide.none;

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          child: AnimatedScale(
            scale: _pressed && !disabledAnimations ? 0.98 : 1,
            duration: disabledAnimations
                ? Duration.zero
                : const Duration(milliseconds: 120),
            child: Material(
              color: background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.radiusControl),
                side: border,
              ),
              child: InkWell(
                onTap: enabled ? widget.onPressed : null,
                borderRadius: BorderRadius.circular(tokens.radiusControl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 52,
                    minWidth: 48,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Center(
                      widthFactor: widget.expanded ? null : 1,
                      child: widget.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: foreground,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    size: 20,
                                    color: foreground,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    widget.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: foreground,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
      ),
    );

    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
