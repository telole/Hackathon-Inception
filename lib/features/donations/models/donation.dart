enum DonationStatus {
  submitted('Menunggu kurasi'),
  curated('Lolos kurasi'),
  shipped('Dalam pengiriman'),
  received('Diterima mitra');

  const DonationStatus(this.label);
  final String label;
}

enum DonationMethod {
  dropOff('Antar ke titik kumpul'),
  pickup('Dijemput relawan');

  const DonationMethod(this.label);
  final String label;
}

class Donation {
  const Donation({
    required this.id,
    required this.userId,
    required this.needId,
    required this.needTitle,
    required this.organizationName,
    required this.category,
    required this.sizeLabel,
    required this.quantity,
    required this.method,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final String userId;
  final String needId;
  final String needTitle;
  final String organizationName;
  final String category;
  final String sizeLabel;
  final int quantity;
  final DonationMethod method;
  final DateTime scheduledAt;
  final DonationStatus status;
  final DateTime createdAt;
  final String note;

  String get itemSummary => '$quantity pakaian · $category · $sizeLabel';
}
