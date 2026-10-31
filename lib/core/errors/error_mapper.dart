import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_failure.dart';

class ErrorMapper {
  /// Memetakan berbagai exception menjadi AppFailure sesuai api-contracts.md
  static AppFailure map(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) {
      return error;
    }

    if (error is SocketException) {
      return const NetworkFailure();
    }

    if (error is AuthException) {
      return AuthRequiredFailure(
        message: error.message,
        details: error.statusCode,
      );
    }

    if (error is PostgrestException) {
      final code = error.code?.toUpperCase().trim() ?? '';
      final msg = error.message;

      // 1. Pemetaan kode SQLSTATE spesifik P1001 - P1009
      switch (code) {
        case 'P1001':
          return AuthRequiredFailure(message: msg, details: error.details);
        case 'P1002':
        case '42501': // PostgreSQL Insufficient Privilege / RLS violation
          return ForbiddenFailure(message: msg, details: error.details);
        case 'P1003':
        case '23514': // Check constraint violation
        case '23502': // Not null violation
          return ValidationErrorFailure(message: msg, details: error.details);
        case 'P1004':
          return VersionConflictFailure(message: msg, details: error.details);
        case 'P1005':
          return StockConflictFailure(message: msg, details: error.details);
        case 'P1006':
          return NeedClosedFailure(message: msg, details: error.details);
        case 'P1007':
          return InvalidTransitionFailure(message: msg, details: error.details);
        case 'P1008':
        case '23505': // Unique key conflict
          return IdempotencyConflictFailure(message: msg, details: error.details);
        case 'P1009':
          return AlreadyConfirmedFailure(message: msg, details: error.details);
      }

      // 2. Pemetaan berbasis pesan error jika driver mengembalikan teks
      final lowerMsg = msg.toLowerCase();
      if (lowerMsg.contains('auth_required') || lowerMsg.contains('session')) {
        return AuthRequiredFailure(message: msg, details: error.details);
      }
      if (lowerMsg.contains('forbidden') || lowerMsg.contains('permission denied')) {
        return ForbiddenFailure(message: msg, details: error.details);
      }
      if (lowerMsg.contains('insufficient stock') || lowerMsg.contains('stock')) {
        return StockConflictFailure(message: msg, details: error.details);
      }
      if (lowerMsg.contains('idempotency')) {
        return IdempotencyConflictFailure(message: msg, details: error.details);
      }
      if (lowerMsg.contains('already final') || lowerMsg.contains('already confirmed')) {
        return AlreadyConfirmedFailure(message: msg, details: error.details);
      }
      if (lowerMsg.contains('invalid status transition') || lowerMsg.contains('invalid transition')) {
        return InvalidTransitionFailure(message: msg, details: error.details);
      }

      return ValidationErrorFailure(message: msg, details: error.details);
    }

    // FunctionsException is from package:functions_client and may not be
    // directly exported. Use a safe dynamic check by runtimeType name.
    if (error.runtimeType.toString() == 'FunctionsException') {
      try {
        final dynamic dynErr = error;
        final int? status = dynErr.status as int?;
        if (status == 503) return const AiUnavailableFailure();
        if (status == 401) return const AuthRequiredFailure();
        if (status == 403) return const ForbiddenFailure();
      } catch (_) {}
    }

    return UnknownFailure(
      message: error.toString(),
      details: stackTrace?.toString(),
    );
  }
}
