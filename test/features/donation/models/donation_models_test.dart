import 'package:flutter_test/flutter_test.dart';
import 'package:resandang/features/donation/models/donation.dart';

void main() {
  group('Donation models', () {
    test('parses Donation with items, photos, and checklist from json', () {
      final json = {
        'id': 'don-1',
        'donor_id': 'donor-uuid-1',
        'tracking_code': 'PK-ABCD1234EFGH5678',
        'point_id': 'point-uuid-1',
        'preferred_need_id': 'need-uuid-1',
        'method': 'dropoff',
        'status': 'submitted',
        'clean_check': true,
        'intact_check': true,
        'not_torn_check': true,
        'scheduled_at': null,
        'created_at': '2026-10-31T09:00:00Z',
        'donation_items': [
          {
            'id': 'item-1',
            'donation_id': 'don-1',
            'category': 'shirt',
            'size_code': 'M',
            'age_group': 'adult',
            'quantity': 3,
          }
        ],
        'donation_photos': [
          {
            'id': 'photo-1',
            'donation_id': 'don-1',
            'storage_path': 'donor-uuid-1/don-1/photo1.jpg',
            'created_at': '2026-10-31T09:05:00Z',
          }
        ],
      };

      final donation = Donation.fromJson(json);

      expect(donation.id, 'don-1');
      expect(donation.trackingCode, 'PK-ABCD1234EFGH5678');
      expect(donation.method, 'dropoff');
      expect(donation.status, 'submitted');
      expect(donation.cleanCheck, isTrue);
      expect(donation.intactCheck, isTrue);
      expect(donation.notTornCheck, isTrue);
      expect(donation.isChecklistComplete, isTrue);
      expect(donation.items.length, 1);
      expect(donation.items.first.quantity, 3);
      expect(donation.photos.length, 1);
      expect(donation.photos.first.storagePath, 'donor-uuid-1/don-1/photo1.jpg');
    });

    test('parses DonationEvent timeline event from json', () {
      final json = {
        'id': 101,
        'donation_id': 'don-1',
        'event_type': 'curated',
        'summary': '8 layak, 2 tidak layak',
        'actor_id': 'volunteer-uuid-1',
        'created_at': '2026-10-31T11:00:00Z',
      };

      final event = DonationEvent.fromJson(json);

      expect(event.id, 101);
      expect(event.donationId, 'don-1');
      expect(event.eventType, 'curated');
      expect(event.summary, '8 layak, 2 tidak layak');
    });
  });
}
