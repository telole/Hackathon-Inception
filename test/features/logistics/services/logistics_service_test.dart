import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/features/logistics/services/logistics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final Future<T> _future;
  FakePostgrestFilterBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> gt(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> or(String filters, {String? referencedTable}) =>
      this;

  @override
  PostgrestFilterBuilder<T> filter(
          String column, String operator, Object? value) =>
      this;

  @override
  PostgrestFilterBuilder<T> order(String column,
          {bool ascending = false,
          bool nullsFirst = false,
          String? referencedTable}) =>
      this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    final singleFuture = (_future as Future<List<Map<String, dynamic>>>)
        .then((list) => list.isEmpty ? null : list.first);
    return FakePostgrestTransformBuilder<Map<String, dynamic>?>(singleFuture);
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select(
          [String columns = '*']) =>
      FakePostgrestTransformBuilder<List<Map<String, dynamic>>>(
          _future as dynamic);
}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final Future<T> _future;
  FakePostgrestTransformBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient mockSupabase;
  late LogisticsService logisticsService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    logisticsService = LogisticsService(client: mockSupabase);
  });

  group('LogisticsService RPCs', () {
    test('respondTask calls respond_task RPC with correct params', () async {
      const taskId = 'task-uuid-1';
      final builder = FakePostgrestFilterBuilder<dynamic>(Future.value(null));
      when(
        () => mockSupabase.rpc(
          'respond_task',
          params: {'p_id': taskId, 'p_status': 'accepted'},
        ),
      ).thenAnswer((_) => builder);

      await logisticsService.respondTask(taskId: taskId, status: 'accepted');

      verify(
        () => mockSupabase.rpc(
          'respond_task',
          params: {'p_id': taskId, 'p_status': 'accepted'},
        ),
      ).called(1);
    });

    test('recordInspection calls record_inspection RPC and returns batchId',
        () async {
      const itemId = 'item-uuid-1';
      const createdBatchId = 'batch-uuid-1';
      final builder =
          FakePostgrestFilterBuilder<dynamic>(Future.value(createdBatchId));
      when(
        () => mockSupabase.rpc(
          'record_inspection',
          params: {
            'p_item': itemId,
            'p_passed': 8,
            'p_rejected': 2,
            'p_reason': 'Noda dan kancing lepas',
          },
        ),
      ).thenAnswer((_) => builder);

      final batchId = await logisticsService.recordInspection(
        itemId: itemId,
        passedQty: 8,
        rejectedQty: 2,
        reason: 'Noda dan kancing lepas',
      );

      expect(batchId, createdBatchId);
      verify(
        () => mockSupabase.rpc(
          'record_inspection',
          params: {
            'p_item': itemId,
            'p_passed': 8,
            'p_rejected': 2,
            'p_reason': 'Noda dan kancing lepas',
          },
        ),
      ).called(1);
    });

    test('reserveAllocation calls reserve_allocation RPC with idempotency key',
        () async {
      const batchId = 'batch-1';
      const needItemId = 'need-item-1';
      const requestKey = 'key-uuid-1';
      const allocationId = 'alloc-uuid-1';
      final builder =
          FakePostgrestFilterBuilder<dynamic>(Future.value(allocationId));
      when(
        () => mockSupabase.rpc(
          'reserve_allocation',
          params: {
            'p_batch': batchId,
            'p_need_item': needItemId,
            'p_qty': 5,
            'p_key': requestKey,
          },
        ),
      ).thenAnswer((_) => builder);

      final result = await logisticsService.reserveAllocation(
        batchId: batchId,
        needItemId: needItemId,
        quantity: 5,
        requestKey: requestKey,
      );

      expect(result, allocationId);
      verify(
        () => mockSupabase.rpc(
          'reserve_allocation',
          params: {
            'p_batch': batchId,
            'p_need_item': needItemId,
            'p_qty': 5,
            'p_key': requestKey,
          },
        ),
      ).called(1);
    });

    test('createShipment calls create_shipment RPC with params', () async {
      const allocId = 'alloc-1';
      const volId = 'vol-1';
      const shipmentId = 'ship-1';
      final builder =
          FakePostgrestFilterBuilder<dynamic>(Future.value(shipmentId));
      when(
        () => mockSupabase.rpc(
          'create_shipment',
          params: {
            'p_allocation': allocId,
            'p_volunteer': volId,
          },
        ),
      ).thenAnswer((_) => builder);

      final result = await logisticsService.createShipment(
        allocationId: allocId,
        volunteerId: volId,
      );

      expect(result, shipmentId);
      verify(
        () => mockSupabase.rpc(
          'create_shipment',
          params: {
            'p_allocation': allocId,
            'p_volunteer': volId,
          },
        ),
      ).called(1);
    });

    test('dispatchShipment calls dispatch_shipment RPC', () async {
      const shipmentId = 'ship-1';
      final builder = FakePostgrestFilterBuilder<dynamic>(Future.value(null));
      when(
        () => mockSupabase.rpc(
          'dispatch_shipment',
          params: {'p_id': shipmentId},
        ),
      ).thenAnswer((_) => builder);

      await logisticsService.dispatchShipment(shipmentId);

      verify(
        () => mockSupabase.rpc(
          'dispatch_shipment',
          params: {'p_id': shipmentId},
        ),
      ).called(1);
    });

    test('confirmReceipt calls confirm_receipt RPC with counts', () async {
      const shipmentId = 'shipment-1';
      final builder = FakePostgrestFilterBuilder<dynamic>(Future.value(null));
      when(
        () => mockSupabase.rpc(
          'confirm_receipt',
          params: {
            'p_id': shipmentId,
            'p_good': 5,
            'p_rejected': 0,
            'p_missing': 0,
          },
        ),
      ).thenAnswer((_) => builder);

      await logisticsService.confirmReceipt(
        shipmentId: shipmentId,
        goodQty: 5,
        rejectedQty: 0,
        missingQty: 0,
      );

      verify(
        () => mockSupabase.rpc(
          'confirm_receipt',
          params: {
            'p_id': shipmentId,
            'p_good': 5,
            'p_rejected': 0,
            'p_missing': 0,
          },
        ),
      ).called(1);
    });

    test('getDonationContact calls get_donation_contact RPC and returns map',
        () async {
      const donationId = 'donation-1';
      final contactData = {
        'contact_name': 'Budi Santoso',
        'phone': '08123456789',
        'address': 'Jl. Melati No. 10',
      };
      final builder =
          FakePostgrestFilterBuilder<dynamic>(Future.value(contactData));
      when(
        () => mockSupabase.rpc(
          'get_donation_contact',
          params: {'p_id': donationId},
        ),
      ).thenAnswer((_) => builder);

      final result = await logisticsService.getDonationContact(donationId);

      expect(result?['contact_name'], 'Budi Santoso');
      expect(result?['phone'], '08123456789');
    });
  });

  group('LogisticsService Queries', () {
    test('fetchMyTasks queries logistics_tasks with filters and returns list',
        () async {
      final mockQuery = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('logistics_tasks'))
          .thenAnswer((_) => mockQuery);

      final tasksData = [
        {
          'id': 'task-1',
          'donation_id': 'donation-1',
          'point_id': 'point-1',
          'assigned_to': 'user-1',
          'kind': 'curation',
          'status': 'assigned',
          'created_at': '2026-10-31T09:00:00.000Z',
          'collection_points': {'name': 'Posko Jakarta'},
          'donations': {'tracking_code': 'PK-12345'},
        }
      ];

      final builder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(tasksData),
      );
      when(() => mockQuery.select(any())).thenAnswer((_) => builder);

      final tasks = await logisticsService.fetchMyTasks(
        statuses: ['assigned', 'accepted'],
        kind: 'curation',
      );

      expect(tasks.length, 1);
      expect(tasks.first.id, 'task-1');
      expect(tasks.first.pointName, 'Posko Jakarta');
      expect(tasks.first.donationTrackingCode, 'PK-12345');
    });

    test('fetchDonationItemsForCuration returns donation items for donation',
        () async {
      final mockQuery = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('donation_items'))
          .thenAnswer((_) => mockQuery);

      final itemsData = [
        {
          'id': 'item-1',
          'donation_id': 'donation-1',
          'category': 'kaos',
          'size_code': 'L',
          'age_group': 'dewasa',
          'quantity': 10,
        }
      ];

      final builder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(itemsData),
      );
      when(() => mockQuery.select()).thenAnswer((_) => builder);

      final items =
          await logisticsService.fetchDonationItemsForCuration('donation-1');

      expect(items.length, 1);
      expect(items.first.id, 'item-1');
      expect(items.first.category, 'kaos');
      expect(items.first.quantity, 10);
    });

    test('fetchInventoryBatches returns batches for given point', () async {
      final mockQuery = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('inventory_batches'))
          .thenAnswer((_) => mockQuery);

      final batchData = [
        {
          'id': 'batch-1',
          'inspection_id': 'insp-1',
          'point_id': 'point-1',
          'category': 'celana',
          'size_code': 'M',
          'age_group': 'dewasa',
          'initial_qty': 5,
          'on_hand_qty': 5,
          'reserved_qty': 0,
        }
      ];

      final builder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(batchData),
      );
      when(() => mockQuery.select()).thenAnswer((_) => builder);

      final batches =
          await logisticsService.fetchInventoryBatches(pointId: 'point-1');

      expect(batches.length, 1);
      expect(batches.first.id, 'batch-1');
      expect(batches.first.category, 'celana');
      expect(batches.first.availableQty, 5);
    });

    test('fetchAllocations queries allocations and returns list', () async {
      final mockQuery = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('allocations'))
          .thenAnswer((_) => mockQuery);

      final allocData = [
        {
          'id': 'alloc-1',
          'batch_id': 'batch-1',
          'need_item_id': 'need-1',
          'quantity': 10,
          'status': 'reserved',
          'request_key': 'key-1',
          'created_by': 'user-1',
          'created_at': '2026-10-31T09:00:00Z',
          'category': 'kaos',
          'size_code': 'L',
        }
      ];

      final builder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(allocData),
      );
      when(() => mockQuery.select(any())).thenAnswer((_) => builder);

      final list = await logisticsService.fetchAllocations(status: 'reserved');

      expect(list.length, 1);
      expect(list.first.id, 'alloc-1');
      expect(list.first.quantity, 10);
    });

    test('fetchShipments queries shipments and returns list with items',
        () async {
      final mockQuery = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('shipments')).thenAnswer((_) => mockQuery);

      final shipData = [
        {
          'id': 'ship-1',
          'source_point_id': 'point-a',
          'destination_point_id': 'point-b',
          'status': 'ready',
          'created_at': '2026-10-31T10:00:00Z',
          'shipment_items': [],
        }
      ];

      final builder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(shipData),
      );
      when(() => mockQuery.select(any())).thenAnswer((_) => builder);

      final list = await logisticsService.fetchShipments(status: 'ready');

      expect(list.length, 1);
      expect(list.first.id, 'ship-1');
      expect(list.first.isReady, isTrue);
    });

    test('fetchShipments applies pointId or filter correctly', () async {
      final mockQuery = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('shipments')).thenAnswer((_) => mockQuery);

      final shipData = [
        {
          'id': 'ship-1',
          'source_point_id': 'point-a',
          'destination_point_id': 'point-b',
          'status': 'ready',
          'created_at': '2026-10-31T10:00:00Z',
          'shipment_items': [],
        }
      ];

      final builder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(shipData),
      );
      when(() => mockQuery.select(any())).thenAnswer((_) => builder);

      final list = await logisticsService.fetchShipments(
        pointId: 'point-a',
      );

      expect(list.length, 1);
      expect(list.first.sourcePointId, 'point-a');
    });

    test('fetchMatchingBatches filters on variant and on_hand_qty > 0',
        () async {
      final mockQuery = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('inventory_batches'))
          .thenAnswer((_) => mockQuery);

      final batchData = [
        {
          'id': 'batch-match-1',
          'inspection_id': 'insp-1',
          'point_id': 'point-1',
          'category': 'kaos',
          'size_code': 'M',
          'age_group': 'anak',
          'initial_qty': 12,
          'on_hand_qty': 10,
          'reserved_qty': 2,
        }
      ];

      final builder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(batchData),
      );
      when(() => mockQuery.select()).thenAnswer((_) => builder);

      final matches = await logisticsService.fetchMatchingBatches(
        category: 'kaos',
        sizeCode: 'M',
        ageGroup: 'anak',
      );

      expect(matches.length, 1);
      expect(matches.first.id, 'batch-match-1');
      expect(matches.first.availableQty, 8);
    });

    test('fetchMatchingBatches excludes fully reserved batches with availableQty == 0', () async {
      final mockQuery = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('inventory_batches'))
          .thenAnswer((_) => mockQuery);

      final batchData = [
        {
          'id': 'batch-fully-reserved',
          'inspection_id': 'insp-2',
          'point_id': 'point-1',
          'category': 'kaos',
          'size_code': 'M',
          'age_group': 'anak',
          'initial_qty': 5,
          'on_hand_qty': 5,
          'reserved_qty': 5,
        }
      ];

      final builder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(batchData),
      );
      when(() => mockQuery.select()).thenAnswer((_) => builder);

      final matches = await logisticsService.fetchMatchingBatches(
        category: 'kaos',
        sizeCode: 'M',
        ageGroup: 'anak',
      );

      expect(matches, isEmpty);
    });
  });
}
