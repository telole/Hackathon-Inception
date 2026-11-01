import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/pk_card.dart';
import '../data/operations_repository.dart';
import 'operations_widgets.dart';

class ScheduleQueueScreen extends StatelessWidget {
  const ScheduleQueueScreen({super.key});
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Jadwal dan penugasan',
    permission: 'admin',
    child: OperationsList(
      resource: 'scheduleQueue',
      emptyMessage: 'Belum ada donasi yang perlu dijadwalkan.',
      itemBuilder: (row) => PkCard(
        onTap: () => context.push('/operations/schedule/${row['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row['tracking_code'] as String,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OperationStatus(row['status'] as String),
            const SizedBox(height: 12),
            Text(
              row['method'] == 'pickup'
                  ? 'Penjemputan oleh relawan'
                  : 'Diantar ke titik donasi',
            ),
            if (row['scheduled_at'] != null)
              Text(workflowDate(row['scheduled_at'])),
            const SizedBox(height: 12),
            const Text('Atur jadwal dan relawan →'),
          ],
        ),
      ),
    ),
  );
}

class ScheduleDonationScreen extends StatelessWidget {
  const ScheduleDonationScreen({required this.donationId, super.key});
  final String donationId;
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Atur penyerahan',
    permission: 'admin',
    child: OperationsData(
      resource: 'donation:$donationId',
      builder: (rows) {
        if (rows.isEmpty) {
          return const OperationsMessage(message: 'Donasi tidak ditemukan.');
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rows.first['tracking_code'] as String,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  OperationStatus(rows.first['status'] as String),
                  const SizedBox(height: 16),
                  for (final item
                      in rows.first['donation_items'] as List? ?? [])
                    Text(
                      '${item['category']} · ${item['size_code']} · ${item['quantity']} potong',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _ScheduleForm(
              key: ValueKey(
                '${rows.first['status']}:${rows.first['scheduled_at']}',
              ),
              donation: rows.first,
            ),
          ],
        );
      },
    ),
  );
}

class _ScheduleForm extends StatefulWidget {
  const _ScheduleForm({required this.donation, super.key});
  final OpsRow donation;
  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  DateTime? _at;
  String? _volunteer;
  String _kind = 'pickup';
  String? _error;
  final _notes = TextEditingController();
  @override
  void initState() {
    super.initState();
    _at = DateTime.tryParse(widget.donation['scheduled_at'] as String? ?? '')
        ?.toLocal();
    _kind = widget.donation['status'] == 'received' ? 'curation' : 'pickup';
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _at != null && _at!.isAfter(now) ? _at! : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _at ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time != null && mounted) {
      setState(() {
        _at = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        _error = null;
      });
    }
  }

  bool _validate({bool assignment = false}) {
    String? error;
    if (_at == null || !_at!.isAfter(DateTime.now())) {
      error = 'Pilih jadwal yang belum lewat.';
    }
    if (assignment && _volunteer == null) {
      error = 'Pilih relawan terlebih dahulu.';
    }
    if (widget.donation['point_id'] == null) {
      error = 'Donasi belum memiliki titik layanan.';
    }
    setState(() => _error = error);
    return error == null;
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.donation['status'];
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Jadwal penyerahan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              _at == null
                  ? 'Pilih tanggal dan waktu'
                  : workflowDate(_at!.toIso8601String()),
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (status == 'submitted' || status == 'scheduled') ...[
            const SizedBox(height: 16),
            OperationButton(
              action: 'schedule',
              label: 'Konfirmasi jadwal',
              validate: _validate,
              values: () => {
                'id': widget.donation['id'],
                'at': _at!.toUtc().toIso8601String(),
              },
            ),
          ],
          if (status == 'submitted') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Alasan perbaikan untuk donatur',
              ),
            ),
            OperationButton(
              action: 'revise',
              label: 'Kembalikan untuk diperbaiki',
              secondary: true,
              validate: () {
                final valid = _notes.text.trim().isNotEmpty;
                setState(
                  () => _error = valid ? null : 'Alasan perbaikan wajib diisi.',
                );
                return valid;
              },
              values: () => {
                'id': widget.donation['id'],
                'reason': _notes.text.trim(),
              },
              onSuccess: () => finishWorkflow(context),
            ),
          ],
          if (status == 'scheduled' || status == 'received') ...[
            const SizedBox(height: 24),
            Text(
              'Penugasan relawan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            OperationsData(
              resource: 'volunteers',
              builder: (volunteers) {
                if (volunteers.isEmpty) {
                  return const Text(
                    'Belum ada akun berizin relawan. Admin dapat memberikan izin melalui Hak akses pengguna.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WorkflowChoice(
                      label: 'Relawan',
                      value: _volunteer,
                      rows: volunteers,
                      idKey: 'user_id',
                      labelFor: (v) =>
                          v['display_name'] as String? ?? 'Relawan',
                      onChanged: (v) => setState(() => _volunteer = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _kind,
                      decoration: const InputDecoration(
                        labelText: 'Jenis tugas',
                      ),
                      items: [
                        if (status == 'scheduled')
                          const DropdownMenuItem(
                            value: 'pickup',
                            child: Text('Penjemputan'),
                          ),
                        const DropdownMenuItem(
                          value: 'curation',
                          child: Text('Kurasi fisik'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _kind = v!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notes,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan untuk relawan',
                      ),
                    ),
                    const SizedBox(height: 16),
                    OperationButton(
                      action: 'assign',
                      label: 'Tugaskan relawan',
                      validate: () => _validate(assignment: true),
                      onSuccess: () => finishWorkflow(context),
                      values: () => {
                        'id': widget.donation['id'],
                        'point_id': widget.donation['point_id'],
                        'volunteer': _volunteer,
                        'kind': _kind,
                        'at': _at!.toUtc().toIso8601String(),
                        'notes': _notes.text.trim(),
                      },
                    ),
                  ],
                );
              },
            ),
          ],
          if (!['submitted', 'scheduled', 'received'].contains(status))
            const Text(
              'Donasi ini tidak berada pada tahap penjadwalan atau penugasan.',
            ),
        ],
      ),
    );
  }
}

class AllocateStockScreen extends StatefulWidget {
  const AllocateStockScreen({super.key});
  @override
  State<AllocateStockScreen> createState() => _AllocateStockScreenState();
}

class _AllocateStockScreenState extends State<AllocateStockScreen> {
  String? _point, _batch, _line;
  final _quantity = TextEditingController(text: '1');
  String? _error;
  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Alokasi pakaian',
    permission: 'mitra',
    child: OperationsData(
      resource: 'points',
      builder: (points) {
        if (points.isEmpty) {
          return const OperationsMessage(
            message: 'Belum ada titik layanan yang dapat dikelola.',
          );
        }
        final point = points.any((p) => p['id'] == _point)
            ? _point!
            : points.first['id'] as String;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Cadangkan pakaian untuk program yang sesuai. Jumlah tersedia diperiksa kembali oleh server.',
            ),
            const SizedBox(height: 24),
            WorkflowChoice(
              label: 'Titik sumber',
              value: point,
              rows: points,
              labelFor: (r) => r['name'] as String,
              onChanged: (v) => setState(() {
                _point = v;
                _batch = null;
                _line = null;
              }),
            ),
            const SizedBox(height: 16),
            OperationsData(
              resource: 'inventory:$point',
              builder: (batches) {
                final available = batches
                    .where((b) => (b['available_qty'] as num) > 0)
                    .toList();
                if (available.isEmpty) {
                  return const PkCard(
                    child: Text('Tidak ada stok tersedia di titik ini.'),
                  );
                }
                final selected = available
                    .where((b) => b['id'] == _batch)
                    .firstOrNull;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WorkflowChoice(
                      label: 'Pakaian tersedia',
                      value: selected?['id'] as String?,
                      rows: available,
                      labelFor: (b) =>
                          '${b['category']} · ${b['size_code']} · ${b['age_group']} (${b['available_qty']})',
                      onChanged: (v) => setState(() {
                        _batch = v;
                        _line = null;
                      }),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 16),
                      OperationsData(
                        resource: 'needLines',
                        builder: (lines) {
                          final matches = lines
                              .where(
                                (l) =>
                                    l['category'] == selected['category'] &&
                                    l['size_code'] == selected['size_code'] &&
                                    l['age_group'] == selected['age_group'],
                              )
                              .toList();
                          if (matches.isEmpty) {
                            return const PkCard(
                              child: Text(
                                'Belum ada program terbuka dengan jenis, ukuran, dan kelompok usia yang sesuai.',
                              ),
                            );
                          }
                          return PkCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                WorkflowChoice(
                                  label: 'Program tujuan',
                                  value: _line,
                                  rows: matches,
                                  labelFor: (l) =>
                                      '${l['needs']['title']} · target ${l['requested_qty']}',
                                  onChanged: (v) => setState(() => _line = v),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _quantity,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Jumlah pakaian',
                                    suffixText: 'potong',
                                  ),
                                ),
                                if (_error != null)
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                OperationButton(
                                  action: 'reserve',
                                  label: 'Reservasi pakaian',
                                  validate: () {
                                    final qty = int.tryParse(_quantity.text);
                                    final line = matches
                                        .where((l) => l['id'] == _line)
                                        .firstOrNull;
                                    final valid =
                                        line != null &&
                                        qty != null &&
                                        qty > 0 &&
                                        qty <=
                                            (selected['available_qty']
                                                as num) &&
                                        qty <= (line['requested_qty'] as num);
                                    setState(
                                      () => _error = valid ? null : 'Pilih tujuan dan isi jumlah sesuai stok serta target program.',
                                    );
                                    return valid;
                                  },
                                  onSuccess: () => finishWorkflow(context),
                                  values: () => {
                                    'batch': _batch,
                                    'need_item': _line,
                                    'quantity': int.parse(_quantity.text),
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        );
      },
    ),
  );
}

class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});
  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  String? _allocation, _volunteer, _error;
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Buat kiriman',
    permission: 'mitra',
    child: OperationsData(
      resource: 'allocations',
      builder: (rows) {
        final allocations = rows
            .where((a) => (a['shipment_items'] as List? ?? []).isEmpty)
            .toList();
        if (allocations.isEmpty) {
          return const OperationsMessage(
            message: 'Belum ada alokasi siap kirim. Reservasi pakaian terlebih dahulu.',
          );
        }
        return OperationsData(
          resource: 'volunteers',
          builder: (volunteers) {
            if (volunteers.isEmpty) {
              return const OperationsMessage(
                message:
                    'Belum ada relawan untuk mengantar kiriman. Hubungi admin.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                PkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Siapkan perjalanan berikutnya',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Satu kiriman membawa satu alokasi. Stok akan dikeluarkan ketika keberangkatan dikonfirmasi.',
                      ),
                      const SizedBox(height: 24),
                      WorkflowChoice(
                        label: 'Alokasi pakaian',
                        value: _allocation,
                        rows: allocations,
                        labelFor: (a) =>
                            '${a['quantity']} potong · ${a['id'].toString().substring(0, 8)}',
                        onChanged: (v) => setState(() => _allocation = v),
                      ),
                      const SizedBox(height: 16),
                      WorkflowChoice(
                        label: 'Relawan pengantar',
                        value: _volunteer,
                        rows: volunteers,
                        idKey: 'user_id',
                        labelFor: (v) =>
                            v['display_name'] as String? ?? 'Relawan',
                        onChanged: (v) => setState(() => _volunteer = v),
                      ),
                      if (_error != null)
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      const SizedBox(height: 24),
                      OperationButton(
                        action: 'createShipment',
                        label: 'Buat kiriman',
                        validate: () {
                          final valid =
                              allocations.any((a) => a['id'] == _allocation) &&
                              volunteers.any((v) => v['user_id'] == _volunteer);
                          setState(
                            () => _error = valid
                                ? null
                                : 'Pilih alokasi dan relawan pengantar.',
                          );
                          return valid;
                        },
                        onSuccess: () => finishWorkflow(context),
                        values: () => {
                          'allocation': _allocation,
                          'volunteer': _volunteer,
                        },
                      ),
                    ],
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

class WorkflowChoice extends StatelessWidget {
  const WorkflowChoice({
    required this.label,
    required this.value,
    required this.rows,
    required this.labelFor,
    required this.onChanged,
    this.idKey = 'id',
    super.key,
  });
  final String label, idKey;
  final String? value;
  final List<OpsRow> rows;
  final String Function(OpsRow) labelFor;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey('$label:$value:${rows.map((r) => r[idKey]).join(',')}'),
    initialValue: rows.any((r) => r[idKey] == value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final row in rows)
        DropdownMenuItem(
          value: row[idKey] as String,
          child: Text(
            labelFor(row),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
    onChanged: onChanged,
  );
}

String workflowDate(dynamic raw) {
  final at = DateTime.tryParse(raw.toString())?.toLocal();
  if (at == null) return 'Jadwal belum ditentukan';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(at.day)}/${two(at.month)}/${at.year} · ${two(at.hour)}:${two(at.minute)}';
}

void finishWorkflow(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/operations');
  }
}
