class Shipment {
  final String id;
  final String sourcePointId;
  final String destinationPointId;
  final String? assignedTo;
  final String status; // 'ready', 'in_transit', 'received', 'disputed', 'cancelled'
  final String? receivedBy;
  final DateTime? dispatchedAt;
  final DateTime? receivedAt;
  final DateTime createdAt;
  final List<ShipmentItem> items;

  // Joined metadata (optional)
  final String? sourcePointName;
  final String? destinationPointName;
  final String? volunteerName;

  const Shipment({
    required this.id,
    required this.sourcePointId,
    required this.destinationPointId,
    this.assignedTo,
    required this.status,
    this.receivedBy,
    this.dispatchedAt,
    this.receivedAt,
    required this.createdAt,
    this.items = const [],
    this.sourcePointName,
    this.destinationPointName,
    this.volunteerName,
  });

  bool get isReady => status == 'ready';
  bool get isInTransit => status == 'in_transit';
  bool get isReceived => status == 'received';
  bool get isDisputed => status == 'disputed';
  bool get isCancelled => status == 'cancelled';

  factory Shipment.fromJson(Map<String, dynamic> json) {
    String? sourcePointName;
    if (json['source_point'] is Map<String, dynamic>) {
      sourcePointName = json['source_point']['name'] as String?;
    } else if (json['source_point_name'] is String) {
      sourcePointName = json['source_point_name'] as String;
    }

    String? destinationPointName;
    if (json['destination_point'] is Map<String, dynamic>) {
      destinationPointName = json['destination_point']['name'] as String?;
    } else if (json['destination_point_name'] is String) {
      destinationPointName = json['destination_point_name'] as String;
    }

    String? volunteerName;
    if (json['profiles'] is Map<String, dynamic>) {
      volunteerName = json['profiles']['display_name'] as String?;
    } else if (json['volunteer_name'] is String) {
      volunteerName = json['volunteer_name'] as String;
    }

    final rawItems = json['shipment_items'];
    final itemsList = <ShipmentItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          itemsList.add(ShipmentItem.fromJson(item));
        }
      }
    }

    return Shipment(
      id: json['id'] as String,
      sourcePointId: json['source_point_id'] as String,
      destinationPointId: json['destination_point_id'] as String,
      assignedTo: json['assigned_to'] as String?,
      status: json['status'] as String? ?? 'ready',
      receivedBy: json['received_by'] as String?,
      dispatchedAt: json['dispatched_at'] != null
          ? DateTime.tryParse(json['dispatched_at'] as String)
          : null,
      receivedAt: json['received_at'] != null
          ? DateTime.tryParse(json['received_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: itemsList,
      sourcePointName: sourcePointName,
      destinationPointName: destinationPointName,
      volunteerName: volunteerName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_point_id': sourcePointId,
      'destination_point_id': destinationPointId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      'status': status,
      if (receivedBy != null) 'received_by': receivedBy,
      if (dispatchedAt != null)
        'dispatched_at': dispatchedAt!.toIso8601String(),
      if (receivedAt != null) 'received_at': receivedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'shipment_items': items.map((i) => i.toJson()).toList(),
      if (sourcePointName != null) 'source_point_name': sourcePointName,
      if (destinationPointName != null)
        'destination_point_name': destinationPointName,
      if (volunteerName != null) 'volunteer_name': volunteerName,
    };
  }
}

class ShipmentItem {
  final String id;
  final String shipmentId;
  final String allocationId;
  final int quantity;
  final int? receivedGood;
  final int? rejected;
  final int? missing;

  const ShipmentItem({
    required this.id,
    required this.shipmentId,
    required this.allocationId,
    required this.quantity,
    this.receivedGood,
    this.rejected,
    this.missing,
  });

  bool get isConfirmed =>
      receivedGood != null || rejected != null || missing != null;

  factory ShipmentItem.fromJson(Map<String, dynamic> json) {
    return ShipmentItem(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      allocationId: json['allocation_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      receivedGood: (json['received_good'] as num?)?.toInt(),
      rejected: (json['rejected'] as num?)?.toInt(),
      missing: (json['missing'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'allocation_id': allocationId,
      'quantity': quantity,
      if (receivedGood != null) 'received_good': receivedGood,
      if (rejected != null) 'rejected': rejected,
      if (missing != null) 'missing': missing,
    };
  }
}
