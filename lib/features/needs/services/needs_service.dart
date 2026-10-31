import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/need.dart';

abstract class INeedsService {
  Future<List<Need>> fetchOpenNeeds({
    String? category,
    String? ageGroup,
    String? sizeCode,
  });
  Future<Need?> fetchNeedById(String id);
}

class NeedsService implements INeedsService {
  final SupabaseClient _client;

  NeedsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<Need>> fetchOpenNeeds({
    String? category,
    String? ageGroup,
    String? sizeCode,
  }) async {
    const query = '''
      id, organization_id, point_id, incident_id, title, description, deadline_at, status, created_at,
      organizations(name),
      collection_points(name),
      need_items(id, need_id, category, size_code, age_group, requested_qty)
    ''';

    final res = await _client.from('needs').select(query);
    final List<Need> needs = [];
    final now = DateTime.now();
    for (final item in res) {
      final need = Need.fromJson(item);
      if (need.status == 'open' && need.deadlineAt.isAfter(now)) {
        final matches = need.items.any((item) {
          if (category != null &&
              item.category.toLowerCase() != category.toLowerCase()) {
            return false;
          }
          if (ageGroup != null &&
              item.ageGroup.toLowerCase() != ageGroup.toLowerCase()) {
            return false;
          }
          if (sizeCode != null &&
              item.sizeCode.toLowerCase() != sizeCode.toLowerCase()) {
            return false;
          }
          return true;
        });

        if (matches) {
          needs.add(need);
        }
      }
    }
    return needs;
  }

  @override
  Future<Need?> fetchNeedById(String id) async {
    const query = '''
      id, organization_id, point_id, incident_id, title, description, deadline_at, status, created_at,
      organizations(name),
      collection_points(name),
      need_items(id, need_id, category, size_code, age_group, requested_qty)
    ''';

    final res = await _client
        .from('needs')
        .select(query)
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return Need.fromJson(res);
  }
}
