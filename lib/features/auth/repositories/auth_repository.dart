import '../../../core/models/app_context.dart';

/// Kontrak auth. Implementasi hari ini: DemoRepository.
abstract class AuthRepository {
  Future<AppContext> signIn({
    required String email,
    required String password,
  });

  Future<AppContext> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<AppContext> signInWithGoogle();

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  Future<AppContext> loadAccess(String userId);

  Future<AppContext> chooseRole({
    required String userId,
    required RoleIntent intent,
  });
}
