import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/models/app_context.dart';
import '../../../core/models/app_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pk_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final repository = controller.repository;
    final query = _search.text.trim().toLowerCase();
    final accounts = repository.accounts.where((account) {
      if (query.isEmpty) return true;
      return account.name.toLowerCase().contains(query) ||
          account.email.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Pengguna', style: theme.textTheme.displaySmall),
        const SizedBox(height: 3),
        Text(
          '${repository.accounts.length} akun demo terdaftar di perangkat ini.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        PkTextField(
          label: 'Cari akun',
          controller: _search,
          hint: 'Nama atau email',
          prefixIcon: Icons.search_rounded,
          onChanged: (_) => setState(() {}),
          suffix: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
        ),
        const SizedBox(height: 14),
        if (accounts.isEmpty)
          const PkEmptyState(
            title: 'Akun tidak ditemukan',
            message: 'Coba kata kunci lain atau hapus pencarian.',
            icon: Icons.person_search_outlined,
          )
        else
          for (final account in accounts) ...[
            _AccountCard(
              name: account.name,
              email: account.email,
              roles: account.roles,
              isAdmin: account.isAdmin,
              verifiedOrganization:
                  repository.organizationById(account.organizationId),
              waiting: repository.applicationFor(account.id)?.status.isPending ??
                  false,
              rejected:
                  repository.applicationFor(account.id)?.status.isRejected ??
                      false,
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 6),
        Text(
          'Role ditampilkan dari data demo. Perubahan role nyata hanya boleh dilakukan server setelah verifikasi.',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.email,
    required this.roles,
    required this.isAdmin,
    required this.verifiedOrganization,
    required this.waiting,
    required this.rejected,
  });

  final String name;
  final String email;
  final Set<AppRole> roles;
  final bool isAdmin;
  final Organization? verifiedOrganization;
  final bool waiting;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final organizationName = verifiedOrganization?.name;
    final organizationVerified = verifiedOrganization?.verified ?? false;

    final String status;
    final PkStatusTone tone;
    if (isAdmin) {
      status = 'Admin';
      tone = PkStatusTone.danger;
    } else if (organizationVerified) {
      status = 'Mitra terverifikasi';
      tone = PkStatusTone.success;
    } else if (waiting) {
      status = 'Menunggu verifikasi';
      tone = PkStatusTone.warning;
    } else if (rejected) {
      status = 'Pengajuan ditolak';
      tone = PkStatusTone.danger;
    } else {
      status = 'Donatur';
      tone = PkStatusTone.neutral;
    }

    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PkAvatar(name: name, size: 42),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PkStatusChip(label: status, tone: tone),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final role in roles)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    _roleLabel(role),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              if (organizationName != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    organizationName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      color: AppColors.forest,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
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
}
