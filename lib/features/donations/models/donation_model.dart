class DonationModel {
  final String id;
  final String trackingCode;
  final String? pointId;
  final String? preferredNeedId;
  final String method; // 'dropoff' atau 'pickup'
  final String status;
  final bool cleanCheck;
  final bool intactCheck;
  final bool notTornCheck;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final List<DonationItemModel> items;
  final List<String> photoPaths;
  final List<DonationEventModel> events;

  DonationModel({
    required this.id,
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
    this.photoPaths = const [],
    this.events = const [],
  });

  int get totalPieces => items.fold(0, (sum, i) => sum + i.quantity);

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draf Tersimpan';
      case 'submitted':
        return 'Diajukan / Menunggu Penjadwalan';
      case 'needs_revision':
        return 'Perlu Revisi';
      case 'scheduled':
        return 'Jadwal Penyerahan Ditetapkan';
      case 'received':
        return 'Diterima di Titik Kumpul';
      case 'curated':
        return 'Telah Terkurasi Fisik';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  factory DonationModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['donation_items'] as List<dynamic>? ?? [];
    final rawPhotos = map['donation_photos'] as List<dynamic>? ?? [];
    final rawEvents = map['donation_events'] as List<dynamic>? ?? [];

    return DonationModel(
      id: map['id'] ?? '',
      trackingCode: map['tracking_code'] ?? '',
      pointId: map['point_id'],
      preferredNeedId: map['preferred_need_id'],
      method: map['method'] ?? 'dropoff',
      status: map['status'] ?? 'draft',
      cleanCheck: map['clean_check'] ?? false,
      intactCheck: map['intact_check'] ?? false,
      notTornCheck: map['not_torn_check'] ?? false,
      scheduledAt: map['scheduled_at'] != null ? DateTime.tryParse(map['scheduled_at']) : null,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      items: rawItems.map((e) => DonationItemModel.fromMap(e as Map<String, dynamic>)).toList(),
      photoPaths: rawPhotos.map((e) => e['storage_path']?.toString() ?? '').toList(),
      events: rawEvents.map((e) => DonationEventModel.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DonationItemModel {
  final String id;
  final String category;
  final String sizeCode;
  final String ageGroup;
  final int quantity;

  DonationItemModel({
    required this.id,
    required this.category,
    required this.sizeCode,
    required this.ageGroup,
    required this.quantity,
  });

  factory DonationItemModel.fromMap(Map<String, dynamic> map) {
    return DonationItemModel(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      sizeCode: map['size_code'] ?? '',
      ageGroup: map['age_group'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class DonationEventModel {
  final int id;
  final String eventType;
  final String summary;
  final DateTime createdAt;

  DonationEventModel({
    required this.id,
    required this.eventType,
    required this.summary,
    required this.createdAt,
  });

  factory DonationEventModel.fromMap(Map<String, dynamic> map) {
    return DonationEventModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      eventType: map['event_type'] ?? '',
      summary: map['summary'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
