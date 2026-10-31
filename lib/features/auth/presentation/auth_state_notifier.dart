import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_access.dart';
import '../services/auth_service.dart';

class AuthStateNotifier extends ChangeNotifier {
  final IAuthService _authService;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isDisposed = false;

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  UserAccess _currentAccess = UserAccess.empty;
  bool _isAwaitingEmailConfirmation = false;

  AuthStateNotifier({IAuthService? authService})
      : _authService = authService ?? AuthService() {
    try {
      _authSubscription = _authService.authStateChanges.listen(
        _handleAuthStateChange,
        onError: (e) {
          _errorMessage = _parseError(e);
          notifyListeners();
        },
      );
    } catch (_) {
      // In tests where authStateChanges stream is not stubbed
    }
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  UserAccess get currentAccess => _currentAccess;
  bool get isAuthenticated =>
      _currentUser != null && !_isAwaitingEmailConfirmation;
  bool get isAwaitingEmailConfirmation => _isAwaitingEmailConfirmation;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _handleAuthStateChange(AuthState state) async {
    final event = state.event;
    final session = state.session;

    if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.tokenRefreshed ||
        event == AuthChangeEvent.userUpdated) {
      if (session != null) {
        _currentUser = session.user;
        _isAwaitingEmailConfirmation = false;
        try {
          _currentAccess = await _authService.fetchAccess();
        } catch (e) {
          _errorMessage = _parseError(e);
          _currentAccess = UserAccess.empty;
        }
      }
    } else if (event == AuthChangeEvent.signedOut) {
      _currentUser = null;
      _currentAccess = UserAccess.empty;
      _isAwaitingEmailConfirmation = false;
      _errorMessage = null;
    }
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        _currentAccess = await _authService.fetchAccess();
      } else {
        _currentAccess = UserAccess.empty;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
      _currentAccess = UserAccess.empty;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signIn(
        email: email.trim(),
        password: password,
      );
      _currentUser = response.user ?? _authService.currentUser;
      _isAwaitingEmailConfirmation = false;
      _currentAccess = await _authService.fetchAccess();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(
    String email,
    String password, {
    String? fullName,
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isAwaitingEmailConfirmation = false;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        email: email.trim(),
        password: password,
        fullName: fullName,
        displayName: displayName,
      );

      // Distinguish registered user awaiting email confirmation from active session
      if (response.user != null && response.session == null) {
        _currentUser = response.user;
        _isAwaitingEmailConfirmation = true;
        _currentAccess = UserAccess.empty;
      } else {
        _currentUser = response.user ?? _authService.currentUser;
        _isAwaitingEmailConfirmation = false;
        if (_currentUser != null) {
          _currentAccess = await _authService.fetchAccess();
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
    } finally {
      _currentUser = null;
      _currentAccess = UserAccess.empty;
      _isAwaitingEmailConfirmation = false;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAccess() async {
    if (_currentUser == null) return;
    try {
      _currentAccess = await _authService.fetchAccess();
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  String _parseError(Object error) {
    if (error is AuthException) {
      return error.message;
    }
    final str = error.toString();
    if (str.contains('42501') || str.contains('FORBIDDEN')) {
      return 'Akses ditolak: Anda tidak memiliki izin untuk tindakan ini.';
    }
    return str;
  }
}
