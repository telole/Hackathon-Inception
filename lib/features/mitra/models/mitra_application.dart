import 'dart:typed_data';

enum MitraApplicationStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected;

  String get label {
    switch (this) {
      case MitraApplicationStatus.draft:
        return 'Draft';
      case MitraApplicationStatus.submitted:
        return 'Menunggu verifikasi';
      case MitraApplicationStatus.underReview:
        return 'Sedang ditinjau';
      case MitraApplicationStatus.approved:
        return 'Disetujui';
      case MitraApplicationStatus.rejected:
        return 'Ditolak';
    }
  }

  bool get isPending =>
      this == MitraApplicationStatus.submitted ||
      this == MitraApplicationStatus.underReview;

  bool get isApproved => this == MitraApplicationStatus.approved;

  bool get isRejected => this == MitraApplicationStatus.rejected;
}

/// Dokumen legalitas. Bytes hanya ada di memori; mode simulasi memakai
/// dokumen contoh dan tidak menyimpan berkas asli.
class MitraDocument {
  const MitraDocument({
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    this.bytes,
    this.isSample = false,
  });

  final String name;
  final int sizeBytes;
  final String mimeType;
  final Uint8List? bytes;
  final bool isSample;

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  MitraDocument copyWith({
    String? name,
    int? sizeBytes,
    String? mimeType,
    Uint8List? bytes,
    bool? isSample,
  }) {
    return MitraDocument(
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      bytes: bytes ?? this.bytes,
      isSample: isSample ?? this.isSample,
    );
  }
}

class MitraApplication {
  const MitraApplication({
    required this.id,
    required this.userId,
    required this.applicantName,
    required this.applicantEmail,
    required this.organizationName,
    required this.organizationKind,
    required this.area,
    required this.pointAddress,
    required this.contactName,
    required this.contactPhone,
    required this.legalNumber,
    required this.legalIssuer,
    this.legalIssuedAt,
    this.beneficiaryEstimate,
    this.documents = const [],
    this.status = MitraApplicationStatus.draft,
    this.reviewNote,
    this.submittedAt,
    this.reviewedAt,
    this.organizationId,
  });

  final String id;
  final String userId;
  final String applicantName;
  final String applicantEmail;
  final String organizationName;
  final String organizationKind;
  final String area;
  final String pointAddress;
  final String contactName;
  final String contactPhone;
  final int? beneficiaryEstimate;
  final String legalNumber;
  final String legalIssuer;
  final DateTime? legalIssuedAt;
  final List<MitraDocument> documents;
  final MitraApplicationStatus status;
  final String? reviewNote;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? organizationId;

  bool get hasRequiredDocument => documents.isNotEmpty;

  static const Object _unset = Object();

  MitraApplication copyWith({
    String? id,
    String? userId,
    String? applicantName,
    String? applicantEmail,
    String? organizationName,
    String? organizationKind,
    String? area,
    String? pointAddress,
    String? contactName,
    String? contactPhone,
    int? beneficiaryEstimate,
    String? legalNumber,
    String? legalIssuer,
    DateTime? legalIssuedAt,
    List<MitraDocument>? documents,
    MitraApplicationStatus? status,
    Object? reviewNote = _unset,
    DateTime? submittedAt,
    Object? reviewedAt = _unset,
    String? organizationId,
  }) {
    return MitraApplication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      organizationName: organizationName ?? this.organizationName,
      organizationKind: organizationKind ?? this.organizationKind,
      area: area ?? this.area,
      pointAddress: pointAddress ?? this.pointAddress,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      beneficiaryEstimate: beneficiaryEstimate ?? this.beneficiaryEstimate,
      legalNumber: legalNumber ?? this.legalNumber,
      legalIssuer: legalIssuer ?? this.legalIssuer,
      legalIssuedAt: legalIssuedAt ?? this.legalIssuedAt,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      reviewNote: identical(reviewNote, _unset)
          ? this.reviewNote
          : reviewNote as String?,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: identical(reviewedAt, _unset)
          ? this.reviewedAt
          : reviewedAt as DateTime?,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}
