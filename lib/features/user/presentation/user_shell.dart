import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/models/app_context.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../mitra/presentation/mitra_space_screen.dart';
import '../../needs/models/need.dart';
import '../../needs/presentation/need_detail_screen.dart';
import '../models/user_tab.dart';
import 'activity_screen.dart';
import 'donations_screen.dart';
import 'donatur_home_screen.dart';
import 'needs_screen.dart';
import 'profile_screen.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  UserTab _tab = UserTab.beranda;

  void _selectTab(UserTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  Future<void> _openNeed(Need need) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NeedDetailScreen(
          need: need,
          onOpenDonations: () => _selectTab(UserTab.donasiku),
        ),
      ),
    );
  }

  void _openMitraSpace() {
    final current = AppScope.read(context).context;
    if (current == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MitraSpaceScreen()),
    );
  }

  void _openMitraApplication() {
    final controller = AppScope.read(context);
    final current = controller.context;
    if (current == null) return;
    if (current.isVerifiedMitra) {
      _openMitraSpace();
      return;
    }
    if (current.hasPendingMitra || current.hasRejectedMitra) {
      controller.showPendingStatus();
      return;
    }
    controller.startMitraApplication();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final current = controller.context;
    if (current == null) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = <Widget>[
      DonaturHomeScreen(
        onOpenNeeds: () => _selectTab(UserTab.kebutuhan),
        onOpenNeed: _openNeed,
        onOpenMitra: _openMitraSpace,
        onOpenMitraStatus: () => controller.showPendingStatus(),
        onOpenDonations: () => _selectTab(UserTab.donasiku),
      ),
      NeedsScreen(onOpenNeed: _openNeed),
      DonationsScreen(onExplore: () => _selectTab(UserTab.kebutuhan)),
      const ActivityScreen(),
      ProfileScreen(
        onOpenMitraSpace: _openMitraSpace,
        onOpenMitraApplication: _openMitraApplication,
        onOpenTab: _selectTab,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _UserTopBar(
              contextData: current,
              onOpenProfile: () => _selectTab(UserTab.profil),
              onOpenActivity: () => _selectTab(UserTab.aktivitas),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab.index,
                children: pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (index) =>
              _selectTab(UserTab.values[index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.checkroom_outlined),
              selectedIcon: Icon(Icons.checkroom_rounded),
              label: 'Kebutuhan',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Donasiku',
            ),
            NavigationDestination(
              icon: Icon(Icons.timeline_outlined),
              selectedIcon: Icon(Icons.timeline_rounded),
              label: 'Aktivitas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTopBar extends StatelessWidget {
  const _UserTopBar({
    required this.contextData,
    required this.onOpenProfile,
    required this.onOpenActivity,
  });

  final AppContext contextData;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenActivity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          const PkLogo(size: 17),
          const Spacer(),
          IconButton(
            tooltip: 'Buka aktivitas',
            onPressed: onOpenActivity,
            icon: const Icon(Icons.timeline_outlined, size: 21),
            color: AppColors.ink,
          ),
          const SizedBox(width: 2),
          Semantics(
            button: true,
            label: 'Buka profil ${contextData.displayName}',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onOpenProfile,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: PkAvatar(name: contextData.displayName, size: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
