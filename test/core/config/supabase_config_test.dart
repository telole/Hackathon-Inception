import 'package:flutter_test/flutter_test.dart';
import 'package:pakaiankita/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test(
      'has valid project URL and publishable anon key',
      () {
        expect(SupabaseConfig.url, isNotEmpty);
        expect(SupabaseConfig.url, contains('tiekssrrvsyossageoiu'));
        expect(SupabaseConfig.anonKey, isNotEmpty);
        expect(SupabaseConfig.isConfigured, isTrue);
      },
      skip: !SupabaseConfig.isConfigured
          ? 'Optional build-config check requires SUPABASE_URL and SUPABASE_ANON_KEY dart-defines.'
          : false,
    );
  });
}
