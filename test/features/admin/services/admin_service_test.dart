import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/core/models/app_role.dart';
import 'package:resandang/features/admin/services/admin_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final Future<T> _future;
  FakePostgrestFilterBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }
}

void main() {
  late MockSupabaseClient mockSupabase;
  late AdminService adminService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    adminService = AdminService(client: mockSupabase);
  });

  group('AdminService', () {
    test('setRole calls admin_set_role RPC with correct params', () async {
      const targetUserId = 'user-uuid-1';
      final builder = FakePostgrestFilterBuilder<dynamic>(Future.value(null));
      when(
        () => mockSupabase.rpc(
          'admin_set_role',
          params: {
            'p_user': targetUserId,
            'p_role': 'relawan',
            'p_grant': true,
          },
        ),
      ).thenAnswer((_) => builder);

      await adminService.setRole(
        userId: targetUserId,
        role: AppRole.relawan,
        grant: true,
      );

      verify(
        () => mockSupabase.rpc(
          'admin_set_role',
          params: {
            'p_user': targetUserId,
            'p_role': 'relawan',
            'p_grant': true,
          },
        ),
      ).called(1);
    });

    test('markNotificationRead calls mark_notification_read RPC with correct p_id', () async {
      const notificationId = 'notif-uuid-1';
      final builder = FakePostgrestFilterBuilder<dynamic>(Future.value(null));
      when(
        () => mockSupabase.rpc(
          'mark_notification_read',
          params: {'p_id': notificationId},
        ),
      ).thenAnswer((_) => builder);

      await adminService.markNotificationRead(notificationId);

      verify(
        () => mockSupabase.rpc(
          'mark_notification_read',
          params: {'p_id': notificationId},
        ),
      ).called(1);
    });
  });
}
