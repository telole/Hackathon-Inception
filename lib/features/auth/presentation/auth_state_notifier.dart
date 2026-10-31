import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/user_access.dart';
import '../services/auth_service.dart';

class AuthStateNotifier extends ChangeNotifier {
  final IAuthService _authService;
  StreamSubscription<AuthState>? _subscription;
  bool _disposed = false;
  int _command = 0, _accessRequest = 0, _sessionEpoch = 0;
  bool _isLoading = false, _awaitingConfirmation = false;
  String? _errorMessage;
  User? _currentUser;
  UserAccess _currentAccess = UserAccess.empty;

  AuthStateNotifier({IAuthService? authService})
    : _authService = authService ?? AuthService() {
    _subscription = _authService.authStateChanges.listen(
      _onAuth,
      onError: (Object error) {
        _errorMessage = _parseError(error);
        notifyListeners();
      },
    );
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  UserAccess get currentAccess => _currentAccess;
  bool get isAuthenticated => _currentUser != null && !_awaitingConfirmation;
  bool get isAwaitingEmailConfirmation => _awaitingConfirmation;
  bool _same(User? a, User? b) =>
      identical(a, b) || (a != null && b != null && a.id == b.id);
  void _setUser(User? user) {
    if (!_same(_currentUser, user)) {
      ++_sessionEpoch;
      ++_accessRequest;
      _currentAccess = UserAccess.empty;
    }
    _currentUser = user;
  }

  Future<bool> _loadAccess(User user) async {
    final epoch = _sessionEpoch;
    final request = ++_accessRequest;
    try {
      final access = await _authService.fetchAccess();
      if (_disposed || epoch != _sessionEpoch || !_same(user, _currentUser)) {
        return false;
      }
      if (request == _accessRequest) _currentAccess = access;
      return true;
    } catch (e) {
      if (_disposed || epoch != _sessionEpoch || request != _accessRequest) {
        return false;
      }
      _currentAccess = UserAccess.empty;
      rethrow;
    }
  }

  void _onAuth(AuthState state) async {
    if (_disposed) return;
    if (state.event == AuthChangeEvent.signedOut) {
      ++_command;
      ++_sessionEpoch;
      ++_accessRequest;
      _setUser(null);
      _currentAccess = UserAccess.empty;
      _awaitingConfirmation = false;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }
    final user = state.session?.user;
    if (user == null) return;
    _setUser(user);
    _awaitingConfirmation = false;
    final epoch = _sessionEpoch;
    try {
      await _loadAccess(user);
    } catch (e) {
      if (!_disposed && epoch == _sessionEpoch) _errorMessage = _parseError(e);
    }
    notifyListeners();
  }

  int _begin() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    return ++_command;
  }

  void _finish(int command) {
    if (!_disposed && command == _command) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    final command = _begin();
    try {
      final user = _authService.currentUser;
      _setUser(user);
      if (user != null) await _loadAccess(user);
    } catch (e) {
      if (command == _command) _errorMessage = _parseError(e);
    } finally {
      _finish(command);
    }
  }

  Future<bool> signIn(String email, String password) async {
    final command = _begin();
    final epoch = _sessionEpoch;
    try {
      final response = await _authService.signIn(
        email: email.trim(),
        password: password,
      );
      if (_disposed || command != _command) return false;
      final user = response.user ?? _authService.currentUser;
      if (user == null) throw const AuthException('No active user returned');
      // signedIn from this same login must not cancel its own command.
      if (epoch != _sessionEpoch && !_same(user, _currentUser)) return false;
      _setUser(user);
      _awaitingConfirmation = false;
      return await _loadAccess(user) && command == _command;
    } catch (e) {
      if (command == _command) _errorMessage = _parseError(e);
      return false;
    } finally {
      _finish(command);
    }
  }

  Future<bool> signUp(
    String email,
    String password, {
    String? fullName,
    String? displayName,
  }) async {
    final command = _begin();
    final epoch = _sessionEpoch;
    try {
      final response = await _authService.signUp(
        email: email.trim(),
        password: password,
        fullName: fullName,
        displayName: displayName,
      );
      if (_disposed || command != _command) return false;
      final user = response.user;
      if (user == null) throw const AuthException('No registration result');
      if (epoch != _sessionEpoch && !_same(user, _currentUser)) return false;
      _setUser(user);
      _awaitingConfirmation = response.session == null;
      if (_awaitingConfirmation) {
        _currentAccess = UserAccess.empty;
        return true;
      }
      return await _loadAccess(user) && command == _command;
    } catch (e) {
      if (command == _command) _errorMessage = _parseError(e);
      return false;
    } finally {
      _finish(command);
    }
  }

  Future<void> signOut() async {
    final command = _begin();
    ++_sessionEpoch;
    ++_accessRequest;
    _setUser(null);
    _currentAccess = UserAccess.empty;
    _awaitingConfirmation = false;
    try {
      await _authService.signOut();
    } catch (e) {
      if (command == _command) _errorMessage = _parseError(e);
      rethrow;
    } finally {
      _finish(command);
    }
  }

  Future<void> refreshAccess() async {
    final user = _currentUser;
    if (user == null || _awaitingConfirmation) return;
    final epoch = _sessionEpoch;
    try {
      await _loadAccess(user);
    } catch (e) {
      if (epoch == _sessionEpoch) _errorMessage = _parseError(e);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_command;
    ++_sessionEpoch;
    ++_accessRequest;
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  String _parseError(Object e) => e is AuthException ? e.message : e.toString();
}
