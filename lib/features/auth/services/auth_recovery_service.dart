import 'package:supabase_flutter/supabase_flutter.dart';

/// Requires the same allow-listed callback in Supabase Auth and the mobile app.
class AuthRecoveryService {
  final SupabaseClient client;
  AuthRecoveryService({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;
  static const callback = 'com.resandang.resandang://auth-callback';
  Future<void> requestReset(
    String email, {
    String redirectTo = callback,
  }) async {
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  Future<void> resendConfirmation(
    String email, {
    String redirectTo = callback,
  }) async {
    await client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: redirectTo,
    );
  }

  Future<void> updatePassword(String password) async {
    if (client.auth.currentSession == null) {
      throw const AuthException('Open the recovery link first');
    }
    await client.auth.updateUser(UserAttributes(password: password));
  }
}
