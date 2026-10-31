import 'app_role.dart';

class UserAccess {
  final List<AppRole> roles;
  final AppUiShell ui;

  const UserAccess({
    required this.roles,
    required this.ui,
  });

  factory UserAccess.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserAccess(roles: [], ui: AppUiShell.user);
    }

    final rawRoles = json['roles'];
    final List<AppRole> parsedRoles = [];
    if (rawRoles is List) {
      for (final r in rawRoles) {
        if (r is String) {
          final role = AppRole.fromString(r);
          if (role != null) {
            parsedRoles.add(role);
          }
        }
      }
    }

    final rawUi = json['ui'] as String?;
    final ui = AppUiShell.fromString(rawUi);

    return UserAccess(
      roles: List.unmodifiable(parsedRoles),
      ui: ui,
    );
  }

  bool get isDonatur => roles.contains(AppRole.donatur);
  bool get isRelawan => roles.contains(AppRole.relawan);
  bool get isMitra => roles.contains(AppRole.mitra);
  bool get isAdmin => roles.contains(AppRole.admin) || ui == AppUiShell.admin;

  static const empty = UserAccess(roles: [], ui: AppUiShell.user);

  @override
  String toString() => 'UserAccess(roles: $roles, ui: $ui)';
}
