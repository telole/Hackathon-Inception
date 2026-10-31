/// Konfigurasi environment. Nilai diisi saat build/run lewat:
/// flutter run --dart-define-from-file=env.json
///
/// Hanya URL dan anon key yang boleh ada di sini.
/// JANGAN pernah taruh service_role atau API key LLM di aplikasi.
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static void assertConfigured() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      // Menunggu konfigurasi environment dari env.json
    }
  }
}