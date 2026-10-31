import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import 'auth_state_notifier.dart';
import 'login_screen.dart';

class RoleShellSwitcher extends StatefulWidget {
  final AuthStateNotifier authNotifier;

  const RoleShellSwitcher({
    super.key,
    required this.authNotifier,
  });

  @override
  State<RoleShellSwitcher> createState() => _RoleShellSwitcherState();
}

class _RoleShellSwitcherState extends State<RoleShellSwitcher> {
  @override
  void initState() {
    super.initState();
    widget.authNotifier.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authNotifier,
      builder: (context, _) {
        if (widget.authNotifier.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (!widget.authNotifier.isAuthenticated) {
          return LoginScreen(
            authNotifier: widget.authNotifier,
            onLoginSuccess: () {
              widget.authNotifier.initialize();
            },
          );
        }

        return AppNavigationShell(
          authNotifier: widget.authNotifier,
        );
      },
    );
  }
}

/// Shell Navigasi Utama sesuai FR-02 & design.md
/// Tab Donatur: Beranda, Kebutuhan, Donasiku, Aktivitas, Profil.
class AppNavigationShell extends StatefulWidget {
  final AuthStateNotifier authNotifier;

  const AppNavigationShell({
    super.key,
    required this.authNotifier,
  });

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final access = widget.authNotifier.currentAccess;

    final titles = ['Beranda', 'Kebutuhan', 'Donasiku', 'Aktivitas', 'Profil'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          // Role Pill Indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  access.roles.isEmpty
                      ? [
                        const Text(
                          'Donatur',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ]
                      : access.roles.map((r) {
                        return Text(
                          r.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        );
                      }).toList(),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _PlaceholderTab(
            title: 'Beranda Donatur',
            subtitle: 'Katalog kebutuhan darurat & rutin terdekat.',
            icon: Icons.home_rounded,
          ),
          _PlaceholderTab(
            title: 'Papan Kebutuhan',
            subtitle: 'Daftar kebutuhan pakaian sandang layak pakai dari mitra terverifikasi.',
            icon: Icons.list_alt_rounded,
          ),
          _PlaceholderTab(
            title: 'Donasiku',
            subtitle: 'Daftar pengajuan donasi pakaianmu dan riwayat penyerahan.',
            icon: Icons.volunteer_activism_rounded,
          ),
          _PlaceholderTab(
            title: 'Aktivitas & Dampak',
            subtitle: 'Pembaruan perjalanan pakaian yang telah kamu salurkan.',
            icon: Icons.notifications_none_rounded,
          ),
          _ProfileTab(
            authNotifier: widget.authNotifier,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            selectedIcon: Icon(Icons.list_alt, color: AppColors.primary),
            label: 'Kebutuhan',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism, color: AppColors.primary),
            label: 'Donasiku',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
            label: 'Aktivitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PlaceholderTab({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final AuthStateNotifier authNotifier;

  const _ProfileTab({required this.authNotifier});

  @override
  Widget build(BuildContext context) {
    final user = authNotifier.currentUser;
    final access = authNotifier.currentAccess;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  child: const Icon(Icons.person, size: 32, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.email ?? 'Pengguna',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Peran Aktif: ${access.roles.isEmpty ? "Donatur" : access.roles.map((r) => r.label).join(", ")}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          title: const Text('Perbarui Hak Akses'),
          subtitle: const Text('Sinkronkan verifikasi peran dari server Supabase'),
          onTap: () async {
            await authNotifier.refreshAccess();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Akses berhasil diperbarui')),
              );
            }
          },
        ),
        const Divider(height: 20),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.logout_rounded, color: AppColors.error),
          title: const Text('Keluar dari Akun', style: TextStyle(color: AppColors.error)),
          onTap: () async {
            await authNotifier.signOut();
          },
        ),
      ],
    );
  }
}
