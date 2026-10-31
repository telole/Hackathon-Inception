import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pk_widgets.dart';
import 'widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.onBack,
    required this.onSignIn,
  });

  final VoidCallback onBack;
  final VoidCallback onSignIn;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _authError;
  bool _consent = false;
  bool _consentError = false;
  bool _busy = false;
  bool _googleBusy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _googleBusy) return;
    FocusScope.of(context).unfocus();
    final nameError = validateName(_name.text);
    final emailError = validateEmail(_email.text);
    final passwordError = validatePassword(_password.text, requireStrong: true);
    String? confirmError;
    if (_confirm.text.isEmpty) {
      confirmError = 'Konfirmasi kata sandi wajib diisi.';
    } else if (_confirm.text != _password.text) {
      confirmError = 'Konfirmasi kata sandi belum sama.';
    }
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _consentError = !_consent;
      _authError = null;
    });
    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmError != null ||
        !_consent) {
      return;
    }

    final controller = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await controller.signUp(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
    } on AppException catch (error) {
      if (mounted) setState(() => _authError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _authError = 'Tidak dapat membuat akun saat ini. Coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    if (_busy || _googleBusy) return;
    FocusScope.of(context).unfocus();
    final controller = AppScope.read(context);
    setState(() {
      _googleBusy = true;
      _authError = null;
    });
    try {
      await controller.signInWithGoogle();
    } on AppException catch (error) {
      if (mounted) setState(() => _authError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _authError = 'Login Google simulasi gagal. Coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PkScaffold(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTopBar(onBack: widget.onBack),
            const SizedBox(height: 22),
            Text('Buat akun', style: theme.textTheme.displaySmall),
            const SizedBox(height: 6),
            Text(
              'Satu akun untuk berdonasi dan mengikuti penyaluran.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 22),
            if (_authError != null) ...[
              PkBanner(
                tone: PkBannerTone.error,
                label: 'Belum bisa dibuat',
                message: _authError!,
              ),
              const SizedBox(height: 16),
            ],
            PkTextField(
              label: 'Nama lengkap',
              controller: _name,
              hint: 'Nama sesuai identitas',
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 16),
            PkTextField(
              label: 'Email',
              controller: _email,
              hint: 'nama@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              errorText: _emailError,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 16),
            PkTextField(
              label: 'Kata sandi',
              controller: _password,
              hint: 'Buat kata sandi',
              helperText: 'Minimal 8 karakter, kombinasi huruf dan angka.',
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              errorText: _passwordError,
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            PkTextField(
              label: 'Konfirmasi kata sandi',
              controller: _confirm,
              hint: 'Ulangi kata sandi',
              obscureText: true,
              textInputAction: TextInputAction.done,
              errorText: _confirmError,
              onChanged: (_) {
                if (_confirmError != null) {
                  setState(() => _confirmError = null);
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            PkCheckboxRow(
              value: _consent,
              onChanged: (value) => setState(() {
                _consent = value;
                if (value) _consentError = false;
              }),
              label:
                  'Saya bersedia data saya digunakan untuk keperluan penyaluran donasi.',
            ),
            if (_consentError) ...[
              const SizedBox(height: 4),
              Text(
                'Persetujuan ini perlu dicentang untuk melanjutkan.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.clay),
              ),
            ],
            const SizedBox(height: 22),
            PkButton(
              key: const Key('signup-submit'),
              label: 'Buat akun',
              busy: _busy,
              onPressed: _googleBusy ? null : _submit,
            ),
            const SizedBox(height: 20),
            const PkDividerLabel(label: 'atau'),
            const SizedBox(height: 18),
            GoogleSignInButton(
              onPressed: _busy || _googleBusy ? null : _google,
              busy: _googleBusy,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sudah punya akun?', style: theme.textTheme.bodySmall),
                TextButton(
                  onPressed: _busy || _googleBusy ? null : widget.onSignIn,
                  child: const Text('Masuk'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Mode simulasi · akun disimpan di perangkat ini',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
