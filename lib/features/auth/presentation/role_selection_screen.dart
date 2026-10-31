import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/presentation/donatur_home_screen.dart';
import '../../mitra/presentation/mitra_verification_screen.dart';
import '../../admin/presentation/admin_approval_screen.dart';
import '../../../core/models/app_role.dart';
import '../../onboarding/services/mock_onboarding_store.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String userName;
  final String userEmail;

  const RoleSelectionScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final store = MockOnboardingStore();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pilih Peran Akun'),
        actions: [
          // Admin quick shortcut for Demo & Jury Presentation
          TextButton.icon(
            onPressed: () {
              store.setActiveRole(AppRole.admin);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminApprovalScreen(),
                ),
              );
            },
            icon: const Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppColors.secondary),
            label: const Text(
              'Panel Admin',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Greeting Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang, $userName!',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Mau berkontribusi sebagai apa?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih peran untuk menyesuaikan tampilan dan hak akses Anda.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // CARD 1: DONATUR
              _RoleCard(
                icon: Icons.volunteer_activism_rounded,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primaryLight,
                roleTitle: 'Donatur (Masyarakat Umum)',
                tagline: 'Langsung Masuk & Mulai Donasi',
                description:
                    'Saya memiliki pakaian layak pakai dan ingin menyalurkan ke program open donasi resmi lembaga terverifikasi.',
                badgeText: 'Akses Instan',
                badgeColor: AppColors.successLight,
                badgeTextColor: AppColors.success,
                buttonText: 'Lanjut sebagai Donatur',
                onTap: () {
                  store.setActiveRole(AppRole.donatur);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const DonaturHomeScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // CARD 2: MITRA KEMANUSIAAN (LEMBAGA / POSKO)
              _RoleCard(
                icon: Icons.business_rounded,
                iconColor: AppColors.secondary,
                iconBgColor: AppColors.secondaryLight,
                roleTitle: 'Mitra Kemanusiaan (Lembaga)',
                tagline: 'Wajib Verifikasi Legalitas Negara',
                description:
                    'Kami yayasan, panti asuhan, atau posko bencana resmi yang membutuhkan pasokan pakaian layak pakai bagi penerima manfaat.',
                badgeText: 'Perlu Approval Admin',
                badgeColor: AppColors.warningLight,
                badgeTextColor: AppColors.warning,
                buttonText: 'Daftar & Kirim Dokumen Legal',
                isHighlighted: true,
                onTap: () {
                  store.setActiveRole(AppRole.mitra);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MitraVerificationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // CARD 3: RELAWAN SAHABAT SANDANG
              _RoleCard(
                icon: Icons.handshake_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                roleTitle: 'Relawan (Sahabat Sandang)',
                tagline: 'Aksi Lapangan & Kurasi Sandang',
                description:
                    'Saya ingin membantu penjemputan pakaian dari donatur dan melakukan kurasi standar kelayakan fisik sebelum disalurkan.',
                badgeText: 'Komunitas Lapangan',
                badgeColor: const Color(0xFFDBEAFE),
                badgeTextColor: const Color(0xFF1D4ED8),
                buttonText: 'Pilih Relawan',
                onTap: () {
                  store.setActiveRole(AppRole.relawan);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Peran Relawan Sahabat Sandang aktif. Siap menerima tugas kurasi.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const DonaturHomeScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String roleTitle;
  final String tagline;
  final String description;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String buttonText;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.roleTitle,
    required this.tagline,
    required this.description,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.buttonText,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? AppColors.secondary.withValues(alpha: 0.5) : AppColors.border,
          width: isHighlighted ? 1.5 : 1.0,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            roleTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: isHighlighted
                ? ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    child: Text(buttonText),
                  )
                : OutlinedButton(
                    onPressed: onTap,
                    child: Text(buttonText),
                  ),
          ),
        ],
      ),
    );
  }
}
