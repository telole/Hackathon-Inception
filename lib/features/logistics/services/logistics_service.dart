import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/services/supabase_client_provider.dart';

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

  Future<String> assignTask({
    required String donationId,
    required String pointId,
    required String volunteerId,
    required String kind,
    DateTime? scheduledAt,
    String? notes,
  });

  Future<void> dispatchShipment(String shipmentId);

  Future<void> confirmReceipt({
    required String shipmentId,
    required int goodQty,
    required int rejectedQty,
    required int missingQty,
  });

  Future<void> cancelAllocation({
    required String allocationId,
    String? reason,
  });

  Future<List<Map<String, dynamic>>> listMyTasks({String? status});

  Future<List<Map<String, dynamic>>> listInventory({
    required String pointId,
    String? category,
    String? sizeCode,
  });

  Future<List<Map<String, dynamic>>> findMatches({
    required String category,
    required String sizeCode,
    required String ageGroup,
    int limit = 5,
  });

  Future<void> updateRecyclingReferral({
    required String referralId,
    String? partnerId,
    String? status,
    String? evidence,
  });

  Future<Map<String, dynamic>?> getDonationContact(String donationId);
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
    try {
      await _client.rpc('respond_task', params: {
        'p_id': taskId,
        'p_status': status,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> advanceDonation({
    required String donationId,
    required String status,
  }) async {
    try {
      await _client.rpc('advance_donation', params: {
        'p_id': donationId,
        'p_status': status,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<String?> recordInspection({
    required String itemId,
    required int passedQty,
    required int rejectedQty,
    String? reason,
  }) async {
    try {
      final result = await _client.rpc('record_inspection', params: {
        'p_item': itemId,
        'p_passed': passedQty,
        'p_rejected': rejectedQty,
        'p_reason': reason,
      });
      return result?.toString();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<String?> reserveAllocation({
    required String batchId,
    required String needItemId,
    required int quantity,
    required String requestKey,
  }) async {
    try {
      final result = await _client.rpc('reserve_allocation', params: {
        'p_batch': batchId,
        'p_need_item': needItemId,
        'p_qty': quantity,
        'p_key': requestKey,
      });
      return result?.toString();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<String?> createShipment({
    required String allocationId,
    required String volunteerId,
  }) async {
    try {
      final result = await _client.rpc('create_shipment', params: {
        'p_allocation': allocationId,
        'p_volunteer': volunteerId,
      });
      return result?.toString();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<String> assignTask({
    required String donationId,
    required String pointId,
    required String volunteerId,
    required String kind,
    DateTime? scheduledAt,
    String? notes,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      final result = await _client.rpc('assign_task', params: {
        'p_donation_id': donationId,
        'p_point_id': pointId,
        'p_volunteer_id': volunteerId,
        'p_kind': kind,
        'p_scheduled_at': scheduledAt?.toIso8601String(),
        'p_notes': notes,
        'p_request_key': key,
      });
      return result?.toString() ?? '';
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> dispatchShipment(String shipmentId) async {
    try {
      await _client.rpc('dispatch_shipment', params: {'p_id': shipmentId});
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> confirmReceipt({
    required String shipmentId,
    required int goodQty,
    required int rejectedQty,
    required int missingQty,
  }) async {
    try {
      await _client.rpc('confirm_receipt', params: {
        'p_id': shipmentId,
        'p_good': goodQty,
        'p_rejected': rejectedQty,
        'p_missing': missingQty,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> cancelAllocation({
    required String allocationId,
    String? reason,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc('cancel_allocation', params: {
        'p_allocation_id': allocationId,
        'p_reason': reason,
        'p_request_key': key,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listMyTasks({String? status}) async {
    try {
      final res = await _client.rpc('list_my_tasks', params: {
        'p_status': status,
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
  Future<List<Map<String, dynamic>>> listInventory({
    required String pointId,
    String? category,
    String? sizeCode,
  }) async {
    try {
      final res = await _client.rpc('list_inventory', params: {
        'p_point_id': pointId,
        'p_category': category,
        'p_size_code': sizeCode,
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
  Future<List<Map<String, dynamic>>> findMatches({
    required String category,
    required String sizeCode,
    required String ageGroup,
    int limit = 5,
  }) async {
    try {
      final res = await _client.rpc('find_matches', params: {
        'p_category': category,
        'p_size_code': sizeCode,
        'p_age_group': ageGroup,
        'p_limit': limit,
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
  Future<void> updateRecyclingReferral({
    required String referralId,
    String? partnerId,
    String? status,
    String? evidence,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc('update_recycling_referral', params: {
        'p_referral_id': referralId,
        'p_partner_id': partnerId,
        'p_status': status,
        'p_evidence': evidence,
        'p_request_key': key,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<Map<String, dynamic>?> getDonationContact(String donationId) async {
    try {
      final result = await _client.rpc(
        'get_donation_contact',
        params: {'p_id': donationId},
      );
      if (result == null) return null;
      return Map<String, dynamic>.from(result as Map);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
