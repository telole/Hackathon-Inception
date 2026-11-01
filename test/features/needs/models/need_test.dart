import 'package:flutter_test/flutter_test.dart';
import 'package:pakaiankita/features/needs/models/need.dart';

void main() {
  group('Need and NeedItem models', () {
    test('parses Need with nested items correctly from json', () {
      final json = {
        'id': 'need-uuid-1',
        'organization_id': 'org-uuid-1',
        'point_id': 'point-uuid-1',
        'incident_id': null,
        'title': 'Kebutuhan Pakaian Hangat Posko Pengungsian',
        'description': 'Dibutuhkan jaket dan sweater untuk lansia dan anak',
        'deadline_at': '2026-11-15T00:00:00Z',
        'status': 'open',
        'created_at': '2026-10-31T10:00:00Z',
        'organizations': {'name': 'PMI Posko Bencana'},
        'collection_points': {'name': 'Titik Kumpul Utama PMI'},
        'need_items': [
          {
            'id': 'item-1',
            'need_id': 'need-uuid-1',
            'category': 'jacket',
            'size_code': 'L',
            'age_group': 'adult',
            'requested_qty': 20,
          },
          {
            'id': 'item-2',
            'need_id': 'need-uuid-1',
            'category': 'sweater',
            'size_code': 'M',
            'age_group': 'children',
            'requested_qty': 15,
          }
        ],
      };

      final need = Need.fromJson(json);

      expect(need.id, 'need-uuid-1');
      expect(need.title, 'Kebutuhan Pakaian Hangat Posko Pengungsian');
      expect(need.organizationName, 'PMI Posko Bencana');
      expect(need.pointName, 'Titik Kumpul Utama PMI');
      expect(need.status, 'open');
      expect(need.items.length, 2);
      expect(need.items[0].category, 'jacket');
      expect(need.items[0].requestedQty, 20);
      expect(need.items[1].category, 'sweater');
      expect(need.items[1].ageGroup, 'children');
    });
  });
}
