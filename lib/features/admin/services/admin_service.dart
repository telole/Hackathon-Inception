import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/models/app_role.dart';
import '../../../core/services/supabase_client_provider.dart';

abstract class IAdminService {
  Future<void> setRole({
    required String userId,
    required AppRole role,
    required bool grant,
  });

  Future<void> markNotificationRead(String notificationId);

  Future<void> approveVerification({
    required String targetType,
    required String targetId,
    required String decision,
    String? reason,
  });

  Future<void> activateIncident({
    required String incidentId,
    String? reason,
  });

  Future<void> closeIncident({
    required String incidentId,
    String? reason,
  });

  Future<void> resolveDispute({
    required String disputeId,
    required int acceptedLateQty,
    required int releasedNeedQty,
    required String reason,
  });

  Future<Map<String, dynamic>?> getMyImpact();

  Future<List<Map<String, dynamic>>> fetchNotifications();
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
    try {
      await _client.rpc('admin_set_role', params: {
        'p_user': userId,
        'p_role': role.name,
        'p_grant': grant,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _client.rpc('mark_notification_read', params: {
        'p_id': notificationId,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> approveVerification({
    required String targetType,
    required String targetId,
    required String decision,
    String? reason,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc('approve_verification', params: {
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_decision': decision,
        'p_reason': reason,
        'p_request_key': key,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> activateIncident({
    required String incidentId,
    String? reason,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc('activate_incident', params: {
        'p_incident_id': incidentId,
        'p_reason': reason,
        'p_request_key': key,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> closeIncident({
    required String incidentId,
    String? reason,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc('close_incident', params: {
        'p_incident_id': incidentId,
        'p_reason': reason,
        'p_request_key': key,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> resolveDispute({
    required String disputeId,
    required int acceptedLateQty,
    required int releasedNeedQty,
    required String reason,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc('resolve_dispute', params: {
        'p_dispute_id': disputeId,
        'p_accepted_late_qty': acceptedLateQty,
        'p_released_need_qty': releasedNeedQty,
        'p_reason': reason,
        'p_request_key': key,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<Map<String, dynamic>?> getMyImpact() async {
    try {
      final res = await _client.rpc('get_my_impact');
      if (res is Map<String, dynamic>) return res;
      if (res is Map) return Map<String, dynamic>.from(res);
      return null;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final res = await _client
          .from('notifications')
          .select('id, title, body, read_at, created_at')
          .order('created_at', ascending: false)
          .limit(50);

      return (res as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
