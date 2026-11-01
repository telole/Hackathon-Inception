import '../../../core/widgets/paged_rows_list.dart';
import '../../../core/data/rows_pager.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_card.dart';
import '../../donation/application/donation_photo_picker.dart';
import '../../home/application/home_providers.dart';
import '../../operations/data/operations_repository.dart';
import '../../operations/presentation/operations_widgets.dart';
import '../../operations/presentation/workflow_screens.dart';
import '../data/program_repository.dart';

class ManagedProgramsScreen extends StatelessWidget {
  const ManagedProgramsScreen({super.key});
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Program lembaga',
    permission: 'mitra',
    child: PagedRowsList(
      resource: 'managedPrograms',
      emptyMessage:
          'Belum ada program. Buat kebutuhan pertama untuk lembagamu.',
      header: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: PkButton(
            label: 'Tambah program',
            expanded: true,
            onPressed: () => context.push('/operations/programs/new'),
          ),
        ),
      ],
      itemBuilder: (row) => PkCard(
        onTap: () => context.push('/operations/programs/${row['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgramBanner(url: row['banner_url'] as String?),
            const SizedBox(height: 16),
            Text(
              row['title'] as String,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(row['organizations']['name'] as String),
            const SizedBox(height: 8),
            OperationStatus(row['status'] as String),
            const SizedBox(height: 8),
            Text('Batas waktu: ${workflowDate(row['deadline_at'])}'),
          ],
        ),
      ),
    ),
  );
}

class ProgramEditorScreen extends ConsumerWidget {
  const ProgramEditorScreen({this.programId, super.key});
  final String? programId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => OperationsPage(
    title: programId == null ? 'Tambah program' : 'Edit program',
    permission: 'mitra',
    child: OperationsData(
      resource: 'points',
      builder: (points) {
        if (points.isEmpty) {
          return const OperationsMessage(
            message: 'Lembagamu perlu memiliki titik layanan aktif dan terverifikasi.',
          );
        }
        if (programId == null) {
          return _ProgramForm(program: const {}, points: points);
        }
        return ref
            .watch(managedProgramProvider(programId!))
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, stack) => OperationsMessage(
                message: 'Program tidak tersedia.',
                retry: () => ref.invalidate(managedProgramProvider(programId!)),
              ),
              data: (row) => _ProgramForm(
                key: ValueKey(programId),
                program: row,
                points: points,
              ),
            );
      },
    ),
  );
}

class _ProgramForm extends ConsumerStatefulWidget {
  const _ProgramForm({required this.program, required this.points, super.key});
  final OpsRow program;
  final List<OpsRow> points;
  @override
  ConsumerState<_ProgramForm> createState() => _ProgramFormState();
}

class _ProgramFormState extends ConsumerState<_ProgramForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController();
  final _lines = <_ProgramLine>[];
  String? _id, _point, _bannerPath, _bannerUrl, _error;
  DateTime? _deadline;
  Uint8List? _banner;
  bool _removeBanner = false, _busy = false;
  @override
  void initState() {
    super.initState();
    final p = widget.program;
    _id = p['id'] as String?;
    _title.text = p['title'] as String? ?? '';
    _description.text = p['description'] as String? ?? '';
    _point = p['point_id'] as String? ?? widget.points.first['id'] as String;
    _deadline = DateTime.tryParse(p['deadline_at'] as String? ?? '')?.toLocal();
    _bannerPath = p['banner_path'] as String?;
    _bannerUrl = p['banner_url'] as String?;
    for (final line in p['need_items'] as List? ?? []) {
      _lines.add(_ProgramLine(Map<String, dynamic>.from(line as Map)));
    }
    if (_lines.isEmpty) _lines.add(_ProgramLine({}));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final line in _lines) {
      line.quantity.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final photo = await ref.read(donationPhotoPickerProvider).pick();
    if (!mounted || photo == null) return;
    if (photo.bytes.length > 1048576 || imageExtension(photo.bytes) == null) {
      setState(() => _error = 'Pilih banner JPG, PNG atau WebP maksimal 1 MB.');
      return;
    }
    setState(() {
      _banner = photo.bytes;
      _removeBanner = false;
      _error = null;
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      initialDate: _deadline != null && _deadline!.isAfter(now)
          ? _deadline!
          : now,
    );
    if (mounted && selected != null) {
      setState(
        () => _deadline = DateTime(
          selected.year,
          selected.month,
          selected.day,
          23,
          59,
        ),
      );
    }
  }

  void _invalidate() {
    ref.invalidate(managedProgramsProvider);
    ref.invalidate(rowsPagerProvider('managedPrograms'));
    ref.invalidate(homeSnapshotProvider);
    if (_id != null) ref.invalidate(managedProgramProvider(_id!));
  }

  Future<void> _save([String? status]) async {
    if (_busy || !_form.currentState!.validate()) return;
    final point = widget.points.where((p) => p['id'] == _point).firstOrNull;
    if (point == null || _deadline == null) {
      setState(() => _error = 'Pilih titik tujuan dan batas waktu.');
      return;
    }
    if (status == 'open' &&
        (!_deadline!.isAfter(DateTime.now()) ||
            (_banner == null && (_bannerPath == null || _removeBanner)))) {
      setState(
        () => _error = 'Program yang dipublikasikan perlu banner dan batas waktu yang belum lewat.',
      );
      return;
    }
    final variants = _lines
        .map((l) => '${l.category}/${l.size}/${l.age}')
        .toSet();
    if (variants.length != _lines.length) {
      setState(
        () =>
            _error = 'Gabungkan baris dengan jenis, ukuran dan usia yang sama.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repository = ref.read(programRepositoryProvider);
    try {
      _id = await repository.save({
        'id': _id,
        'organization_id': point['organization_id'],
        'point_id': _point,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'deadline_at': _deadline!.toUtc().toIso8601String(),
        'incident_id': widget.program['incident_id'],
        'items': [for (final line in _lines) line.values],
      });
      // Keep the ID if upload fails, so retry updates the same draft.
      if (_banner != null) {
        _bannerPath = await repository.uploadBanner(_id!, _banner!);
        _banner = null;
      } else if (_removeBanner) {
        await repository.removeBanner(_id!);
        _bannerPath = null;
      }
      if (status != null) await repository.status(_id!, status);
      _invalidate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program berhasil disimpan.')),
        );
        context.go('/operations/programs');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Program belum selesai disimpan. Periksa izin, koneksi, dan komitmen stok pada item. Kamu dapat mencoba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy || _id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus program?'),
        content: const Text(
          'Program yang sudah memiliki donasi atau alokasi perlu ditutup, bukan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(programRepositoryProvider).delete(_id!);
      _invalidate();
      if (mounted) context.go('/operations/programs');
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Program tidak dapat dihapus. Jika sudah memiliki aktivitas, gunakan Tutup program.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
    absorbing: _busy,
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProgramBanner(
                  bytes: _banner,
                  url: _removeBanner ? null : _bannerUrl,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickBanner,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Pilih / ganti banner'),
                ),
                if (_banner != null || (_bannerPath != null && !_removeBanner))
                  TextButton(
                    onPressed: () => setState(() {
                      _banner = null;
                      _removeBanner = true;
                    }),
                    child: const Text('Hapus banner'),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  maxLength: 150,
                  decoration: const InputDecoration(labelText: 'Nama program'),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Nama program wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 3000,
                  decoration: const InputDecoration(
                    labelText: 'Cerita dan kebutuhan program',
                  ),
                ),
                const SizedBox(height: 16),
                WorkflowChoice(
                  label: 'Titik tujuan / lembaga',
                  value: _point,
                  rows: widget.points,
                  labelFor: (p) => p['name'] as String,
                  onChanged: (v) => setState(() => _point = v),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _deadline == null
                        ? 'Pilih batas waktu'
                        : workflowDate(_deadline!.toIso8601String()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Pakaian yang dibutuhkan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final line in _lines)
            Padding(
              key: ObjectKey(line),
              padding: const EdgeInsets.only(bottom: 16),
              child: PkCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: line.category,
                      decoration: const InputDecoration(
                        labelText: 'Jenis pakaian',
                      ),
                      items: [
                        for (final value in {
                          'kaos',
                          'kemeja',
                          'celana',
                          'batik',
                          'seragam',
                          line.category,
                        })
                          DropdownMenuItem(value: value, child: Text(value)),
                      ],
                      onChanged: (v) => line.category = v!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: line.size,
                      decoration: const InputDecoration(labelText: 'Ukuran'),
                      items: [
                        for (final value in {
                          'XS',
                          'S',
                          'M',
                          'L',
                          'XL',
                          'ALL',
                          line.size,
                        })
                          DropdownMenuItem(value: value, child: Text(value)),
                      ],
                      onChanged: (v) => line.size = v!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: line.age,
                      decoration: const InputDecoration(
                        labelText: 'Kelompok usia',
                      ),
                      items: [
                        for (final value in {'anak', 'dewasa', line.age})
                          DropdownMenuItem(value: value, child: Text(value)),
                      ],
                      onChanged: (v) => line.age = v!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: line.quantity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target jumlah',
                        suffixText: 'potong',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n <= 0 || n > 1000000
                            ? 'Isi jumlah 1–1.000.000.'
                            : null;
                      },
                    ),
                    if (_lines.length > 1)
                      TextButton(
                        onPressed: () => setState(() {
                          _lines.remove(line);
                          line.quantity.dispose();
                        }),
                        child: const Text('Hapus jenis ini'),
                      ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => setState(() => _lines.add(_ProgramLine({}))),
            icon: const Icon(Icons.add),
            label: const Text('Tambah jenis pakaian'),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          PkButton(
            label: 'Simpan program',
            expanded: true,
            isLoading: _busy,
            onPressed: _busy ? null : () => _save(),
          ),
          const SizedBox(height: 12),
          PkButton(
            label: 'Simpan dan publikasikan',
            expanded: true,
            onPressed: () => _save('open'),
          ),
          if (_id != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _save('paused'),
              child: const Text('Jeda program'),
            ),
            OutlinedButton(
              onPressed: () => _save('closed'),
              child: const Text('Tutup program'),
            ),
            TextButton(onPressed: _delete, child: const Text('Hapus program')),
          ],
        ],
      ),
    ),
  );
}

class _ProgramLine {
  _ProgramLine(OpsRow row)
    : id = row['id'] as String?,
      category = row['category'] as String? ?? 'kaos',
      size = row['size_code'] as String? ?? 'M',
      age = row['age_group'] as String? ?? 'anak',
      quantity = TextEditingController(text: '${row['requested_qty'] ?? 1}');
  String? id;
  String category, size, age;
  final TextEditingController quantity;
  OpsRow get values => {
    'id': id,
    'category': category,
    'size_code': size,
    'age_group': age,
    'requested_qty': int.parse(quantity.text),
  };
}

class ProgramBanner extends StatelessWidget {
  const ProgramBanner({this.url, this.bytes, super.key});
  final String? url;
  final Uint8List? bytes;
  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Center(child: Icon(Icons.landscape_outlined, size: 48)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: bytes != null
            ? Image.memory(
                bytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => placeholder,
              )
            : url != null
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}
