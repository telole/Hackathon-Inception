import 'package:flutter/foundation.dart';
import '../../needs/models/need.dart';
import '../models/emergency_stock_match.dart';
import '../models/incident.dart';
import '../services/disaster_service.dart';

class DisasterNotifier extends ChangeNotifier {
  final IDisasterService _disasterService;

  List<Incident> _activeIncidents = [];
  List<Incident> _allIncidents = [];
  Incident? _selectedIncident;
  List<Need> _emergencyNeeds = [];
  List<EmergencyStockMatch> _stockMatches = [];
  bool _isDisasterMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  DisasterNotifier({IDisasterService? disasterService})
      : _disasterService = disasterService ?? DisasterService();

  List<Incident> get activeIncidents => List.unmodifiable(_activeIncidents);
  List<Incident> get allIncidents => List.unmodifiable(_allIncidents);
  Incident? get selectedIncident => _selectedIncident;
  List<Need> get emergencyNeeds => List.unmodifiable(_emergencyNeeds);
  List<EmergencyStockMatch> get stockMatches =>
      List.unmodifiable(_stockMatches);
  bool get isDisasterMode => _isDisasterMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setDisasterMode(bool enabled) {
    _isDisasterMode = enabled;
    notifyListeners();
  }

  Future<void> loadIncidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final active = await _disasterService.fetchActiveIncidents();
      final all = await _disasterService.fetchAllIncidents();

      _activeIncidents = active;
      _allIncidents = all;

      if (active.isNotEmpty) {
        _isDisasterMode = true;
        _selectedIncident = active.first;
        await loadEmergencyNeeds(incidentId: active.first.id);
      } else {
        _isDisasterMode = false;
        _selectedIncident = null;
        _emergencyNeeds = [];
        _stockMatches = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectIncident(Incident? incident) async {
    _selectedIncident = incident;
    _stockMatches = [];
    _errorMessage = null;

    if (incident != null) {
      _isDisasterMode = true;
      await loadEmergencyNeeds(incidentId: incident.id);
    } else {
      _isDisasterMode = false;
      _emergencyNeeds = [];
      _stockMatches = [];
      notifyListeners();
    }
  }

  Future<void> loadEmergencyNeeds({String? incidentId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _emergencyNeeds =
          await _disasterService.fetchEmergencyNeeds(incidentId: incidentId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> findMatchesForNeedItem({
    required String category,
    required String sizeCode,
    required String ageGroup,
    required int requestedQty,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stockMatches = await _disasterService.findPreCuratedStockForEmergency(
        category: category,
        sizeCode: sizeCode,
        ageGroup: ageGroup,
        requestedQty: requestedQty,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> declareEmergency({
    required String organizationId,
    required String title,
    String? area,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _disasterService.requestDisasterDeclaration(
        organizationId: organizationId,
        title: title,
        area: area,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      await loadIncidents();
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> approveDisaster(String incidentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _disasterService.approveDisaster(incidentId: incidentId);
      await loadIncidents();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeDisaster(String incidentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _disasterService.closeDisaster(incidentId: incidentId);
      await loadIncidents();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
