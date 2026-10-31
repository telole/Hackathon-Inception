class NeedItem {
  final String id;
  final String needId;
  final String category;
  final String sizeCode;
  final String ageGroup;
  final int requestedQty;

  const NeedItem({
    required this.id,
    required this.needId,
    required this.category,
    required this.sizeCode,
    required this.ageGroup,
    required this.requestedQty,
  });

  factory NeedItem.fromJson(Map<String, dynamic> json) {
    return NeedItem(
      id: json['id'] as String,
      needId: json['need_id'] as String,
      category: json['category'] as String,
      sizeCode: json['size_code'] as String,
      ageGroup: json['age_group'] as String,
      requestedQty: (json['requested_qty'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'need_id': needId,
      'category': category,
      'size_code': sizeCode,
      'age_group': ageGroup,
      'requested_qty': requestedQty,
    };
  }
}

class Need {
  final String id;
  final String organizationId;
  final String pointId;
  final String? incidentId;
  final String title;
  final String? description;
  final DateTime deadlineAt;
  final String status;
  final DateTime createdAt;
  final List<NeedItem> items;
  final String? organizationName;
  final String? pointName;

  const Need({
    required this.id,
    required this.organizationId,
    required this.pointId,
    this.incidentId,
    required this.title,
    this.description,
    required this.deadlineAt,
    required this.status,
    required this.createdAt,
    this.items = const [],
    this.organizationName,
    this.pointName,
  });

  factory Need.fromJson(Map<String, dynamic> json) {
    final rawItems = json['need_items'];
    final List<NeedItem> parsedItems = [];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          parsedItems.add(NeedItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    String? orgName;
    final org = json['organizations'];
    if (org is Map) {
      orgName = org['name'] as String?;
    }

    String? ptName;
    final pt = json['collection_points'];
    if (pt is Map) {
      ptName = pt['name'] as String?;
    }

    return Need(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      pointId: json['point_id'] as String,
      incidentId: json['incident_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadlineAt: DateTime.parse(json['deadline_at'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: List.unmodifiable(parsedItems),
      organizationName: orgName,
      pointName: ptName,
    );
  }

  bool get isOpen => status == 'open' && deadlineAt.isAfter(DateTime.now());
  bool get isFulfilled => status == 'fulfilled';
}
