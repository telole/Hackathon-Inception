import 'package:supabase_flutter/supabase_flutter.dart';
import '../../donation/models/donation.dart';
import '../models/inspection.dart';
import '../models/inventory_batch.dart';
import '../models/logistics_task.dart';

abstract class ILogisticsService {
  Future<void> respondTask({
    required String taskId,
    required String status,
  });
  Future<void> advanceDonation({
    required String donationId,
    required String status,
  });
  Future<String?> recordInspection({
    required String itemId,
    required int passedQty,
    required int rejectedQty,
    String? reason,
  });
  Future<String?> reserveAllocation({
    required String batchId,
    required String needItemId,
    required int quantity,
    required String requestKey,
  });
  Future<String?> createShipment({
    required String allocationId,
    required String volunteerId,
  });
  Future<void> dispatchShipment(String shipmentId);
  Future<void> confirmReceipt({
    required String shipmentId,
    required int goodQty,
    required int rejectedQty,
    required int missingQty,
  });
  Future<Map<String, dynamic>?> getDonationContact(String donationId);
  Future<List<LogisticsTask>> fetchMyTasks({
    List<String>? statuses,
    String? kind,
  });
  Future<List<DonationItem>> fetchDonationItemsForCuration(String donationId);
  Future<List<Inspection>> fetchInspectionsForDonation(String donationId);
  Future<List<InventoryBatch>> fetchInventoryBatches({String? pointId});
}

class LogisticsService implements ILogisticsService {
  final SupabaseClient _client;

  LogisticsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> respondTask({
    required String taskId,
    required String status,
  }) async {
    await _client.rpc(
      'respond_task',
      params: {
        'p_id': taskId,
        'p_status': status,
      },
    );
  }

  @override
  Future<void> advanceDonation({
    required String donationId,
    required String status,
  }) async {
    await _client.rpc(
      'advance_donation',
      params: {
        'p_id': donationId,
        'p_status': status,
      },
    );
  }

  @override
  Future<String?> recordInspection({
    required String itemId,
    required int passedQty,
    required int rejectedQty,
    String? reason,
  }) async {
    final result = await _client.rpc(
      'record_inspection',
      params: {
        'p_item': itemId,
        'p_passed': passedQty,
        'p_rejected': rejectedQty,
        'p_reason': ?reason,
      },
    );
    return result?.toString();
  }

  @override
  Future<String?> reserveAllocation({
    required String batchId,
    required String needItemId,
    required int quantity,
    required String requestKey,
  }) async {
    final result = await _client.rpc(
      'reserve_allocation',
      params: {
        'p_batch': batchId,
        'p_need_item': needItemId,
        'p_qty': quantity,
        'p_key': requestKey,
      },
    );
    return result?.toString();
  }

  @override
  Future<String?> createShipment({
    required String allocationId,
    required String volunteerId,
  }) async {
    final result = await _client.rpc(
      'create_shipment',
      params: {
        'p_allocation': allocationId,
        'p_volunteer': volunteerId,
      },
    );
    return result?.toString();
  }

  @override
  Future<void> dispatchShipment(String shipmentId) async {
    await _client.rpc(
      'dispatch_shipment',
      params: {'p_id': shipmentId},
    );
  }

  @override
  Future<void> confirmReceipt({
    required String shipmentId,
    required int goodQty,
    required int rejectedQty,
    required int missingQty,
  }) async {
    await _client.rpc(
      'confirm_receipt',
      params: {
        'p_id': shipmentId,
        'p_good': goodQty,
        'p_rejected': rejectedQty,
        'p_missing': missingQty,
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> getDonationContact(String donationId) async {
    final result = await _client.rpc(
      'get_donation_contact',
      params: {'p_id': donationId},
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<List<LogisticsTask>> fetchMyTasks({
    List<String>? statuses,
    String? kind,
  }) async {
    var query = _client.from('logistics_tasks').select(
      'id, donation_id, point_id, assigned_to, kind, status, scheduled_at, notes, created_at, '
      'collection_points(name), donations(tracking_code)',
    );

    if (statuses != null && statuses.isNotEmpty) {
      query = query.filter('status', 'in', statuses);
    }
    if (kind != null) {
      query = query.eq('kind', kind);
    }

    final res = await query.order('created_at', ascending: false);
    final tasks = <LogisticsTask>[];
    for (final item in res) {
      tasks.add(LogisticsTask.fromJson(item));
    }
    return tasks;
  }

  @override
  Future<List<DonationItem>> fetchDonationItemsForCuration(
      String donationId) async {
    final res = await _client
        .from('donation_items')
        .select()
        .eq('donation_id', donationId);

    final items = <DonationItem>[];
    for (final item in res) {
      items.add(DonationItem.fromJson(item));
    }
    return items;
  }

  @override
  Future<List<Inspection>> fetchInspectionsForDonation(
      String donationId) async {
    final res = await _client
        .from('inspections')
        .select('id, item_id, point_id, inspector_id, passed_qty, rejected_qty, rejection_reason, created_at, donation_items!inner(donation_id)')
        .eq('donation_items.donation_id', donationId);

    final inspections = <Inspection>[];
    for (final item in res) {
      inspections.add(Inspection.fromJson(item));
    }
    return inspections;
  }

  @override
  Future<List<InventoryBatch>> fetchInventoryBatches(
      {String? pointId}) async {
    var query = _client.from('inventory_batches').select();
    if (pointId != null) {
      query = query.eq('point_id', pointId);
    }
    final res = await query.order('created_at', ascending: false);

    final batches = <InventoryBatch>[];
    for (final item in res) {
      batches.add(InventoryBatch.fromJson(item));
    }
    return batches;
  }
}
