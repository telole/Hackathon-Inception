import '../../../core/widgets/paged_rows_list.dart';
import '../../../core/data/rows_pager.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_button.dart';
import '../../donation/application/donation_providers.dart';
import '../../home/application/home_providers.dart';
import '../application/operations_providers.dart';
import '../data/operations_repository.dart';

class OperationsPage extends ConsumerWidget {
  const OperationsPage({
    required this.title,
    required this.child,
    this.permission,
    super.key,
  });
  final String title;
  final String? permission;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: ref
          .watch(operationsAccessProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => OperationsMessage(
              message: 'Akses operasional belum dapat dimuat. Periksa sesi dan koneksi.',
              retry: () => ref.invalidate(operationsAccessProvider),
            ),
            data: (access) {
              final allowed = permission == null
                  ? access.isAdmin ||
                        access.allows('relawan') ||
                        access.allows('mitra')
                  : access.allows(permission!);
              return allowed
                  ? child
                  : const OperationsMessage(
                      message: 'Akunmu belum memiliki izin untuk halaman ini. Hubungi admin lembagamu.',
                      icon: Icons.lock_outline,
                    );
            },
          ),
    ),
  );
}

class OperationsMessage extends StatelessWidget {
  const OperationsMessage({
    required this.message,
    this.retry,
    this.icon = Icons.info_outline,
    super.key,
  });
  final String message;
  final VoidCallback? retry;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Coba lagi')),
        ],
      ),
    ),
  );
}

class OperationsData extends ConsumerWidget {
  const OperationsData({
    required this.resource,
    required this.builder,
    super.key,
  });
  final String resource;
  final Widget Function(List<OpsRow>) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(operationsDataProvider(resource))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => OperationsMessage(
          message: 'Data belum dapat dimuat. Periksa koneksi atau minta admin memeriksa layanan ini.',
          retry: () => ref.invalidate(operationsDataProvider(resource)),
        ),
        data: builder,
      );
}

class OperationsList extends ConsumerWidget {
  const OperationsList({
    required this.resource,
    required this.emptyMessage,
    required this.itemBuilder,
    super.key,
  });
  final String resource;
  final String emptyMessage;
  final Widget Function(OpsRow) itemBuilder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => PagedRowsList(
    resource: resource,
    emptyMessage: emptyMessage,
    itemBuilder: itemBuilder,
  );
}

class OperationButton extends ConsumerStatefulWidget {
  const OperationButton({
    required this.action,
    required this.label,
    required this.values,
    this.validate,
    this.secondary = false,
    this.onSuccess,
    super.key,
  });
  final String action;
  final String label;
  final OpsRow Function() values;
  final bool Function()? validate;
  final bool secondary;
  final VoidCallback? onSuccess;
  @override
  ConsumerState<OperationButton> createState() => _OperationButtonState();
}

class _OperationButtonState extends ConsumerState<OperationButton> {
  bool _busy = false;
  bool _confirming = false;
  String _requestKey = const Uuid().v4();
  Future<void> _run() async {
    if (_busy || _confirming || !(widget.validate?.call() ?? true)) return;
    _confirming = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.label),
        content: const Text(
          'Periksa kembali data sebelum menyimpan tindakan ini.',
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
    _confirming = false;
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(operationsRepositoryProvider)
          .act(widget.action, widget.values(), _requestKey);
      _requestKey = const Uuid().v4();
      ref.invalidate(operationsDataProvider);
      ref.invalidate(rowsPagerProvider);
      ref.invalidate(donationsProvider);
      ref.invalidate(homeSnapshotProvider);
      if (widget.action == 'role' || widget.action == 'verify') {
        ref.invalidate(operationsAccessProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perubahan berhasil disimpan.')),
        );
        widget.onSuccess?.call();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Belum dapat disimpan. Periksa izin, data, dan koneksi sebelum mencoba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PkButton(
    label: widget.label,
    onPressed: _busy ? null : _run,
    isLoading: _busy,
    expanded: true,
    variant: widget.secondary
        ? PkButtonVariant.secondary
        : PkButtonVariant.primary,
  );
}

class OperationStatus extends StatelessWidget {
  const OperationStatus(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final done = [
      'completed',
      'received',
      'curated',
      'verified',
    ].contains(status);
    final failed = [
      'failed',
      'cancelled',
      'declined',
      'disputed',
    ].contains(status);
    final color = failed
        ? const Color(0xFFB3261E)
        : done
        ? tokens.accentStrong
        : const Color(0xFF895900);
    final label = switch (status) {
      'assigned' => 'Menunggu tanggapan',
      'accepted' => 'Tugas diterima',
      'in_progress' => 'Sedang dikerjakan',
      'completed' => 'Selesai',
      'received' => 'Diterima',
      'curated' => 'Selesai dikurasi',
      'submitted' => 'Perlu ditinjau',
      'scheduled' => 'Terjadwal',
      'needs_revision' => 'Perlu revisi',
      'ready' => 'Siap dikirim',
      'in_transit' => 'Dalam perjalanan',
      'disputed' => 'Perlu tindak lanjut',
      'cancelled' => 'Dibatalkan',
      'declined' => 'Ditolak',
      'failed' => 'Gagal',
      _ => status,
    };
    return Row(
      children: [
        Icon(
          failed
              ? Icons.cancel
              : done
              ? Icons.check_circle
              : Icons.schedule,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}

String taskLabel(String? kind) => switch (kind) {
  'pickup' => 'Penjemputan pakaian',
  'curation' => 'Kurasi pakaian',
  'delivery' => 'Pengantaran kiriman',
  _ => 'Tugas relawan',
};
