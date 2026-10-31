import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pk_widgets.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset data simulasi?'),
        content: const Text(
          'Semua pengajuan, akun, kebutuhan, dan donasi akan kembali ke data demo awal. Kamu akan keluar dari sesi ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.clay),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AppScope.read(context).resetDemo();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun admin?'),
        content: const Text(
          'Data simulasi tetap tersimpan. Kamu bisa masuk lagi dengan akun admin demo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.clay),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AppScope.read(context).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = AppScope.watch(context).context;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Pengaturan', style: theme.textTheme.displaySmall),
        const SizedBox(height: 3),
        Text(
          'Sesi admin dan data simulasi.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        PkCard(
          child: Row(
            children: [
              PkAvatar(name: current?.displayName ?? 'Admin', size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current?.displayName ?? 'Admin',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      current?.email ?? '-',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const PkStatusChip(
                label: 'Admin',
                tone: PkStatusTone.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const PkSectionHeader(title: 'Mode simulasi'),
        const SizedBox(height: 8),
        const PkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.memory_outlined,
                    size: 18,
                    color: AppColors.forest,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data hanya tersimpan di memori perangkat',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Tidak ada koneksi ke Supabase, Google, atau layanan eksternal. Semua keputusan verifikasi di sini adalah simulasi dan tidak mengubah data server.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const PkBanner(
          tone: PkBannerTone.warning,
          label: 'Batas simulasi',
          message:
              'Tabel verifikasi mitra dan RPC approval belum ada di backend. Jangan memakai hasil demo ini sebagai bukti keamanan server.',
        ),
        const SizedBox(height: 18),
        const PkSectionHeader(title: 'Kontrol demo'),
        const SizedBox(height: 8),
        PkCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.restart_alt_rounded, size: 20),
                title: const Text('Reset semua data simulasi'),
                subtitle: const Text(
                  'Kembalikan akun, pengajuan, kebutuhan, dan donasi ke data awal.',
                ),
                onTap: () => _confirmReset(context),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.logout_rounded, size: 20),
                title: const Text('Keluar'),
                subtitle: const Text('Akhiri sesi admin di perangkat ini.'),
                onTap: () => _confirmSignOut(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PkButton(
          label: 'Keluar dari akun admin',
          variant: PkButtonVariant.ghost,
          icon: Icons.logout_rounded,
          onPressed: () => _confirmSignOut(context),
        ),
        const SizedBox(height: 10),
        Text(
          'PakaianKita · demo hackathon · versi 0.1.0',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
