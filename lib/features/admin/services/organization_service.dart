import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/page_request.dart';

/// Administrative operations are enforced by existing Admin-only RLS.
class OrganizationService {
  final SupabaseClient client;
  OrganizationService({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;
  Future<List<Map<String, dynamic>>> listOrganizations({
    PageRequest page = const PageRequest(),
  }) async {
    page.validate();
    return await client
        .from('organizations')
        .select()
        .order('name')
        .order('id')
        .range(page.offset, page.end);
  }

  Future<String> saveOrganization({
    String? id,
    required String name,
    required String kind,
    String? area,
    bool verified = false,
    bool active = true,
  }) async {
    final data = {
      'name': name,
      'kind': kind,
      'area': area,
      'verified': verified,
      'active': active,
    };
    final row = id == null
        ? await client.from('organizations').insert(data).select('id').single()
        : await client
              .from('organizations')
              .update(data)
              .eq('id', id)
              .select('id')
              .single();
    return row['id'] as String;
  }

  Future<void> setMembership(
    String organizationId,
    String userId, {
    bool active = true,
  }) async {
    await client.from('organization_members').upsert({
      'organization_id': organizationId,
      'user_id': userId,
      'active': active,
    }, onConflict: 'organization_id,user_id');
  }

  Future<String> savePoint({
    String? id,
    required String organizationId,
    required String name,
    required String publicAddress,
    String? openingHours,
    int? capacityPieces,
    double? latitude,
    double? longitude,
    bool active = true,
  }) async {
    final data = {
      'organization_id': organizationId,
      'name': name,
      'public_address': publicAddress,
      'opening_hours': openingHours,
      'capacity_pieces': capacityPieces,
      'latitude': latitude,
      'longitude': longitude,
      'active': active,
    };
    final row = id == null
        ? await client
              .from('collection_points')
              .insert(data)
              .select('id')
              .single()
        : await client
              .from('collection_points')
              .update(data)
              .eq('id', id)
              .select('id')
              .single();
    return row['id'] as String;
  }

  Future<List<Map<String, dynamic>>> listProfiles({
    PageRequest page = const PageRequest(),
  }) async {
    page.validate();
    return await client
        .from('profiles')
        .select('*,user_roles(role)')
        .order('created_at', ascending: false)
        .order('id')
        .range(page.offset, page.end);
  }

  Future<void> deleteOrganization(String id) async {
    await client
        .from('organizations')
        .delete()
        .eq('id', id)
        .select('id')
        .single();
  }

  Future<void> deletePoint(String id) async {
    await client
        .from('collection_points')
        .delete()
        .eq('id', id)
        .select('id')
        .single();
  }
}
