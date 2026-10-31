class OrganizationMembership {
  final String organizationId;
  final String orgName;
  final String kind;
  final bool verified;
  final bool active;

  const OrganizationMembership({
    required this.organizationId,
    required this.orgName,
    required this.kind,
    required this.verified,
    required this.active,
  });

  factory OrganizationMembership.fromMap(Map<String, dynamic> map) {
    return OrganizationMembership(
      organizationId: map['organization_id']?.toString() ?? '',
      orgName: map['org_name']?.toString() ?? '',
      kind: map['kind']?.toString() ?? 'social_institution',
      verified: map['verified'] == true,
      active: map['active'] == true,
    );
  }
}
