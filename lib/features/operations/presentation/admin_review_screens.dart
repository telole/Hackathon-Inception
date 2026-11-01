import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/operations_providers.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/operations_repository.dart';
import '../../../core/widgets/pk_card.dart';
import 'operations_widgets.dart';
import 'workflow_screens.dart';

class AdminDonationReviewScreen extends ConsumerWidget {
  const AdminDonationReviewScreen({required this.donationId, super.key});
  final String donationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => OperationsPage(
    title: 'Tinjau detail donasi',
    permission: 'admin',
    child: OperationsData(
      resource: 'review:$donationId',
      builder: (rows) {
        if (rows.isEmpty) {
          return const OperationsMessage(message: 'Pengajuan tidak ditemukan.');
        }
        final donation = rows.first;
        final events =
            List<dynamic>.from(donation['donation_events'] as List? ?? [])
              ..sort(
                (a, b) => b['created_at'].toString().compareTo(
                  a['created_at'].toString(),
                ),
              );
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(operationsDataProvider('review:$donationId')),
              icon: const Icon(Icons.refresh),
              label: const Text('Perbarui data dan foto'),
            ),
            PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation['tracking_code'] as String,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  OperationStatus(donation['status'] as String),
                  const SizedBox(height: 16),
                  Text(
                    donation['method'] == 'pickup'
                        ? 'Metode: dijemput relawan'
                        : 'Metode: antar ke titik layanan',
                  ),
                  const SizedBox(height: 12),
                  for (final item in donation['donation_items'] as List? ?? [])
                    Text(
                      '${item['category']} · ukuran ${item['size_code']} · ${item['quantity']} potong',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Foto pengajuan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if ((donation['photo_urls'] as List? ?? []).isEmpty)
              const PkCard(
                child: Text('Tidak ada foto yang dapat ditampilkan.'),
              ),
            for (final url in donation['photo_urls'] as List? ?? [])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => Dialog(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: InteractiveViewer(
                                child: Image.network(
                                  url,
                                  errorBuilder: (_, error, stack) =>
                                      const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Text('Foto gagal dimuat.'),
                                      ),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        url as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stack) => const Center(
                          child: Text('Foto gagal dimuat. Muat ulang halaman.'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pernyataan donatur',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final item in {
                    'clean_check': 'Sudah dicuci',
                    'intact_check': 'Bagian pakaian lengkap',
                    'not_torn_check': 'Tidak robek',
                  }.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        donation[item.key] == true
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                      ),
                      title: Text(item.value),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if ([
              'submitted',
              'scheduled',
              'received',
            ].contains(donation['status']))
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/operations/schedule/$donationId'),
                icon: const Icon(Icons.event_outlined),
                label: const Text('Atur jadwal dan penugasan'),
              ),
            if (donation['status'] == 'submitted')
              _RevisionNote(donationId: donationId),
            const SizedBox(height: 24),
            Text(
              'Riwayat pengajuan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final event in events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(event['summary'] as String),
                subtitle: Text(workflowDate(event['created_at'])),
              ),
          ],
        );
      },
    ),
  );
}

class _RevisionNote extends StatefulWidget {
  const _RevisionNote({required this.donationId});
  final String donationId;
  @override
  State<_RevisionNote> createState() => _RevisionNoteState();
}

class _RevisionNoteState extends State<_RevisionNote> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PkCard(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Perlu diperbaiki?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reason,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Catatan untuk donatur',
            ),
            validator: (v) => (v ?? '').trim().isEmpty
                ? 'Jelaskan bagian yang perlu diperbaiki.'
                : null,
          ),
          const SizedBox(height: 16),
          OperationButton(
            action: 'revise',
            label: 'Kirim permintaan perbaikan',
            validate: () => _form.currentState!.validate(),
            values: () => {
              'id': widget.donationId,
              'reason': _reason.text.trim(),
            },
            onSuccess: () => finishWorkflow(context),
          ),
        ],
      ),
    ),
  );
}

class AdminTasksScreen extends StatelessWidget {
  const AdminTasksScreen({super.key});
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Kelola penugasan',
    permission: 'admin',
    child: OperationsList(
      resource: 'adminTasks',
      emptyMessage: 'Belum ada tugas yang dibuat.',
      itemBuilder: (task) => PkCard(
        onTap: () => context.push('/operations/admin-tasks/${task['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskLabel(task['kind'] as String?),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              (task['profiles'] as Map?)?['display_name'] as String? ??
                  'Relawan',
            ),
            Text(
              (task['donations'] as Map?)?['tracking_code'] as String? ??
                  'Donasi',
            ),
            const SizedBox(height: 12),
            OperationStatus(task['status'] as String),
          ],
        ),
      ),
    ),
  );
}

class ReassignTaskScreen extends StatelessWidget {
  const ReassignTaskScreen({required this.taskId, super.key});
  final String taskId;
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Ubah penugasan',
    permission: 'admin',
    child: OperationsData(
      resource: 'adminTask:$taskId',
      builder: (tasks) {
        final task = tasks.where((t) => t['id'] == taskId).firstOrNull;
        if (task == null) {
          return const OperationsMessage(message: 'Tugas tidak ditemukan.');
        }
        if (![
              'assigned',
              'declined',
              'cancelled',
              'failed',
            ].contains(task['status']) ||
            !['pickup', 'curation'].contains(task['kind'])) {
          return const OperationsMessage(
            message: 'Tugas yang sudah diterima/dikerjakan tidak dapat dialihkan melalui halaman ini.',
          );
        }
        return OperationsData(
          resource: 'volunteers',
          builder: (volunteers) =>
              _ReassignForm(task: task, volunteers: volunteers),
        );
      },
    ),
  );
}

class _ReassignForm extends StatefulWidget {
  const _ReassignForm({required this.task, required this.volunteers});
  final OpsRow task;
  final List<OpsRow> volunteers;
  @override
  State<_ReassignForm> createState() => _ReassignFormState();
}

class _ReassignFormState extends State<_ReassignForm> {
  String? _volunteer, _error;
  DateTime? _at;
  final _notes = TextEditingController();
  @override
  void initState() {
    super.initState();
    _volunteer = widget.task['assigned_to'] as String?;
    _notes.text = widget.task['notes'] as String? ?? '';
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
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (mounted && time != null) {
      setState(
        () => _at = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      PkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              taskLabel(widget.task['kind'] as String?),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            OperationStatus(widget.task['status'] as String),
            const SizedBox(height: 24),
            WorkflowChoice(
              label: 'Relawan pengganti',
              value: _volunteer,
              rows: widget.volunteers,
              idKey: 'user_id',
              labelFor: (v) => v['display_name'] as String? ?? 'Relawan',
              onChanged: (v) => setState(() => _volunteer = v),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pick,
              child: Text(
                _at == null
                    ? 'Pilih jadwal tugas (opsional)'
                    : workflowDate(_at!.toIso8601String()),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Catatan tugas'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 24),
            OperationButton(
              action: 'assign',
              label: 'Simpan penugasan',
              validate: () {
                final valid =
                    widget.volunteers.any((v) => v['user_id'] == _volunteer) &&
                    (_at == null || _at!.isAfter(DateTime.now()));
                setState(
                  () => _error = valid
                      ? null
                      : 'Pilih relawan dan jadwal yang belum lewat.',
                );
                return valid;
              },
              values: () => {
                'id': widget.task['donation_id'],
                'task_id': widget.task['id'],
                'point_id': widget.task['point_id'],
                'volunteer': _volunteer,
                'kind': widget.task['kind'],
                'at': _at?.toUtc().toIso8601String(),
                'notes': _notes.text.trim(),
              },
              onSuccess: () => finishWorkflow(context),
            ),
          ],
        ),
      ),
    ],
  );
}
