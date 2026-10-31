import 'package:supabase_flutter/supabase_flutter.dart';

abstract class IDonationService {
  Future<void> submitDonation(String donationId);
  Future<void> saveDonationContact({
    required String donationId,
    required String address,
    required String contactName,
    required String phone,
  });
  Future<Map<String, dynamic>?> getDonationContact(String donationId);
}

class DonationService implements IDonationService {
  final SupabaseClient _client;

  DonationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> submitDonation(String donationId) async {
    await _client.rpc(
      'submit_donation',
      params: {'p_id': donationId},
    );
  }

  @override
  Future<void> saveDonationContact({
    required String donationId,
    required String address,
    required String contactName,
    required String phone,
  }) async {
    await _client.rpc(
      'save_donation_contact',
      params: {
        'p_id': donationId,
        'p_address': address,
        'p_name': contactName,
        'p_phone': phone,
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> getDonationContact(String donationId) async {
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
  }
}
