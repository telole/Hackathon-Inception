import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pk_widgets.dart';
import 'admin_dashboard_screen.dart';
import 'admin_programs_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_users_screen.dart';
import 'verification_queue_screen.dart';

enum AdminTab { dashboard, program, operasional, pengguna, pengaturan }

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminTab _tab = AdminTab.dashboard;

  void _selectTab(AdminTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  void _openQueue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const VerificationQueueScreen(),
      ),
    );
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
    final pending = controller.repository.pendingVerificationCount;

    final pages = <Widget>[
      AdminDashboardScreen(
        onOpenQueue: _openQueue,
        onOpenOperasional: () => _selectTab(AdminTab.operasional),
        onOpenPrograms: () => _selectTab(AdminTab.program),
      ),
      const AdminProgramsScreen(),
      const VerificationQueueView(),
      const AdminUsersScreen(),
      const AdminSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 6),
              child: Row(
                children: [
                  const PkLogo(size: 17),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ADMIN',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const Spacer(),
                  PkIconAction(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notifikasi verifikasi',
                    badge: pending,
                    onPressed: _openQueue,
                  ),
                  Semantics(
                    button: true,
                    label: 'Buka pengaturan admin',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _selectTab(AdminTab.pengaturan),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: PkAvatar(
                          name: current.displayName,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
              _selectTab(AdminTab.values[index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Program',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: 'Operasional',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group_rounded),
              label: 'Pengguna',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
