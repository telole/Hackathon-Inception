import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_mapper.dart';
import '../models/donation_model.dart';
import '../services/donations_service.dart';

class DonationsRepository {
  final SupabaseClient _client;
  final IDonationsService _service;

  DonationsRepository({SupabaseClient? client, IDonationsService? service})
      : _client = client ?? Supabase.instance.client,
        _service = service ?? DonationsService(client: client);

  /// Mengambil daftar donasi milik donatur yang sedang login
  Future<List<DonationModel>> fetchMyDonations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
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
          .eq('donor_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => DonationModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Membuat draft donasi baru via RPC create_donation_draft (idempoten)
  Future<Map<String, dynamic>> createDraft() async {
    try {
      return await _service.createDonationDraft();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Menyimpan draft donasi via RPC save_donation_draft (menggantikan insert manual)
  Future<void> saveDraft({
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
      await _service.saveDonationDraft(
        donationId: donationId,
        pointId: pointId,
        method: method,
        cleanCheck: cleanCheck,
        intactCheck: intactCheck,
        notTornCheck: notTornCheck,
        preferredNeedId: preferredNeedId,
        items: items,
        address: address,
        contactName: contactName,
        phone: phone,
      );
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Registrasi foto donasi via RPC register_donation_photo (idempoten)
  Future<String> registerPhoto({
    required String donationId,
    required String storagePath,
  }) async {
    try {
      return await _service.registerDonationPhoto(
        donationId: donationId,
        storagePath: storagePath,
      );
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Mengirim pengajuan donasi secara atomik via RPC submit_donation
  Future<void> submitDonation(String donationId) async {
    try {
      await _service.submitDonation(donationId);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Mengambil detail donasi lengkap (digunakan oleh DetailScreen)
  Future<DonationModel?> fetchDonationDetail(String donationId) async {
    try {
      final map = await _service.fetchDonationDetail(donationId);
      if (map != null) return DonationModel.fromMap(map);
      return null;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Menyimpan kontak privat untuk penjemputan
  Future<void> saveDonationContact({
    required String donationId,
    required String address,
    required String contactName,
    required String phone,
  }) async {
    try {
      await _service.saveDonationContact(
        donationId: donationId,
        address: address,
        contactName: contactName,
        phone: phone,
      );
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Mendapatkan kontak privat donasi
  Future<Map<String, dynamic>?> getDonationContact(String donationId) async {
    try {
      return await _service.getDonationContact(donationId);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
