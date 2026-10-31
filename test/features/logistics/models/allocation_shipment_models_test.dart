import 'package:flutter_test/flutter_test.dart';
import 'package:resandang/features/logistics/models/allocation.dart';
import 'package:resandang/features/logistics/models/shipment.dart';

void main() {
  group('Allocation & Shipment Models', () {
    test('Allocation parses json correctly and exposes status getters', () {
      final json = {
        'id': 'alloc-1',
        'batch_id': 'batch-1',
        'need_item_id': 'need-item-1',
        'quantity': 5,
        'status': 'reserved',
        'request_key': 'key-123',
        'created_by': 'user-1',
        'created_at': '2026-10-31T10:00:00Z',
        'inventory_batches': {'category': 'kaos', 'size_code': 'M'},
        'need_items': {
          'needs': {
            'title': 'Baju Anak Korban Banjir',
            'organizations': {'name': 'Panti Asuhan Kasih'},
          }
        },
      };

      final alloc = Allocation.fromJson(json);

      expect(alloc.id, 'alloc-1');
      expect(alloc.batchId, 'batch-1');
      expect(alloc.needItemId, 'need-item-1');
      expect(alloc.quantity, 5);
      expect(alloc.status, 'reserved');
      expect(alloc.isReserved, isTrue);
      expect(alloc.isDispatched, isFalse);
      expect(alloc.isReceived, isFalse);
      expect(alloc.batchCategory, 'kaos');
      expect(alloc.batchSizeCode, 'M');
      expect(alloc.needTitle, 'Baju Anak Korban Banjir');
      expect(alloc.organizationName, 'Panti Asuhan Kasih');

      final outJson = alloc.toJson();
      expect(outJson['id'], 'alloc-1');
      expect(outJson['quantity'], 5);
      expect(outJson['category'], 'kaos');
    });

    test('Shipment parses json with nested items and exposes status getters', () {
      final json = {
        'id': 'shipment-1',
        'source_point_id': 'point-a',
        'destination_point_id': 'point-b',
        'assigned_to': 'vol-1',
        'status': 'ready',
        'created_at': '2026-10-31T11:00:00Z',
        'source_point_name': 'Posko Pusat',
        'destination_point_name': 'Panti B',
        'volunteer_name': 'Relawan Ahmad',
        'shipment_items': [
          {
            'id': 'item-1',
            'shipment_id': 'shipment-1',
            'allocation_id': 'alloc-1',
            'quantity': 5,
            'received_good': 5,
            'rejected': 0,
            'missing': 0,
          }
        ],
      };

      final shipment = Shipment.fromJson(json);

      expect(shipment.id, 'shipment-1');
      expect(shipment.sourcePointId, 'point-a');
      expect(shipment.destinationPointId, 'point-b');
      expect(shipment.isReady, isTrue);
      expect(shipment.isInTransit, isFalse);
      expect(shipment.sourcePointName, 'Posko Pusat');
      expect(shipment.destinationPointName, 'Panti B');
      expect(shipment.volunteerName, 'Relawan Ahmad');
      expect(shipment.items.length, 1);

      final item = shipment.items.first;
      expect(item.id, 'item-1');
      expect(item.quantity, 5);
      expect(item.receivedGood, 5);
      expect(item.isConfirmed, isTrue);

      final outJson = shipment.toJson();
      expect(outJson['id'], 'shipment-1');
      expect(outJson['status'], 'ready');
      expect((outJson['shipment_items'] as List).length, 1);
    });
  });
}
