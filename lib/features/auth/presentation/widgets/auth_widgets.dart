import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pk_widgets.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({
    super.key,
    this.showBack = true,
    this.onBack,
    this.trailing,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              tooltip: 'Kembali',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: AppColors.ink,
              ),
            ),
          )
        else
          const SizedBox(width: 44),
        const Spacer(),
        const PkLogo(size: 16),
        const Spacer(),
        SizedBox(width: 44, child: trailing),
      ],
    );
  }
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GooglePainter(),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;
    final stroke = size.width * 0.17;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(rect, start, sweep, false, paint..color = color);
    }

    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    arc(blue, -0.62, 1.55);
    arc(green, 0.93, 1.25);
    arc(yellow, 2.18, 1.25);
    arc(red, 3.43, 1.55);

    // Palang biru khas Google G.
    final bar = Paint()..color = blue;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx + size.width * 0.01,
        center.dy - stroke / 2,
        radius + stroke / 2,
        stroke,
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.busy = false,
  });

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lanjut dengan Google, simulasi',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onPressed,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line, width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const GoogleMark(size: 20),
                const SizedBox(width: 10),
                Text(
                  'Lanjut dengan Google',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'simulasi',
                    style: TextStyle(
                      fontFamily: AppTheme.uiFamily,
                      fontSize: 9.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Color(0xFF6B5526),
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

class DemoAccountCard extends StatelessWidget {
  const DemoAccountCard({super.key, required this.onSelect});

  final ValueChanged<String> onSelect;

  static const _accounts = [
    ('Donatur', 'donatur@pakaiankita.id'),
    ('Mitra', 'mitra@pakaiankita.id'),
    ('Menunggu', 'pending@pakaiankita.id'),
    ('Ditolak', 'ditolak@pakaiankita.id'),
    ('Admin', 'admin@pakaiankita.id'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7DDC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science_outlined,
                size: 16,
                color: Color(0xFF6B5526),
              ),
              const SizedBox(width: 7),
              Text(
                'AKUN DEMO',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF6B5526),
                ),
              ),
              const Spacer(),
              Text(
                'sandi: demo1234',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: const Color(0xFF6B5526),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final account in _accounts)
                _DemoChip(
                  label: account.$1,
                  onTap: () => onSelect(account.$2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ketuk nama akun untuk mengisi email. Data hanya ada di perangkat ini.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: const Color(0xFF6B5526),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
          ),
        ),
      ),
    );
  }
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email wajib diisi.';
  final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  if (!pattern.hasMatch(email)) return 'Format email belum benar.';
  return null;
}

String? validatePassword(String? value, {bool requireStrong = false}) {
  final password = value ?? '';
  if (password.isEmpty) return 'Kata sandi wajib diisi.';
  if (requireStrong) {
    if (password.length < 8) return 'Minimal 8 karakter.';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    if (!hasLetter || !hasNumber) {
      return 'Gunakan kombinasi huruf dan angka.';
    }
  }
  return null;
}

String? validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Nama lengkap wajib diisi.';
  if (name.length < 3) return 'Nama terlalu pendek.';
  return null;
}
