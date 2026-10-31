import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/services/supabase_client_provider.dart';

abstract class IDonationsService {
  Future<Map<String, dynamic>> createDonationDraft();

  Future<void> saveDonationDraft({
    required String donationId,
    required String pointId,
    required String method,
    required bool cleanCheck,
    required bool intactCheck,
    required bool notTornCheck,
    String? preferredNeedId,
    required List<Map<String, dynamic>> items,
    String? address,
    String? contactName,
    String? phone,
  });

  Future<String> registerDonationPhoto({
    required String donationId,
    required String storagePath,
  });

  Future<void> submitDonation(String donationId);

  Future<void> reviewDonation({
    required String donationId,
    required String decision,
    String? note,
  });

  Future<void> advanceDonation({
    required String donationId,
    required String status,
  });

  Future<void> saveDonationContact({
    required String donationId,
    required String address,
    required String contactName,
    required String phone,
  });

  Future<Map<String, dynamic>?> getDonationContact(String donationId);

  Future<Map<String, dynamic>?> fetchDonationDetail(String donationId);
}

class DonationsService implements IDonationsService {
  final SupabaseClient _client;

  DonationsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Map<String, dynamic>> createDonationDraft() async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      final res = await _client.rpc('create_donation_draft', params: {
        'p_request_key': key,
      });
      if (res is Map<String, dynamic>) {
        return res;
      } else if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'donation_id': res.toString()};
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> saveDonationDraft({
    required String donationId,
    required String pointId,
    required String method,
    required bool cleanCheck,
    required bool intactCheck,
    required bool notTornCheck,
    String? preferredNeedId,
    required List<Map<String, dynamic>> items,
    String? address,
    String? contactName,
    String? phone,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc('save_donation_draft', params: {
        'p_id': donationId,
        'p_point_id': pointId,
        'p_method': method,
        'p_clean_check': cleanCheck,
        'p_intact_check': intactCheck,
        'p_not_torn_check': notTornCheck,
        'p_preferred_need_id': preferredNeedId,
        'p_items': items,
        'p_address': address,
        'p_contact_name': contactName,
        'p_phone': phone,
        'p_request_key': key,
      });
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<String> registerDonationPhoto({
    required String donationId,
    required String storagePath,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      final res = await _client.rpc('register_donation_photo', params: {
        'p_donation_id': donationId,
        'p_storage_path': storagePath,
        'p_request_key': key,
      });
      return res.toString();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> submitDonation(String donationId) async {
    try {
      await _client.rpc('submit_donation', params: {'p_id': donationId});
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> reviewDonation({
    required String donationId,
    required String decision,
    String? note,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc('review_donation', params: {
        'p_donation_id': donationId,
        'p_decision': decision,
        'p_note': note,
        'p_request_key': key,
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
  Future<void> saveDonationContact({
    required String donationId,
    required String address,
    required String contactName,
    required String phone,
  }) async {
    try {
      await _client.rpc(
        'save_donation_contact',
        params: {
          'p_id': donationId,
          'p_address': address,
          'p_name': contactName,
          'p_phone': phone,
        },
      );
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
      if (result is Map<String, dynamic>) {
        return result;
      } else if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchDonationDetail(String donationId) async {
    try {
      final res = await _client
          .from('donations')
          .select('''
            id,
            tracking_code,
            point_id,
            preferred_need_id,
            method,
            status,
            clean_check,
            intact_check,
            not_torn_check,
            scheduled_at,
            created_at,
            donation_items ( id, category, size_code, age_group, quantity ),
            donation_photos ( storage_path ),
            donation_events ( id, event_type, summary, created_at )
          ''')
          .eq('id', donationId)
          .maybeSingle();

      return res;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
