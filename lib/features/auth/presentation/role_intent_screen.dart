import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/app_context.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pk_widgets.dart';

class RoleIntentScreen extends StatefulWidget {
  const RoleIntentScreen({super.key});

  @override
  State<RoleIntentScreen> createState() => _RoleIntentScreenState();
}

class _RoleIntentScreenState extends State<RoleIntentScreen> {
  RoleIntent? _selected;
  bool _busy = false;
  String? _error;

  Future<void> _continue() async {
    final selected = _selected;
    if (selected == null || _busy) return;
    final controller = AppScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await controller.chooseRole(selected);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Pilihan belum bisa disimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final contextData = controller.context;
    return PkScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const PkLogo(size: 17),
                const Spacer(),
                TextButton(
                  onPressed: _busy ? null : () => controller.signOut(),
                  child: const Text('Keluar'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'SATU LANGKAH LAGI',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu mau bergabung sebagai apa?',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              contextData == null
                  ? 'Pilih peran awal untuk melanjutkan.'
                  : 'Halo, ${contextData.firstName}. Pilih peran awal untuk melanjutkan.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              PkBanner(
                tone: PkBannerTone.error,
                label: 'Belum tersimpan',
                message: _error!,
              ),
              const SizedBox(height: 16),
            ],
            _RoleOption(
              key: const Key('role-donatur'),
              title: 'Donatur',
              description:
                  'Donasikan pakaian layak pakai dan ikuti perjalanannya sampai diterima.',
              icon: Icons.volunteer_activism_outlined,
              selected: _selected == RoleIntent.donatur,
              onTap: () => setState(() => _selected = RoleIntent.donatur),
            ),
            const SizedBox(height: 12),
            _RoleOption(
              key: const Key('role-mitra'),
              title: 'Mitra',
              description:
                  'Lembaga sosial atau posko yang menyalurkan bantuan. Perlu verifikasi legalitas.',
              icon: Icons.account_balance_outlined,
              selected: _selected == RoleIntent.mitra,
              onTap: () => setState(() => _selected = RoleIntent.mitra),
            ),
            const SizedBox(height: 14),
            const PkBanner(
              message:
                  'Kamu bisa menjadi donatur dulu dan mengajukan mitra nanti. Role relawan diberikan admin.',
            ),
            const SizedBox(height: 24),
            PkButton(
              key: const Key('role-continue'),
              label: 'Lanjut',
              busy: _busy,
              onPressed: _selected == null ? null : _continue,
            ),
            const SizedBox(height: 12),
            Text(
              'Role mitra aktif hanya setelah admin menyetujui dokumen lembaga.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: '$title. $description',
      child: PkCard(
        onTap: onTap,
        color: selected ? AppColors.sage.withValues(alpha: 0.55) : AppColors.surface,
        borderColor: selected ? AppColors.forest : AppColors.line,
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? AppColors.forest : AppColors.sage,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 21,
                color: selected ? Colors.white : AppColors.forest,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.forest : AppColors.surface,
                  border: Border.all(
                    color: selected ? AppColors.forest : AppColors.line,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
