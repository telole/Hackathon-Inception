import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

// ---------------------------------------------------------------------------
// Kerangka halaman
// ---------------------------------------------------------------------------

class PkScaffold extends StatelessWidget {
  const PkScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.paper,
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(top: appBar == null, child: child),
    );
  }
}

class PkPage extends StatelessWidget {
  const PkPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 32),
    this.gap = 16,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}

class PkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PkAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.showBack = false,
    this.bottom,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBack;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title == null ? null : Text(title!),
      leading: leading ??
          (showBack
              ? const PkBackButton()
              : null),
      actions: actions,
      bottom: bottom,
      titleSpacing: showBack || leading != null ? 0 : 20,
      actionsPadding: const EdgeInsets.only(right: 8),
    );
  }
}

class PkBackButton extends StatelessWidget {
  const PkBackButton({super.key, this.onPressed, this.tooltip = 'Kembali'});

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_rounded),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AppColors.ink,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Merek
// ---------------------------------------------------------------------------

class PkLogo extends StatelessWidget {
  const PkLogo({super.key, this.size = 18, this.showMark = true});

  final double size;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMark) ...[
          Container(
            width: size + 10,
            height: size + 10,
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              Icons.checkroom_rounded,
              color: Colors.white,
              size: size - 1,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          'PakaianKita',
          style: TextStyle(
            fontFamily: AppTheme.displayFamily,
            fontSize: size,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class ShirtIllustration extends StatelessWidget {
  const ShirtIllustration({super.key, this.height = 210});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DDC8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _ShirtPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _ShirtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Lingkaran latar yang tenang.
    final halo = Paint()..color = AppColors.sand.withValues(alpha: 0.16);
    canvas.drawCircle(Offset(w * 0.78, h * 0.22), w * 0.14, halo);
    final halo2 = Paint()..color = AppColors.sage.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.16, h * 0.82), w * 0.10, halo2);

    // Gantungan.
    final hangerPaint = Paint()
      ..color = AppColors.forest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final hook = Path()
      ..moveTo(center.dx, h * 0.18)
      ..lineTo(center.dx, h * 0.235)
      ..cubicTo(
        w * 0.53,
        h * 0.16,
        w * 0.60,
        h * 0.17,
        w * 0.60,
        h * 0.225,
      );
    canvas.drawPath(hook, hangerPaint);
    final hanger = Path()
      ..moveTo(w * 0.30, h * 0.30)
      ..lineTo(center.dx, h * 0.235)
      ..lineTo(w * 0.70, h * 0.30);
    canvas.drawPath(hanger, hangerPaint);

    // Badan kemeja.
    final shirt = Path()
      ..moveTo(w * 0.37, h * 0.34)
      ..lineTo(w * 0.22, h * 0.46)
      ..quadraticBezierTo(w * 0.18, h * 0.49, w * 0.20, h * 0.53)
      ..lineTo(w * 0.28, h * 0.64)
      ..lineTo(w * 0.37, h * 0.58)
      ..lineTo(w * 0.37, h * 0.82)
      ..quadraticBezierTo(w * 0.37, h * 0.85, w * 0.40, h * 0.85)
      ..lineTo(w * 0.60, h * 0.85)
      ..quadraticBezierTo(w * 0.63, h * 0.85, w * 0.63, h * 0.82)
      ..lineTo(w * 0.63, h * 0.58)
      ..lineTo(w * 0.72, h * 0.64)
      ..lineTo(w * 0.80, h * 0.53)
      ..quadraticBezierTo(w * 0.82, h * 0.49, w * 0.78, h * 0.46)
      ..lineTo(w * 0.63, h * 0.34)
      ..close();

    final shirtFill = Paint()..color = AppColors.surface;
    canvas.drawPath(shirt, shirtFill);

    canvas.save();
    canvas.clipPath(shirt);
    final stripePaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1.4;
    for (var i = 0; i < 5; i++) {
      final x = w * (0.40 + i * 0.052);
      canvas.drawLine(Offset(x, h * 0.34), Offset(x, h * 0.86), stripePaint);
    }
    canvas.restore();

    canvas.drawPath(shirt, hangerPaint);

    // Kerah.
    final collar = Path()
      ..moveTo(w * 0.44, h * 0.34)
      ..lineTo(center.dx, h * 0.41)
      ..lineTo(w * 0.56, h * 0.34);
    canvas.drawPath(collar, hangerPaint);

    // Kancing.
    final buttonPaint = Paint()..color = AppColors.forest;
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(center.dx, h * (0.53 + i * 0.10)),
        2.1,
        buttonPaint,
      );
    }

    // Label kecil di tepi.
    final tagPaint = Paint()..color = AppColors.claySoft;
    canvas.save();
    canvas.translate(w * 0.635, h * 0.65);
    canvas.rotate(-0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 16, 9),
        const Radius.circular(2),
      ),
      tagPaint,
    );
    canvas.restore();
    canvas.drawLine(
      Offset(w * 0.635, h * 0.655),
      Offset(w * 0.63, h * 0.62),
      hangerPaint..strokeWidth = 1.2,
    );

    // Garis lipat lengan.
    final foldPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawLine(
      Offset(w * 0.24, h * 0.49),
      Offset(w * 0.30, h * 0.57),
      foldPaint,
    );
    canvas.drawLine(
      Offset(w * 0.76, h * 0.49),
      Offset(w * 0.70, h * 0.57),
      foldPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Tombol
// ---------------------------------------------------------------------------

enum PkButtonVariant { primary, secondary, ghost, danger }

class PkButton extends StatelessWidget {
  const PkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PkButtonVariant.primary,
    this.busy = false,
    this.icon,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final PkButtonVariant variant;
  final bool busy;
  final IconData? icon;
  final bool expand;
  final double height;

  bool get _enabled => onPressed != null && !busy;

  (Color, Color) get _colors {
    switch (variant) {
      case PkButtonVariant.primary:
        return (AppColors.forest, Colors.white);
      case PkButtonVariant.secondary:
        return (AppColors.surface, AppColors.ink);
      case PkButtonVariant.ghost:
        return (Colors.transparent, AppColors.forest);
      case PkButtonVariant.danger:
        return (AppColors.clay, Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors;
    final disabled = onPressed == null;
    final effectiveBackground = disabled && !busy
        ? (variant == PkButtonVariant.ghost
            ? Colors.transparent
            : AppColors.line)
        : background;
    final effectiveForeground = disabled && !busy
        ? AppColors.muted
        : foreground;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: label,
      child: Material(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          child: Container(
            height: height,
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: variant == PkButtonVariant.secondary
                  ? Border.all(color: AppColors.line)
                  : null,
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: busy ? 0 : 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 19, color: effectiveForeground),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.uiFamily,
                            fontSize: 15,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: effectiveForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        variant == PkButtonVariant.secondary
                            ? AppColors.forest
                            : foreground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

class PkTextField extends StatefulWidget {
  const PkTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.enabled = true,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.inputFormatters,
    this.optional = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool optional;

  @override
  State<PkTextField> createState() => _PkTextFieldState();
}

class _PkTextFieldState extends State<PkTextField> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
              ),
            ),
            if (widget.optional)
              Text(
                'Opsional',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 7),
        Semantics(
          label: widget.label,
          textField: true,
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscureText && _hidden,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            style: theme.textTheme.bodyLarge,
            cursorColor: AppColors.forest,
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helperText,
              errorText: widget.errorText,
              errorMaxLines: 3,
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(
                      widget.prefixIcon,
                      size: 19,
                      color: AppColors.muted,
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 42),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      tooltip: _hidden
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.muted,
                      ),
                    )
                  : widget.suffix,
            ),
          ),
        ),
      ],
    );
  }
}

class PkCheckboxRow extends StatelessWidget {
  const PkCheckboxRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged == null
                      ? null
                      : (next) => onChanged!(next ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu dan label
// ---------------------------------------------------------------------------

class PkCard extends StatelessWidget {
  const PkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = 12,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? AppColors.line),
    );
    return Material(
      color: color ?? AppColors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class PkSectionHeader extends StatelessWidget {
  const PkSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

enum PkStatusTone { neutral, success, warning, danger, info }

class PkStatusChip extends StatelessWidget {
  const PkStatusChip({
    super.key,
    required this.label,
    this.tone = PkStatusTone.neutral,
    this.icon,
  });

  final String label;
  final PkStatusTone tone;
  final IconData? icon;

  Color get _background {
    switch (tone) {
      case PkStatusTone.neutral:
        return AppColors.surface;
      case PkStatusTone.success:
      case PkStatusTone.info:
        return AppColors.sage;
      case PkStatusTone.warning:
        return AppColors.parchment;
      case PkStatusTone.danger:
        return AppColors.alertSurface;
    }
  }

  Color get _foreground {
    switch (tone) {
      case PkStatusTone.neutral:
        return AppColors.muted;
      case PkStatusTone.success:
      case PkStatusTone.info:
        return AppColors.forest;
      case PkStatusTone.warning:
        return const Color(0xFF7A5A1F);
      case PkStatusTone.danger:
        return AppColors.clay;
    }
  }

  IconData get _defaultIcon {
    switch (tone) {
      case PkStatusTone.neutral:
        return Icons.circle_outlined;
      case PkStatusTone.success:
        return Icons.check_circle_outline_rounded;
      case PkStatusTone.warning:
        return Icons.schedule_rounded;
      case PkStatusTone.danger:
        return Icons.error_outline_rounded;
      case PkStatusTone.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground = _foreground;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: tone == PkStatusTone.neutral ? AppColors.line : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? _defaultIcon, size: 13, color: foreground),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.uiFamily,
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PkOrgBadge extends StatelessWidget {
  const PkOrgBadge({super.key, this.label = 'Mitra terverifikasi'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return PkStatusChip(
      label: label,
      tone: PkStatusTone.success,
      icon: Icons.verified_outlined,
    );
  }
}

enum PkBannerTone { simulation, info, warning, error, success }

class PkBanner extends StatelessWidget {
  const PkBanner({
    super.key,
    required this.message,
    this.label,
    this.tone = PkBannerTone.info,
    this.icon,
    this.action,
  });

  final String message;
  final String? label;
  final PkBannerTone tone;
  final IconData? icon;
  final Widget? action;

  (Color, Color, IconData) get _style {
    switch (tone) {
      case PkBannerTone.simulation:
        return (AppColors.parchment, const Color(0xFF6B5526), Icons.science_outlined);
      case PkBannerTone.info:
        return (AppColors.sage, AppColors.forest, Icons.info_outline_rounded);
      case PkBannerTone.warning:
        return (AppColors.parchment, const Color(0xFF7A5A1F), Icons.schedule_rounded);
      case PkBannerTone.error:
        return (AppColors.alertSurface, AppColors.clay, Icons.error_outline_rounded);
      case PkBannerTone.success:
        return (AppColors.sage, AppColors.forest, Icons.check_circle_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground, defaultIcon) = _style;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 18, color: foreground),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null) ...[
                  Text(
                    label!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTheme.uiFamily,
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foreground,
                        height: 1.4,
                      ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 8),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PkProgressBar extends StatelessWidget {
  const PkProgressBar({super.key, required this.value, this.tone});

  final double value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progres ${(value * 100).round()} persen',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 6,
          backgroundColor: AppColors.sage,
          valueColor: AlwaysStoppedAnimation<Color>(tone ?? AppColors.forest),
        ),
      ),
    );
  }
}

class PkDividerLabel extends StatelessWidget {
  const PkDividerLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Langkah, timeline, upload
// ---------------------------------------------------------------------------

class PkStepHeader extends StatelessWidget {
  const PkStepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    this.onBack,
  });

  final int step;
  final int total;
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  tooltip: 'Kembali ke langkah sebelumnya',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    foregroundColor: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              'LANGKAH $step DARI $total',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.forest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PkProgressBar(value: step / total),
        const SizedBox(height: 14),
        Text(title, style: theme.textTheme.headlineMedium),
      ],
    );
  }
}

enum PkStepState { done, current, upcoming, error }

class PkTimelineStep {
  const PkTimelineStep({
    required this.title,
    this.description,
    this.state = PkStepState.upcoming,
  });

  final String title;
  final String? description;
  final PkStepState state;
}

class PkTimeline extends StatelessWidget {
  const PkTimeline({super.key, required this.steps});

  final List<PkTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      _dot(steps[i].state),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 1.2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: steps[i].state == PkStepState.done
                                ? AppColors.forest
                                : AppColors.line,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == steps.length - 1 ? 0 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: steps[i].state == PkStepState.upcoming
                                ? AppColors.muted
                                : AppColors.ink,
                          ),
                        ),
                        if (steps[i].description != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            steps[i].description!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dot(PkStepState state) {
    switch (state) {
      case PkStepState.done:
        return const Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: AppColors.forest,
        );
      case PkStepState.current:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.sage,
            border: Border.all(color: AppColors.forest, width: 2),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.forest,
            ),
          ),
        );
      case PkStepState.upcoming:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.line, width: 2),
          ),
        );
      case PkStepState.error:
        return const Icon(
          Icons.cancel_rounded,
          size: 20,
          color: AppColors.clay,
        );
    }
  }
}

class PkFileField extends StatelessWidget {
  const PkFileField({
    super.key,
    required this.label,
    required this.onPick,
    this.fileName,
    this.sizeBytes,
    this.isImage = false,
    this.previewBytes,
    this.onRemove,
    this.busy = false,
    this.errorText,
    this.optional = false,
    this.pickLabel = 'Lampirkan dokumen',
  });

  final String label;
  final VoidCallback onPick;
  final String? fileName;
  final int? sizeBytes;
  final bool isImage;
  final Uint8List? previewBytes;
  final VoidCallback? onRemove;
  final bool busy;
  final String? errorText;
  final bool optional;
  final String pickLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = fileName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
              ),
            ),
            if (optional)
              Text(
                'Opsional',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: errorText == null ? AppColors.line : AppColors.clay,
            ),
          ),
          child: hasFile
              ? Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: _thumb(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sizeBytes == null ? 'Siap diunggah' : formatBytes(sizeBytes!),
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (busy)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else ...[
                      TextButton(
                        onPressed: onPick,
                        child: const Text('Ganti'),
                      ),
                      IconButton(
                        tooltip: 'Hapus dokumen',
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppColors.muted,
                      ),
                    ],
                  ],
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: busy ? null : onPick,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            size: 19,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pickLabel,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'JPG, PNG, atau PDF · maks. 5 MB',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.clay),
          ),
        ],
      ],
    );
  }

  Widget _thumb() {
    if (isImage && previewBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          previewBytes!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _iconThumb(Icons.image_outlined),
        ),
      );
    }
    return _iconThumb(isImage ? Icons.image_outlined : Icons.description_outlined);
  }

  Widget _iconThumb(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 21, color: AppColors.forest),
    );
  }
}

// ---------------------------------------------------------------------------
// Lain-lain
// ---------------------------------------------------------------------------

class PkEmptyState extends StatelessWidget {
  const PkEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.sage,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: AppColors.forest),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class PkAvatar extends StatelessWidget {
  const PkAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontFamily: AppTheme.uiFamily,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: AppColors.forest,
        ),
      ),
    );
  }
}

class PkKeyValue extends StatelessWidget {
  const PkKeyValue({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.muted),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PkSheetHandle extends StatelessWidget {
  const PkSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class PkIconAction extends StatelessWidget {
  const PkIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: badge == null ? tooltip : '$tooltip, $badge menunggu',
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, size: 22),
            color: AppColors.ink,
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
            ),
          ),
          if (badge != null && badge! > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.clay,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.paper, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge! > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                    fontFamily: AppTheme.uiFamily,
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
