import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../../../core/data/rows_pager.dart';
import '../../../core/widgets/paged_rows_list.dart';
import '../../../core/widgets/pk_card.dart';
import '../../../core/widgets/pk_button.dart';
import '../../operations/application/operations_providers.dart';
import '../../operations/data/operations_repository.dart';
import '../../operations/presentation/operations_widgets.dart';
import '../data/registration_repository.dart';
import 'registration_screens.dart';

class MyOrganizationsScreen extends StatelessWidget {
  const MyOrganizationsScreen({super.key});
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Lembaga saya',
    permission: 'mitra',
    child: PagedRowsList(
      resource: 'myOrganizations',
      emptyMessage: 'Belum ada lembaga aktif yang dapat kamu kelola.',
      itemBuilder: (org) => PkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              org['name'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(org['area'] as String? ?? ''),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () =>
                  context.push('/organization/${org['id']}/members'),
              icon: const Icon(Icons.people_outline),
              label: const Text('Anggota lembaga'),
            ),
            TextButton.icon(
              onPressed: () =>
                  context.push('/organization/${org['id']}/points'),
              icon: const Icon(Icons.place_outlined),
              label: const Text('Titik layanan'),
            ),
          ],
        ),
      ),
    ),
  );
}

final organizationManagerProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, org) async {
      final access = await ref.watch(operationsAccessProvider.future);
      if (access.isAdmin) return true;
      final client = ref.watch(supabaseClientProvider);
      final uid = client?.auth.currentUser?.id;
      if (uid == null || !access.organizations.contains(org)) return false;
      final row = await client!
          .from('organization_members')
          .select('member_role,active')
          .eq('organization_id', org)
          .eq('user_id', uid)
          .maybeSingle();
      return row?['active'] == true && row?['member_role'] == 'manager';
    });

class OrganizationMembersScreen extends ConsumerStatefulWidget {
  const OrganizationMembersScreen({required this.organizationId, super.key});
  final String organizationId;
  @override
  ConsumerState<OrganizationMembersScreen> createState() =>
      _OrganizationMembersScreenState();
}

class _OrganizationMembersScreenState
    extends ConsumerState<OrganizationMembersScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _save({String? user, bool active = true}) async {
    if (_busy) return;
    if (user == null &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())) {
      setState(() => _error = 'Isi email akun yang sudah terdaftar.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(active ? 'Aktifkan anggota?' : 'Nonaktifkan anggota?'),
        content: const Text(
          'Perubahan ini mengatur akses operasional pada lembaga ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(registrationRepositoryProvider)
          .member(
            widget.organizationId,
            email: user == null ? _email.text.trim() : null,
            user: user,
            active: active,
          );
      ref.invalidate(rowsPagerProvider('members:${widget.organizationId}'));
      _email.clear();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Anggota belum diperbarui. Periksa email, izin pengelola, dan koneksi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager =
        ref.watch(organizationManagerProvider(widget.organizationId)).value ??
        false;
    return OperationsPage(
      title: 'Anggota lembaga',
      permission: 'mitra',
      child: PagedRowsList(
        resource: 'members:${widget.organizationId}',
        emptyMessage: 'Belum ada anggota.',
        header: [
          if (manager)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: PkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email anggota yang terdaftar',
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
                      label: 'Tambahkan anggota',
                      isLoading: _busy,
                      onPressed: _busy ? null : () => _save(),
                    ),
                  ],
                ),
              ),
            ),
        ],
        itemBuilder: (member) => PkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member['display_name'] as String,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                member['member_role'] == 'manager'
                    ? 'Pengelola lembaga'
                    : 'Anggota',
              ),
              Text(member['active'] == true ? 'Aktif' : 'Nonaktif'),
              if (manager && member['member_role'] != 'manager')
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _save(
                          user: member['user_id'] as String,
                          active: member['active'] != true,
                        ),
                  child: Text(
                    member['active'] == true
                        ? 'Nonaktifkan anggota'
                        : 'Aktifkan anggota',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrganizationPointsScreen extends ConsumerWidget {
  const OrganizationPointsScreen({required this.organizationId, super.key});
  final String organizationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager =
        ref.watch(organizationManagerProvider(organizationId)).value ?? false;
    return OperationsPage(
      title: 'Titik layanan',
      permission: 'mitra',
      child: PagedRowsList(
        resource: 'organizationPoints:$organizationId',
        emptyMessage: 'Belum ada titik layanan.',
        header: [
          if (manager)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: PkButton(
                label: 'Tambah titik layanan',
                onPressed: () =>
                    context.push('/organization/$organizationId/points/new'),
              ),
            ),
        ],
        itemBuilder: (point) => PkCard(
          onTap: manager
              ? () => context.push(
                  '/organization/$organizationId/points/${point['id']}',
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                point['name'] as String,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(point['public_address'] as String),
              Text(
                point['opening_hours'] as String? ?? 'Jam layanan belum diisi',
              ),
              Text(point['active'] == true ? 'Aktif' : 'Nonaktif'),
            ],
          ),
        ),
      ),
    );
  }
}

class PointEditorScreen extends ConsumerWidget {
  const PointEditorScreen({
    required this.organizationId,
    this.pointId,
    super.key,
  });
  final String organizationId;
  final String? pointId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => OperationsPage(
    title: 'Atur titik layanan',
    permission: 'mitra',
    child: ref
        .watch(organizationManagerProvider(organizationId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, stack) => const OperationsMessage(
            message: 'Izin pengelola belum tersedia.',
          ),
          data: (allowed) {
            if (!allowed) {
              return const OperationsMessage(
                message: 'Hanya pengelola lembaga yang dapat mengubah titik layanan.',
              );
            }
            if (pointId == null) {
              return _PointForm(org: organizationId, initial: const {});
            }
            return OperationsData(
              resource: 'point:$pointId',
              builder: (rows) =>
                  rows.isEmpty ||
                      rows.first['organization_id'] != organizationId
                  ? const OperationsMessage(
                      message: 'Titik layanan tidak ditemukan.',
                    )
                  : _PointForm(org: organizationId, initial: rows.first),
            );
          },
        ),
  );
}

class _PointForm extends ConsumerStatefulWidget {
  const _PointForm({required this.org, required this.initial});
  final String org;
  final OpsRow initial;
  @override
  ConsumerState<_PointForm> createState() => _PointFormState();
}

class _PointFormState extends ConsumerState<_PointForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _address = TextEditingController(),
      _hours = TextEditingController();
  bool _active = true, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name.text = widget.initial['name'] as String? ?? '';
    _address.text = widget.initial['public_address'] as String? ?? '';
    _hours.text = widget.initial['opening_hours'] as String? ?? '';
    _active = widget.initial['active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _hours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(registrationRepositoryProvider)
          .savePoint(
            id: widget.initial['id'] as String?,
            org: widget.org,
            name: _name.text.trim(),
            address: _address.text.trim(),
            hours: _hours.text.trim(),
            active: _active,
          );
      ref.invalidate(rowsPagerProvider('organizationPoints:${widget.org}'));
      ref.invalidate(operationsDataProvider('points'));
      if (mounted) context.go('/organization/${widget.org}/points');
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Titik layanan belum tersimpan. Periksa isian, koneksi, dan izin pengelola.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      PkCard(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Nama titik layanan',
                ),
                validator: requiredText,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Alamat publik'),
                validator: (v) => (v ?? '').trim().length < 5
                    ? 'Alamat belum lengkap.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hours,
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'Jam layanan'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Titik layanan aktif'),
                value: _active,
                onChanged: _busy ? null : (v) => setState(() => _active = v),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 24),
              PkButton(
                label: 'Simpan titik layanan',
                isLoading: _busy,
                onPressed: _busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
