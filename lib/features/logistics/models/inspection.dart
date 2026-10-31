class Inspection {
  final String id;
  final String itemId;
  final String pointId;
  final String inspectorId;
  final int passedQty;
  final int rejectedQty;
  final String? rejectionReason;
  final DateTime createdAt;

  const Inspection({
    required this.id,
    required this.itemId,
    required this.pointId,
    required this.inspectorId,
    required this.passedQty,
    required this.rejectedQty,
    this.rejectionReason,
    required this.createdAt,
  });

  int get totalQty => passedQty + rejectedQty;
  bool get hasRejection => rejectedQty > 0;

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      pointId: json['point_id'] as String,
      inspectorId: json['inspector_id'] as String,
      passedQty: (json['passed_qty'] as num).toInt(),
      rejectedQty: (json['rejected_qty'] as num).toInt(),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'point_id': pointId,
      'inspector_id': inspectorId,
      'passed_qty': passedQty,
      'rejected_qty': rejectedQty,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
