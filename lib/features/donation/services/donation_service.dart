import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/donation.dart';

abstract class IDonationService {
  Future<void> submitDonation(String donationId);
  Future<void> saveDonationContact({
    required String donationId,
    required String address,
    required String contactName,
    required String phone,
  });
  Future<Map<String, dynamic>?> getDonationContact(String donationId);
  Future<String> createDraftDonation({
    required String method,
    String? pointId,
    String? preferredNeedId,
  });
  Future<void> addDonationItem({
    required String donationId,
    required String category,
    required String sizeCode,
    required String ageGroup,
    required int quantity,
  });
  Future<void> recordDonationPhoto({
    required String donationId,
    required String storagePath,
  });
  Future<void> updateChecklist({
    required String donationId,
    required bool clean,
    required bool intact,
    required bool notTorn,
  });
  Future<List<Donation>> fetchMyDonations();
  Future<List<DonationEvent>> fetchDonationTimeline(String donationId);
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

  @override
  Future<String> createDraftDonation({
    required String method,
    String? pointId,
    String? preferredNeedId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final payload = {
      'donor_id': user.id,
      'method': method,
      'status': 'draft',
      'clean_check': false,
      'intact_check': false,
      'not_torn_check': false,
      'point_id': ?pointId,
      'preferred_need_id': ?preferredNeedId,
    };

    final res = await _client.from('donations').insert(payload).select('id').single();
    return res['id'] as String;
  }

  @override
  Future<void> addDonationItem({
    required String donationId,
    required String category,
    required String sizeCode,
    required String ageGroup,
    required int quantity,
  }) async {
    await _client.from('donation_items').insert({
      'donation_id': donationId,
      'category': category,
      'size_code': sizeCode,
      'age_group': ageGroup,
      'quantity': quantity,
    });
  }

  @override
  Future<void> recordDonationPhoto({
    required String donationId,
    required String storagePath,
  }) async {
    await _client.from('donation_photos').insert({
      'donation_id': donationId,
      'storage_path': storagePath,
    });
  }

  @override
  Future<void> updateChecklist({
    required String donationId,
    required bool clean,
    required bool intact,
    required bool notTorn,
  }) async {
    await _client.from('donations').update({
      'clean_check': clean,
      'intact_check': intact,
      'not_torn_check': notTorn,
    }).eq('id', donationId);
  }

  @override
  Future<List<Donation>> fetchMyDonations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    const query = '''
      id, donor_id, tracking_code, point_id, preferred_need_id, method, status,
      clean_check, intact_check, not_torn_check, scheduled_at, created_at,
      donation_items(id, donation_id, category, size_code, age_group, quantity),
      donation_photos(id, donation_id, storage_path, created_at)
    ''';

    final res = await _client
        .from('donations')
        .select(query)
        .eq('donor_id', user.id)
        .order('created_at', ascending: false);

    final List<Donation> list = [];
    for (final item in res) {
      list.add(Donation.fromJson(item));
    }
    return list;
  }

  @override
  Future<List<DonationEvent>> fetchDonationTimeline(String donationId) async {
    final res = await _client
        .from('donation_events')
        .select('id, donation_id, event_type, summary, actor_id, created_at')
        .eq('donation_id', donationId)
        .order('created_at', ascending: false);

    final List<DonationEvent> list = [];
    for (final item in res) {
      list.add(DonationEvent.fromJson(item));
    }
    return list;
  }
}
