enum NeedStatus {
  open,
  fulfilled,
  closed;

  String get label {
    switch (this) {
      case NeedStatus.open:
        return 'Terbuka';
      case NeedStatus.fulfilled:
        return 'Tercukupi';
      case NeedStatus.closed:
        return 'Ditutup';
    }
  }
}

enum NeedCategory {
  anak('Pakaian anak'),
  dewasa('Pakaian dewasa'),
  bayi('Pakaian bayi'),
  sekolah('Perlengkapan sekolah'),
  lainnya('Lainnya');

  const NeedCategory(this.label);
  final String label;
}

class NeedItem {
  const NeedItem({
    required this.category,
    required this.sizeLabel,
    required this.ageGroup,
    required this.requestedQty,
    required this.receivedQty,
  });

  final NeedCategory category;
  final String sizeLabel;
  final String ageGroup;
  final int requestedQty;
  final int receivedQty;

  int get remainingQty => (requestedQty - receivedQty).clamp(0, requestedQty);

  String get summary => '${category.label} · $sizeLabel · $ageGroup';
}

class Need {
  const Need({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.organizationVerified,
    required this.title,
    required this.description,
    required this.city,
    required this.pointName,
    required this.pointAddress,
    required this.deadline,
    required this.items,
    required this.createdAt,
    this.status = NeedStatus.open,
    this.urgent = false,
  });

  final String id;
  final String organizationId;
  final String organizationName;
  final bool organizationVerified;
  final String title;
  final String description;
  final String city;
  final String pointName;
  final String pointAddress;
  final DateTime deadline;
  final List<NeedItem> items;
  final DateTime createdAt;
  final NeedStatus status;
  final bool urgent;

  int get requestedQty =>
      items.fold(0, (total, item) => total + item.requestedQty);

  int get receivedQty =>
      items.fold(0, (total, item) => total + item.receivedQty);

  int get remainingQty => (requestedQty - receivedQty).clamp(0, requestedQty);

  double get progress =>
      requestedQty == 0 ? 0 : (receivedQty / requestedQty).clamp(0, 1);

  String get itemSummary => items.isEmpty ? 'Pakaian layak pakai' : items.first.summary;

  bool get isOpen => status == NeedStatus.open && remainingQty > 0;

  Need copyWith({
    String? organizationName,
    bool? organizationVerified,
    String? title,
    String? description,
    String? city,
    String? pointName,
    String? pointAddress,
    DateTime? deadline,
    List<NeedItem>? items,
    NeedStatus? status,
    bool? urgent,
  }) {
    return Need(
      id: id,
      organizationId: organizationId,
      organizationName: organizationName ?? this.organizationName,
      organizationVerified: organizationVerified ?? this.organizationVerified,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      pointName: pointName ?? this.pointName,
      pointAddress: pointAddress ?? this.pointAddress,
      deadline: deadline ?? this.deadline,
      items: items ?? this.items,
      createdAt: createdAt,
      status: status ?? this.status,
      urgent: urgent ?? this.urgent,
    );
  }
}
