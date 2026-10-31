class InventoryBatch {
  final String id;
  final String inspectionId;
  final String pointId;
  final String category;
  final String sizeCode;
  final String ageGroup;
  final int initialQty;
  final int onHandQty;
  final int reservedQty;

  const InventoryBatch({
    required this.id,
    required this.inspectionId,
    required this.pointId,
    required this.category,
    required this.sizeCode,
    required this.ageGroup,
    required this.initialQty,
    required this.onHandQty,
    this.reservedQty = 0,
  });

  int get availableQty => onHandQty - reservedQty;

  factory InventoryBatch.fromJson(Map<String, dynamic> json) {
    return InventoryBatch(
      id: json['id'] as String,
      inspectionId: json['inspection_id'] as String,
      pointId: json['point_id'] as String,
      category: json['category'] as String,
      sizeCode: json['size_code'] as String,
      ageGroup: json['age_group'] as String,
      initialQty: (json['initial_qty'] as num).toInt(),
      onHandQty: (json['on_hand_qty'] as num).toInt(),
      reservedQty: (json['reserved_qty'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inspection_id': inspectionId,
      'point_id': pointId,
      'category': category,
      'size_code': sizeCode,
      'age_group': ageGroup,
      'initial_qty': initialQty,
      'on_hand_qty': onHandQty,
      'reserved_qty': reservedQty,
    };
  }
}
