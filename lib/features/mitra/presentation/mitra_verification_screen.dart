import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/services/mock_onboarding_store.dart';
import 'mitra_pending_screen.dart';

class MitraVerificationScreen extends StatefulWidget {
  const MitraVerificationScreen({super.key});

  @override
  State<MitraVerificationScreen> createState() => _MitraVerificationScreenState();
}

class _MitraVerificationScreenState extends State<MitraVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _orgNameController = TextEditingController(text: 'Yayasan Insan Kasih Nusantara');
  final _legalNumberController = TextEditingController(text: 'AHU-0012489.AH.01.04.Tahun 2023');
  final _picNameController = TextEditingController(text: 'H. Budi Santoso, S.Sos');
  final _picPhoneController = TextEditingController(text: '081234567890');

  String _selectedCategory = 'Yayasan Dhuafa & Yatim';
  final List<String> _categories = [
    'Yayasan Dhuafa & Yatim',
    'Posko Kemanusiaan & Bencana',
    'Panti Asuhan Terdaftar',
    'Lembaga Amil & Filantropi',
    'Komunitas Relawan Berbadan Hukum',
  ];

  final String _uploadedFileName = 'SK_KEMENKUMHAM_RESMI_2023.pdf';
  bool _isFileUploaded = true;

  @override
  void dispose() {
    _orgNameController.dispose();
    _legalNumberController.dispose();
    _picNameController.dispose();
    _picPhoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isFileUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wajib mengunggah surat legalitas / SK Kemenkumham.'),
            backgroundColor: AppColors.emergency,
          ),
        );
        return;
      }

      // Submit to store
      final store = MockOnboardingStore();
      store.submitMitraLegal(
        orgName: _orgNameController.text.trim(),
        orgCategory: _selectedCategory,
        legalNumber: _legalNumberController.text.trim(),
        documentFileName: _uploadedFileName,
        picName: _picNameController.text.trim(),
        picPhone: _picPhoneController.text.trim(),
      );

      // Navigate to Pending Approval Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MitraPendingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Legalisasi Mitra Lembaga'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.info, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Verifikasi Legalitas Negara',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Untuk mencegah penipuan dan menjaga transparansi, setiap lembaga kemanusiaan wajib melampirkan bukti legalitas sebelum disetujui oleh Admin.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Fields
                const Text(
                  '1. Informasi Lembaga',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _orgNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Resmi Lembaga / Posko',
                    hintText: 'Contoh: Posko Relawan Peduli Banjir',
                    prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Nama lembaga wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // Kategori dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Lembaga Kemanusiaan',
                    prefixIcon: Icon(Icons.category_rounded, size: 20),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _legalNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor SK Kemenkumham / Izin Dinsos',
                    hintText: 'Contoh: AHU-001234.AH.01.04.Tahun 2023',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Nomor izin resmi wajib diisi' : null,
                ),
                const SizedBox(height: 24),

                const Text(
                  '2. Unggah Dokumen Bukti Legalitas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lampirkan SK Kemenkumham, Akta Notaris, atau Surat Keterangan Dinsos (PDF/JPG, maks. 5MB).',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // Document Upload Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isFileUploaded ? AppColors.success : AppColors.border,
                      width: _isFileUploaded ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_isFileUploaded) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.success, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _uploadedFileName,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '1.4 MB • Terlampir Siap Diverifikasi',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.success),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('File dokumen diperbarui.')),
                                );
                              },
                            ),
                          ],
                        ),
                      ] else ...[
                        const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.primary),
                        const SizedBox(height: 8),
                        const Text(
                          'Ketuk untuk memilih file dokumen resmi',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _isFileUploaded = true),
                          icon: const Icon(Icons.attach_file_rounded, size: 18),
                          label: const Text('Pilih File PDF/Foto'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  '3. Kontak Penanggung Jawab (PIC)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _picNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap Penanggung Jawab',
                    hintText: 'Nama Ketua / Pengurus Posko',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Nama PIC wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _picPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp Aktif',
                    hintText: '0812xxxxxxxx',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Nomor WhatsApp wajib diisi' : null,
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Kirim Pengajuan Legalitas ke Admin'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
