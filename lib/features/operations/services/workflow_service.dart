import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/page_request.dart';
import '../../collection_points/models/collection_point.dart';
import '../../donation/models/donation.dart';
import '../../logistics/models/logistics_task.dart';
import '../../needs/models/need.dart';

/// Core write workflows. Database RPCs authorize ownership and commit atomically.
/// Use with the signed-in user's client; never embed service_role credentials.
class WorkflowService {
  final SupabaseClient client;
  WorkflowService({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  Future<String> saveNeed({
    String? id,
    required String organizationId,
    required String pointId,
    required String title,
    String? description,
    required DateTime deadline,
    String? incidentId,
    required List<NeedItem> items,
  }) async {
    final result = await client.rpc(
      'save_need',
      params: {
        'p_id': id,
        'p_org': organizationId,
        'p_point': pointId,
        'p_title': title,
        'p_description': description,
        'p_deadline': deadline.toUtc().toIso8601String(),
        'p_incident': incidentId,
        'p_items': items
            .map(
              (i) => {
                'id': i.id.isEmpty ? null : i.id,
                'category': i.category,
                'size_code': i.sizeCode,
                'age_group': i.ageGroup,
                'requested_qty': i.requestedQty,
              },
            )
            .toList(),
      },
    );
    return result as String;
  }

  Future<void> setNeedStatus(String id, String status) async {
    await client.rpc(
      'set_need_status',
      params: {'p_id': id, 'p_status': status},
    );
  }

  Future<void> deleteNeed(String id) async {
    await client.rpc('delete_need', params: {'p_id': id});
  }

  Future<void> scheduleDonation(String id, DateTime at) async {
    await client.rpc(
      'schedule_donation',
      params: {'p_id': id, 'p_at': at.toUtc().toIso8601String()},
    );
  }

  Future<String> assignTask({
    String? id,
    required String donationId,
    required String pointId,
    required String volunteerId,
    required String kind,
    DateTime? scheduledAt,
    String? notes,
  }) async {
    final result = await client.rpc(
      'assign_logistics_task',
      params: {
        'p_id': id,
        'p_donation': donationId,
        'p_point': pointId,
        'p_volunteer': volunteerId,
        'p_kind': kind,
        'p_at': scheduledAt?.toUtc().toIso8601String(),
        'p_notes': notes,
      },
    );
    return result as String;
  }

  Future<List<Donation>> listPointDonations(
    String pointId, {
    PageRequest page = const PageRequest(),
  }) async {
    page.validate();
    final rows = await client
        .from('donations')
        .select('*,donation_items(*),donation_photos(*)')
        .eq('point_id', pointId)
        .order('created_at', ascending: false)
        .order('id')
        .range(page.offset, page.end);
    return rows.map(Donation.fromJson).toList();
  }

  Future<List<LogisticsTask>> listPointTasks(
    String pointId, {
    PageRequest page = const PageRequest(),
  }) async {
    page.validate();
    final rows = await client
        .from('logistics_tasks')
        .select()
        .eq('point_id', pointId)
        .order('created_at', ascending: false)
        .order('id')
        .range(page.offset, page.end);
    return rows.map(LogisticsTask.fromJson).toList();
  }

  Future<List<Need>> listManagedNeeds(
    String organizationId, {
    PageRequest page = const PageRequest(),
  }) async {
    page.validate();
    final rows = await client
        .from('needs')
        .select('*,need_items(*)')
        .eq('organization_id', organizationId)
        .order('created_at', ascending: false)
        .order('id')
        .range(page.offset, page.end);
    return rows.map(Need.fromJson).toList();
  }

  Future<List<CollectionPoint>> listPoints({
    PageRequest page = const PageRequest(),
  }) async {
    page.validate();
    final rows = await client
        .from('collection_points')
        .select()
        .eq('active', true)
        .order('name')
        .order('id')
        .range(page.offset, page.end);
    return rows.map(CollectionPoint.fromJson).toList();
  }
}
