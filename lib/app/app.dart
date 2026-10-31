import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../demo/demo_repository.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'auth_gate.dart';

class PakaianKitaApp extends StatefulWidget {
  const PakaianKitaApp({super.key, this.repository});

  /// Bisa diisi repository sendiri untuk widget test.
  final DemoRepository? repository;

  @override
  State<PakaianKitaApp> createState() => _PakaianKitaAppState();
}

class _PakaianKitaAppState extends State<PakaianKitaApp> {
  late final DemoRepository _repository;
  late final AppController _controller;
  late final bool _ownsRepository;

  @override
  void initState() {
    super.initState();
    _ownsRepository = widget.repository == null;
    _repository = widget.repository ?? DemoRepository.seeded();
    _controller = AppController(_repository)..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_ownsRepository) _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'PakaianKita',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AuthGate(),
      ),
    );
  }
}
