import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/services/supabase_client_provider.dart';

abstract class INeedsService {
  Future<List<Map<String, dynamic>>> listNeeds({
    String? category,
    String? size,
    String? ageGroup,
    String? area,
    bool? emergency,
    int limit = 20,
    int offset = 0,
  });

  Future<Map<String, dynamic>?> getNeedDetail(String needId);

  Future<String> saveNeed({
    String? needId,
    required String organizationId,
    required String pointId,
    required String title,
    required String description,
    required DateTime deadlineAt,
    String? incidentId,
    required List<Map<String, dynamic>> lines,
  });

  Future<void> publishNeed(String needId);

  Future<void> changeNeedStatus({
    required String needId,
    required String status,
    String? reason,
  });

  Future<List<Map<String, dynamic>>> listPoints({String? area});
}

class NeedsService implements INeedsService {
  final SupabaseClient _client;

  NeedsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> listNeeds({
    String? category,
    String? size,
    String? ageGroup,
    String? area,
    bool? emergency,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await _client.rpc('list_needs', params: {
        'p_category': category,
        'p_size': size,
        'p_age_group': ageGroup,
        'p_area': area,
        'p_emergency': emergency,
        'p_limit': limit,
        'p_offset': offset,
      });

      if (res is List) {
        return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<Map<String, dynamic>?> getNeedDetail(String needId) async {
    try {
      final res = await _client.rpc('get_need_detail', params: {
        'p_need_id': needId,
      });
      if (res is Map<String, dynamic>) {
        return res;
      } else if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return null;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<String> saveNeed({
    String? needId,
    required String organizationId,
    required String pointId,
    required String title,
    required String description,
    required DateTime deadlineAt,
    String? incidentId,
    required List<Map<String, dynamic>> lines,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      final res = await _client.rpc('save_need', params: {
        'p_need_id': needId,
        'p_organization_id': organizationId,
        'p_point_id': pointId,
        'p_title': title,
        'p_description': description,
        'p_deadline_at': deadlineAt.toIso8601String(),
        'p_incident_id': incidentId,
        'p_lines': lines,
        'p_request_key': key,
      });
      return res.toString();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> publishNeed(String needId) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc('publish_need', params: {
        'p_need_id': needId,
        'p_request_key': key,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> changeNeedStatus({
    required String needId,
    required String status,
    String? reason,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc('change_need_status', params: {
        'p_need_id': needId,
        'p_status': status,
        'p_reason': reason,
        'p_request_key': key,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listPoints({String? area}) async {
    try {
      final res = await _client.rpc('list_points', params: {
        'p_area': area,
      });
      if (res is List) {
        return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
