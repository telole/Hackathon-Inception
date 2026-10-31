import 'package:flutter/foundation.dart';

import '../core/models/app_context.dart';
import '../demo/demo_repository.dart';
import '../features/mitra/models/mitra_application.dart';

enum SessionPhase {
  initializing,
  signedOut,
  needsRole,
  mitraApplication,
  pendingMitra,
  authenticated,
  failure,
}

class AppController extends ChangeNotifier {
  AppController(this.repository) {
    repository.addListener(_handleRepositoryChange);
  }

  final DemoRepository repository;

  SessionPhase _phase = SessionPhase.initializing;
  AppContext? _context;
  bool _pendingDismissed = false;
  String? _failureMessage;

  SessionPhase get phase => _phase;
  AppContext? get context => _context;
  String? get failureMessage => _failureMessage;
  bool get isInitializing => _phase == SessionPhase.initializing;

  Future<void> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _phase = SessionPhase.signedOut;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    final next = await repository.signIn(email: email, password: password);
    _apply(next);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final next = await repository.signUp(
      name: name,
      email: email,
      password: password,
    );
    _apply(next);
  }

  Future<void> signInWithGoogle() async {
    final next = await repository.signInWithGoogle();
    _apply(next);
  }

  Future<void> signOut() async {
    await repository.signOut();
    _context = null;
    _pendingDismissed = false;
    _failureMessage = null;
    _phase = SessionPhase.signedOut;
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) =>
      repository.sendPasswordReset(email);

  Future<void> chooseRole(RoleIntent intent) async {
    final current = _requireContext();
    final next = await repository.chooseRole(
      userId: current.userId,
      intent: intent,
    );
    _pendingDismissed = false;
    _apply(next);
  }

  Future<void> startMitraApplication() async {
    final current = _requireContext();
    if (current.hasPendingMitra) {
      showPendingStatus();
      return;
    }
    final next = await repository.chooseRole(
      userId: current.userId,
      intent: RoleIntent.mitra,
    );
    _context = next;
    _phase = SessionPhase.mitraApplication;
    notifyListeners();
  }

  Future<void> cancelMitraApplication() async {
    final current = _requireContext();
    final application = current.mitraApplication;
    if (application != null &&
        (application.status.isPending || application.status.isRejected)) {
      _phase = SessionPhase.pendingMitra;
      notifyListeners();
      return;
    }
    final next = await repository.chooseRole(
      userId: current.userId,
      intent: RoleIntent.donatur,
    );
    _context = next;
    _pendingDismissed = true;
    _phase = SessionPhase.authenticated;
    notifyListeners();
  }

  Future<void> saveMitraDraft(MitraApplication application) async {
    final saved = await repository.saveDraft(application);
    final current = _requireContext();
    final updated = repository.peekAccess(current.userId);
    if (updated != null) _context = updated;
    _phase = SessionPhase.mitraApplication;
    debugPrint('Draft pengajuan mitra disimpan: ${saved.id}');
    notifyListeners();
  }

  Future<void> submitMitraApplication(MitraApplication application) async {
    await repository.submit(application);
    final current = _requireContext();
    final updated = await repository.loadAccess(current.userId);
    _context = updated;
    _pendingDismissed = false;
    _phase = SessionPhase.pendingMitra;
    notifyListeners();
  }

  Future<void> reviseMitraApplication() async {
    _phase = SessionPhase.mitraApplication;
    notifyListeners();
  }

  void showPendingStatus() {
    _pendingDismissed = false;
    _phase = SessionPhase.pendingMitra;
    notifyListeners();
  }

  void continueAsDonor() {
    _pendingDismissed = true;
    _phase = SessionPhase.authenticated;
    notifyListeners();
  }

  Future<void> approveApplication(String applicationId) async {
    final current = _requireContext();
    await repository.approve(applicationId, adminId: current.userId);
  }

  Future<void> rejectApplication(String applicationId, String reason) async {
    final current = _requireContext();
    await repository.reject(
      applicationId,
      adminId: current.userId,
      reason: reason,
    );
  }

  Future<void> refreshSession() async {
    final current = _context;
    if (current == null) return;
    try {
      final next = await repository.loadAccess(current.userId);
      _context = next;
      _phase = _phaseFor(next);
      notifyListeners();
    } catch (_) {
      _failureMessage = 'Sesi tidak dapat dimuat ulang. Coba lagi.';
      _phase = SessionPhase.failure;
      notifyListeners();
    }
  }

  Future<void> resetDemo() async {
    repository.reset();
    _context = null;
    _pendingDismissed = false;
    _failureMessage = null;
    _phase = SessionPhase.signedOut;
    notifyListeners();
  }

  void retryFromFailure() {
    _phase = _context == null ? SessionPhase.signedOut : _phaseFor(_context!);
    notifyListeners();
  }

  AppContext _requireContext() {
    final current = _context;
    if (current == null) {
      throw StateError('Belum ada sesi aktif.');
    }
    return current;
  }

  void _apply(AppContext next) {
    _context = next;
    _pendingDismissed = false;
    _phase = _phaseFor(next);
    notifyListeners();
  }

  SessionPhase _phaseFor(AppContext context) {
    if (!context.onboardingCompleted) return SessionPhase.needsRole;
    if (context.roleIntent == RoleIntent.mitra) {
      final application = context.mitraApplication;
      if (application == null) return SessionPhase.mitraApplication;
      if (application.status == MitraApplicationStatus.draft) {
        return SessionPhase.mitraApplication;
      }
      if (application.status.isPending || application.status.isRejected) {
        return _pendingDismissed
            ? SessionPhase.authenticated
            : SessionPhase.pendingMitra;
      }
      return SessionPhase.authenticated;
    }
    return SessionPhase.authenticated;
  }

  void _handleRepositoryChange() {
    final current = _context;
    if (current != null) {
      final updated = repository.peekAccess(current.userId);
      if (updated != null) {
        _context = updated;
        _phase = _phaseFor(updated);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    repository.removeListener(_handleRepositoryChange);
    super.dispose();
  }
}
