import 'package:flutter/foundation.dart';
import '../models/donation.dart';
import '../services/donation_service.dart';

class DonationNotifier extends ChangeNotifier {
  final IDonationService _donationService;

  bool _isLoading = false;
  String? _errorMessage;
  List<Donation> _myDonations = const [];
  List<DonationEvent> _timeline = const [];

  DonationNotifier({IDonationService? donationService})
      : _donationService = donationService ?? DonationService();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Donation> get myDonations => _myDonations;
  List<DonationEvent> get timeline => _timeline;

  Future<void> loadMyDonations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myDonations = await _donationService.fetchMyDonations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> startNewDraft({
    required String method,
    String? pointId,
    String? preferredNeedId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _donationService.createDraftDonation(
        method: method,
        pointId: pointId,
        preferredNeedId: preferredNeedId,
      );
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addItemToDraft({
    required String donationId,
    required String category,
    required String sizeCode,
    required String ageGroup,
    required int quantity,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _donationService.addDonationItem(
        donationId: donationId,
        category: category,
        sizeCode: sizeCode,
        ageGroup: ageGroup,
        quantity: quantity,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateChecklist({
    required String donationId,
    required bool clean,
    required bool intact,
    required bool notTorn,
  }) async {
    try {
      await _donationService.updateChecklist(
        donationId: donationId,
        clean: clean,
        intact: intact,
        notTorn: notTorn,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitDraft(String donationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _donationService.submitDonation(donationId);
      await loadMyDonations();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadTimeline(String donationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _timeline = await _donationService.fetchDonationTimeline(donationId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
