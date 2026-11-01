import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pakaiankita/features/logistics/services/logistics_service.dart';
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

}
