import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).extension<PkTokens>()!.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Semantics(
              image: true,
              label: 'PakaianKita, donasi sandang, kurangi limbah',
              child: dark
                  ? const PkLogo(width: 334, onDark: true)
                  : Image.asset(
                      MediaQuery.disableAnimationsOf(context)
                          ? 'assets/splash/pakaiankita-still.png'
                          : 'assets/splash/pakaiankita.gif',
                      width: 334,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
