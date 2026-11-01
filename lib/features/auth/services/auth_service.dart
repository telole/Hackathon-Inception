import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/models/app_role.dart';
import '../../../core/models/user_access.dart';
import '../../../core/services/supabase_client_provider.dart';

abstract class IAuthService {
  User? get currentUser;
  Session? get currentSession;
  Stream<AuthState> get authStateChanges;
  bool get isAuthenticated;
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? displayName,
  });
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<UserAccess> fetchAccess();
  Future<void> requestRole(AppRole role);
  Future<String> requestOrganization({
    required String name,
    required String kind,
    required String area,
  });
  Future<void> updateProfile({
    String? displayName,
    String? avatarPath,
    String? area,
  });
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
    String? displayName,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      final name = displayName ?? fullName;
      if (name != null && name.trim().isNotEmpty) {
        data['display_name'] = name.trim();
      }
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: data.isNotEmpty ? data : null,
      );
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<UserAccess> fetchAccess() async {
    if (currentUser == null) {
      return UserAccess.empty;
    }

    // Match the installed backend contract and let connection/permission errors
    // reach the caller instead of treating them as an empty permission set.
    final result = await _client.rpc('my_access');
    if (result is Map) {
      return UserAccess.fromJson(Map<String, dynamic>.from(result));
    }
    throw StateError('Invalid access context returned by the server.');
  }

  @override
  Future<void> requestRole(AppRole role) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      await _client.rpc(
        'request_role',
        params: {'p_role': role.name, 'p_request_key': key},
      );
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<String> requestOrganization({
    required String name,
    required String kind,
    required String area,
  }) async {
    try {
      final key = SupabaseClientProvider.newRequestKey();
      final res = await _client.rpc(
        'request_organization',
        params: {
          'p_name': name,
          'p_kind': kind,
          'p_area': area,
          'p_request_key': key,
        },
      );
      return res.toString();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? avatarPath,
    String? area,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarPath != null) updates['avatar_path'] = avatarPath;
      if (area != null) updates['area'] = area;

      if (updates.isNotEmpty) {
        await _client.from('profiles').update(updates).eq('id', uid);
      }
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
