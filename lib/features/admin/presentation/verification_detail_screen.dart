import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../mitra/models/mitra_application.dart';
import 'verification_queue_screen.dart';

class VerificationDetailScreen extends StatefulWidget {
  const VerificationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  State<VerificationDetailScreen> createState() =>
      _VerificationDetailScreenState();
}

class _VerificationDetailScreenState extends State<VerificationDetailScreen> {
  bool _busy = false;
  String? _actionError;

  Future<void> _approve(MitraApplication application) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Setujui ${application.organizationName}?'),
        content: Text(
          'Akun ${application.applicantName} akan mendapat akses mitra untuk organisasi ini. '
          'Lembaga ditandai terverifikasi dan kebutuhan yang sudah dibuat akan tampil ke donatur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Setujui pengajuan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final controller = AppScope.read(context);
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await controller.approveApplication(application.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${application.organizationName} disetujui. Akses mitra aktif untuk akun pemohon.',
          ),
        ),
      );
    } on AppException catch (error) {
      if (mounted) setState(() => _actionError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionError = 'Pengajuan belum bisa disetujui. Coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(MitraApplication application) async {
    if (_busy) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectDialog(organizationName: application.organizationName),
    );
    if (reason == null || !mounted) return;

    final controller = AppScope.read(context);
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await controller.rejectApplication(application.id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan dikembalikan ke pemohon dengan catatan.'),
        ),
      );
    } on AppException catch (error) {
      if (mounted) setState(() => _actionError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionError = 'Pengajuan belum bisa ditolak. Coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final current = controller.context;
    final application = controller.repository.applications
        .where((item) => item.id == widget.applicationId)
        .firstOrNull;

    if (application == null) {
      return PkScaffold(
        appBar: const PkAppBar(title: 'Detail pengajuan', showBack: true),
        child: const PkPage(
          children: [
            SizedBox(height: 40),
            PkEmptyState(
              title: 'Pengajuan tidak ditemukan',
              message:
                  'Data mungkin sudah direset atau pengajuan ini tidak tersedia lagi.',
              icon: Icons.search_off_rounded,
            ),
          ],
        ),
      );
    }

    final pending = application.status.isPending;
    final ownApplication =
        current != null && application.userId == current.userId;

    return PkScaffold(
      appBar: const PkAppBar(title: 'Detail pengajuan', showBack: true),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Row(
                  children: [
                    PkStatusChip(
                      label: application.status.label,
                      tone: applicationStatusTone(application.status),
                    ),
                    const Spacer(),
                    Text(
                      'DATA SIMULASI',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  application.organizationName,
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${application.organizationKind} · ${application.area}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (_actionError != null) ...[
                  PkBanner(
                    tone: PkBannerTone.error,
                    label: 'Aksi belum berhasil',
                    message: _actionError!,
                  ),
                  const SizedBox(height: 14),
                ],
                if (ownApplication) ...[
                  const PkBanner(
                    tone: PkBannerTone.warning,
                    label: 'Pengajuan sendiri',
                    message:
                        'Admin tidak dapat menyetujui atau menolak pengajuannya sendiri. Minta admin lain meninjaunya.',
                  ),
                  const SizedBox(height: 14),
                ],
                if (!pending) ...[
                  PkBanner(
                    tone: application.status.isApproved
                        ? PkBannerTone.success
                        : PkBannerTone.error,
                    label: application.status.isApproved
                        ? 'Disetujui'
                        : 'Ditolak',
                    message: application.status.isApproved
                        ? 'Akses mitra aktif${application.reviewedAt == null ? '' : ' sejak ${formatDateTime(application.reviewedAt!)}'}. Kebutuhan lembaga ini sudah tampil ke donatur.'
                        : (application.reviewNote ??
                            'Pengajuan dikembalikan ke pemohon.'),
                  ),
                  const SizedBox(height: 14),
                ],
                _Section(
                  title: 'Identitas pemohon',
                  children: [
                    PkKeyValue(
                      label: 'Nama',
                      value: application.applicantName,
                    ),
                    PkKeyValue(
                      label: 'Email',
                      value: application.applicantEmail,
                    ),
                    PkKeyValue(
                      label: 'Penanggung jawab',
                      value: application.contactName,
                    ),
                    PkKeyValue(
                      label: 'WhatsApp',
                      value: application.contactPhone,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Data lembaga',
                  children: [
                    PkKeyValue(
                      label: 'Jenis',
                      value: application.organizationKind,
                    ),
                    PkKeyValue(
                      label: 'Wilayah',
                      value: application.area,
                    ),
                    PkKeyValue(
                      label: 'Titik kumpul',
                      value: application.pointAddress,
                    ),
                    PkKeyValue(
                      label: 'Penerima',
                      value: application.beneficiaryEstimate == null
                          ? 'Tidak diisi'
                          : '± ${application.beneficiaryEstimate} orang',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Legalitas',
                  children: [
                    PkKeyValue(
                      label: 'Nomor dokumen',
                      value: application.legalNumber,
                    ),
                    PkKeyValue(
                      label: 'Instansi',
                      value: application.legalIssuer,
                    ),
                    PkKeyValue(
                      label: 'Tanggal',
                      value: application.legalIssuedAt == null
                          ? 'Tidak diisi'
                          : formatDate(application.legalIssuedAt!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Dokumen legalitas',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Hanya admin yang dapat melihat bagian ini.',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                ),
                const SizedBox(height: 10),
                if (application.documents.isEmpty)
                  const PkBanner(
                    tone: PkBannerTone.warning,
                    label: 'Dokumen kosong',
                    message:
                        'Pemohon belum melampirkan dokumen. Jangan disetujui sebelum dokumen diterima.',
                  )
                else
                  PkCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0;
                            i < application.documents.length;
                            i++) ...[
                          if (i > 0)
                            const Divider(indent: 14, endIndent: 14),
                          _DocumentRow(
                            document: application.documents[i],
                            onPreview: () => _previewDocument(
                              context,
                              application.documents[i],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (pending)
                  const PkBanner(
                    message:
                        'Periksa kecocokan nama lembaga, nomor dokumen, dan instansi penerbit sebelum memutuskan.',
                  ),
                const SizedBox(height: 6),
                Text(
                  'Diajukan ${application.submittedAt == null ? 'belum dikirim' : formatDateTime(application.submittedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (pending && !ownApplication)
            _ActionBar(
              busy: _busy,
              onApprove: () => _approve(application),
              onReject: () => _reject(application),
            ),
        ],
      ),
    );
  }

  void _previewDocument(BuildContext context, MitraDocument document) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pratinjau dokumen',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Admin',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DocumentPreview(document: document),
              const SizedBox(height: 14),
              Text(document.name, style: theme.textTheme.titleSmall),
              const SizedBox(height: 3),
              Text(
                '${formatBytes(document.sizeBytes)} · ${document.mimeType}${document.isSample ? ' · dokumen contoh' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
              ),
              const SizedBox(height: 12),
              const PkBanner(
                tone: PkBannerTone.simulation,
                label: 'Mode simulasi',
                message:
                    'Berkas asli tidak disimpan. Pratinjau ini hanya memperlihatkan bentuk pemeriksaan dokumen di mode demo.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        PkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document, required this.onPreview});

  final MitraDocument document;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = document.isImage
        ? Icons.image_outlined
        : document.isPdf
            ? Icons.picture_as_pdf_outlined
            : Icons.description_outlined;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.sage,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 19, color: AppColors.forest),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatBytes(document.sizeBytes)}${document.isSample ? ' · contoh' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onPreview,
            child: const Text('Lihat'),
          ),
        ],
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.document});

  final MitraDocument document;

  @override
  Widget build(BuildContext context) {
    final bytes = document.bytes;
    if (document.isImage && bytes != null) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7DDC8)),
        ),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            width: 210,
            height: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 4,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                for (final width in [double.infinity, 150.0, 180.0, 120.0])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: width == double.infinity ? 1 : null,
                      child: Container(
                        height: 3.5,
                        width: width == double.infinity ? null : width,
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.claySoft,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'PK',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.claySoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('verification-reject'),
              onPressed: busy ? null : onReject,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Tolak'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.clay,
                side: const BorderSide(color: Color(0xFFE8C7BE)),
                minimumSize: const Size(0, 52),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PkButton(
              key: const Key('verification-approve'),
              label: 'Setujui',
              icon: Icons.check_rounded,
              busy: busy,
              onPressed: onApprove,
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.organizationName});

  final String organizationName;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason.text.trim();
    if (reason.length < 10) {
      setState(() => _error = 'Alasan minimal 10 karakter.');
      return;
    }
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Tolak ${widget.organizationName}?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pemohon akan melihat alasan ini dan bisa memperbaiki pengajuan. Tuliskan bagian dokumen yang perlu diperjelas.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            PkTextField(
              label: 'Alasan penolakan',
              controller: _reason,
              hint: 'Contoh: nomor akta tidak terbaca pada hasil pindai',
              maxLines: 4,
              errorText: _error,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Minimal 10 karakter.',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _submit,
          style: TextButton.styleFrom(foregroundColor: AppColors.clay),
          child: const Text('Tolak pengajuan'),
        ),
      ],
    );
  }
}
