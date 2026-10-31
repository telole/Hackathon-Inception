import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_card.dart';
import '../../../core/widgets/pk_logo.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _notice;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      setState(() {
        _errorMessage =
            'Backend belum dikonfigurasi. Jalankan dengan '
            '--dart-define-from-file=env.json.';
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _notice = null;
    });

    try {
      if (_isSignUp) {
        final response = await client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {'display_name': _nameController.text.trim()},
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(
            () => _notice =
                'Akun dibuat. Periksa email untuk mengonfirmasi pendaftaran.',
          );
          return;
        }
      } else {
        await client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;
      context.go(_safeRedirect);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _safeRedirect {
    final candidate = widget.redirectTo;
    if (candidate == null ||
        !candidate.startsWith('/') ||
        candidate.startsWith('//') ||
        candidate == '/auth') {
      return '/home';
    }
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: PkLogo(width: 180)),
                  SizedBox(height: tokens.spaceXl),
                  Text(
                    _isSignUp
                        ? 'Mulai berbagi kebaikan.'
                        : 'Selamat datang kembali.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: tokens.spaceXs),
                  Text(
                    _isSignUp
                        ? 'Buat akun untuk menyimpan dan melacak donasimu.'
                        : 'Masuk untuk melihat kebutuhan dan perjalanan donasimu.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: tokens.mutedText),
                  ),
                  SizedBox(height: tokens.spaceLg),
                  PkCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nama lengkap',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Masukkan nama lengkap.';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: tokens.spaceSm),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (value) {
                              if (value == null ||
                                  !value.trim().contains('@')) {
                                return 'Masukkan alamat email yang valid.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: tokens.spaceSm),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: [
                              _isSignUp
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Kata sandi',
                            ),
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return 'Kata sandi minimal 8 karakter.';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (_errorMessage != null) ...[
                            SizedBox(height: tokens.spaceSm),
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: tokens.terracotta),
                            ),
                          ],
                          if (_notice != null) ...[
                            SizedBox(height: tokens.spaceSm),
                            Text(
                              _notice!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: tokens.accentStrong),
                            ),
                          ],
                          SizedBox(height: tokens.spaceMd),
                          PkButton(
                            label: _isSignUp ? 'Buat akun' : 'Masuk',
                            expanded: true,
                            isLoading: _isSubmitting,
                            onPressed: _isSubmitting ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                            _notice = null;
                          }),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      _isSignUp
                          ? 'Sudah punya akun? Masuk'
                          : 'Belum punya akun? Daftar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
