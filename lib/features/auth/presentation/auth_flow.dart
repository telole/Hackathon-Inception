import 'package:flutter/material.dart';

import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';

enum _AuthPage { welcome, login, signup, forgot }

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  _AuthPage _page = _AuthPage.welcome;

  void _go(_AuthPage page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    final Widget screen;
    switch (_page) {
      case _AuthPage.welcome:
        screen = WelcomeScreen(
          key: const ValueKey('welcome'),
          onStart: () => _go(_AuthPage.signup),
          onSignIn: () => _go(_AuthPage.login),
        );
      case _AuthPage.login:
        screen = LoginScreen(
          key: const ValueKey('login'),
          onBack: () => _go(_AuthPage.welcome),
          onSignUp: () => _go(_AuthPage.signup),
          onForgotPassword: () => _go(_AuthPage.forgot),
        );
      case _AuthPage.signup:
        screen = SignupScreen(
          key: const ValueKey('signup'),
          onBack: () => _go(_AuthPage.welcome),
          onSignIn: () => _go(_AuthPage.login),
        );
      case _AuthPage.forgot:
        screen = ForgotPasswordScreen(
          key: const ValueKey('forgot'),
          onBack: () => _go(_AuthPage.login),
          onSignIn: () => _go(_AuthPage.login),
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: screen,
    );
  }
}
