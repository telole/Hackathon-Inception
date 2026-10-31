import 'package:flutter/foundation.dart';
import '../models/need.dart';
import '../services/needs_service.dart';

class NeedsNotifier extends ChangeNotifier {
  final INeedsService _needsService;

  bool _isLoading = false;
  String? _errorMessage;
  List<Need> _needs = const [];
  String? _selectedCategory;
  String? _selectedAgeGroup;
  String? _selectedSizeCode;

  NeedsNotifier({INeedsService? needsService})
      : _needsService = needsService ?? NeedsService();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Need> get needs => _needs;
  String? get selectedCategory => _selectedCategory;
  String? get selectedAgeGroup => _selectedAgeGroup;
  String? get selectedSizeCode => _selectedSizeCode;

  void setFilters({String? category, String? ageGroup, String? sizeCode}) {
    _selectedCategory = category;
    _selectedAgeGroup = ageGroup;
    _selectedSizeCode = sizeCode;
    loadNeeds();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedAgeGroup = null;
    _selectedSizeCode = null;
    loadNeeds();
  }

  Future<void> loadNeeds() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _needs = await _needsService.fetchOpenNeeds(
        category: _selectedCategory,
        ageGroup: _selectedAgeGroup,
        sizeCode: _selectedSizeCode,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
