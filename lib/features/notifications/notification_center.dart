import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/supabase_client_provider.dart';
import '../../core/data/rows_pager.dart';
import '../../core/widgets/paged_rows_list.dart';
import '../../core/widgets/pk_card.dart';
import '../operations/presentation/operations_widgets.dart';
import '../operations/presentation/workflow_screens.dart';

final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  ref.watch(authUserProvider.select((s) => s.value?.id));
  final client = ref.watch(supabaseClientProvider);
  if (client?.auth.currentUser == null) return 0;
  return ((await client!.rpc('notification_unread_count')) as num).toInt();
});
String? safeNotificationRoute(String? route) {
  if (route == null || !route.startsWith('/') || route.startsWith('//')) {
    return null;
  }
  final uri = Uri.tryParse(route);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (uri.path == '/join' ||
      uri.path == '/tracking' ||
      uri.path.startsWith('/operations/tasks/') ||
      uri.path.startsWith('/operations/shipments/') ||
      uri.path.startsWith('/operations/registrations/')) {
    return route;
  }
  return null;
}

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationsProvider).value ?? 0;
    return IconButton(
      tooltip: 'Notifikasi',
      onPressed: () => context.push('/notifications'),
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        child: const Icon(Icons.notifications_none_outlined),
      ),
    );
  }
}

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});
  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  bool _busy = false;
  Future<void> _readAll() async {
    if (_busy) return;
    final client = ref.read(supabaseClientProvider);
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;
    setState(() => _busy = true);
    try {
      await client
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', uid)
          .isFilter('read_at', null);
      ref.invalidate(unreadNotificationsProvider);
      ref.invalidate(rowsPagerProvider('notifications'));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifikasi belum dapat diperbarui.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Map<String, dynamic> row) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    try {
      if (row['read_at'] == null) {
        await client.rpc('mark_notification_read', params: {'p_id': row['id']});
        ref.invalidate(unreadNotificationsProvider);
        ref.invalidate(rowsPagerProvider('notifications'));
      }
      final route = safeNotificationRoute(row['route'] as String?);
      if (mounted && route != null) context.push(route);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi belum dapat dibuka. Coba lagi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifikasi'),
      actions: [
        IconButton(
          tooltip: 'Tandai semua dibaca',
          onPressed: _busy ? null : _readAll,
          icon: const Icon(Icons.done_all),
        ),
      ],
    ),
    body: PagedRowsList(
      resource: 'notifications',
      emptyMessage: 'Belum ada kabar baru. Perubahan donasi dan tugas akan muncul di sini.',
      itemBuilder: (row) => PkCard(
        onTap: () => _open(row),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              row['read_at'] == null ? Icons.circle : Icons.notifications_none,
              size: row['read_at'] == null ? 12 : 22,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(row['body'] as String),
                  const SizedBox(height: 8),
                  Text(
                    workflowDate(row['created_at']),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Semua donasi saya')),
    body: PagedRowsList(
      resource: 'myDonations',
      emptyMessage: 'Belum ada donasi.',
      itemBuilder: (row) => PkCard(
        onTap: () => context.go('/tracking?donation=${row['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row['tracking_code'] as String,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            OperationStatus(row['status'] as String),
            const SizedBox(height: 8),
            Text(workflowDate(row['created_at'])),
          ],
        ),
      ),
    ),
  );
}
