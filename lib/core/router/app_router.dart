import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/auth_screen.dart';
import '../../features/home/application/home_models.dart';
import '../../features/campaign/presentation/campaign_detail_screen.dart';
import '../../features/donation/presentation/donation_flow_screen.dart';
import '../../features/donation/presentation/donation_points_screen.dart';
import '../../features/donation/presentation/donation_success_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/tracking/presentation/tracking_screen.dart';
import '../../features/donation/application/donation_models.dart';
import '../theme/pk_tokens.dart';
import '../config/supabase_config.dart';

final _routerAuthRefresh = _RouterAuthRefresh();

void bindRouterAuthRefresh(SupabaseClient? client) {
  _routerAuthRefresh.bind(client);
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/onboarding',
  refreshListenable: _routerAuthRefresh,
  redirect: (context, state) {
    if (!SupabaseConfig.isConfigured) return null;

    final user = Supabase.instance.client.auth.currentUser;
    final location = state.matchedLocation;
    if (user == null && location != '/onboarding' && location != '/auth') {
      return Uri(
        path: '/auth',
        queryParameters: {'redirect': state.uri.toString()},
      ).toString();
    }
    if (user != null && location == '/onboarding') return '/home';
    if (user != null && location == '/auth') {
      return state.uri.queryParameters['redirect'] ?? '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => _transitionPage(
        state,
        AuthScreen(redirectTo: state.uri.queryParameters['redirect']),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) =>
          _transitionPage(state, const OnboardingScreen()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  _transitionPage(state, const HomeScreen()),
            ),
            GoRoute(
              path: '/campaign/:id',
              pageBuilder: (context, state) => _transitionPage(
                state,
                CampaignDetailScreen(campaignId: state.pathParameters['id']!),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/donate',
              pageBuilder: (context, state) => _transitionPage(
                state,
                DonationFlowScreen(
                  initialCategory: _categoryFromId(
                    state.uri.queryParameters['kategori'],
                  ),
                  preferredNeedId: state.uri.queryParameters['kebutuhan'],
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tracking',
              pageBuilder: (context, state) =>
                  _transitionPage(state, const TrackingScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  _transitionPage(state, const ProfileScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/points',
      pageBuilder: (context, state) =>
          _transitionPage(state, const DonationPointsScreen()),
    ),
    GoRoute(
      path: '/success',
      pageBuilder: (context, state) => _transitionPage(
        state,
        DonationSuccessScreen(
          donation: state.extra is DonationRecord
              ? state.extra! as DonationRecord
              : null,
        ),
      ),
    ),
  ],
);

class _RouterAuthRefresh extends ChangeNotifier {
  StreamSubscription<AuthState>? _subscription;

  void bind(SupabaseClient? client) {
    _subscription?.cancel();
    _subscription = client?.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

DonationCategory? _categoryFromId(String? id) {
  for (final category in DonationCategory.values) {
    if (category.id == id) return category;
  }
  return null;
}

CustomTransitionPage<void> _transitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final progress = MediaQuery.disableAnimationsOf(context)
          ? const AlwaysStoppedAnimation<double>(1)
          : CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: progress,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(progress),
          child: child,
        ),
      );
    },
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (
      label: 'Beranda',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    (
      label: 'Donasi',
      icon: Icons.volunteer_activism_outlined,
      activeIcon: Icons.volunteer_activism_rounded,
    ),
    (
      label: 'Lacak',
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping_rounded,
    ),
    (
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _GlassBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _GlassBottomNavigation extends StatelessWidget {
  const _GlassBottomNavigation({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surface.withValues(alpha: 0.88),
              border: Border.all(color: tokens.border.withValues(alpha: 0.8)),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [tokens.cardShadow],
            ),
            child: Row(
              children: [
                for (var index = 0; index < _AppShell._items.length; index++)
                  Expanded(
                    child: _NavigationItem(
                      item: _AppShell._items[index],
                      selected: index == currentIndex,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ({String label, IconData icon, IconData activeIcon}) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final color = selected ? tokens.accentStrong : tokens.mutedText;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                color: color,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
