/// Konfigurasi environment. Nilai diisi saat build/run lewat:
/// flutter run --dart-define-from-file=env.json
///
/// Hanya URL dan anon key yang boleh ada di sini.
/// JANGAN pernah taruh service_role atau API key LLM di aplikasi Flutter.
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Panggil sebelum Supabase.initialize agar gagal cepat jika config kosong.
  static void assertConfigured() {
    assert(
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
      'SUPABASE_URL / SUPABASE_ANON_KEY kosong. '
      'Jalankan dengan --dart-define-from-file=env.json',
    );
  }
}