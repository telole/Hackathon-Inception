class LogisticsTaskModel {
  final String id;
  final String? donationId;
  final String? pointId;
  final String? volunteerId;
  final String kind;
  final String status;
  final DateTime? scheduledAt;
  final String? notes;
  final DateTime createdAt;

  const LogisticsTaskModel({
    required this.id,
    this.donationId,
    this.pointId,
    this.volunteerId,
    required this.kind,
    required this.status,
    this.scheduledAt,
    this.notes,
    required this.createdAt,
  });

  factory LogisticsTaskModel.fromMap(Map<String, dynamic> map) {
    return LogisticsTaskModel(
      id: map['id']?.toString() ?? '',
      donationId: map['donation_id']?.toString(),
      pointId: map['point_id']?.toString(),
      volunteerId: map['volunteer_id']?.toString(),
      kind: map['kind']?.toString() ?? map['task_kind']?.toString() ?? 'pickup',
      status: map['status']?.toString() ?? 'assigned',
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.tryParse(map['scheduled_at'].toString())
          : null,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donation_id': donationId,
      'point_id': pointId,
      'volunteer_id': volunteerId,
      'kind': kind,
      'status': status,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
