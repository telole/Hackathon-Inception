class LogisticsTask {
  final String id;
  final String? donationId;
  final String pointId;
  final String? assignedTo;
  final String kind; // 'pickup', 'curation', 'delivery'
  final String status; // 'assigned', 'accepted', 'in_progress', 'completed', 'declined', 'cancelled', 'failed'
  final DateTime? scheduledAt;
  final String? notes;
  final DateTime createdAt;

  // Joined metadata (optional)
  final String? pointName;
  final String? donationTrackingCode;

  const LogisticsTask({
    required this.id,
    this.donationId,
    required this.pointId,
    this.assignedTo,
    required this.kind,
    required this.status,
    this.scheduledAt,
    this.notes,
    required this.createdAt,
    this.pointName,
    this.donationTrackingCode,
  });

  bool get isAssigned => status == 'assigned';
  bool get isAccepted => status == 'accepted';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';
  bool get isFailed => status == 'failed';

  bool get isPickup => kind == 'pickup';
  bool get isCuration => kind == 'curation';
  bool get isDelivery => kind == 'delivery';

  bool get isActive => isAssigned || isAccepted || isInProgress;

  factory LogisticsTask.fromJson(Map<String, dynamic> json) {
    String? pointName;
    if (json['collection_points'] is Map<String, dynamic>) {
      pointName = json['collection_points']['name'] as String?;
    } else if (json['point_name'] is String) {
      pointName = json['point_name'] as String;
    }

    String? donationTrackingCode;
    if (json['donations'] is Map<String, dynamic>) {
      donationTrackingCode =
          json['donations']['tracking_code'] as String?;
    } else if (json['tracking_code'] is String) {
      donationTrackingCode = json['tracking_code'] as String;
    }

    return LogisticsTask(
      id: json['id'] as String,
      donationId: json['donation_id'] as String?,
      pointId: json['point_id'] as String,
      assignedTo: json['assigned_to'] as String?,
      kind: json['kind'] as String,
      status: json['status'] as String? ?? 'assigned',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      pointName: pointName,
      donationTrackingCode: donationTrackingCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (donationId != null) 'donation_id': donationId,
      'point_id': pointId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      'kind': kind,
      'status': status,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (pointName != null) 'point_name': pointName,
      if (donationTrackingCode != null)
        'tracking_code': donationTrackingCode,
    };
  }
}
