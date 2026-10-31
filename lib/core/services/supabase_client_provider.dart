import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../errors/error_mapper.dart';

/// Provider terpusat untuk SupabaseClient dan pemanggilan aman RPC
class SupabaseClientProvider {
  static final SupabaseClientProvider _instance = SupabaseClientProvider._internal();
  factory SupabaseClientProvider() => _instance;
  SupabaseClientProvider._internal();

  static const _uuid = Uuid();

  /// Mendapatkan instance SupabaseClient
  SupabaseClient get client => Supabase.instance.client;

  /// Membuat UUID v4 untuk idempotency request key
  static String newRequestKey() => _uuid.v4();

  /// Menjalankan RPC dengan penanganan error terpetakan ke AppFailure
  Future<T> safeRpc<T>(String functionName, {Map<String, dynamic>? params}) async {
    try {
      final res = await client.rpc(functionName, params: params);
      return res as T;
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }

  /// Menjalankan query tabel dengan penanganan error terpetakan ke AppFailure
  Future<T> safeQuery<T>(Future<T> Function(SupabaseClient client) queryFn) async {
    try {
      return await queryFn(client);
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
