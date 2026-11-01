import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

void main() {
  test(
    'real SDK subscription receives only the session notification',
    () async {
      final config = jsonDecode(File('env.json').readAsStringSync()) as Map;
      final fixture = jsonDecode(
        File('${Platform.environment['TEMP']}/pakaiankita-live-member-qa.json')
            .readAsStringSync(),
      ) as Map;
      final client = SupabaseClient(
        config['SUPABASE_URL'] as String,
        config['SUPABASE_ANON_KEY'] as String,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final admin = SupabaseClient(
        config['SUPABASE_URL'] as String,
        config['SUPABASE_ANON_KEY'] as String,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      RealtimeChannel? channel;
      try {
        final user = fixture['users']['donatur'] as Map;
        final manager = fixture['users']['admin'] as Map;
        await client.auth.signInWithPassword(
          email: user['email'] as String,
          password: user['password'] as String,
        );
        await admin.auth.signInWithPassword(
          email: manager['email'] as String,
          password: manager['password'] as String,
        );
        debugPrint('QA: authenticated test sessions');
        final request = const Uuid().v4();
        final marker = 'Realtime QA $request';
        final ready = Completer<void>();
        final received = Completer<void>();
        channel = client
            .channel('qa-notifications-$request')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: user['id'],
              ),
              callback: (payload) {
                expect(payload.newRecord['user_id'], user['id']);
                if (payload.newRecord['body'].toString().contains(marker) &&
                    !received.isCompleted) {
                  received.complete();
                }
              },
            )
            .subscribe((status, error) {
              if (status == RealtimeSubscribeStatus.subscribed &&
                  !ready.isCompleted) {
                ready.complete();
              }
              if (error != null && !ready.isCompleted) {
                ready.completeError(StateError('Realtime subscription failed'));
              }
            });
        await ready.future.timeout(const Duration(seconds: 25));
        debugPrint('QA: realtime subscription joined');
        await client.rpc(
          'apply_volunteer',
          params: {
            'p_id': request,
            'p_message': 'Temporary realtime verification request',
          },
        );
        await admin.rpc(
          'review_registration',
          params: {
            'p_type': 'volunteer',
            'p_id': request,
            'p_approve': false,
            'p_reason': marker,
          },
        );
        debugPrint('QA: registration decision committed');
        await received.future.timeout(const Duration(seconds: 25));
        debugPrint('QA: notification received over realtime');
        final count = await client.rpc('notification_unread_count');
        expect((count as num).toInt(), greaterThan(0));
      } finally {
        if (channel != null) await client.removeChannel(channel);
        await client.dispose();
        await admin.dispose();
      }
    },
    skip: !const bool.fromEnvironment('LIVE_REALTIME_TEST'),
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
