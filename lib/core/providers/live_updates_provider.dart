import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';
import '../data/rows_pager.dart';
import '../../features/operations/application/operations_providers.dart';
import '../../features/home/application/home_providers.dart';
import '../../features/donation/application/donation_providers.dart';
import '../../features/campaign/data/program_repository.dart';
import '../../features/profile/application/profile_providers.dart';
import '../../features/notifications/notification_center.dart';

/// One subscription per session. No FCM and no background push delivery.
final liveUpdatesProvider = Provider<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid =
      ref.watch(authUserProvider.select((s) => s.value?.id)) ??
      client?.auth.currentUser?.id;
  if (client == null || uid == null) return;
  var disposed = false;
  Timer? debounce;
  final changed = <String>{};
  void refresh({bool all = false}) {
    if (disposed) return;
    if (all || changed.contains('notifications')) {
      ref.invalidate(unreadNotificationsProvider);
      ref.invalidate(rowsPagerProvider('notifications'));
    }
    if (all || changed.any((t) => t != 'notifications')) {
      ref.invalidate(operationsDataProvider);
      ref.invalidate(rowsPagerProvider);
      ref.invalidate(homeSnapshotProvider);
      ref.invalidate(campaignProvider);
      ref.invalidate(donationsProvider);
      ref.invalidate(managedProgramsProvider);
      ref.invalidate(managedProgramProvider);
    }
    if (all ||
        changed.any(
          (t) => [
            'user_roles',
            'organization_members',
            'organizations',
            'role_requests',
            'organization_applications',
          ].contains(t),
        )) {
      ref.invalidate(operationsAccessProvider);
    }
    if (all || changed.contains('profiles')) {
      ref.invalidate(profileDataProvider);
    }
    changed.clear();
  }

  void schedule(String table) {
    if (disposed) return;
    changed.add(table);
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), refresh);
  }

  final lifecycle = _ForegroundObserver(() => refresh(all: true));
  WidgetsBinding.instance.addObserver(lifecycle);
  final channel = client.channel('pk-live-$uid');
  for (final table in [
    'notifications',
    'role_requests',
    'organization_applications',
    'donations',
    'donation_events',
    'logistics_tasks',
    'shipments',
    'needs',
    'inventory_batches',
    'user_roles',
    'organization_members',
    'collection_points',
    'profiles',
    'organizations',
  ]) {
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      callback: (_) => schedule(table),
    );
  }
  channel.subscribe((status, error) {
    if (!disposed && status == RealtimeSubscribeStatus.subscribed) {
      schedule('reconnected');
    }
  });
  // Recover missed events after a reconnect; RLS still scopes each fresh query.
  final fallback = Timer.periodic(const Duration(seconds: 60), (_) {
    if (lifecycle.foreground) refresh(all: true);
  });
  ref.onDispose(() {
    disposed = true;
    debounce?.cancel();
    fallback.cancel();
    WidgetsBinding.instance.removeObserver(lifecycle);
    unawaited(client.removeChannel(channel));
  });
});

class _ForegroundObserver extends WidgetsBindingObserver {
  _ForegroundObserver(this.refresh);
  final VoidCallback refresh;
  bool foreground = true;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground) refresh();
  }
}
