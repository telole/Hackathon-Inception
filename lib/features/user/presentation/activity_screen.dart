import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../donations/models/donation.dart';
import '../../mitra/models/mitra_application.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final current = controller.context;
    if (current == null) return const SizedBox.shrink();

    final events = <_ActivityEvent>[];
    for (final donation in controller.repository.donationsFor(current.userId)) {
      events.add(
        _ActivityEvent(
          at: donation.createdAt,
          title: 'Donasi diajukan',
          description:
              '${donation.needTitle} untuk ${donation.organizationName}',
          icon: Icons.volunteer_activism_outlined,
          color: AppColors.forest,
          background: AppColors.sage,
        ),
      );
      if (donation.status != DonationStatus.submitted) {
        events.add(
          _ActivityEvent(
            at: donation.scheduledAt,
            title: donation.status.label,
            description: donation.itemSummary,
            icon: _iconFor(donation.status),
            color: donation.status == DonationStatus.received
                ? AppColors.forest
                : AppColors.ink,
            background: donation.status == DonationStatus.received
                ? AppColors.sage
                : AppColors.parchment,
          ),
        );
      }
    }

    final application = current.mitraApplication;
    if (application != null) {
      if (application.submittedAt != null) {
        events.add(
          _ActivityEvent(
            at: application.submittedAt!,
            title: 'Pengajuan mitra dikirim',
            description: application.organizationName,
            icon: Icons.assignment_turned_in_outlined,
            color: const Color(0xFF7A5A1F),
            background: AppColors.parchment,
          ),
        );
      }
      if (application.reviewedAt != null) {
        final rejected =
            application.status == MitraApplicationStatus.rejected;
        events.add(
          _ActivityEvent(
            at: application.reviewedAt!,
            title: rejected
                ? 'Pengajuan mitra perlu diperbaiki'
                : 'Pengajuan mitra disetujui',
            description: rejected
                ? (application.reviewNote ??
                    'Buka status pengajuan untuk melihat catatan admin.')
                : '${application.organizationName} sekarang bisa mengelola kebutuhan.',
            icon: rejected
                ? Icons.error_outline_rounded
                : Icons.verified_outlined,
            color: rejected ? AppColors.clay : AppColors.forest,
            background: rejected ? AppColors.alertSurface : AppColors.sage,
          ),
        );
      }
    }

    events.sort((a, b) => b.at.compareTo(a.at));
    final groups = <String, List<_ActivityEvent>>{};
    for (final event in events) {
      groups.putIfAbsent(relativeDay(event.at), () => []).add(event);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Aktivitas', style: theme.textTheme.displaySmall),
        const SizedBox(height: 3),
        Text(
          'Riwayat donasi dan pengajuan akunmu.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        if (events.isEmpty)
          PkEmptyState(
            title: 'Belum ada aktivitas',
            message:
                'Setelah kamu mencatat donasi atau mengajukan mitra, perjalanannya akan muncul di sini.',
            icon: Icons.timeline_outlined,
          )
        else
          for (final entry in groups.entries) ...[
            Text(
              entry.key.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            PkCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    if (i > 0) const Divider(),
                    _ActivityRow(event: entry.value[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
        if (events.isNotEmpty)
          Text(
            'Data simulasi. Waktu mengikuti data demo di perangkat ini.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
      ],
    );
  }

  IconData _iconFor(DonationStatus status) {
    switch (status) {
      case DonationStatus.submitted:
        return Icons.schedule_rounded;
      case DonationStatus.curated:
        return Icons.fact_check_outlined;
      case DonationStatus.shipped:
        return Icons.local_shipping_outlined;
      case DonationStatus.received:
        return Icons.check_circle_outline_rounded;
    }
  }
}

class _ActivityEvent {
  const _ActivityEvent({
    required this.at,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
  });

  final DateTime at;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final _ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: event.background,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(event.icon, size: 19, color: event.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatTime(event.at),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  event.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
