/// Kelas hierarki kegagalan domain untuk reSandang
/// Mengacu pada api-contracts.md Bagian 1 & architecture.md
sealed class AppFailure implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const AppFailure({required this.code, required this.message, this.details});

  @override
  String toString() => '[$code] $message';
}

/// P1001 - Sesi tidak ada atau telah berakhir
class AuthRequiredFailure extends AppFailure {
  const AuthRequiredFailure({
    super.message = 'Sesi Anda telah berakhir. Silakan masuk kembali.',
    super.details,
  }) : super(code: 'AUTH_REQUIRED');
}

/// P1002 - Peran atau hubungan objek tidak sah
class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({
    super.message = 'Anda tidak memiliki hak akses untuk tindakan ini.',
    super.details,
  }) : super(code: 'FORBIDDEN');
}

/// P1003 - Field atau persamaan kuantitas salah
class ValidationErrorFailure extends AppFailure {
  const ValidationErrorFailure({
    super.message = 'Data yang dikirimkan tidak valid atau belum lengkap.',
    super.details,
  }) : super(code: 'VALIDATION_ERROR');
}

/// P1004 - Objek berubah sejak terakhir dibuka
class VersionConflictFailure extends AppFailure {
  const VersionConflictFailure({
    super.message =
        'Data telah diperbarui di server. Silakan muat ulang halaman.',
    super.details,
  }) : super(code: 'VERSION_CONFLICT');
}

/// P1005 - Kuantitas yang diminta melebihi stok tersedia
class StockConflictFailure extends AppFailure {
  const StockConflictFailure({
    super.message = 'Stok tersedia tidak mencukupi untuk alokasi ini.',
    super.details,
  }) : super(code: 'STOCK_CONFLICT');
}

/// P1006 - Kebutuhan telah ditutup, terpenuhi, atau melewati tenggat
class NeedClosedFailure extends AppFailure {
  const NeedClosedFailure({
    super.message = 'Kebutuhan ini telah ditutup atau melewati batas waktu.',
    super.details,
  }) : super(code: 'NEED_CLOSED');
}

/// P1007 - Status saat ini tidak menerima tindakan yang dipilih
class InvalidTransitionFailure extends AppFailure {
  const InvalidTransitionFailure({
    super.message = 'Perubahan status tidak sah untuk kondisi donasi saat ini.',
    super.details,
  }) : super(code: 'INVALID_TRANSITION');
}

/// P1008 - Idempotency key lama digunakan dengan muatan payload berbeda
class IdempotencyConflictFailure extends AppFailure {
  const IdempotencyConflictFailure({
    super.message = 'Konflik kunci idempotensi: permintaan serupa telah diproses sebelumnya.',
    super.details,
  }) : super(code: 'IDEMPOTENCY_CONFLICT');
}

/// P1009 - Konfirmasi penerimaan atau serah terima sudah final
class AlreadyConfirmedFailure extends AppFailure {
  const AlreadyConfirmedFailure({
    super.message =
        'Konfirmasi penerimaan donasi sudah final dan tidak dapat diubah.',
    super.details,
  }) : super(code: 'ALREADY_CONFIRMED');
}

/// AI Provider gagal / tidak mendukung (Edge HTTP 503)
class AiUnavailableFailure extends AppFailure {
  const AiUnavailableFailure({
    super.message = 'Layanan bantuan AI sedang tidak tersedia. Silakan lanjutkan kurasi secara manual.',
    super.details,
  }) : super(code: 'AI_UNAVAILABLE');
}

/// Gangguan jaringan atau timeout
class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message =
        'Koneksi internet bermasalah. Periksa sambungan Anda dan coba lagi.',
    super.details,
  }) : super(code: 'NETWORK_ERROR');
}

/// Kesalahan tak terduga
class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'Terjadi kesalahan sistem yang tidak terduga.',
    super.details,
  }) : super(code: 'UNKNOWN_ERROR');
}
