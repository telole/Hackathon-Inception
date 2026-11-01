import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/rows_pager.dart';
import '../../../core/widgets/paged_rows_list.dart';
import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_card.dart';
import '../../operations/application/operations_providers.dart';
import '../../operations/data/operations_repository.dart';
import '../../operations/presentation/operations_widgets.dart';
import '../../operations/presentation/workflow_screens.dart';
import '../data/registration_repository.dart';

void refreshRegistrations(WidgetRef ref) {
  ref.invalidate(operationsDataProvider);
  ref.invalidate(rowsPagerProvider);
  ref.invalidate(operationsAccessProvider);
}

class JoinScreen extends ConsumerWidget {
  const JoinScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Bergabung dan pengajuan')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ambil bagian lebih jauh',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Pengajuan akan diperiksa admin. Izin operasional aktif setelah disetujui.',
              ),
              const SizedBox(height: 24),
              PkButton(
                label: 'Daftar sebagai relawan',
                onPressed: () => context.push('/join/volunteer'),
              ),
              const SizedBox(height: 12),
              PkButton(
                label: 'Daftarkan lembaga',
                variant: PkButtonVariant.secondary,
                onPressed: () => context.push('/join/organization/new'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Pengajuan relawan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        OperationsData(
          resource: 'myRoleRequests',
          builder: (rows) => Column(
            children: [
              if (rows.isEmpty)
                const PkCard(child: Text('Belum ada pengajuan relawan.')),
              for (final row in rows.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RegistrationStatusCard(row: row),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Pengajuan lembaga',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        OperationsData(
          resource: 'myOrganizationApplications',
          builder: (rows) => Column(
            children: [
              if (rows.isEmpty)
                const PkCard(child: Text('Belum ada pengajuan lembaga.')),
              for (final row in rows.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () =>
                        context.push('/join/organization/${row['id']}'),
                    child: RegistrationStatusCard(row: row),
                  ),
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.push('/join/history/volunteer'),
          child: const Text('Semua riwayat relawan'),
        ),
        TextButton(
          onPressed: () => context.push('/join/history/organization'),
          child: const Text('Semua riwayat lembaga'),
        ),
      ],
    ),
  );
}

class RegistrationStatusCard extends StatelessWidget {
  const RegistrationStatusCard({required this.row, super.key});
  final OpsRow row;
  @override
  Widget build(BuildContext context) => PkCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row['name'] as String? ?? 'Pengajuan relawan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        OperationStatus(row['status'] as String),
        const SizedBox(height: 8),
        Text(workflowDate(row['created_at'])),
        if (row['review_reason'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Catatan admin: ${row['review_reason']}'),
          ),
      ],
    ),
  );
}

class RegistrationHistoryScreen extends StatelessWidget {
  const RegistrationHistoryScreen({required this.type, super.key});
  final String type;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat pengajuan')),
    body: PagedRowsList(
      resource: type == 'volunteer'
          ? 'myRoleRequests'
          : 'myOrganizationApplications',
      emptyMessage: 'Belum ada pengajuan.',
      itemBuilder: (row) => InkWell(
        onTap: type == 'organization'
            ? () => context.push('/join/organization/${row['id']}')
            : null,
        child: RegistrationStatusCard(row: row),
      ),
    ),
  );
}

class VolunteerApplicationScreen extends ConsumerStatefulWidget {
  const VolunteerApplicationScreen({super.key});
  @override
  ConsumerState<VolunteerApplicationScreen> createState() =>
      _VolunteerApplicationScreenState();
}

class _VolunteerApplicationScreenState
    extends ConsumerState<VolunteerApplicationScreen> {
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _id = const Uuid().v4();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(registrationRepositoryProvider)
          .volunteer(_id, _message.text.trim());
      refreshRegistrations(ref);
      if (mounted) context.go('/join');
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Pengajuan belum terkirim. Periksa koneksi atau pengajuan yang masih menunggu.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daftar relawan')),
    body: ref
        .watch(operationsAccessProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, stack) => OperationsMessage(
            message: 'Izin akun belum dapat dimuat.',
            retry: () => ref.invalidate(operationsAccessProvider),
          ),
          data: (access) {
            if (access.roles.contains('relawan')) {
              return const OperationsMessage(
                message: 'Akunmu sudah memiliki izin relawan. Buka Ruang operasional untuk melihat tugas.',
              );
            }
            return OperationsData(
              resource: 'myRoleRequests',
              builder: (rows) {
                if (rows.any((r) => r['status'] == 'pending')) {
                  return const OperationsMessage(
                    message: 'Pengajuanmu sedang diperiksa admin. Lihat hasilnya pada halaman pengajuan.',
                  );
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
                            const Text(
                              'Ceritakan wilayah dan waktu yang bisa kamu bantu, serta pengalaman yang relevan.',
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _message,
                              minLines: 5,
                              maxLines: 8,
                              maxLength: 1000,
                              decoration: const InputDecoration(
                                labelText: 'Motivasi dan ketersediaan',
                              ),
                              validator: (v) => (v ?? '').trim().length < 10
                                  ? 'Tulis sedikitnya 10 karakter.'
                                  : null,
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
                              label: 'Kirim pengajuan relawan',
                              isLoading: _busy,
                              onPressed: _busy ? null : _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
  );
}

class OrganizationApplicationScreen extends StatelessWidget {
  const OrganizationApplicationScreen({this.applicationId, super.key});
  final String? applicationId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pendaftaran lembaga')),
    body: OperationsData(
      resource: 'myOrganizationApplications',
      builder: (rows) {
        final row = applicationId == null
            ? rows
                  .where((r) => ['draft', 'pending'].contains(r['status']))
                  .firstOrNull
            : rows.where((r) => r['id'] == applicationId).firstOrNull;
        if (applicationId != null && row == null) {
          return OperationsData(
            resource: 'registration:organization:$applicationId',
            builder: (found) => found.isEmpty
                ? const OperationsMessage(message: 'Pengajuan tidak ditemukan.')
                : _OrganizationForm(
                    key: ValueKey(found.first['id']),
                    initial: found.first,
                  ),
          );
        }
        return _OrganizationForm(
          key: ValueKey(applicationId ?? 'new'),
          initial: row ?? {},
        );
      },
    ),
  );
}

class _OrganizationForm extends ConsumerStatefulWidget {
  const _OrganizationForm({required this.initial, super.key});
  final OpsRow initial;
  @override
  ConsumerState<_OrganizationForm> createState() => _OrganizationFormState();
}

class _OrganizationFormState extends ConsumerState<_OrganizationForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _area = TextEditingController(),
      _contact = TextEditingController(),
      _phone = TextEditingController();
  late String _id;
  String _kind = 'social_institution';
  String? _path, _filename, _error;
  Uint8List? _document;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final row = widget.initial;
    _id = row['id'] as String? ?? const Uuid().v4();
    _name.text = row['name'] as String? ?? '';
    _area.text = row['area'] as String? ?? '';
    _contact.text = row['contact_name'] as String? ?? '';
    _phone.text = row['contact_phone'] as String? ?? '';
    _kind = row['kind'] as String? ?? _kind;
    _path = row['document_path'] as String?;
  }

  @override
  void dispose() {
    for (final c in [_name, _area, _contact, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Dokumen verifikasi',
            extensions: ['pdf', 'jpg', 'jpeg', 'png'],
            mimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
            uniformTypeIdentifiers: [
              'com.adobe.pdf',
              'public.jpeg',
              'public.png',
            ],
          ),
        ],
      );
      if (file == null || !mounted) return;
      if (await file.length() > 5242880) {
        setState(() => _error = 'Dokumen maksimal 5 MB.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (verificationDocumentType(bytes) == null) {
        setState(() => _error = 'Gunakan PDF, JPG atau PNG.');
        return;
      }
      if (mounted) {
        setState(() {
          _document = bytes;
          _filename = file.name;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Dokumen belum dapat dibuka. Coba pilih kembali.',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_document == null && _path == null) {
      setState(() => _error = 'Lampirkan dokumen pendukung lembaga.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(registrationRepositoryProvider);
      await repo.saveOrganization(_id, {
        'name': _name.text.trim(),
        'kind': _kind,
        'area': _area.text.trim(),
        'contact_name': _contact.text.trim(),
        'contact_phone': _phone.text.trim(),
      });
      if (_document != null) {
        _path = await repo.uploadDocument(_id, _document!);
        _document = null;
      }
      await repo.submitOrganization(_id, _path!);
      refreshRegistrations(ref);
      if (mounted) context.go('/join');
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Pengajuan belum selesai dikirim. Periksa koneksi dan pastikan tidak ada pengajuan lain yang sedang diperiksa.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readonly = ['pending', 'approved'].contains(widget.initial['status']);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (widget.initial.isNotEmpty) ...[
          RegistrationStatusCard(row: widget.initial),
          const SizedBox(height: 24),
        ],
        PkCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  readOnly: readonly,
                  maxLength: 150,
                  decoration: const InputDecoration(labelText: 'Nama lembaga'),
                  validator: requiredText,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'Jenis lembaga'),
                  items: const [
                    DropdownMenuItem(
                      value: 'social_institution',
                      child: Text('Lembaga sosial / panti'),
                    ),
                    DropdownMenuItem(
                      value: 'disaster_post',
                      child: Text('Posko kemanusiaan'),
                    ),
                    DropdownMenuItem(
                      value: 'recycling_partner',
                      child: Text('Mitra daur ulang'),
                    ),
                  ],
                  onChanged: readonly
                      ? null
                      : (v) => setState(() => _kind = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _area,
                  readOnly: readonly,
                  maxLength: 150,
                  decoration: const InputDecoration(labelText: 'Wilayah'),
                  validator: requiredText,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contact,
                  readOnly: readonly,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nama penanggung jawab',
                  ),
                  validator: requiredText,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  readOnly: readonly,
                  maxLength: 30,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nomor kontak'),
                  validator: (v) => (v ?? '').trim().length < 6
                      ? 'Nomor kontak belum lengkap.'
                      : null,
                ),
                const SizedBox(height: 16),
                if (_path != null) DocumentButton(path: _path!),
                if (!readonly) ...[
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_filename ?? 'Pilih dokumen pendukung'),
                  ),
                  const Text(
                    'PDF, JPG atau PNG maksimal 5 MB. Dokumen hanya dapat dibuka pemohon dan admin.',
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
                    label: 'Kirim pengajuan lembaga',
                    isLoading: _busy,
                    onPressed: _busy ? null : _submit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String? requiredText(String? value) =>
    (value ?? '').trim().length < 2 ? 'Isi sedikitnya 2 karakter.' : null;

class DocumentButton extends ConsumerStatefulWidget {
  const DocumentButton({required this.path, super.key});
  final String path;
  @override
  ConsumerState<DocumentButton> createState() => _DocumentButtonState();
}

class _DocumentButtonState extends ConsumerState<DocumentButton> {
  bool _busy = false;
  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final url = await ref
          .read(registrationRepositoryProvider)
          .documentUrl(widget.path);
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError('Viewer unavailable');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dokumen belum dapat dibuka. Coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _busy ? null : _open,
    icon: const Icon(Icons.description_outlined),
    label: const Text('Buka dokumen verifikasi'),
  );
}

class RegistrationQueueScreen extends StatelessWidget {
  const RegistrationQueueScreen({required this.type, super.key});
  final String type;
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: type == 'volunteer' ? 'Pengajuan relawan' : 'Pengajuan lembaga',
    permission: 'admin',
    child: PagedRowsList(
      resource: type == 'volunteer'
          ? 'pendingVolunteers'
          : 'pendingOrganizations',
      emptyMessage: 'Semua pengajuan sudah ditinjau.',
      itemBuilder: (row) => InkWell(
        onTap: () =>
            context.push('/operations/registrations/$type/${row['id']}'),
        child: RegistrationStatusCard(row: row),
      ),
    ),
  );
}

class RegistrationReviewScreen extends StatelessWidget {
  const RegistrationReviewScreen({
    required this.type,
    required this.requestId,
    super.key,
  });
  final String type, requestId;
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Tinjau pengajuan',
    permission: 'admin',
    child: OperationsData(
      resource: 'registration:$type:$requestId',
      builder: (rows) => rows.isEmpty
          ? const OperationsMessage(message: 'Pengajuan tidak ditemukan.')
          : _RegistrationReviewForm(type: type, row: rows.first),
    ),
  );
}

class _RegistrationReviewForm extends StatefulWidget {
  const _RegistrationReviewForm({required this.type, required this.row});
  final String type;
  final OpsRow row;
  @override
  State<_RegistrationReviewForm> createState() =>
      _RegistrationReviewFormState();
}

class _RegistrationReviewFormState extends State<_RegistrationReviewForm> {
  final _reason = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      RegistrationStatusCard(row: widget.row),
      const SizedBox(height: 24),
      PkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.type == 'volunteer')
              Text(widget.row['message'] as String)
            else ...[
              Text('Wilayah: ${widget.row['area']}'),
              Text('Penanggung jawab: ${widget.row['contact_name']}'),
              Text('Kontak: ${widget.row['contact_phone']}'),
              if (widget.row['document_path'] != null)
                DocumentButton(path: widget.row['document_path'] as String),
            ],
            if (widget.row['status'] == 'pending') ...[
              const SizedBox(height: 24),
              TextField(
                controller: _reason,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Catatan keputusan',
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              OperationButton(
                action: 'reviewRegistration',
                label: 'Setujui pengajuan',
                values: () => {
                  'id': widget.row['id'],
                  'type': widget.type,
                  'approve': true,
                  'reason': _reason.text.trim(),
                },
                onSuccess: () => finishWorkflow(context),
              ),
              const SizedBox(height: 12),
              OperationButton(
                action: 'reviewRegistration',
                label: 'Tolak dengan alasan',
                secondary: true,
                validate: () {
                  final valid = _reason.text.trim().isNotEmpty;
                  setState(
                    () =>
                        _error = valid ? null : 'Alasan penolakan wajib diisi.',
                  );
                  return valid;
                },
                values: () => {
                  'id': widget.row['id'],
                  'type': widget.type,
                  'approve': false,
                  'reason': _reason.text.trim(),
                },
                onSuccess: () => finishWorkflow(context),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
