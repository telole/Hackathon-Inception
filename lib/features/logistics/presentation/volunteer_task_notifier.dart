import 'package:flutter/foundation.dart';
import '../../donation/models/donation.dart';
import '../models/inspection.dart';
import '../models/logistics_task.dart';
import '../services/logistics_service.dart';

class VolunteerTaskNotifier extends ChangeNotifier {
  final ILogisticsService _logisticsService;

  List<LogisticsTask> _activeTasks = [];
  List<LogisticsTask> _completedTasks = [];
  LogisticsTask? _selectedTask;
  List<DonationItem> _curationItems = [];
  Map<String, Inspection> _inspections = {};
  Map<String, dynamic>? _donorContact;
  int _selectionRequestId = 0;
  bool _isLoading = false;
  String? _errorMessage;

  VolunteerTaskNotifier({ILogisticsService? logisticsService})
      : _logisticsService = logisticsService ?? LogisticsService();

  List<LogisticsTask> get activeTasks => List.unmodifiable(_activeTasks);
  List<LogisticsTask> get completedTasks => List.unmodifiable(_completedTasks);
  LogisticsTask? get selectedTask => _selectedTask;
  List<DonationItem> get curationItems => List.unmodifiable(_curationItems);
  Map<String, Inspection> get inspections => Map.unmodifiable(_inspections);
  Map<String, dynamic>? get donorContact => _donorContact;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final active = await _logisticsService.fetchMyTasks(
        statuses: const ['assigned', 'accepted', 'in_progress'],
      );
      final completed = await _logisticsService.fetchMyTasks(
        statuses: const ['completed', 'declined', 'cancelled', 'failed'],
      );

      _activeTasks = active;
      _completedTasks = completed;

      // Keep selectedTask reference synchronized if still in list
      if (_selectedTask != null) {
        final match = active.cast<LogisticsTask?>().firstWhere(
              (t) => t?.id == _selectedTask!.id,
              orElse: () => completed.cast<LogisticsTask?>().firstWhere(
                    (t) => t?.id == _selectedTask!.id,
                    orElse: () => null,
                  ),
            );
        if (match != null) {
          _selectedTask = match;
        } else {
          _selectedTask = null;
          _curationItems = [];
          _inspections = {};
          _donorContact = null;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectTask(LogisticsTask task) async {
    final requestId = ++_selectionRequestId;
    _selectedTask = task;
    _curationItems = [];
    _inspections = {};
    _donorContact = null;
    _errorMessage = null;
    notifyListeners();

    final donationId = task.donationId;
    if (donationId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      List<DonationItem> items = [];
      Map<String, Inspection> inspections = {};
      Map<String, dynamic>? contact;

      if (task.isCuration) {
        final fetchedItems =
            await _logisticsService.fetchDonationItemsForCuration(donationId);
        final inspList =
            await _logisticsService.fetchInspectionsForDonation(donationId);

        items = fetchedItems;
        inspections = {for (final i in inspList) i.itemId: i};
      }

      if ((task.isPickup || task.isCuration) &&
          (task.isAccepted || task.isInProgress)) {
        try {
          contact = await _logisticsService.getDonationContact(donationId);
        } catch (_) {
          // Contact may be restricted if task is not active
          contact = null;
        }
      }

      // Guard against stale async responses if selection changed
      if (requestId != _selectionRequestId) return;

      _curationItems = items;
      _inspections = inspections;
      _donorContact = contact;
    } catch (e) {
      if (requestId != _selectionRequestId) return;
      _errorMessage = e.toString();
    } finally {
      if (requestId == _selectionRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> acceptTask(String taskId) async {
    return _respondToTask(taskId, 'accepted');
  }

  Future<bool> startTask(String taskId) async {
    return _respondToTask(taskId, 'in_progress');
  }

  Future<bool> completeTask(String taskId) async {
    return _respondToTask(taskId, 'completed');
  }

  Future<bool> declineTask(String taskId) async {
    return _respondToTask(taskId, 'declined');
  }

  Future<bool> _respondToTask(String taskId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _logisticsService.respondTask(taskId: taskId, status: status);
      await loadTasks();

      // If the currently selected task was updated, reload its context
      if (_selectedTask != null && _selectedTask!.id == taskId) {
        await selectTask(_selectedTask!);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> recordCuration({
    required String itemId,
    required int passedQty,
    required int rejectedQty,
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final batchId = await _logisticsService.recordInspection(
        itemId: itemId,
        passedQty: passedQty,
        rejectedQty: rejectedQty,
        reason: reason,
      );

      // Refresh inspection list and curation items for selected task
      if (_selectedTask != null && _selectedTask!.donationId != null) {
        final inspList = await _logisticsService
            .fetchInspectionsForDonation(_selectedTask!.donationId!);
        _inspections = {for (final i in inspList) i.itemId: i};
      }

      _isLoading = false;
      notifyListeners();
      return batchId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
