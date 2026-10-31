import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../needs/models/need.dart';
import '../models/emergency_stock_match.dart';
import '../models/incident.dart';

abstract class IDisasterService {
  Future<List<Incident>> fetchActiveIncidents({String? area});
  Future<List<Incident>> fetchAllIncidents();
  Future<String> requestDisasterDeclaration({
    required String organizationId,
    required String title,
    String? area,
    required DateTime startsAt,
    required DateTime endsAt,
  });
  Future<void> approveDisaster({required String incidentId});
  Future<void> closeDisaster({required String incidentId});
  Future<List<Need>> fetchEmergencyNeeds({
    String? incidentId,
    bool onlyActive = true,
  });
  Future<List<EmergencyStockMatch>> findPreCuratedStockForEmergency({
    required String category,
    required String sizeCode,
    required String ageGroup,
    required int requestedQty,
  });
}

class DisasterService implements IDisasterService {
  final SupabaseClient _client;

  DisasterService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<Incident>> fetchActiveIncidents({String? area}) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    var query = _client.from('incidents').select(
      'id, organization_id, title, area, status, starts_at, ends_at, approved_by, '
      'organizations(name)',
    ).eq('status', 'active').lte('starts_at', nowIso).gt('ends_at', nowIso);

    if (area != null) {
      query = query.eq('area', area);
    }

    final res = await query.order('starts_at', ascending: false);
    final incidents = <Incident>[];
    for (final item in res) {
      incidents.add(Incident.fromJson(item));
    }
    return incidents;
  }

  @override
  Future<List<Incident>> fetchAllIncidents() async {
    final res = await _client.from('incidents').select(
      'id, organization_id, title, area, status, starts_at, ends_at, approved_by, '
      'organizations(name)',
    ).order('starts_at', ascending: false);

    final incidents = <Incident>[];
    for (final item in res) {
      incidents.add(Incident.fromJson(item));
    }
    return incidents;
  }

  @override
  Future<String> requestDisasterDeclaration({
    required String organizationId,
    required String title,
    String? area,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final res = await _client
        .from('incidents')
        .insert({
          'organization_id': organizationId,
          'title': title,
          'area': ?area,
          'status': 'requested',
          'starts_at': startsAt.toUtc().toIso8601String(),
          'ends_at': endsAt.toUtc().toIso8601String(),
        })
        .select('id')
        .single();

    return res['id'] as String;
  }

  @override
  Future<void> approveDisaster({required String incidentId}) async {
    final adminId = _client.auth.currentUser?.id;
    await _client.from('incidents').update({
      'status': 'active',
      'approved_by': ?adminId,
    }).eq('id', incidentId);
  }

  @override
  Future<void> closeDisaster({required String incidentId}) async {
    await _client.from('incidents').update({
      'status': 'closed',
    }).eq('id', incidentId);
  }

  @override
  Future<List<Need>> fetchEmergencyNeeds({
    String? incidentId,
    bool onlyActive = true,
  }) async {
    var query = _client.from('needs').select(
      'id, organization_id, point_id, title, description, deadline_at, status, created_at, incident_id, '
      'need_items(*)',
    ).not('incident_id', 'is', null);

    if (incidentId != null) {
      query = query.eq('incident_id', incidentId);
    }
    if (onlyActive) {
      query = query.eq('status', 'open');
    }

    final res = await query.order('created_at', ascending: false);
    final needs = <Need>[];
    final now = DateTime.now();
    for (final item in res) {
      final need = Need.fromJson(item);
      if (onlyActive && (need.status != 'open' || need.deadlineAt.isBefore(now))) {
        continue;
      }
      needs.add(need);
    }
    return needs;
  }

  @override
  Future<List<EmergencyStockMatch>> findPreCuratedStockForEmergency({
    required String category,
    required String sizeCode,
    required String ageGroup,
    required int requestedQty,
  }) async {
    final res = await _client.from('inventory_batches').select(
      'id, point_id, category, size_code, age_group, initial_qty, on_hand_qty, reserved_qty, '
      'collection_points(id, name, public_address)',
    ).eq('category', category).eq('size_code', sizeCode).eq('age_group', ageGroup).gt('on_hand_qty', 0);

    final matches = <EmergencyStockMatch>[];
    for (final item in res) {
      final onHand = (item['on_hand_qty'] as num).toInt();
      final reserved = (item['reserved_qty'] as num?)?.toInt() ?? 0;
      final available = onHand - reserved;

      if (available > 0) {
        String pointName = 'Posko Mitra';
        String? address;
        if (item['collection_points'] is Map<String, dynamic>) {
          final pt = item['collection_points'] as Map<String, dynamic>;
          pointName = pt['name'] as String? ?? pointName;
          address = pt['public_address'] as String?;
        }

        matches.add(EmergencyStockMatch(
          batchId: item['id'] as String,
          pointId: item['point_id'] as String,
          pointName: pointName,
          pointAddress: address,
          category: category,
          sizeCode: sizeCode,
          ageGroup: ageGroup,
          requestedQty: requestedQty,
          availableQty: available,
          matchedQty: min(requestedQty, available),
        ));
      }
    }

    // Sort by largest available stock first
    matches.sort((a, b) => b.availableQty.compareTo(a.availableQty));
    return matches;
  }
}
