/// Kelas hierarki kegagalan domain untuk reSandang
/// Mengacu pada api-contracts.md Bagian 1 & architecture.md
sealed class AppFailure implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const AppFailure({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => '[$code] $message';
}

/// P1001 - Sesi tidak ada atau telah berakhir
class AuthRequiredFailure extends AppFailure {
  const AuthRequiredFailure({
    String message = 'Sesi Anda telah berakhir. Silakan masuk kembali.',
    dynamic details,
  }) : super(code: 'AUTH_REQUIRED', message: message, details: details);
}

/// P1002 - Peran atau hubungan objek tidak sah
class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({
    String message = 'Anda tidak memiliki hak akses untuk tindakan ini.',
    dynamic details,
  }) : super(code: 'FORBIDDEN', message: message, details: details);
}

/// P1003 - Field atau persamaan kuantitas salah
class ValidationErrorFailure extends AppFailure {
  const ValidationErrorFailure({
    String message = 'Data yang dikirimkan tidak valid atau belum lengkap.',
    dynamic details,
  }) : super(code: 'VALIDATION_ERROR', message: message, details: details);
}

/// P1004 - Objek berubah sejak terakhir dibuka
class VersionConflictFailure extends AppFailure {
  const VersionConflictFailure({
    String message = 'Data telah diperbarui di server. Silakan muat ulang halaman.',
    dynamic details,
  }) : super(code: 'VERSION_CONFLICT', message: message, details: details);
}

/// P1005 - Kuantitas yang diminta melebihi stok tersedia
class StockConflictFailure extends AppFailure {
  const StockConflictFailure({
    String message = 'Stok tersedia tidak mencukupi untuk alokasi ini.',
    dynamic details,
  }) : super(code: 'STOCK_CONFLICT', message: message, details: details);
}

/// P1006 - Kebutuhan telah ditutup, terpenuhi, atau melewati tenggat
class NeedClosedFailure extends AppFailure {
  const NeedClosedFailure({
    String message = 'Kebutuhan ini telah ditutup atau melewati batas waktu.',
    dynamic details,
  }) : super(code: 'NEED_CLOSED', message: message, details: details);
}

/// P1007 - Status saat ini tidak menerima tindakan yang dipilih
class InvalidTransitionFailure extends AppFailure {
  const InvalidTransitionFailure({
    String message = 'Perubahan status tidak sah untuk kondisi donasi saat ini.',
    dynamic details,
  }) : super(code: 'INVALID_TRANSITION', message: message, details: details);
}

/// P1008 - Idempotency key lama digunakan dengan muatan payload berbeda
class IdempotencyConflictFailure extends AppFailure {
  const IdempotencyConflictFailure({
    String message = 'Konflik kunci idempotensi: permintaan serupa telah diproses sebelumnya.',
    dynamic details,
  }) : super(code: 'IDEMPOTENCY_CONFLICT', message: message, details: details);
}

/// P1009 - Konfirmasi penerimaan atau serah terima sudah final
class AlreadyConfirmedFailure extends AppFailure {
  const AlreadyConfirmedFailure({
    String message = 'Konfirmasi penerimaan donasi sudah final dan tidak dapat diubah.',
    dynamic details,
  }) : super(code: 'ALREADY_CONFIRMED', message: message, details: details);
}

/// AI Provider gagal / tidak mendukung (Edge HTTP 503)
class AiUnavailableFailure extends AppFailure {
  const AiUnavailableFailure({
    String message = 'Layanan bantuan AI sedang tidak tersedia. Silakan lanjutkan kurasi secara manual.',
    dynamic details,
  }) : super(code: 'AI_UNAVAILABLE', message: message, details: details);
}

/// Gangguan jaringan atau timeout
class NetworkFailure extends AppFailure {
  const NetworkFailure({
    String message = 'Koneksi internet bermasalah. Periksa sambungan Anda dan coba lagi.',
    dynamic details,
  }) : super(code: 'NETWORK_ERROR', message: message, details: details);
}

/// Kesalahan tak terduga
class UnknownFailure extends AppFailure {
  const UnknownFailure({
    String message = 'Terjadi kesalahan sistem yang tidak terduga.',
    dynamic details,
  }) : super(code: 'UNKNOWN_ERROR', message: message, details: details);
}
