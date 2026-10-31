import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_mapper.dart';
import '../models/need_item_model.dart';
import '../services/needs_service.dart';

class NeedsRepository {
  final SupabaseClient _client;
  final INeedsService _service;

  NeedsRepository({SupabaseClient? client, INeedsService? service})
      : _client = client ?? Supabase.instance.client,
        _service = service ?? NeedsService(client: client);

  /// Mengambil kebutuhan terverifikasi yang terbuka via RPC list_needs dengan fallback query
  Future<List<NeedModel>> fetchActiveNeeds({
    bool? emergencyOnly,
    String? categoryFilter,
    String? areaFilter,
  }) async {
    // 1. Coba panggil RPC list_needs sesuai api-contracts.md
    try {
      final rpcResults = await _service.listNeeds(
        category: categoryFilter,
        area: areaFilter,
        emergency: emergencyOnly,
      );

      if (rpcResults.isNotEmpty) {
        return rpcResults.map((e) => NeedModel.fromMap(e)).toList();
      }
    } catch (_) {
      // Abaikan dan coba query langsung
    }

    // 2. Fallback ke query tabel RLS langsung
    try {
      final response = await _client
          .from('needs')
          .select(
            '''
            id,
            organization_id,
            point_id,
            incident_id,
            title,
            description,
            deadline_at,
            status,
            organizations ( name, verified, active ),
            need_items ( id, category, size_code, age_group, requested_qty )
            ''',
          )
          .eq('status', 'open')
          .order('created_at', ascending: false);

      var list = (response as List<dynamic>)
          .map((e) => NeedModel.fromMap(e as Map<String, dynamic>))
          .toList();

      if (emergencyOnly == true) {
        list = list.where((n) => n.incidentId != null).toList();
      }

      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        list = list.where((n) {
          return n.lines.any((l) => l.category.toLowerCase() == categoryFilter.toLowerCase());
        }).toList();
      }
      return list;
    } catch (_) {
      // 3. Fallback ke fixture terstruktur jika offline/belum terhubung
      return _fallbackFixtureNeeds();
    }
  }

  /// Mengambil detail kebutuhan lengkap via RPC get_need_detail
  Future<NeedModel?> fetchNeedDetail(String needId) async {
    try {
      final map = await _service.getNeedDetail(needId);
      if (map != null) {
        return NeedModel.fromMap(map);
      }
    } catch (_) {}
    return null;
  }

  /// Membuat atau memperbarui kebutuhan donasi
  Future<String> saveNeed({
    String? needId,
    required String organizationId,
    required String pointId,
    required String title,
    required String description,
    required DateTime deadlineAt,
    String? incidentId,
    required List<Map<String, dynamic>> lines,
  }) async {
    try {
      return await _service.saveNeed(
        needId: needId,
        organizationId: organizationId,
        pointId: pointId,
        title: title,
        description: description,
        deadlineAt: deadlineAt,
        incidentId: incidentId,
        lines: lines,
      );
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Memublikasikan draf kebutuhan ke status open
  Future<void> publishNeed(String needId) async {
    try {
      await _service.publishNeed(needId);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Mengubah status kebutuhan (open, paused, closed)
  Future<void> changeNeedStatus({
    required String needId,
    required String status,
    String? reason,
  }) async {
    try {
      await _service.changeNeedStatus(
        needId: needId,
        status: status,
        reason: reason,
      );
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Mengambil insiden bencana aktif (FR-10)
  Future<Map<String, dynamic>?> fetchActiveDisasterIncident() async {
    try {
      final res = await _client
          .from('incidents')
          .select('id, title, area, starts_at, ends_at, status')
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil titik kumpul aktif via RPC list_points atau query langsung
  Future<List<Map<String, dynamic>>> fetchCollectionPoints({String? area}) async {
    try {
      final pts = await _service.listPoints(area: area);
      if (pts.isNotEmpty) return pts;
    } catch (_) {}

    try {
      final res = await _client
          .from('collection_points')
          .select('id, name, public_address, opening_hours, capacity_pieces')
          .eq('active', true);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [
        {
          'id': 'pt-1',
          'name': 'Titik Kumpul Utama Rawamangun',
          'public_address': 'Jl. Pemuda No. 45, Jakarta Timur',
          'opening_hours': '08:00 - 17:00 WIB',
          'capacity_pieces': 1200,
        },
        {
          'id': 'pt-2',
          'name': 'Posko Sandang Kebon Jeruk',
          'public_address': 'Jl. Panjang No. 12, Jakarta Barat',
          'opening_hours': '09:00 - 18:00 WIB',
          'capacity_pieces': 800,
        },
      ];
    }
  }

  List<NeedModel> _fallbackFixtureNeeds() {
    return [
      NeedModel(
        id: 'fx-1',
        organizationId: 'org-1',
        organizationName: 'Posko Peduli Bencana Serayu',
        pointId: 'pt-2',
        incidentId: 'inc-1',
        incidentTitle: 'Banjir Luapan Sungai Serayu',
        title: 'Darurat: Sandang Hangat Pengungsi Anak',
        description:
            'Kebutuhan mendesak pakaian hangat dan bersih untuk pengungsi anak usia 7-12 tahun di Posko Pengungsian Serayu.',
        deadlineAt: DateTime.now().add(const Duration(days: 3)),
        status: 'open',
        isEmergency: true,
        lines: [
          NeedItemLine(
            id: 'l-1',
            category: 'Kaos / Atasan',
            sizeCode: '7-8',
            ageGroup: 'anak',
            requestedQty: 10,
            receivedQty: 0,
            reservedQty: 0,
            remainingQty: 10,
          ),
          NeedItemLine(
            id: 'l-2',
            category: 'Celana Panjang',
            sizeCode: '9-10',
            ageGroup: 'anak',
            requestedQty: 8,
            receivedQty: 0,
            reservedQty: 0,
            remainingQty: 8,
          ),
        ],
      ),
      NeedModel(
        id: 'fx-2',
        organizationId: 'org-2',
        organizationName: 'Panti Asuhan Kasih Mandiri',
        pointId: 'pt-1',
        title: 'Pakaian Sekolah dan Santai Harian',
        description:
            'Kebutuhan rutin kemeja putih dan celana harian untuk anak-anak panti menjelang semester baru.',
        deadlineAt: DateTime.now().add(const Duration(days: 14)),
        status: 'open',
        isEmergency: false,
        lines: [
          NeedItemLine(
            id: 'l-3',
            category: 'Kemeja',
            sizeCode: 'S',
            ageGroup: 'remaja',
            requestedQty: 15,
            receivedQty: 5,
            reservedQty: 3,
            remainingQty: 7,
          ),
        ],
      ),
    ];
  }
}
