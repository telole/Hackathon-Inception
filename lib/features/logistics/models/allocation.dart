class Allocation {
  final String id;
  final String batchId;
  final String needItemId;
  final int quantity;
  final String status; // 'reserved', 'dispatched', 'received', 'disputed', 'cancelled'
  final String requestKey;
  final String createdBy;
  final DateTime createdAt;

  // Joined metadata (optional)
  final String? batchCategory;
  final String? batchSizeCode;
  final String? needTitle;
  final String? organizationName;

  const Allocation({
    required this.id,
    required this.batchId,
    required this.needItemId,
    required this.quantity,
    required this.status,
    required this.requestKey,
    required this.createdBy,
    required this.createdAt,
    this.batchCategory,
    this.batchSizeCode,
    this.needTitle,
    this.organizationName,
  });

  bool get isReserved => status == 'reserved';
  bool get isDispatched => status == 'dispatched';
  bool get isReceived => status == 'received';
  bool get isCancelled => status == 'cancelled';

  factory Allocation.fromJson(Map<String, dynamic> json) {
    String? batchCategory;
    String? batchSizeCode;
    if (json['inventory_batches'] is Map<String, dynamic>) {
      batchCategory = json['inventory_batches']['category'] as String?;
      batchSizeCode = json['inventory_batches']['size_code'] as String?;
    } else {
      batchCategory = json['category'] as String?;
      batchSizeCode = json['size_code'] as String?;
    }

    String? needTitle;
    String? organizationName;
    if (json['need_items'] is Map<String, dynamic>) {
      final needItems = json['need_items'] as Map<String, dynamic>;
      if (needItems['needs'] is Map<String, dynamic>) {
        final needs = needItems['needs'] as Map<String, dynamic>;
        needTitle = needs['title'] as String?;
        if (needs['organizations'] is Map<String, dynamic>) {
          organizationName =
              needs['organizations']['name'] as String?;
        }
      }
    }

    return Allocation(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      needItemId: json['need_item_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      status: json['status'] as String? ?? 'reserved',
      requestKey: json['request_key'] as String,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      batchCategory: batchCategory,
      batchSizeCode: batchSizeCode,
      needTitle: needTitle,
      organizationName: organizationName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'need_item_id': needItemId,
      'quantity': quantity,
      'status': status,
      'request_key': requestKey,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (batchCategory != null) 'category': batchCategory,
      if (batchSizeCode != null) 'size_code': batchSizeCode,
      if (needTitle != null) 'need_title': needTitle,
      if (organizationName != null) 'organization_name': organizationName,
    };
  }
}
