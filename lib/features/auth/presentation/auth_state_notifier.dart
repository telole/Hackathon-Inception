import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_access.dart';
import '../services/auth_service.dart';

class AuthStateNotifier extends ChangeNotifier {
  final IAuthService _authService;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isDisposed = false;
  int _authOperationGeneration = 0;

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
    final opId = ++_authOperationGeneration;
    final event = state.event;
    final session = state.session;

    if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.tokenRefreshed ||
        event == AuthChangeEvent.userUpdated) {
      if (session != null) {
        _currentUser = session.user;
        _isAwaitingEmailConfirmation = false;
        try {
          final access = await _authService.fetchAccess();
          if (opId != _authOperationGeneration ||
              _currentUser != session.user) {
            return;
          }
          _currentAccess = access;
        } catch (e) {
          if (opId != _authOperationGeneration ||
              _currentUser != session.user) {
            return;
          }
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
    final opId = ++_authOperationGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      _currentUser = user;
      if (user != null) {
        final access = await _authService.fetchAccess();
        if (opId != _authOperationGeneration ||
            _currentUser != user) {
          return;
        }
        _currentAccess = access;
      } else {
        _currentAccess = UserAccess.empty;
      }
    } catch (e) {
      if (opId != _authOperationGeneration) return;
      _errorMessage = _parseError(e);
      _currentAccess = UserAccess.empty;
    } finally {
      if (opId == _authOperationGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    final opId = ++_authOperationGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signIn(
        email: email.trim(),
        password: password,
      );
      final user = response.user ?? _authService.currentUser;
      _currentUser = user;
      _isAwaitingEmailConfirmation = false;
      if (user != null) {
        final access = await _authService.fetchAccess();
        if (opId != _authOperationGeneration ||
            _currentUser != user) {
          return false;
        }
        _currentAccess = access;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (opId != _authOperationGeneration) return false;
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
    final opId = ++_authOperationGeneration;
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
        final user = response.user ?? _authService.currentUser;
        _currentUser = user;
        _isAwaitingEmailConfirmation = false;
        if (user != null) {
          final access = await _authService.fetchAccess();
          if (opId != _authOperationGeneration ||
              _currentUser != user) {
            return false;
          }
          _currentAccess = access;
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (opId != _authOperationGeneration) return false;
      _errorMessage = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    ++_authOperationGeneration;
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
    final user = _currentUser;
    if (user == null) return;
    final opId = ++_authOperationGeneration;
    try {
      final access = await _authService.fetchAccess();
      if (opId != _authOperationGeneration ||
          _currentUser != user) {
        return;
      }
      _currentAccess = access;
      notifyListeners();
    } catch (e) {
      if (opId != _authOperationGeneration) return;
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
