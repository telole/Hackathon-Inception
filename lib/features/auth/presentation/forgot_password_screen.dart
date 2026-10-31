import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pk_widgets.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onBack,
    required this.onSignIn,
  });

  final VoidCallback onBack;
  final VoidCallback onSignIn;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _emailError;
  String? _authError;
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final emailError = validateEmail(_email.text);
    setState(() {
      _emailError = emailError;
      _authError = null;
    });
    if (emailError != null) return;

    final controller = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await controller.sendPasswordReset(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AppException catch (error) {
      if (mounted) setState(() => _authError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _authError = 'Tautan belum bisa diproses. Coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PkScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTopBar(onBack: widget.onBack),
            const SizedBox(height: 22),
            if (!_sent) ...[
              Text('Lupa kata sandi?', style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Masukkan email akunmu. Kami akan mengirim tautan untuk membuat kata sandi baru.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 24),
              if (_authError != null) ...[
                PkBanner(
                  tone: PkBannerTone.error,
                  label: 'Belum terkirim',
                  message: _authError!,
                ),
                const SizedBox(height: 16),
              ],
              PkTextField(
                label: 'Email',
                controller: _email,
                hint: 'nama@email.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 22),
              PkButton(
                label: 'Kirim tautan',
                busy: _busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 18),
              const PkBanner(
                tone: PkBannerTone.simulation,
                label: 'Mode simulasi',
                message:
                    'Tidak ada email yang benar-benar dikirim. Alur ini hanya memperlihatkan langkah pemulihan.',
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.sage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 26,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 18),
              Text('Tautan sudah disiapkan', style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Di mode simulasi, tautan pemulihan tidak dikirim ke email. Gunakan akun demo atau kembali masuk.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 24),
              PkButton(
                label: 'Kembali ke masuk',
                onPressed: widget.onSignIn,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
