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
    for (final item in res) {
      final need = Need.fromJson(item);
      if (need.status == 'open') {
        if (category != null &&
            !need.items.any((i) => i.category.toLowerCase() == category.toLowerCase())) {
          continue;
        }
        if (ageGroup != null &&
            !need.items.any((i) => i.ageGroup.toLowerCase() == ageGroup.toLowerCase())) {
          continue;
        }
        if (sizeCode != null &&
            !need.items.any((i) => i.sizeCode.toLowerCase() == sizeCode.toLowerCase())) {
          continue;
        }
        needs.add(need);
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

    final res = await _client.from('needs').select(query);
    for (final item in res) {
      if (item['id'] == id) {
        return Need.fromJson(item);
      }
    }
    return null;
  }
}
