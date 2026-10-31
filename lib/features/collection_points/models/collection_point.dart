class CollectionPoint {
  final String id;
  final String organizationId;
  final String name;
  final String publicAddress;
  final double? latitude;
  final double? longitude;
  final String? openingHours;
  final int? capacityPieces;
  final bool active;

  const CollectionPoint({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.publicAddress,
    this.latitude,
    this.longitude,
    this.openingHours,
    this.capacityPieces,
    required this.active,
  });

  factory CollectionPoint.fromJson(Map<String, dynamic> json) {
    return CollectionPoint(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      publicAddress: json['public_address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      openingHours: json['opening_hours'] as String?,
      capacityPieces: (json['capacity_pieces'] as num?)?.toInt(),
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'public_address': publicAddress,
      'latitude': latitude,
      'longitude': longitude,
      'opening_hours': openingHours,
      'capacity_pieces': capacityPieces,
      'active': active,
    };
  }
}
