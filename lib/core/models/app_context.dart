import '../../features/mitra/models/mitra_application.dart';
import 'app_role.dart';

enum RoleIntent {
  donatur,
  mitra;

  String get label => this == RoleIntent.donatur ? 'Donatur' : 'Mitra';
}

class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.kind,
    required this.area,
    required this.pointAddress,
    required this.contactName,
    required this.contactPhone,
    required this.verified,
    required this.active,
  });

  final String id;
  final String name;
  final String kind;
  final String area;
  final String pointAddress;
  final String contactName;
  final String contactPhone;
  final bool verified;
  final bool active;

  Organization copyWith({
    String? name,
    String? kind,
    String? area,
    String? pointAddress,
    String? contactName,
    String? contactPhone,
    bool? verified,
    bool? active,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      area: area ?? this.area,
      pointAddress: pointAddress ?? this.pointAddress,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      verified: verified ?? this.verified,
      active: active ?? this.active,
    );
  }
}

class AppContext {
  const AppContext({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.roles,
    required this.ui,
    required this.onboardingCompleted,
    this.roleIntent,
    this.mitraApplication,
    this.organization,
  });

  final String userId;
  final String displayName;
  final String email;
  final Set<AppRole> roles;
  final AppUiShell ui;
  final bool onboardingCompleted;
  final RoleIntent? roleIntent;
  final MitraApplication? mitraApplication;
  final Organization? organization;

  bool get isAdmin =>
      ui == AppUiShell.admin && roles.contains(AppRole.admin);

  bool get isVerifiedMitra =>
      roles.contains(AppRole.mitra) &&
      organization != null &&
      organization!.verified &&
      organization!.active;

  bool get hasPendingMitra =>
      mitraApplication != null && mitraApplication!.status.isPending;

  bool get hasRejectedMitra =>
      mitraApplication != null && mitraApplication!.status.isRejected;

  String get firstName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? displayName : parts.first;
  }

  List<AppRole> get sortedRoles {
    const order = [
      AppRole.donatur,
      AppRole.mitra,
      AppRole.relawan,
      AppRole.admin,
    ];
    final list = roles.toList()
      ..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return list;
  }
}
