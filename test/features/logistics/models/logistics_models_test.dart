import 'package:flutter_test/flutter_test.dart';
import 'package:resandang/features/logistics/models/inspection.dart';
import 'package:resandang/features/logistics/models/inventory_batch.dart';
import 'package:resandang/features/logistics/models/logistics_task.dart';

void main() {
  group('Logistics Models', () {
    test('LogisticsTask parses json correctly and exposes helper status getters', () {
      final json = {
        'id': 'task-123',
        'donation_id': 'donation-456',
        'point_id': 'point-789',
        'assigned_to': 'volunteer-001',
        'kind': 'curation',
        'status': 'assigned',
        'scheduled_at': '2026-10-31T10:00:00.000Z',
        'notes': 'Periksa kelayakan pakaian',
        'created_at': '2026-10-31T09:00:00.000Z',
        'collection_points': {'name': 'Posko Siaga Jakarta'},
        'donations': {'tracking_code': 'PK-ABCDEF123456'},
      };

      final task = LogisticsTask.fromJson(json);

      expect(task.id, 'task-123');
      expect(task.donationId, 'donation-456');
      expect(task.pointId, 'point-789');
      expect(task.assignedTo, 'volunteer-001');
      expect(task.kind, 'curation');
      expect(task.status, 'assigned');
      expect(task.pointName, 'Posko Siaga Jakarta');
      expect(task.donationTrackingCode, 'PK-ABCDEF123456');
      expect(task.notes, 'Periksa kelayakan pakaian');

      // Helper getters
      expect(task.isAssigned, isTrue);
      expect(task.isAccepted, isFalse);
      expect(task.isInProgress, isFalse);
      expect(task.isCompleted, isFalse);
      expect(task.isCuration, isTrue);
      expect(task.isPickup, isFalse);
      expect(task.isActive, isTrue);

      final outJson = task.toJson();
      expect(outJson['id'], 'task-123');
      expect(outJson['status'], 'assigned');
      expect(outJson['kind'], 'curation');
    });

    test('Inspection parses json correctly and calculates totals', () {
      final json = {
        'id': 'insp-123',
        'item_id': 'item-456',
        'point_id': 'point-789',
        'inspector_id': 'volunteer-001',
        'passed_qty': 8,
        'rejected_qty': 2,
        'rejection_reason': 'Sobek kecil pada lengan',
        'created_at': '2026-10-31T11:00:00.000Z',
      };

      final inspection = Inspection.fromJson(json);

      expect(inspection.id, 'insp-123');
      expect(inspection.itemId, 'item-456');
      expect(inspection.passedQty, 8);
      expect(inspection.rejectedQty, 2);
      expect(inspection.rejectionReason, 'Sobek kecil pada lengan');
      expect(inspection.totalQty, 10);
      expect(inspection.hasRejection, isTrue);

      final outJson = inspection.toJson();
      expect(outJson['passed_qty'], 8);
      expect(outJson['rejected_qty'], 2);
    });

    test('InventoryBatch parses json correctly and computes availableQty', () {
      final json = {
        'id': 'batch-123',
        'inspection_id': 'insp-123',
        'point_id': 'point-789',
        'category': 'kaos',
        'size_code': 'M',
        'age_group': 'dewasa',
        'initial_qty': 10,
        'on_hand_qty': 8,
        'reserved_qty': 3,
      };

      final batch = InventoryBatch.fromJson(json);

      expect(batch.id, 'batch-123');
      expect(batch.inspectionId, 'insp-123');
      expect(batch.pointId, 'point-789');
      expect(batch.category, 'kaos');
      expect(batch.sizeCode, 'M');
      expect(batch.ageGroup, 'dewasa');
      expect(batch.initialQty, 10);
      expect(batch.onHandQty, 8);
      expect(batch.reservedQty, 3);
      expect(batch.availableQty, 5);

      final outJson = batch.toJson();
      expect(outJson['on_hand_qty'], 8);
      expect(outJson['reserved_qty'], 3);
    });
  });
}
