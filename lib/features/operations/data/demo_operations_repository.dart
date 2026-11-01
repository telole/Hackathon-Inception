import 'dart:convert';

import 'operations_repository.dart';

/// Explicit demo-only store. Never used as a fallback for a failed live request.
class DemoOperationsRepository implements OperationsRepository {
  final Map<String, List<OpsRow>> _data = {
    'tasks': [
      {
        'id': 'demo-task-1',
        'donation_id': 'demo-donation-1',
        'tracking_code': 'PK-DEMO-0142',
        'point_id': 'demo-point',
        'point_name': 'Rumah Sandang Dago',
        'kind': 'curation',
        'status': 'accepted',
        'scheduled_at': '2026-11-03T03:00:00Z',
        'notes': 'Periksa pakaian anak yang sudah diterima.',
      },
      {
        'id': 'demo-task-2',
        'donation_id': 'demo-donation-2',
        'tracking_code': 'PK-DEMO-0143',
        'point_id': 'demo-point',
        'point_name': 'Rumah Sandang Dago',
        'kind': 'pickup',
        'status': 'assigned',
        'scheduled_at': '2026-11-03T06:00:00Z',
      },
    ],
    'points': [
      {
        'id': 'demo-point',
        'name': 'Rumah Sandang Dago',
        'organization_id': 'demo-org',
      },
    ],
    'inventory:demo-point': [
      {
        'id': 'demo-batch',
        'category': 'kaos',
        'size_code': 'M',
        'age_group': 'anak',
        'on_hand_qty': 40,
        'reserved_qty': 10,
        'available_qty': 30,
      },
    ],
    'donation:demo-donation-1': [
      {
        'id': 'demo-donation-1',
        'tracking_code': 'PK-DEMO-0142',
        'status': 'received',
        'donation_items': [
          {
            'id': 'demo-item-1',
            'category': 'Kaos anak',
            'size_code': 'M',
            'quantity': 5,
            'inspections': [],
          },
        ],
      },
    ],
    'donation:demo-donation-2': [
      {
        'id': 'demo-donation-2',
        'tracking_code': 'PK-DEMO-0143',
        'status': 'scheduled',
        'donation_items': [
          {
            'id': 'demo-item-2',
            'category': 'Kemeja',
            'size_code': 'L',
            'quantity': 3,
            'inspections': [],
          },
        ],
      },
    ],
    'shipments': [
      {
        'id': 'demo-shipment-1',
        'status': 'in_transit',
        'shipment_items': [
          {'quantity': 20},
        ],
      },
      {
        'id': 'demo-shipment-2',
        'status': 'ready',
        'shipment_items': [
          {'quantity': 8},
        ],
      },
    ],
    'queue': [
      {
        'id': 'demo-review',
        'tracking_code': 'PK-DEMO-0144',
        'status': 'submitted',
        'donation_items': [
          {'quantity': 6},
        ],
      },
    ],
    'organizations': [
      {
        'id': 'demo-org',
        'name': 'Yayasan Pelita Anak',
        'area': 'Cianjur, Jawa Barat',
        'verified': false,
        'active': true,
      },
    ],
    'users': [
      {
        'id': 'demo-user',
        'display_name': 'Rina Pratiwi',
        'area': 'Bandung',
        'user_roles': [
          {'role': 'donatur'},
          {'role': 'relawan'},
        ],
      },
    ],
  };
  @override
  Future<OperationsAccess> access() async => const OperationsAccess(
    roles: ['donatur', 'relawan', 'mitra', 'admin'],
    organizations: ['demo-org'],
  );
  @override
  Future<List<OpsRow>> load(String resource) async {
    if (resource.startsWith('task:')) {
      return (await load('tasks'))
          .where((r) => r['id'] == resource.substring(5))
          .toList();
    }
    if (resource.startsWith('shipment:')) {
      return (await load('shipments'))
          .where((r) => r['id'] == resource.substring(9))
          .toList();
    }
    final source = _data[resource] ?? [];
    final rows = resource == 'queue'
        ? source.where((r) => r['status'] == 'submitted').toList()
        : resource == 'organizations'
        ? source
              .where((r) => r['verified'] == false && r['active'] == true)
              .toList()
        : source;
    return [
      for (final row in jsonDecode(jsonEncode(rows)) as List)
        Map<String, dynamic>.from(row as Map),
    ];
  }

  @override
  Future<void> act(String action, OpsRow input, String requestKey) async {
    final id = input['id'];
    OpsRow find(String resource) =>
        _data[resource]!.firstWhere((r) => r['id'] == id);
    switch (action) {
      case 'accept':
      case 'decline':
        final row = find('tasks');
        row['status'] = action == 'accept' ? 'accepted' : 'declined';
        if (action == 'accept') {
          row['contact_info'] = {
            'contact_name': 'Nadia (contoh)',
            'phone': 'Nomor contoh',
            'address': 'Alamat penjemputan contoh di Bandung',
          };
        }
      case 'receive':
        _data['donation:$id']!.first['status'] = 'received';
      case 'inspect':
        for (final entry in _data.entries.where(
          (e) => e.key.startsWith('donation:'),
        )) {
          for (final row in entry.value) {
            for (final item in row['donation_items'] as List) {
              if (item['id'] != id) continue;
              if ((item['inspections'] as List).isNotEmpty) {
                throw StateError('Sudah diperiksa.');
              }
              if ((input['good'] as int) + (input['bad'] as int) !=
                  item['quantity']) {
                throw ArgumentError('Jumlah tidak sesuai.');
              }
              item['inspections'] = [
                {'id': 'demo-inspection'},
              ];
              row['status'] = 'curated';
              final batch = _data['inventory:demo-point']!.first;
              batch['on_hand_qty'] =
                  (batch['on_hand_qty'] as int) + (input['good'] as int);
              batch['available_qty'] =
                  (batch['on_hand_qty'] as int) -
                  (batch['reserved_qty'] as int);
            }
          }
        }
      case 'dispatch':
        find('shipments')['status'] = 'in_transit';
      case 'receipt':
        final row = find('shipments');
        final total = (row['shipment_items'] as List).fold<int>(
          0,
          (sum, item) => sum + item['quantity'] as int,
        );
        if ((input['good'] as int) +
                (input['bad'] as int) +
                (input['missing'] as int) !=
            total) {
          throw ArgumentError('Jumlah tidak sesuai.');
        }
        row['status'] = input['bad'] == 0 && input['missing'] == 0
            ? 'received'
            : 'disputed';
      case 'approve':
      case 'revise':
        find('queue')['status'] = action == 'approve'
            ? 'scheduled'
            : 'needs_revision';
      case 'verify':
        final row = find('organizations');
        if (input['decision'] == 'approve') {
          row['verified'] = true;
        } else {
          row['active'] = false;
        }
      case 'role':
        final row = find('users');
        final roles = row['user_roles'] as List;
        roles.removeWhere((r) => r['role'] == input['role']);
        if (input['grant'] == true) roles.add({'role': input['role']});
      default:
        throw ArgumentError('Tindakan tidak dikenal.');
    }
  }
}
