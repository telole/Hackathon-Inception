import 'package:supabase_flutter/supabase_flutter.dart';

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
}
