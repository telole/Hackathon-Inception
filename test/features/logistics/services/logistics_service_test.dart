import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/features/logistics/services/logistics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

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
}

void main() {
  late MockSupabaseClient mockSupabase;
  late LogisticsService logisticsService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    logisticsService = LogisticsService(client: mockSupabase);
  });

  group('LogisticsService', () {
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

    test('recordInspection calls record_inspection RPC and returns batchId', () async {
      const itemId = 'item-uuid-1';
      const createdBatchId = 'batch-uuid-1';
      final builder = FakePostgrestFilterBuilder<dynamic>(Future.value(createdBatchId));
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

    test('reserveAllocation calls reserve_allocation RPC with idempotency key', () async {
      const batchId = 'batch-1';
      const needItemId = 'need-item-1';
      const requestKey = 'key-uuid-1';
      const allocationId = 'alloc-uuid-1';
      final builder = FakePostgrestFilterBuilder<dynamic>(Future.value(allocationId));
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
  });
}
