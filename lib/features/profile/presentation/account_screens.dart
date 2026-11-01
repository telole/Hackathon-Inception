import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_card.dart';
import '../../home/application/home_providers.dart';
import '../application/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _area = TextEditingController();
  bool _initialized = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final client = ref.read(supabaseClientProvider);
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      setState(() => _error = 'Masuk kembali untuk menyimpan profil.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await client
          .from('profiles')
          .update({
            'display_name': _name.text.trim(),
            'area': _area.text.trim(),
          })
          .eq('id', uid)
          .select('id')
          .single();
      ref.invalidate(profileDataProvider);
      ref.invalidate(homeSnapshotProvider);
      if (mounted) context.go('/profile');
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Profil belum tersimpan. Periksa koneksi dan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profil')),
    body: ref
        .watch(profileDataProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, stack) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(profileDataProvider),
              child: const Text('Muat ulang profil'),
            ),
          ),
          data: (profile) {
            if (!_initialized) {
              _name.text = profile['display_name'] as String? ?? '';
              _area.text = profile['area'] as String? ?? '';
              _initialized = true;
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                PkCard(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Nama yang dikenali sesama',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _name,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Nama lengkap',
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Nama wajib diisi.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _area,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Kota / wilayah',
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_error != null)
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        PkButton(
                          label: 'Simpan profil',
                          expanded: true,
                          isLoading: _busy,
                          onPressed: _busy ? null : _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
  );
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController(), _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      if (client == null || client.auth.currentUser == null) {
        throw StateError('Sesi diperlukan.');
      }
      await client.auth.updateUser(UserAttributes(password: _password.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kata sandi berhasil diperbarui.')),
        );
        context.go('/profile');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Kata sandi belum diperbarui. Gunakan kata sandi baru atau ulangi pemulihan akun.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kata sandi baru')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PkCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'Kata sandi baru',
                  ),
                  validator: (v) =>
                      (v ?? '').length < 8 ? 'Minimal 8 karakter.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Ulangi kata sandi',
                  ),
                  validator: (v) =>
                      v != _password.text ? 'Kata sandi belum sama.' : null,
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                PkButton(
                  label: 'Simpan kata sandi',
                  isLoading: _busy,
                  onPressed: _busy ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
