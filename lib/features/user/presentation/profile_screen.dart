import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/models/app_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../models/user_tab.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.onOpenMitraSpace,
    required this.onOpenMitraApplication,
    required this.onOpenTab,
  });

  final VoidCallback onOpenMitraSpace;
  final VoidCallback onOpenMitraApplication;
  final ValueChanged<UserTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final current = controller.context;
    if (current == null) return const SizedBox.shrink();
    final application = current.mitraApplication;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Profil', style: theme.textTheme.displaySmall),
        const SizedBox(height: 3),
        Text(
          'Akun, peran, dan pengaturan simulasi.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        PkCard(
          child: Row(
            children: [
              PkAvatar(name: current.displayName, size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.displayName,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      current.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final role in current.sortedRoles)
                          PkStatusChip(
                            label: _roleLabel(role),
                            tone: role == AppRole.admin
                                ? PkStatusTone.danger
                                : role == AppRole.mitra
                                    ? PkStatusTone.success
                                    : PkStatusTone.neutral,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const PkSectionHeader(
          title: 'Status mitra',
          subtitle: 'Akses lembaga pada akun ini',
        ),
        const SizedBox(height: 10),
        if (current.isVerifiedMitra) ...[
          PkCard(
            color: AppColors.sage,
            borderColor: const Color(0xFFCFDCC8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 19,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        current.organization?.name ?? 'Lembaga terverifikasi',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${current.organization?.kind ?? 'Mitra'} · ${current.organization?.area ?? 'Wilayah layanan'}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),
                PkButton(
                  label: 'Buka ruang mitra',
                  variant: PkButtonVariant.secondary,
                  onPressed: onOpenMitraSpace,
                ),
              ],
            ),
          ),
        ] else if (application != null &&
            (application.status.isPending || application.status.isRejected)) ...[
          PkCard(
            color: application.status.isRejected
                ? AppColors.alertSurface
                : AppColors.parchment,
            borderColor: application.status.isRejected
                ? const Color(0xFFF0C9BD)
                : const Color(0xFFE7DDC8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      application.status.isRejected
                          ? Icons.error_outline_rounded
                          : Icons.hourglass_top_rounded,
                      size: 18,
                      color: application.status.isRejected
                          ? AppColors.clay
                          : const Color(0xFF7A5A1F),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        application.organizationName,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    PkStatusChip(
                      label: application.status.label,
                      tone: application.status.isRejected
                          ? PkStatusTone.danger
                          : PkStatusTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  application.status.isRejected
                      ? 'Pengajuan dikembalikan admin. Perbaiki dokumen lalu kirim ulang.'
                      : 'Dokumen legalitas sedang diperiksa admin. Kamu tetap bisa berdonasi.',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
                if (application.status.isRejected &&
                    application.reviewNote != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Catatan admin: ${application.reviewNote}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.clay,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                PkButton(
                  label: application.status.isRejected
                      ? 'Perbaiki pengajuan'
                      : 'Lihat status pengajuan',
                  variant: PkButtonVariant.secondary,
                  onPressed: onOpenMitraApplication,
                ),
              ],
            ),
          ),
        ] else ...[
          PkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        size: 19,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingin menyalurkan lewat lembaga?',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ajukan mitra dan unggah dokumen legalitas untuk diverifikasi admin.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PkButton(
                  label: 'Ajukan sebagai mitra',
                  variant: PkButtonVariant.secondary,
                  onPressed: onOpenMitraApplication,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const PkSectionHeader(title: 'Akun dan data'),
        const SizedBox(height: 8),
        PkCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined, size: 20),
                title: const Text('Donasiku'),
                subtitle: const Text('Riwayat pakaian yang kamu salurkan'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => onOpenTab(UserTab.donasiku),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.timeline_outlined, size: 20),
                title: const Text('Aktivitas'),
                subtitle: const Text('Perjalanan donasi dan pengajuan'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => onOpenTab(UserTab.aktivitas),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.science_outlined, size: 20),
                title: const Text('Panduan demo'),
                subtitle: const Text('Akun contoh dan alur singkat'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => _showDemoGuide(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const PkSectionHeader(title: 'Pengaturan simulasi'),
        const SizedBox(height: 8),
        PkCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.memory_outlined, size: 20),
                title: const Text('Data disimpan di perangkat'),
                subtitle: const Text(
                  'Mode mock, tidak terhubung ke Supabase atau Google.',
                ),
                trailing: const PkStatusChip(
                  label: 'Simulasi',
                  tone: PkStatusTone.warning,
                ),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.restart_alt_rounded,
                  size: 20,
                  color: AppColors.clay,
                ),
                title: const Text(
                  'Reset data simulasi',
                  style: TextStyle(color: AppColors.clay),
                ),
                subtitle: const Text(
                  'Kembalikan akun, pengajuan, dan kebutuhan ke data awal.',
                ),
                onTap: () => _confirmReset(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PkButton(
          label: 'Keluar',
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

  String _roleLabel(AppRole role) {
    switch (role) {
      case AppRole.donatur:
        return 'Donatur';
      case AppRole.relawan:
        return 'Relawan';
      case AppRole.mitra:
        return 'Mitra';
      case AppRole.admin:
        return 'Admin';
    }
  }

  Future<void> _showDemoGuide(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Panduan demo', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Semua akun memakai kata sandi demo1234. Data hanya ada di perangkat ini.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              for (final account in const [
                ('Admin', 'admin@pakaiankita.id', 'Setujui atau tolak pengajuan mitra'),
                ('Donatur', 'donatur@pakaiankita.id', 'Beranda kebutuhan terverifikasi'),
                ('Mitra', 'mitra@pakaiankita.id', 'Ruang mitra dan kelola kebutuhan'),
                ('Menunggu', 'pending@pakaiankita.id', 'Status pengajuan ditinjau'),
                ('Ditolak', 'ditolak@pakaiankita.id', 'Perbaiki pengajuan mitra'),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    size: 19,
                  ),
                  title: Text(account.$1, style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    '${account.$2} · ${account.$3}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                  ),
                ),
              const SizedBox(height: 8),
              const PkBanner(
                tone: PkBannerTone.simulation,
                label: 'Alur 3 menit',
                message:
                    'Masuk sebagai admin, setujui pengajuan, lalu masuk sebagai mitra. Setelah itu masuk sebagai donatur untuk melihat kebutuhan baru.',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset data simulasi?'),
        content: const Text(
          'Semua akun, donasi, dan pengajuan yang kamu buat akan kembali ke data demo awal. Kamu akan keluar dari sesi ini.',
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
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Data simulasi tetap tersimpan di perangkat ini. Kamu bisa masuk lagi dengan akun demo yang sama.',
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
}
