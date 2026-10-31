enum LegalStatus {
  pending,
  approved,
  rejected,
}

class MitraLegalSubmission {
  final String id;
  final String orgName;
  final String orgCategory;
  final String legalNumber;
  final String documentFileName;
  final String picName;
  final String picPhone;
  final DateTime submittedAt;
  final LegalStatus status;
  final String? adminNotes;

  const MitraLegalSubmission({
    required this.id,
    required this.orgName,
    required this.orgCategory,
    required this.legalNumber,
    required this.documentFileName,
    required this.picName,
    required this.picPhone,
    required this.submittedAt,
    this.status = LegalStatus.pending,
    this.adminNotes,
  });

  MitraLegalSubmission copyWith({
    String? id,
    String? orgName,
    String? orgCategory,
    String? legalNumber,
    String? documentFileName,
    String? picName,
    String? picPhone,
    DateTime? submittedAt,
    LegalStatus? status,
    String? adminNotes,
  }) {
    return MitraLegalSubmission(
      id: id ?? this.id,
      orgName: orgName ?? this.orgName,
      orgCategory: orgCategory ?? this.orgCategory,
      legalNumber: legalNumber ?? this.legalNumber,
      documentFileName: documentFileName ?? this.documentFileName,
      picName: picName ?? this.picName,
      picPhone: picPhone ?? this.picPhone,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}

class CampaignNeed {
  final String id;
  final String orgName;
  final bool orgVerified;
  final String title;
  final String description;
  final String category;
  final int requestedQty;
  final int collectedQty;
  final String location;
  final bool isEmergency;
  final String deadline;
  final String imageUrl;

  const CampaignNeed({
    required this.id,
    required this.orgName,
    required this.orgVerified,
    required this.title,
    required this.description,
    required this.category,
    required this.requestedQty,
    required this.collectedQty,
    required this.location,
    this.isEmergency = false,
    required this.deadline,
    required this.imageUrl,
  });

  double get progressPercentage {
    if (requestedQty <= 0) return 0.0;
    final ratio = collectedQty / requestedQty;
    return ratio > 1.0 ? 1.0 : ratio;
  }
}

