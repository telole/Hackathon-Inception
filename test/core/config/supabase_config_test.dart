import 'package:flutter_test/flutter_test.dart';
import 'package:resandang/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test('has valid project URL and publishable anon key', () {
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.url, contains('tiekssrrvsyossageoiu'));
      expect(SupabaseConfig.anonKey, isNotEmpty);
      expect(SupabaseConfig.isConfigured, isTrue);
    });
  });
}
