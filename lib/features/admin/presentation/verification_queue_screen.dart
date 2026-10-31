import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../mitra/models/mitra_application.dart';
import 'verification_detail_screen.dart';

enum _QueueFilter { pending, approved, rejected, all }

class VerificationQueueScreen extends StatelessWidget {
  const VerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PkScaffold(
      appBar: const PkAppBar(title: 'Verifikasi mitra', showBack: true),
      child: const VerificationQueueView(showTitle: false),
    );
  }
}

class VerificationQueueView extends StatefulWidget {
  const VerificationQueueView({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  State<VerificationQueueView> createState() => _VerificationQueueViewState();
}

class _VerificationQueueViewState extends State<VerificationQueueView> {
  final _search = TextEditingController();
  _QueueFilter _filter = _QueueFilter.pending;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openDetail(MitraApplication application) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            VerificationDetailScreen(applicationId: application.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final all = controller.repository.applications;
    final pendingCount = all.where((app) => app.status.isPending).length;
    final approvedCount = all.where((app) => app.status.isApproved).length;
    final rejectedCount = all.where((app) => app.status.isRejected).length;
    final query = _search.text.trim().toLowerCase();

    final filtered = all.where((application) {
      final matchesFilter = switch (_filter) {
        _QueueFilter.pending => application.status.isPending,
        _QueueFilter.approved => application.status.isApproved,
        _QueueFilter.rejected => application.status.isRejected,
        _QueueFilter.all => true,
      };
      final matchesQuery = query.isEmpty ||
          application.organizationName.toLowerCase().contains(query) ||
          application.applicantName.toLowerCase().contains(query) ||
          application.area.toLowerCase().contains(query) ||
          application.applicantEmail.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        if (widget.showTitle) ...[
          Text('Operasional', style: theme.textTheme.displaySmall),
          const SizedBox(height: 3),
          Text(
            'Tinjau legalitas calon mitra sebelum memberi akses lembaga.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
        ],
        if (pendingCount > 0 && _filter != _QueueFilter.pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PkBanner(
              tone: PkBannerTone.warning,
              label: '$pendingCount pengajuan menunggu',
              message:
                  'Buka filter Menunggu untuk memeriksa dokumen yang belum diputuskan.',
              action: TextButton(
                onPressed: () =>
                    setState(() => _filter = _QueueFilter.pending),
                child: const Text('Lihat yang menunggu'),
              ),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Menunggu',
                count: pendingCount,
                selected: _filter == _QueueFilter.pending,
                onTap: () =>
                    setState(() => _filter = _QueueFilter.pending),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Disetujui',
                count: approvedCount,
                selected: _filter == _QueueFilter.approved,
                onTap: () =>
                    setState(() => _filter = _QueueFilter.approved),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Ditolak',
                count: rejectedCount,
                selected: _filter == _QueueFilter.rejected,
                onTap: () =>
                    setState(() => _filter = _QueueFilter.rejected),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Semua',
                count: all.length,
                selected: _filter == _QueueFilter.all,
                onTap: () => setState(() => _filter = _QueueFilter.all),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PkTextField(
          label: 'Cari pengajuan',
          controller: _search,
          hint: 'Nama lembaga, pemohon, atau wilayah',
          prefixIcon: Icons.search_rounded,
          onChanged: (_) => setState(() {}),
          suffix: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '${filtered.length} pengajuan',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.forest,
              ),
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
        if (filtered.isEmpty)
          PkEmptyState(
            title: _emptyTitle,
            message: _emptyMessage,
            icon: Icons.inbox_outlined,
            action: _filter == _QueueFilter.pending
                ? null
                : TextButton(
                    onPressed: () =>
                        setState(() => _filter = _QueueFilter.pending),
                    child: const Text('Lihat yang menunggu'),
                  ),
          )
        else
          ApplicationList(
            applications: filtered,
            onTap: _openDetail,
          ),
        if (filtered.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Keputusan admin langsung mengubah akses akun pemohon pada data simulasi ini.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ],
    );
  }

  String get _emptyTitle {
    switch (_filter) {
      case _QueueFilter.pending:
        return 'Tidak ada pengajuan menunggu';
      case _QueueFilter.approved:
        return 'Belum ada pengajuan disetujui';
      case _QueueFilter.rejected:
        return 'Belum ada pengajuan ditolak';
      case _QueueFilter.all:
        return 'Belum ada pengajuan';
    }
  }

  String get _emptyMessage {
    switch (_filter) {
      case _QueueFilter.pending:
        return 'Semua pengajuan sudah diputuskan. Antrean baru akan muncul saat akun mengirim pengajuan mitra.';
      case _QueueFilter.approved:
        return 'Pengajuan yang disetujui akan tercatat di sini.';
      case _QueueFilter.rejected:
        return 'Pengajuan yang ditolak akan tercatat di sini bersama alasannya.';
      case _QueueFilter.all:
        return 'Belum ada akun yang mengajukan diri sebagai mitra.';
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.sage : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.line,
            ),
          ),
          child: Text(
            '$label · $count',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.forest : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class ApplicationList extends StatelessWidget {
  const ApplicationList({
    super.key,
    required this.applications,
    required this.onTap,
  });

  final List<MitraApplication> applications;
  final ValueChanged<MitraApplication> onTap;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < applications.length; i++) ...[
            if (i > 0) const Divider(indent: 14, endIndent: 14),
            ApplicationRow(
              application: applications[i],
              onTap: () => onTap(applications[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class ApplicationRow extends StatelessWidget {
  const ApplicationRow({
    super.key,
    required this.application,
    required this.onTap,
  });

  final MitraApplication application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = applicationStatusTone(application.status);
    final submitted = application.submittedAt == null
        ? 'Belum dikirim'
        : formatDateShort(application.submittedAt!);
    return Semantics(
      button: true,
      label:
          '${application.organizationName}, ${application.status.label}, diajukan $submitted',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.account_balance_outlined,
                    size: 19,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.organizationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${application.organizationKind} · ${application.area}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            application.applicantName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10.5,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '· $submitted',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PkStatusChip(
                      label: application.status.label,
                      tone: tone,
                    ),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.muted,
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

PkStatusTone applicationStatusTone(MitraApplicationStatus status) {
  switch (status) {
    case MitraApplicationStatus.draft:
      return PkStatusTone.neutral;
    case MitraApplicationStatus.submitted:
    case MitraApplicationStatus.underReview:
      return PkStatusTone.warning;
    case MitraApplicationStatus.approved:
      return PkStatusTone.success;
    case MitraApplicationStatus.rejected:
      return PkStatusTone.danger;
  }
}
