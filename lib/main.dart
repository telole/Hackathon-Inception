import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_state_notifier.dart';
import 'features/auth/presentation/role_shell_switcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.assertConfigured();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  runApp(const PakaianKitaApp());
}

class PakaianKitaApp extends StatefulWidget {
  const PakaianKitaApp({super.key});

  @override
  State<PakaianKitaApp> createState() => _PakaianKitaAppState();
}

class _PakaianKitaAppState extends State<PakaianKitaApp> {
  late final AuthStateNotifier _authNotifier;

  @override
  void initState() {
    super.initState();
    _authNotifier = AuthStateNotifier();
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PakaianKita',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: RoleShellSwitcher(
        authNotifier: _authNotifier,
      ),
    );
  }
}