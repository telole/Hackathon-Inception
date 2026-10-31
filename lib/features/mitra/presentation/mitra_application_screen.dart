import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_scope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../models/mitra_application.dart';

class MitraApplicationScreen extends StatefulWidget {
  const MitraApplicationScreen({super.key});

  @override
  State<MitraApplicationScreen> createState() => _MitraApplicationScreenState();
}

class _MitraApplicationScreenState extends State<MitraApplicationScreen> {
  static const _kinds = [
    'Lembaga sosial',
    'Posko bencana',
    'Panti asuhan',
    'Komunitas',
    'Lainnya',
  ];

  final _scroll = ScrollController();
  final _orgName = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _contactName = TextEditingController();
  final _phone = TextEditingController();
  final _beneficiaries = TextEditingController();
  final _legalNumber = TextEditingController();
  final _legalIssuer = TextEditingController();

  String _kind = _kinds.first;
  DateTime? _legalDate;
  MitraDocument? _document1;
  MitraDocument? _document2;
  bool _declared = false;
  int _step = 1;
  bool _busy = false;
  String? _error;

  String? _orgNameError;
  String? _areaError;
  String? _addressError;
  String? _contactNameError;
  String? _phoneError;
  String? _beneficiaryError;
  String? _legalNumberError;
  String? _issuerError;
  String? _dateError;
  String? _documentError;
  bool _declarationError = false;

  @override
  void initState() {
    super.initState();
    final controller = AppScope.read(context);
    final application = controller.context?.mitraApplication;
    if (application != null) {
      _orgName.text = application.organizationName;
      _kind = _kinds.contains(application.organizationKind)
          ? application.organizationKind
          : _kinds.first;
      _area.text = application.area;
      _address.text = application.pointAddress;
      _contactName.text = application.contactName;
      _phone.text = application.contactPhone;
      _beneficiaries.text = application.beneficiaryEstimate?.toString() ?? '';
      _legalNumber.text = application.legalNumber;
      _legalIssuer.text = application.legalIssuer;
      _legalDate = application.legalIssuedAt;
      if (application.documents.isNotEmpty) _document1 = application.documents[0];
      if (application.documents.length > 1) _document2 = application.documents[1];
    } else {
      final current = controller.context;
      if (current != null) {
        _contactName.text = current.displayName;
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _orgName.dispose();
    _area.dispose();
    _address.dispose();
    _contactName.dispose();
    _phone.dispose();
    _beneficiaries.dispose();
    _legalNumber.dispose();
    _legalIssuer.dispose();
    super.dispose();
  }

  MitraApplication _buildApplication() {
    final controller = AppScope.read(context);
    final current = controller.context!;
    final existing = current.mitraApplication;
    final documents = <MitraDocument>[?_document1, ?_document2];
    return MitraApplication(
      id: existing?.id ?? '',
      userId: current.userId,
      applicantName: current.displayName,
      applicantEmail: current.email,
      organizationName: _orgName.text.trim(),
      organizationKind: _kind,
      area: _area.text.trim(),
      pointAddress: _address.text.trim(),
      contactName: _contactName.text.trim(),
      contactPhone: _phone.text.trim(),
      beneficiaryEstimate: int.tryParse(_beneficiaries.text.trim()),
      legalNumber: _legalNumber.text.trim(),
      legalIssuer: _legalIssuer.text.trim(),
      legalIssuedAt: _legalDate,
      documents: documents,
      status: MitraApplicationStatus.draft,
      organizationId: existing?.organizationId,
    );
  }

  bool _validateStepOne() {
    final phoneDigits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final beneficiaryText = _beneficiaries.text.trim();
    final beneficiary = beneficiaryText.isEmpty ? null : int.tryParse(beneficiaryText);
    setState(() {
      _orgNameError = _orgName.text.trim().isEmpty
          ? 'Nama lembaga wajib diisi.'
          : null;
      _areaError = _area.text.trim().isEmpty
          ? 'Wilayah layanan wajib diisi.'
          : null;
      _addressError = _address.text.trim().isEmpty
          ? 'Alamat titik kumpul wajib diisi.'
          : null;
      _contactNameError = _contactName.text.trim().isEmpty
          ? 'Nama penanggung jawab wajib diisi.'
          : null;
      _phoneError = phoneDigits.length < 9
          ? 'Nomor WhatsApp minimal 9 digit.'
          : null;
      _beneficiaryError = beneficiaryText.isNotEmpty &&
              (beneficiary == null || beneficiary <= 0)
          ? 'Isi dengan angka lebih dari 0.'
          : null;
      _error = null;
    });
    return _orgNameError == null &&
        _areaError == null &&
        _addressError == null &&
        _contactNameError == null &&
        _phoneError == null &&
        _beneficiaryError == null;
  }

  bool _validateStepTwo() {
    setState(() {
      _legalNumberError = _legalNumber.text.trim().isEmpty
          ? 'Nomor dokumen wajib diisi.'
          : null;
      _issuerError = _legalIssuer.text.trim().isEmpty
          ? 'Instansi penerbit wajib diisi.'
          : null;
      _dateError = _legalDate == null
          ? 'Tanggal dokumen wajib dipilih.'
          : _legalDate!.isAfter(DateTime.now())
              ? 'Tanggal tidak boleh di masa depan.'
              : null;
      _documentError =
          _document1 == null ? 'Unggah minimal satu dokumen legalitas.' : null;
      _declarationError = !_declared;
      _error = null;
    });
    return _legalNumberError == null &&
        _issuerError == null &&
        _dateError == null &&
        _documentError == null &&
        _declared;
  }

  Future<bool> _saveDraft({bool feedback = false}) async {
    if (_busy) return false;
    final controller = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await controller.saveMitraDraft(_buildApplication());
      if (feedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft pengajuan tersimpan.')),
        );
      }
      return true;
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return false;
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Draft belum bisa disimpan. Coba lagi.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _next() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_validateStepOne()) return;
    final saved = await _saveDraft();
    if (!saved || !mounted) return;
    setState(() => _step = 2);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_validateStepOne() || !_validateStepTwo()) {
      if (_step == 1) setState(() => _step = 2);
      return;
    }
    final controller = AppScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await controller.submitMitraApplication(_buildApplication());
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Pengajuan belum bisa dikirim. Periksa jaringan lalu coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _legalDate ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(1990),
      lastDate: now,
      locale: const Locale('id', 'ID'),
      helpText: 'Tanggal dokumen',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null && mounted) {
      setState(() {
        _legalDate = picked;
        _dateError = null;
      });
    }
  }

  Future<void> _attachDocument(int slot) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Lampirkan dokumen',
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih gambar dari galeri atau pakai dokumen contoh untuk simulasi.',
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _SheetOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Pilih gambar dari galeri',
                  subtitle: 'JPG atau PNG, maksimal 5 MB',
                  onTap: () => Navigator.pop(sheetContext, 'gallery'),
                ),
                const SizedBox(height: 8),
                _SheetOption(
                  icon: Icons.description_outlined,
                  title: 'Gunakan dokumen contoh',
                  subtitle: 'Berkas dummy, bukan dokumen asli',
                  onTap: () => Navigator.pop(sheetContext, 'sample'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mode simulasi tidak menyimpan berkas ke server.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    if (choice == 'sample') {
      _useSampleDocument(slot);
      return;
    }
    await _pickFromGallery(slot);
  }

  Future<void> _pickFromGallery(int slot) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 85,
      );
      if (picked == null) return;
      final length = await picked.length();
      if (length > 5 * 1024 * 1024) {
        if (!mounted) return;
        setState(() {
          _documentError = 'Ukuran dokumen melebihi 5 MB. Pilih berkas lain.';
        });
        return;
      }
      final Uint8List bytes = await picked.readAsBytes();
      final lower = picked.name.toLowerCase();
      final mime = lower.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final document = MitraDocument(
        name: picked.name,
        sizeBytes: length,
        mimeType: mime,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        if (slot == 0) {
          _document1 = document;
        } else {
          _document2 = document;
        }
        _documentError = null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Galeri tidak bisa dibuka. Gunakan dokumen contoh untuk melanjutkan.',
          ),
        ),
      );
    }
  }

  void _useSampleDocument(int slot) {
    final rawName = _orgName.text.trim();
    final slug = rawName.isEmpty
        ? 'Lembaga'
        : rawName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    final document = slot == 0
        ? MitraDocument(
            name: 'SK-Kemenkumham-$slug.pdf',
            sizeBytes: 842 * 1024,
            mimeType: 'application/pdf',
            isSample: true,
          )
        : MitraDocument(
            name: 'Akta-Notaris-$slug.jpg',
            sizeBytes: 640 * 1024,
            mimeType: 'image/jpeg',
            isSample: true,
          );
    setState(() {
      if (slot == 0) {
        _document1 = document;
      } else {
        _document2 = document;
      }
      _documentError = null;
    });
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar dari pengajuan?'),
          content: const Text(
            'Draft yang sudah diisi tetap tersimpan. Kamu bisa melanjutkan pengajuan dari Profil.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Lanjutkan mengisi'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.clay),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
    if (leave != true || !mounted) return;
    await AppScope.read(context).cancelMitraApplication();
  }

  void _backStep() {
    if (_step == 2) {
      setState(() => _step = 1);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_step == 2) {
          _backStep();
        } else {
          _confirmExit();
        }
      },
      child: PkScaffold(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const PkLogo(size: 17),
                        const Spacer(),
                        TextButton(
                          onPressed: _busy ? null : () => _saveDraft(feedback: true),
                          child: const Text('Simpan'),
                        ),
                        IconButton(
                          tooltip: 'Batalkan pengajuan',
                          onPressed: _busy ? null : _confirmExit,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    PkStepHeader(
                      step: _step,
                      total: 2,
                      title: _step == 1
                          ? 'Identitas lembaga'
                          : 'Legalitas lembaga',
                      onBack: _step == 1 ? null : _backStep,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == 1
                          ? 'Data ini dipakai admin untuk mencocokkan lembaga dengan dokumen resmi.'
                          : 'Lampirkan dokumen yang menunjukkan lembaga ini resmi dan berbadan hukum.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      PkBanner(
                        tone: PkBannerTone.error,
                        label: 'Belum bisa dilanjutkan',
                        message: _error!,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_step == 1) ..._stepOne(theme) else ..._stepTwo(theme),
                  ],
                ),
              ),
            ),
            _bottomBar(theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _stepOne(ThemeData theme) {
    return [
      const _SectionLabel('DATA LEMBAGA'),
      const SizedBox(height: 12),
      PkTextField(
        label: 'Nama lembaga',
        controller: _orgName,
        hint: 'Contoh: Yayasan Sahabat Sandang',
        textCapitalization: TextCapitalization.words,
        errorText: _orgNameError,
        onChanged: (_) {
          if (_orgNameError != null) setState(() => _orgNameError = null);
        },
      ),
      const SizedBox(height: 16),
      _DropdownField(
        label: 'Jenis lembaga',
        value: _kind,
        items: _kinds,
        onChanged: (value) => setState(() => _kind = value),
      ),
      const SizedBox(height: 16),
      PkTextField(
        label: 'Wilayah layanan',
        controller: _area,
        hint: 'Kota atau kecamatan',
        textCapitalization: TextCapitalization.words,
        errorText: _areaError,
        onChanged: (_) {
          if (_areaError != null) setState(() => _areaError = null);
        },
      ),
      const SizedBox(height: 16),
      PkTextField(
        label: 'Alamat titik kumpul',
        controller: _address,
        hint: 'Alamat yang bisa dituju donatur',
        maxLines: 2,
        errorText: _addressError,
        onChanged: (_) {
          if (_addressError != null) setState(() => _addressError = null);
        },
      ),
      const SizedBox(height: 24),
      const _SectionLabel('PENANGGUNG JAWAB'),
      const SizedBox(height: 12),
      PkTextField(
        label: 'Nama penanggung jawab',
        controller: _contactName,
        hint: 'Nama lengkap',
        textCapitalization: TextCapitalization.words,
        errorText: _contactNameError,
        onChanged: (_) {
          if (_contactNameError != null) {
            setState(() => _contactNameError = null);
          }
        },
      ),
      const SizedBox(height: 16),
      PkTextField(
        label: 'Nomor WhatsApp',
        controller: _phone,
        hint: '08xx xxxx xxxx',
        keyboardType: TextInputType.phone,
        errorText: _phoneError,
        onChanged: (_) {
          if (_phoneError != null) setState(() => _phoneError = null);
        },
      ),
      const SizedBox(height: 16),
      PkTextField(
        label: 'Perkiraan penerima manfaat',
        controller: _beneficiaries,
        hint: 'Jumlah orang',
        optional: true,
        keyboardType: TextInputType.number,
        errorText: _beneficiaryError,
        onChanged: (_) {
          if (_beneficiaryError != null) {
            setState(() => _beneficiaryError = null);
          }
        },
      ),
      const SizedBox(height: 16),
      const PkBanner(
        message:
            'Nomor WhatsApp hanya dipakai admin untuk konfirmasi legalitas, tidak ditampilkan ke donatur.',
      ),
    ];
  }

  List<Widget> _stepTwo(ThemeData theme) {
    return [
      const _SectionLabel('DOKUMEN RESMI'),
      const SizedBox(height: 12),
      PkTextField(
        label: 'Nomor dokumen',
        controller: _legalNumber,
        hint: 'SK Kemenkumham, akta notaris, atau surat rekomendasi',
        errorText: _legalNumberError,
        onChanged: (_) {
          if (_legalNumberError != null) {
            setState(() => _legalNumberError = null);
          }
        },
      ),
      const SizedBox(height: 16),
      PkTextField(
        label: 'Instansi penerbit',
        controller: _legalIssuer,
        hint: 'Contoh: Kementerian Hukum dan HAM RI',
        textCapitalization: TextCapitalization.words,
        errorText: _issuerError,
        onChanged: (_) {
          if (_issuerError != null) setState(() => _issuerError = null);
        },
      ),
      const SizedBox(height: 16),
      _DateField(
        label: 'Tanggal dokumen',
        value: _legalDate,
        errorText: _dateError,
        onTap: _busy ? null : _pickDate,
      ),
      const SizedBox(height: 24),
      const _SectionLabel('BERKAS LEGALITAS'),
      const SizedBox(height: 12),
      PkFileField(
        label: 'Dokumen utama',
        fileName: _document1?.name,
        sizeBytes: _document1?.sizeBytes,
        isImage: _document1?.isImage ?? false,
        previewBytes: _document1?.bytes,
        onPick: _busy ? () {} : () => _attachDocument(0),
        onRemove: _busy ? null : () => setState(() => _document1 = null),
        errorText: _documentError,
        pickLabel: 'Unggah surat kelembagaan',
      ),
      const SizedBox(height: 14),
      PkFileField(
        label: 'Dokumen pendukung',
        optional: true,
        fileName: _document2?.name,
        sizeBytes: _document2?.sizeBytes,
        isImage: _document2?.isImage ?? false,
        previewBytes: _document2?.bytes,
        onPick: _busy ? () {} : () => _attachDocument(1),
        onRemove: _busy ? null : () => setState(() => _document2 = null),
        pickLabel: 'Unggah akta atau rekomendasi',
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Dokumen hanya dapat dilihat admin. Jangan unggah dokumen asli di mode simulasi.',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      PkCheckboxRow(
        value: _declared,
        onChanged: (value) => setState(() {
          _declared = value;
          if (value) _declarationError = false;
        }),
        label:
            'Saya menyatakan dokumen ini asli dan berhak mewakili lembaga.',
      ),
      if (_declarationError) ...[
        const SizedBox(height: 4),
        Text(
          'Pernyataan ini perlu dicentang sebelum mengirim.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.clay),
        ),
      ],
      const SizedBox(height: 20),
      PkCard(
        color: AppColors.parchment,
        borderColor: const Color(0xFFE7DDC8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan pengajuan', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            PkKeyValue(
              label: 'Lembaga',
              value: _orgName.text.trim().isEmpty
                  ? 'Belum diisi'
                  : _orgName.text.trim(),
            ),
            PkKeyValue(
              label: 'Wilayah',
              value: _area.text.trim().isEmpty ? 'Belum diisi' : _area.text.trim(),
            ),
            PkKeyValue(
              label: 'Dokumen',
              value: '${[
                if (_document1 != null) 1,
                if (_document2 != null) 1,
              ].length} berkas',
            ),
          ],
        ),
      ),
    ];
  }

  Widget _bottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: _step == 1
          ? PkButton(
              key: const Key('mitra-next'),
              label: 'Lanjut ke legalitas',
              busy: _busy,
              onPressed: _next,
            )
          : Row(
              children: [
                Expanded(
                  child: PkButton(
                    label: 'Kembali',
                    variant: PkButtonVariant.secondary,
                    onPressed: _busy ? null : _backStep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PkButton(
                    key: const Key('mitra-submit'),
                    label: 'Kirim pengajuan',
                    busy: _busy,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.forest,
          ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 7),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.muted,
                size: 20,
              ),
              style: theme.textTheme.bodyLarge,
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              items: [
                for (final item in items)
                  DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
              ],
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 7),
        Semantics(
          button: true,
          label: value == null
              ? '$label, belum dipilih'
              : '$label, ${formatDate(value!)}',
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: errorText == null ? AppColors.line : AppColors.clay,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: value == null ? AppColors.muted : AppColors.forest,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      value == null ? 'Pilih tanggal' : formatDate(value!),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: value == null ? AppColors.textMuted : AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.clay),
          ),
        ],
      ],
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 20, color: AppColors.forest),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
