import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/home_models.dart';

abstract interface class HomeRepository {
  Future<HomeSnapshot> fetchHome();
  Future<Campaign?> fetchCampaign(String id);
}

class InMemoryHomeRepository implements HomeRepository {
  const InMemoryHomeRepository();

  static const _campaigns = [
    Campaign(
      id: 'seragam-cianjur',
      title: 'Seragam sekolah untuk Cianjur',
      partner: 'Yayasan Pelita Anak',
      location: 'Coblong, Bandung',
      distanceKm: 3.2,
      category: DonationCategory.schoolUniform,
      story:
          'Awal tahun ajaran baru semakin dekat. Banyak anak di Cianjur '
          'membutuhkan seragam yang nyaman agar bisa kembali belajar dengan '
          'percaya diri. Seragam layak pakai darimu akan dirapikan dan '
          'disalurkan bersama relawan Yayasan Pelita Anak.',
      requestedItems: 80,
      receivedItems: 46,
      icon: Icons.school_rounded,
    ),
    Campaign(
      id: 'pakaian-hangat',
      title: 'Pakaian hangat keluarga',
      partner: 'Rumah Singgah Harapan',
      location: 'Sukajadi, Bandung',
      distanceKm: 5.8,
      category: DonationCategory.adults,
      story:
          'Rumah Singgah Harapan mendampingi keluarga yang sedang memulai '
          'kembali hidupnya. Pakaian bersih dan layak membantu mereka merasa '
          'lebih nyaman saat beraktivitas dan mencari kesempatan baru.',
      requestedItems: 60,
      receivedItems: 24,
      icon: Icons.checkroom_rounded,
    ),
    Campaign(
      id: 'busana-anak',
      title: 'Baju kecil, harapan besar',
      partner: 'Komunitas Tumbuh Bersama',
      location: 'Cicendo, Bandung',
      distanceKm: 7.1,
      category: DonationCategory.children,
      story:
          'Komunitas Tumbuh Bersama menyiapkan paket pakaian anak untuk '
          'keluarga yang membutuhkan. Setiap baju kecil yang masih nyaman '
          'dipakai bisa menjadi awal hari yang lebih ceria.',
      requestedItems: 50,
      receivedItems: 31,
      icon: Icons.child_care_rounded,
    ),
  ];

  @override
  Future<HomeSnapshot> fetchHome() async => const HomeSnapshot(
    displayName: 'Nadia',
    impact: ImpactStats(
      receivedItems: 18,
      submittedDonations: 4,
      curatedDonations: 2,
    ),
    campaigns: _campaigns,
  );

  @override
  Future<Campaign?> fetchCampaign(String id) async {
    for (final campaign in _campaigns) {
      if (campaign.id == id) return campaign;
    }
    return null;
  }
}

class SupabaseHomeRepository implements HomeRepository {
  SupabaseHomeRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<HomeSnapshot> fetchHome() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Silakan masuk terlebih dahulu.');
    }

    final results = await Future.wait<Object?>([
      _fetchOpenNeeds().then<Object?>((value) => value),
      _fetchMyDonations(user.id).then<Object?>((value) => value),
      _client
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle()
          .then<Object?>((value) => value),
    ]);

    final needs = results[0] as List<Map<String, dynamic>>;
    final donations = results[1] as List<Map<String, dynamic>>;
    final profile = results[2] as Map<String, dynamic>?;
    final displayName = (profile?['display_name'] as String?)?.trim();

    return HomeSnapshot(
      displayName: displayName == null || displayName.isEmpty
          ? (user.email?.split('@').first ?? 'Sahabat')
          : displayName,
      impact: _impactFrom(donations),
      campaigns: needs.map(_campaignFromNeed).toList(growable: false),
    );
  }

  @override
  Future<Campaign?> fetchCampaign(String id) async {
    final response = await _client
        .from('needs')
        .select('''
          id, organization_id, point_id, incident_id, title, description,
          deadline_at, status, created_at,
          organizations(name),
          collection_points(name),
          need_items(id, category, size_code, age_group, requested_qty)
        ''')
        .eq('id', id)
        .eq('status', 'open')
        .maybeSingle();
    if (response == null) return null;
    return _campaignFromNeed(response);
  }

  Future<List<Map<String, dynamic>>> _fetchOpenNeeds() async {
    final response = await _client
        .from('needs')
        .select('''
          id, organization_id, point_id, incident_id, title, description,
          deadline_at, status, created_at,
          organizations(name),
          collection_points(name),
          need_items!inner(id, category, size_code, age_group, requested_qty)
        ''')
        .eq('status', 'open')
        .gt('deadline_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .order('id')
        .range(0, 29);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchMyDonations(String userId) async {
    final response = await _client
        .from('donations')
        .select('status, donation_items(quantity, inspections(passed_qty))')
        .eq('donor_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Campaign _campaignFromNeed(Map<String, dynamic> need) {
    final organization = need['organizations'];
    final point = need['collection_points'];
    final rawItems = need['need_items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    final category = _campaignCategory(items);
    final requestedItems = items.fold<int>(
      0,
      (total, item) => total + ((item['requested_qty'] as num?)?.toInt() ?? 0),
    );

    return Campaign(
      id: need['id'] as String,
      title: need['title'] as String? ?? 'Kebutuhan pakaian',
      partner: organization is Map
          ? organization['name'] as String? ?? 'Mitra terverifikasi'
          : 'Mitra terverifikasi',
      location: point is Map
          ? point['name'] as String? ?? 'Titik penyaluran terverifikasi'
          : 'Titik penyaluran terverifikasi',
      category: category,
      story: (need['description'] as String?)?.trim().isNotEmpty == true
          ? (need['description'] as String).trim()
          : 'Mitra ini sedang mengumpulkan pakaian layak pakai untuk '
                'kebutuhan yang telah diverifikasi.',
      requestedItems: requestedItems,
      icon: category.icon,
    );
  }

  DonationCategory _campaignCategory(List<Map<String, dynamic>> items) {
    final item = items.firstOrNull;
    if (item == null) return DonationCategory.adults;

    final category = (item['category'] as String? ?? '').toLowerCase();
    final ageGroup = (item['age_group'] as String? ?? '').toLowerCase();
    if (category.contains('seragam')) return DonationCategory.schoolUniform;
    if (category.contains('batik') || category.contains('formal')) {
      return DonationCategory.batikFormal;
    }
    if (ageGroup == 'anak' || ageGroup == 'children') {
      return DonationCategory.children;
    }
    return DonationCategory.adults;
  }

  ImpactStats _impactFrom(List<Map<String, dynamic>> donations) {
    var receivedItems = 0;
    var submittedDonations = 0;
    var curatedDonations = 0;
    for (final donation in donations) {
      final status = donation['status'] as String? ?? '';
      if (status != 'draft' && status != 'cancelled') submittedDonations++;
      if (status == 'curated') curatedDonations++;
      if (status == 'curated') {
        final items = donation['donation_items'] as List<dynamic>? ?? const [];
        receivedItems += items.fold<int>(0, (sum, item) {
          final rawInspections = (item as Map)['inspections'];
          final inspections = rawInspections is List
              ? rawInspections
              : rawInspections is Map
              ? [rawInspections]
              : const [];
          return sum +
              inspections.fold<int>(
                0,
                (total, inspection) =>
                    total +
                    (((inspection as Map)['passed_qty'] as num?)?.toInt() ?? 0),
              );
        });
      }
    }
    return ImpactStats(
      receivedItems: receivedItems,
      submittedDonations: submittedDonations,
      curatedDonations: curatedDonations,
    );
  }
}
