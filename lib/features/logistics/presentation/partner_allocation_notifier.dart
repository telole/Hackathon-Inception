import 'package:flutter/foundation.dart';
import '../models/allocation.dart';
import '../models/inventory_batch.dart';
import '../models/shipment.dart';
import '../services/logistics_service.dart';

class PartnerAllocationNotifier extends ChangeNotifier {
  final ILogisticsService _logisticsService;

  List<Allocation> _allocations = [];
  List<Shipment> _shipments = [];
  List<InventoryBatch> _matchingBatches = [];
  Shipment? _selectedShipment;
  bool _isLoading = false;
  String? _errorMessage;

  PartnerAllocationNotifier({ILogisticsService? logisticsService})
      : _logisticsService = logisticsService ?? LogisticsService();

  List<Allocation> get allocations => List.unmodifiable(_allocations);
  List<Shipment> get shipments => List.unmodifiable(_shipments);
  List<InventoryBatch> get matchingBatches =>
      List.unmodifiable(_matchingBatches);
  Shipment? get selectedShipment => _selectedShipment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllocations({
    String? needItemId,
    String? status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allocations = await _logisticsService.fetchAllocations(
        needItemId: needItemId,
        status: status,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadShipments({
    String? status,
    String? pointId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _shipments = await _logisticsService.fetchShipments(
        status: status,
        pointId: pointId,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> findMatchingBatches({
    required String category,
    required String sizeCode,
    required String ageGroup,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _matchingBatches = await _logisticsService.fetchMatchingBatches(
        category: category,
        sizeCode: sizeCode,
        ageGroup: ageGroup,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> reserveStock({
    required String batchId,
    required String needItemId,
    required int quantity,
    required String requestKey,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allocationId = await _logisticsService.reserveAllocation(
        batchId: batchId,
        needItemId: needItemId,
        quantity: quantity,
        requestKey: requestKey,
      );
      await loadAllocations();
      return allocationId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> createShipmentForAllocation({
    required String allocationId,
    required String volunteerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final shipmentId = await _logisticsService.createShipment(
        allocationId: allocationId,
        volunteerId: volunteerId,
      );
      await loadShipments();
      await loadAllocations();
      return shipmentId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> selectShipment(String shipmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedShipment =
          await _logisticsService.fetchShipmentDetail(shipmentId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmShipmentReceipt({
    required String shipmentId,
    required int goodQty,
    required int rejectedQty,
    required int missingQty,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _logisticsService.confirmReceipt(
        shipmentId: shipmentId,
        goodQty: goodQty,
        rejectedQty: rejectedQty,
        missingQty: missingQty,
      );
      await loadShipments();
      if (_selectedShipment != null && _selectedShipment!.id == shipmentId) {
        await selectShipment(shipmentId);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
