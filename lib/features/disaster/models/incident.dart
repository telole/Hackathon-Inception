class Incident {
  final String id;
  final String organizationId;
  final String title;
  final String? area;
  final String status; // 'requested', 'active', 'closed', 'rejected'
  final DateTime startsAt;
  final DateTime endsAt;
  final String? approvedBy;

  // Joined metadata (optional)
  final String? organizationName;

  const Incident({
    required this.id,
    required this.organizationId,
    required this.title,
    this.area,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    this.approvedBy,
    this.organizationName,
  });

  bool get isRequested => status == 'requested';
  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';
  bool get isRejected => status == 'rejected';

  bool isRunningAt(DateTime now) {
    return isActive &&
        now.isAfter(startsAt.subtract(const Duration(seconds: 1))) &&
        now.isBefore(endsAt);
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    String? orgName;
    if (json['organizations'] is Map<String, dynamic>) {
      orgName = json['organizations']['name'] as String?;
    } else if (json['organization_name'] is String) {
      orgName = json['organization_name'] as String;
    }

    return Incident(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      title: json['title'] as String,
      area: json['area'] as String?,
      status: json['status'] as String? ?? 'requested',
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      approvedBy: json['approved_by'] as String?,
      organizationName: orgName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'title': title,
      if (area != null) 'area': area,
      'status': status,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      if (approvedBy != null) 'approved_by': approvedBy,
      if (organizationName != null) 'organization_name': organizationName,
    };
  }
}
