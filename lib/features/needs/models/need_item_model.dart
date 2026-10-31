class NeedModel {
  final String id;
  final String organizationId;
  final String organizationName;
  final String pointId;
  final String? pointName;
  final String? incidentId;
  final String? incidentTitle;
  final String title;
  final String description;
  final DateTime deadlineAt;
  final String status;
  final List<NeedItemLine> lines;
  final bool isEmergency;

  NeedModel({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.pointId,
    this.pointName,
    this.incidentId,
    this.incidentTitle,
    required this.title,
    required this.description,
    required this.deadlineAt,
    required this.status,
    required this.lines,
    this.isEmergency = false,
  });

  int get totalRequestedQty => lines.fold(0, (sum, l) => sum + l.requestedQty);
  int get totalReceivedQty => lines.fold(0, (sum, l) => sum + l.receivedQty);
  int get totalAllocatedQty => lines.fold(0, (sum, l) => sum + l.allocatedQty);
  int get totalRemainingQty => lines.fold(0, (sum, l) => sum + l.remainingQty);

  factory NeedModel.fromMap(Map<String, dynamic> map) {
    final org = map['organizations'] as Map<String, dynamic>?;
    final linesRaw = (map['lines'] ?? map['need_items']) as List<dynamic>? ?? [];

    return NeedModel(
      id: map['id']?.toString() ?? '',
      organizationId: map['organization_id']?.toString() ?? '',
      organizationName: map['organization_name']?.toString() ?? org?['name']?.toString() ?? 'Lembaga Sosial',
      pointId: map['point_id']?.toString() ?? '',
      pointName: map['point_name']?.toString(),
      incidentId: map['incident_id']?.toString(),
      incidentTitle: map['incident_title']?.toString(),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      deadlineAt: DateTime.tryParse(map['deadline_at']?.toString() ?? '') ?? DateTime.now(),
      status: map['status']?.toString() ?? 'open',
      isEmergency: map['incident_id'] != null,
      lines: linesRaw.map((e) => NeedItemLine.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }
}

class NeedItemLine {
  final String id;
  final String category;
  final String sizeCode;
  final String ageGroup;
  final int requestedQty;
  final int receivedQty;
  final int allocatedQty;
  final int reservedQty;
  final int dispatchedQty;
  final int remainingQty;

  NeedItemLine({
    required this.id,
    required this.category,
    required this.sizeCode,
    required this.ageGroup,
    required this.requestedQty,
    this.receivedQty = 0,
    this.allocatedQty = 0,
    this.reservedQty = 0,
    this.dispatchedQty = 0,
    int? remainingQty,
  }) : remainingQty = remainingQty ?? (requestedQty - receivedQty - reservedQty - dispatchedQty).clamp(0, requestedQty);

  factory NeedItemLine.fromMap(Map<String, dynamic> map) {
    final req = (map['requested_qty'] as num?)?.toInt() ?? 0;
    final rec = (map['received_qty'] as num?)?.toInt() ?? 0;
    final res = (map['reserved_qty'] as num?)?.toInt() ?? 0;
    final disp = (map['dispatched_qty'] as num?)?.toInt() ?? 0;
    final rem = (map['remaining_qty'] as num?)?.toInt();

    return NeedItemLine(
      id: map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      sizeCode: map['size_code']?.toString() ?? '',
      ageGroup: map['age_group']?.toString() ?? '',
      requestedQty: req,
      receivedQty: rec,
      reservedQty: res,
      dispatchedQty: disp,
      allocatedQty: (map['allocated_qty'] as num?)?.toInt() ?? (res + disp),
      remainingQty: rem,
    );
  }
}
