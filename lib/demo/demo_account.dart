import '../../core/models/app_context.dart';
import '../../core/models/app_role.dart';

/// Akun demo yang dipakai repository mock dan daftar pengguna admin.
class DemoAccount {
  DemoAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.roles,
    this.ui = AppUiShell.user,
    this.onboardingCompleted = false,
    this.roleIntent,
    this.organizationId,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final Set<AppRole> roles;
  final AppUiShell ui;
  bool onboardingCompleted;
  RoleIntent? roleIntent;
  String? organizationId;

  bool get isAdmin =>
      ui == AppUiShell.admin && roles.contains(AppRole.admin);

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'PK';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length > 1 ? 2 : 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
