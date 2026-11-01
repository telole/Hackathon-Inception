import 'core/providers/live_updates_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/providers/supabase_client_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/phone_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isPartiallyConfigured) {
    throw StateError(
      'SUPABASE_URL dan SUPABASE_ANON_KEY harus diatur bersamaan.',
    );
  }

  SupabaseClient? client;
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    client = Supabase.instance.client;
  }
  bindRouterAuthRefresh(client);

  runApp(
    ProviderScope(
      overrides: [supabaseClientProvider.overrideWithValue(client)],
      child: const PakaiankitaApp(),
    ),
  );
}

class PakaiankitaApp extends ConsumerWidget {
  const PakaiankitaApp({super.key, this.demoMode = false});

  final bool demoMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!demoMode) ref.watch(liveUpdatesProvider);
    return MaterialApp.router(
      title: 'Pakaiankita',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      builder: (context, child) => PhoneFrame(
        child: demoMode
            ? Banner(
                message: 'DEMO',
                location: BannerLocation.topEnd,
                child: child ?? const SizedBox.shrink(),
              )
            : child ?? const SizedBox.shrink(),
      ),
    );
  }
}
