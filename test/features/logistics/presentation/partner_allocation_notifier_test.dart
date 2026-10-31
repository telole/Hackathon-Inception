import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/features/logistics/models/allocation.dart';
import 'package:resandang/features/logistics/models/inventory_batch.dart';
import 'package:resandang/features/logistics/models/shipment.dart';
import 'package:resandang/features/logistics/presentation/partner_allocation_notifier.dart';
import 'package:resandang/features/logistics/services/logistics_service.dart';

class MockLogisticsService extends Mock implements ILogisticsService {}

void main() {
  late MockLogisticsService mockService;
  late PartnerAllocationNotifier notifier;

  final sampleAllocation = Allocation(
    id: 'alloc-1',
    batchId: 'batch-1',
    needItemId: 'need-item-1',
    quantity: 5,
    status: 'reserved',
    requestKey: 'key-1',
    createdBy: 'mitra-1',
    createdAt: DateTime.parse('2026-10-31T10:00:00Z'),
  );

  final sampleShipment = Shipment(
    id: 'ship-1',
    sourcePointId: 'point-a',
    destinationPointId: 'point-b',
    status: 'ready',
    createdAt: DateTime.parse('2026-10-31T11:00:00Z'),
  );

  final sampleBatch = const InventoryBatch(
    id: 'batch-1',
    inspectionId: 'insp-1',
    pointId: 'point-a',
    category: 'kaos',
    sizeCode: 'M',
    ageGroup: 'anak',
    initialQty: 10,
    onHandQty: 10,
    reservedQty: 0,
  );

  setUp(() {
    mockService = MockLogisticsService();
    notifier = PartnerAllocationNotifier(logisticsService: mockService);
  });

  group('PartnerAllocationNotifier', () {
    test('initial state has empty lists and not loading', () {
      expect(notifier.allocations, isEmpty);
      expect(notifier.shipments, isEmpty);
      expect(notifier.matchingBatches, isEmpty);
      expect(notifier.selectedShipment, isNull);
      expect(notifier.isLoading, isFalse);
      expect(notifier.errorMessage, isNull);
    });

    test('loadAllocations loads allocations on success', () async {
      when(() => mockService.fetchAllocations(
            needItemId: any(named: 'needItemId'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [sampleAllocation]);

      await notifier.loadAllocations();

      expect(notifier.allocations.length, 1);
      expect(notifier.allocations.first.id, 'alloc-1');
      expect(notifier.isLoading, isFalse);
      expect(notifier.errorMessage, isNull);
    });

    test('loadAllocations sets errorMessage on failure', () async {
      when(() => mockService.fetchAllocations(
            needItemId: any(named: 'needItemId'),
            status: any(named: 'status'),
          )).thenThrow(Exception('Failed to fetch allocations'));

      await notifier.loadAllocations();

      expect(notifier.allocations, isEmpty);
      expect(notifier.errorMessage, contains('Failed to fetch allocations'));
      expect(notifier.isLoading, isFalse);
    });

    test('loadShipments loads shipments on success', () async {
      when(() => mockService.fetchShipments(
            status: any(named: 'status'),
            pointId: any(named: 'pointId'),
          )).thenAnswer((_) async => [sampleShipment]);

      await notifier.loadShipments();

      expect(notifier.shipments.length, 1);
      expect(notifier.shipments.first.id, 'ship-1');
      expect(notifier.isLoading, isFalse);
    });

    test('findMatchingBatches finds batches with matching variant', () async {
      when(() => mockService.fetchMatchingBatches(
            category: 'kaos',
            sizeCode: 'M',
            ageGroup: 'anak',
          )).thenAnswer((_) async => [sampleBatch]);

      await notifier.findMatchingBatches(
        category: 'kaos',
        sizeCode: 'M',
        ageGroup: 'anak',
      );

      expect(notifier.matchingBatches.length, 1);
      expect(notifier.matchingBatches.first.id, 'batch-1');
      expect(notifier.isLoading, isFalse);
    });

    test('reserveStock reserves allocation and reloads allocations list',
        () async {
      when(() => mockService.reserveAllocation(
            batchId: 'batch-1',
            needItemId: 'need-1',
            quantity: 5,
            requestKey: 'key-123',
          )).thenAnswer((_) async => 'alloc-1');

      when(() => mockService.fetchAllocations(
            needItemId: any(named: 'needItemId'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [sampleAllocation]);

      final result = await notifier.reserveStock(
        batchId: 'batch-1',
        needItemId: 'need-1',
        quantity: 5,
        requestKey: 'key-123',
      );

      expect(result, 'alloc-1');
      expect(notifier.allocations.length, 1);
    });

    test('createShipmentForAllocation creates shipment and reloads lists',
        () async {
      when(() => mockService.createShipment(
            allocationId: 'alloc-1',
            volunteerId: 'vol-1',
          )).thenAnswer((_) async => 'ship-1');

      when(() => mockService.fetchShipments(
            status: any(named: 'status'),
            pointId: any(named: 'pointId'),
          )).thenAnswer((_) async => [sampleShipment]);
      when(() => mockService.fetchAllocations(
            needItemId: any(named: 'needItemId'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => []);

      final result = await notifier.createShipmentForAllocation(
        allocationId: 'alloc-1',
        volunteerId: 'vol-1',
      );

      expect(result, 'ship-1');
      expect(notifier.shipments.length, 1);
    });

    test('selectShipment loads shipment detail', () async {
      when(() => mockService.fetchShipmentDetail('ship-1'))
          .thenAnswer((_) async => sampleShipment);

      await notifier.selectShipment('ship-1');

      expect(notifier.selectedShipment?.id, 'ship-1');
    });

    test('confirmShipmentReceipt confirms receipt and refreshes detail',
        () async {
      when(() => mockService.confirmReceipt(
            shipmentId: 'ship-1',
            goodQty: 5,
            rejectedQty: 0,
            missingQty: 0,
          )).thenAnswer((_) async {});

      when(() => mockService.fetchShipments(
            status: any(named: 'status'),
            pointId: any(named: 'pointId'),
          )).thenAnswer((_) async => [sampleShipment]);
      when(() => mockService.fetchShipmentDetail('ship-1'))
          .thenAnswer((_) async => sampleShipment);

      // Select first
      await notifier.selectShipment('ship-1');

      final success = await notifier.confirmShipmentReceipt(
        shipmentId: 'ship-1',
        goodQty: 5,
        rejectedQty: 0,
        missingQty: 0,
      );

      expect(success, isTrue);
      verify(() => mockService.confirmReceipt(
            shipmentId: 'ship-1',
            goodQty: 5,
            rejectedQty: 0,
            missingQty: 0,
          )).called(1);
    });
  });
}
