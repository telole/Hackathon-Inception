class DonationItem {
  final String id;
  final String donationId;
  final String category;
  final String sizeCode;
  final String ageGroup;
  final int quantity;

  const DonationItem({
    required this.id,
    required this.donationId,
    required this.category,
    required this.sizeCode,
    required this.ageGroup,
    required this.quantity,
  });

  factory DonationItem.fromJson(Map<String, dynamic> json) {
    return DonationItem(
      id: json['id'] as String,
      donationId: json['donation_id'] as String,
      category: json['category'] as String,
      sizeCode: json['size_code'] as String,
      ageGroup: json['age_group'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donation_id': donationId,
      'category': category,
      'size_code': sizeCode,
      'age_group': ageGroup,
      'quantity': quantity,
    };
  }
}

class DonationPhoto {
  final String id;
  final String donationId;
  final String storagePath;
  final DateTime createdAt;

  const DonationPhoto({
    required this.id,
    required this.donationId,
    required this.storagePath,
    required this.createdAt,
  });

  factory DonationPhoto.fromJson(Map<String, dynamic> json) {
    return DonationPhoto(
      id: json['id'] as String,
      donationId: json['donation_id'] as String,
      storagePath: json['storage_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DonationEvent {
  final int id;
  final String donationId;
  final String eventType;
  final String summary;
  final String? actorId;
  final DateTime createdAt;

  const DonationEvent({
    required this.id,
    required this.donationId,
    required this.eventType,
    required this.summary,
    this.actorId,
    required this.createdAt,
  });

  factory DonationEvent.fromJson(Map<String, dynamic> json) {
    return DonationEvent(
      id: (json['id'] as num).toInt(),
      donationId: json['donation_id'] as String,
      eventType: json['event_type'] as String,
      summary: json['summary'] as String,
      actorId: json['actor_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Donation {
  final String id;
  final String donorId;
  final String trackingCode;
  final String? pointId;
  final String? preferredNeedId;
  final String method;
  final String status;
  final bool cleanCheck;
  final bool intactCheck;
  final bool notTornCheck;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final List<DonationItem> items;
  final List<DonationPhoto> photos;

  const Donation({
    required this.id,
    required this.donorId,
    required this.trackingCode,
    this.pointId,
    this.preferredNeedId,
    required this.method,
    required this.status,
    required this.cleanCheck,
    required this.intactCheck,
    required this.notTornCheck,
    this.scheduledAt,
    required this.createdAt,
    this.items = const [],
    this.photos = const [],
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    final rawItems = json['donation_items'];
    final List<DonationItem> parsedItems = [];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          parsedItems.add(DonationItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawPhotos = json['donation_photos'];
    final List<DonationPhoto> parsedPhotos = [];
    if (rawPhotos is List) {
      for (final photo in rawPhotos) {
        if (photo is Map) {
          parsedPhotos.add(DonationPhoto.fromJson(Map<String, dynamic>.from(photo)));
        }
      }
    }

    return Donation(
      id: json['id'] as String,
      donorId: json['donor_id'] as String,
      trackingCode: json['tracking_code'] as String,
      pointId: json['point_id'] as String?,
      preferredNeedId: json['preferred_need_id'] as String?,
      method: json['method'] as String,
      status: json['status'] as String,
      cleanCheck: json['clean_check'] as bool? ?? false,
      intactCheck: json['intact_check'] as bool? ?? false,
      notTornCheck: json['not_torn_check'] as bool? ?? false,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: List.unmodifiable(parsedItems),
      photos: List.unmodifiable(parsedPhotos),
    );
  }

  bool get isChecklistComplete => cleanCheck && intactCheck && notTornCheck;
  bool get hasValidPhotoCount => photos.isNotEmpty && photos.length <= 5;
  bool get isReadyToSubmit =>
      isChecklistComplete &&
      hasValidPhotoCount &&
      items.isNotEmpty &&
      pointId != null &&
      status == 'draft';
}
