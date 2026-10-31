import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../needs/models/need.dart';

enum _ProgramFilter { open, fulfilled, all }

class AdminProgramsScreen extends StatefulWidget {
  const AdminProgramsScreen({super.key});

  @override
  State<AdminProgramsScreen> createState() => _AdminProgramsScreenState();
}

class _AdminProgramsScreenState extends State<AdminProgramsScreen> {
  _ProgramFilter _filter = _ProgramFilter.open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final all = controller.repository.allNeeds;
    final openCount = all.where((need) => need.isOpen).length;
    final fulfilledCount = all.where((need) => !need.isOpen).length;
    final filtered = all.where((need) {
      switch (_filter) {
        case _ProgramFilter.open:
          return need.isOpen;
        case _ProgramFilter.fulfilled:
          return !need.isOpen;
        case _ProgramFilter.all:
          return true;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Program', style: theme.textTheme.displaySmall),
        const SizedBox(height: 3),
        Text(
          'Semua kebutuhan, termasuk yang belum tampil ke donatur.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'Terbuka · $openCount',
              selected: _filter == _ProgramFilter.open,
              onTap: () => setState(() => _filter = _ProgramFilter.open),
            ),
            _FilterChip(
              label: 'Tertutup · $fulfilledCount',
              selected: _filter == _ProgramFilter.fulfilled,
              onTap: () => setState(() => _filter = _ProgramFilter.fulfilled),
            ),
            _FilterChip(
              label: 'Semua · ${all.length}',
              selected: _filter == _ProgramFilter.all,
              onTap: () => setState(() => _filter = _ProgramFilter.all),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          PkEmptyState(
            title: 'Belum ada program',
            message: _filter == _ProgramFilter.open
                ? 'Tidak ada kebutuhan terbuka saat ini. Program baru muncul setelah mitra terverifikasi menerbitkannya.'
                : 'Belum ada kebutuhan pada filter ini.',
            icon: Icons.menu_book_outlined,
            action: _filter == _ProgramFilter.all
                ? null
                : TextButton(
                    onPressed: () =>
                        setState(() => _filter = _ProgramFilter.all),
                    child: const Text('Lihat semua program'),
                  ),
          )
        else
          for (final need in filtered) ...[
            _ProgramCard(
              need: need,
              onTap: () => _showDetail(context, need),
            ),
            const SizedBox(height: 10),
          ],
        if (filtered.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Program dari organisasi yang belum terverifikasi tetap tersembunyi dari beranda donatur.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ],
    );
  }

  void _showDetail(BuildContext context, Need need) {
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
                  PkStatusChip(
                    label: need.isOpen ? 'Terbuka' : need.status.label,
                    tone: need.isOpen
                        ? PkStatusTone.success
                        : PkStatusTone.neutral,
                  ),
                  const Spacer(),
                  PkStatusChip(
                    label: need.organizationVerified
                        ? 'Mitra terverifikasi'
                        : 'Belum terverifikasi',
                    tone: need.organizationVerified
                        ? PkStatusTone.success
                        : PkStatusTone.warning,
                    icon: need.organizationVerified
                        ? Icons.verified_outlined
                        : Icons.error_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(need.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(need.organizationName, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Text(
                need.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              PkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < need.items.length; i++) ...[
                      if (i > 0) const Divider(height: 18),
                      Text(
                        need.items[i].summary,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${need.items[i].receivedQty} terkumpul dari ${need.items[i].requestedQty} diminta',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    PkProgressBar(value: need.progress),
                    const SizedBox(height: 12),
                    PkKeyValue(
                      label: 'Tenggat',
                      value: formatDate(need.deadline),
                    ),
                    PkKeyValue(
                      label: 'Titik kumpul',
                      value: '${need.pointName}\n${need.pointAddress}',
                    ),
                    PkKeyValue(
                      label: 'Kota',
                      value: need.city,
                    ),
                    PkKeyValue(
                      label: 'Visibilitas',
                      value: need.organizationVerified
                          ? 'Tampil di beranda donatur'
                          : 'Tersembunyi dari donatur',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
            label,
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

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.need, required this.onTap});

  final Need need;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PkCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  need.organizationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PkStatusChip(
                label: need.organizationVerified
                    ? 'Terverifikasi'
                    : 'Belum terverifikasi',
                tone: need.organizationVerified
                    ? PkStatusTone.success
                    : PkStatusTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  need.title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              PkStatusChip(
                label: need.isOpen ? 'Terbuka' : need.status.label,
                tone: need.isOpen
                    ? PkStatusTone.info
                    : PkStatusTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${need.city} · ${deadlineLabel(need.deadline)}',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terkumpul ${need.receivedQty} dari ${need.requestedQty}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(
                'Sisa ${need.remainingQty}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: need.isOpen ? AppColors.forest : AppColors.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          PkProgressBar(
            value: need.progress,
            tone: need.isOpen ? AppColors.forest : AppColors.muted,
          ),
        ],
      ),
    );
  }
}
