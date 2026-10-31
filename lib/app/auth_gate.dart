import 'package:flutter/material.dart';

import '../features/admin/presentation/admin_shell.dart';
import '../features/auth/presentation/auth_flow.dart';
import '../features/auth/presentation/role_intent_screen.dart';
import '../features/mitra/presentation/mitra_application_screen.dart';
import '../features/mitra/presentation/mitra_status_screen.dart';
import '../features/user/presentation/user_shell.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'session_error_screen.dart';
import 'splash_screen.dart';

/// Gerbang tunggal yang memetakan fase sesi ke layar yang tepat.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final Widget screen;
    switch (controller.phase) {
      case SessionPhase.initializing:
        screen = const SplashScreen(key: ValueKey('phase-splash'));
      case SessionPhase.signedOut:
        screen = const AuthFlow(key: ValueKey('phase-signed-out'));
      case SessionPhase.needsRole:
        screen = const RoleIntentScreen(key: ValueKey('phase-role-intent'));
      case SessionPhase.mitraApplication:
        screen = const MitraApplicationScreen(key: ValueKey('phase-mitra-form'));
      case SessionPhase.pendingMitra:
        screen = const MitraStatusScreen(key: ValueKey('phase-mitra-status'));
      case SessionPhase.authenticated:
        final contextData = controller.context;
        screen = contextData != null && contextData.isAdmin
            ? const AdminShell(key: ValueKey('phase-admin'))
            : const UserShell(key: ValueKey('phase-user'));
      case SessionPhase.failure:
        screen = SessionErrorScreen(
          key: const ValueKey('phase-failure'),
          message: controller.failureMessage ?? 'Sesi tidak dapat dimuat.',
          onRetry: controller.retryFromFailure,
          onSignOut: controller.signOut,
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: screen,
    );
  }
}
