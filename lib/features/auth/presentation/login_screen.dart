import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../../demo/demo_repository.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onBack,
    required this.onSignUp,
    required this.onForgotPassword,
  });

  final VoidCallback onBack;
  final VoidCallback onSignUp;
  final VoidCallback onForgotPassword;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _authError;
  bool _busy = false;
  bool _googleBusy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _googleBusy) return;
    FocusScope.of(context).unfocus();
    final emailError = validateEmail(_email.text);
    final passwordError = validatePassword(_password.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _authError = null;
    });
    if (emailError != null || passwordError != null) return;

    final controller = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await controller.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on AppException catch (error) {
      if (mounted) setState(() => _authError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _authError = 'Tidak dapat masuk saat ini. Coba lagi.';
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

  void _fillDemo(String email) {
    setState(() {
      _email.text = email;
      _password.text = DemoRepository.demoPassword;
      _emailError = null;
      _passwordError = null;
      _authError = null;
    });
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
            Text(
              'Selamat datang kembali',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Masuk untuk melanjutkan donasi dan memantau penyaluran.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 22),
            if (_authError != null) ...[
              PkBanner(
                tone: PkBannerTone.error,
                label: 'Tidak bisa masuk',
                message: _authError!,
              ),
              const SizedBox(height: 16),
            ],
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
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            PkTextField(
              label: 'Kata sandi',
              controller: _password,
              hint: 'Masukkan kata sandi',
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              errorText: _passwordError,
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy || _googleBusy ? null : widget.onForgotPassword,
                child: const Text('Lupa kata sandi?'),
              ),
            ),
            const SizedBox(height: 4),
            PkButton(
              key: const Key('login-submit'),
              label: 'Masuk',
              busy: _busy,
              onPressed: _googleBusy ? null : _submit,
            ),
            const SizedBox(height: 22),
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
                Text('Belum punya akun?', style: theme.textTheme.bodySmall),
                TextButton(
                  onPressed: _busy || _googleBusy ? null : widget.onSignUp,
                  child: const Text('Daftar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DemoAccountCard(onSelect: _fillDemo),
          ],
        ),
      ),
    );
  }
}
