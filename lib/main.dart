import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );
      debugPrint('[reSandang] Supabase backend initialized.');
    } catch (e) {
      debugPrint('[reSandang] Supabase init error: $e');
    }
  } else {
    debugPrint('[reSandang] Menunggu konfigurasi SUPABASE_URL dan SUPABASE_ANON_KEY.');
  }
}
