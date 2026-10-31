import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/models/app_role.dart';
import '../../../core/models/user_access.dart';
import '../models/app_profile.dart';
import '../services/auth_service.dart';

abstract class IAuthRepository {
  User? get currentUser;
  Session? get currentSession;
  Stream<AuthState> get authStateChanges;
  bool get isAuthenticated;

  Future<AuthResponse> signIn({required String email, required String password});
  Future<AuthResponse> signUp({required String email, required String password, String? fullName});
  Future<void> signOut();
  Future<UserAccess> fetchAccess();
  Future<AppProfile?> fetchCurrentProfile();
  Future<void> requestRole(AppRole role);
  Future<String> requestOrganization({
    required String name,
    required String kind,
    required String area,
  });
  Future<void> updateProfile({String? displayName, String? avatarPath, String? area});
}

class AuthRepository implements IAuthRepository {
  final IAuthService _service;
  final SupabaseClient _client;

  AuthRepository({IAuthService? service, SupabaseClient? client})
      : _service = service ?? AuthService(client: client),
        _client = client ?? Supabase.instance.client;

  @override
  User? get currentUser => _service.currentUser;

  @override
  Session? get currentSession => _service.currentSession;

  @override
  Stream<AuthState> get authStateChanges => _service.authStateChanges;

  @override
  bool get isAuthenticated => _service.isAuthenticated;

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      return await _service.signIn(email: email, password: password);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      return await _service.signUp(email: email, password: password, fullName: fullName);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _service.signOut();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<UserAccess> fetchAccess() async {
    try {
      return await _service.fetchAccess();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<AppProfile?> fetchCurrentProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    try {
      final res = await _client
          .from('profiles')
          .select('id, full_name, role, avatar_url, phone, is_verified, created_at')
          .eq('id', uid)
          .maybeSingle();

      if (res != null) {
        return AppProfile.fromMap(res);
      }
      return null;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  @override
  Future<void> requestRole(AppRole role) async {
    try {
      await _service.requestRole(role);
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
      return await _service.requestOrganization(name: name, kind: kind, area: area);
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
    try {
      await _service.updateProfile(displayName: displayName, avatarPath: avatarPath, area: area);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
