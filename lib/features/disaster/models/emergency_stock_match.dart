class EmergencyStockMatch {
  final String batchId;
  final String pointId;
  final String pointName;
  final String? pointAddress;
  final String category;
  final String sizeCode;
  final String ageGroup;
  final int availableQty;
  final int matchedQty;

  const EmergencyStockMatch({
    required this.batchId,
    required this.pointId,
    required this.pointName,
    this.pointAddress,
    required this.category,
    required this.sizeCode,
    required this.ageGroup,
    required this.availableQty,
    required this.matchedQty,
  });

  bool get isFullMatch => matchedQty >= availableQty;

  factory EmergencyStockMatch.fromJson(Map<String, dynamic> json) {
    return EmergencyStockMatch(
      batchId: json['batch_id'] as String,
      pointId: json['point_id'] as String,
      pointName: json['point_name'] as String? ?? 'Posko Bantuan',
      pointAddress: json['point_address'] as String?,
      category: json['category'] as String,
      sizeCode: json['size_code'] as String,
      ageGroup: json['age_group'] as String,
      availableQty: (json['available_qty'] as num).toInt(),
      matchedQty: (json['matched_qty'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_id': batchId,
      'point_id': pointId,
      'point_name': pointName,
      if (pointAddress != null) 'point_address': pointAddress,
      'category': category,
      'size_code': sizeCode,
      'age_group': ageGroup,
      'available_qty': availableQty,
      'matched_qty': matchedQty,
    };
  }
}
