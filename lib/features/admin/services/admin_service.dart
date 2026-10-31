import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/app_role.dart';

abstract class IAdminService {
  Future<void> setRole({
    required String userId,
    required AppRole role,
    required bool grant,
  });
  Future<void> markNotificationRead(String notificationId);
}

class AdminService implements IAdminService {
  final SupabaseClient _client;

  AdminService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> setRole({
    required String userId,
    required AppRole role,
    required bool grant,
  }) async {
    await _client.rpc(
      'admin_set_role',
      params: {
        'p_user': userId,
        'p_role': role.name,
        'p_grant': grant,
      },
    );
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    await _client.rpc(
      'mark_notification_read',
      params: {'p_id': notificationId},
    );
  }
}
