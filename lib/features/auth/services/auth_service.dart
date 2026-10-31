import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_access.dart';

abstract class IAuthService {
  User? get currentUser;
  Session? get currentSession;
  Stream<AuthState> get authStateChanges;
  bool get isAuthenticated;
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  });
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<UserAccess> fetchAccess();
}

class AuthService implements IAuthService {
  final SupabaseClient _client;

  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  bool get isAuthenticated => currentUser != null;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final Map<String, dynamic> data = {};
    if (fullName != null && fullName.trim().isNotEmpty) {
      data['full_name'] = fullName.trim();
    }
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: data.isNotEmpty ? data : null,
    );
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<UserAccess> fetchAccess() async {
    if (currentUser == null) {
      return UserAccess.empty;
    }

    try {
      final res = await _client.rpc('my_access');
      if (res is Map<String, dynamic>) {
        return UserAccess.fromJson(res);
      } else if (res is Map) {
        return UserAccess.fromJson(Map<String, dynamic>.from(res));
      }
      return UserAccess.empty;
    } catch (_) {
      // Re-throw or return empty access depending on contract.
      // Returning empty access triggers safe fallback to restricted viewer.
      return UserAccess.empty;
    }
  }
}
