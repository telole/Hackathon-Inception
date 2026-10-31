import 'app_role.dart';
import '../../features/auth/models/app_profile.dart';
import '../../features/auth/models/organization_membership.dart';

class UserAccess {
  final List<AppRole> roles;
  final AppUiShell ui;
  final AppProfile? profile;
  final List<OrganizationMembership> memberships;

  const UserAccess({
    required this.roles,
    required this.ui,
    this.profile,
    this.memberships = const [],
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

    AppProfile? profile;
    if (json['profile'] is Map) {
      profile = AppProfile.fromMap(
        Map<String, dynamic>.from(json['profile'] as Map),
        defaultId: json['user_id']?.toString(),
      );
    }

    final List<OrganizationMembership> memberships = [];
    if (json['memberships'] is List) {
      for (final m in json['memberships']) {
        if (m is Map) {
          memberships.add(OrganizationMembership.fromMap(Map<String, dynamic>.from(m)));
        }
      }
    }

    return UserAccess(
      roles: List.unmodifiable(parsedRoles),
      ui: ui,
      profile: profile,
      memberships: List.unmodifiable(memberships),
    );
  }

  bool get isDonatur => roles.contains(AppRole.donatur);
  bool get isRelawan => roles.contains(AppRole.relawan);
  bool get isMitra => roles.contains(AppRole.mitra);
  bool get isAdmin => roles.contains(AppRole.admin) || ui == AppUiShell.admin;

  static const empty = UserAccess(roles: [], ui: AppUiShell.user);

  @override
  String toString() => 'UserAccess(roles: $roles, ui: $ui, profile: ${profile?.displayName})';
}