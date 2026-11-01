import '../../features/registration/presentation/registration_screens.dart';
import '../../features/registration/presentation/organization_screens.dart';
import '../../features/notifications/notification_center.dart';
import '../../features/profile/presentation/account_screens.dart';
import '../../features/campaign/presentation/program_management_screens.dart';
import '../../features/operations/presentation/admin_review_screens.dart';
import '../../features/operations/presentation/operations_screens.dart';
import '../../features/operations/presentation/workflow_screens.dart';

import 'dart:async';
import 'dart:ui';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/campaign/presentation/campaign_list_screen.dart';

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
  initialLocation: '/splash',
  refreshListenable: _routerAuthRefresh,
  redirect: (context, state) {
    if (!SupabaseConfig.isConfigured) return null;

    final user = Supabase.instance.client.auth.currentUser;
    final location = state.matchedLocation;
    if (user == null &&
        location != '/splash' &&
        location != '/onboarding' &&
        location != '/auth') {
      return Uri(
        path: '/auth',
        queryParameters: {'redirect': state.uri.toString()},
      ).toString();
    }
    if (user != null && location == '/onboarding') return '/home';
    if (user != null && location == '/auth') {
      final target = state.uri.queryParameters['redirect'];
      if (target == null ||
          !target.startsWith('/') ||
          target.startsWith('//') ||
          Uri.tryParse(target)?.path == '/auth') {
        return '/home';
      }
      return target;
    }
    return null;
  },
  routes: [
    GoRoute(path: '/join', builder: (context, state) => const JoinScreen()),
    GoRoute(
      path: '/join/volunteer',
      builder: (context, state) => const VolunteerApplicationScreen(),
    ),
    GoRoute(
      path: '/join/organization/new',
      builder: (context, state) => const OrganizationApplicationScreen(),
    ),
    GoRoute(
      path: '/join/organization/:id',
      builder: (context, state) => OrganizationApplicationScreen(
        applicationId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/join/history/:type',
      builder: (context, state) =>
          RegistrationHistoryScreen(type: state.pathParameters['type']!),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationCenterScreen(),
    ),
    GoRoute(
      path: '/donations/history',
      builder: (context, state) => const DonationHistoryScreen(),
    ),
    GoRoute(
      path: '/organization',
      builder: (context, state) => const MyOrganizationsScreen(),
    ),
    GoRoute(
      path: '/organization/:id/members',
      builder: (context, state) => OrganizationMembersScreen(
        organizationId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/organization/:id/points/new',
      builder: (context, state) =>
          PointEditorScreen(organizationId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/organization/:id/points/:point',
      builder: (context, state) => PointEditorScreen(
        organizationId: state.pathParameters['id']!,
        pointId: state.pathParameters['point']!,
      ),
    ),
    GoRoute(
      path: '/organization/:id/points',
      builder: (context, state) =>
          OrganizationPointsScreen(organizationId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/operations/registrations/:type/:id',
      builder: (context, state) => RegistrationReviewScreen(
        type: state.pathParameters['type']!,
        requestId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/operations/registrations/:type',
      builder: (context, state) =>
          RegistrationQueueScreen(type: state.pathParameters['type']!),
    ),
    GoRoute(
      path: '/account/password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/account/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/operations/programs',
      builder: (context, state) => const ManagedProgramsScreen(),
    ),
    GoRoute(
      path: '/operations/programs/new',
      builder: (context, state) => const ProgramEditorScreen(),
    ),
    GoRoute(
      path: '/operations/programs/:id',
      builder: (context, state) =>
          ProgramEditorScreen(programId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/operations/reviews/:id',
      builder: (context, state) =>
          AdminDonationReviewScreen(donationId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/operations/admin-tasks',
      builder: (context, state) => const AdminTasksScreen(),
    ),
    GoRoute(
      path: '/operations/admin-tasks/:id',
      builder: (context, state) =>
          ReassignTaskScreen(taskId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/operations/schedule',
      builder: (context, state) => const ScheduleQueueScreen(),
    ),
    GoRoute(
      path: '/operations/schedule/:id',
      builder: (context, state) =>
          ScheduleDonationScreen(donationId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/operations/allocate',
      builder: (context, state) => const AllocateStockScreen(),
    ),
    GoRoute(
      path: '/operations/shipments/new',
      builder: (context, state) => const CreateShipmentScreen(),
    ),
    GoRoute(
      path: '/operations',
      builder: (context, state) => const OperationsHomeScreen(),
    ),
    GoRoute(
      path: '/operations/tasks',
      builder: (context, state) => const VolunteerTasksScreen(),
    ),
    GoRoute(
      path: '/operations/tasks/:id',
      builder: (context, state) =>
          VolunteerTaskDetailScreen(taskId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/operations/curation/:id',
      builder: (context, state) =>
          PhysicalCurationScreen(donationId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/operations/stock',
      builder: (context, state) => const PartnerStockScreen(),
    ),
    GoRoute(
      path: '/operations/shipments',
      builder: (context, state) => const PartnerShipmentsScreen(),
    ),
    GoRoute(
      path: '/operations/shipments/:id',
      builder: (context, state) =>
          ShipmentDetailScreen(shipmentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/operations/reviews',
      builder: (context, state) => const AdminReviewsScreen(),
    ),
    GoRoute(
      path: '/operations/organizations',
      builder: (context, state) => const AdminOrganizationsScreen(),
    ),
    GoRoute(
      path: '/operations/users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
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
              path: '/needs',
              pageBuilder: (context, state) =>
                  _transitionPage(state, const CampaignListScreen()),
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
                DonationFlowHost(
                  key: ValueKey(
                    'donate:${state.uri.queryParameters['edit']}:${state.uri.queryParameters['kebutuhan']}',
                  ),
                  editId: state.uri.queryParameters['edit'],
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
              pageBuilder: (context, state) => _transitionPage(
                state,
                TrackingScreen(
                  key: ValueKey(
                    'tracking:${state.uri.queryParameters['donation']}',
                  ),
                  initialId: state.uri.queryParameters['donation'],
                ),
              ),
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
