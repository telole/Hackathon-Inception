import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../needs/models/need.dart';

class CreateNeedScreen extends StatefulWidget {
  const CreateNeedScreen({super.key});

  @override
  State<CreateNeedScreen> createState() => _CreateNeedScreenState();
}

class _CreateNeedScreenState extends State<CreateNeedScreen> {
  static const _ageGroups = [
    'Bayi',
    'Anak',
    'Remaja',
    'Dewasa',
    'Lansia',
    'Semua usia',
  ];

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _size = TextEditingController();
  final _quantity = TextEditingController(text: '10');
  final _pointName = TextEditingController();
  final _pointAddress = TextEditingController();

  NeedCategory _category = NeedCategory.dewasa;
  String _ageGroup = 'Dewasa';
  late DateTime _deadline;
  bool _urgent = false;
  bool _busy = false;
  String? _error;

  String? _titleError;
  String? _descriptionError;
  String? _sizeError;
  String? _quantityError;
  String? _pointNameError;
  String? _pointAddressError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _deadline = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 14));
    final organization = AppScope.read(context).context?.organization;
    if (organization != null) {
      _pointName.text = 'Posko ${organization.area}';
      _pointAddress.text = organization.pointAddress;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _size.dispose();
    _quantity.dispose();
    _pointName.dispose();
    _pointAddress.dispose();
    super.dispose();
  }

  String get _sizeHint {
    switch (_category) {
      case NeedCategory.bayi:
        return 'Contoh: 6–12 bulan';
      case NeedCategory.anak:
        return 'Contoh: 7–8 tahun';
      case NeedCategory.sekolah:
        return 'Contoh: S–XL';
      case NeedCategory.dewasa:
        return 'Contoh: M–L';
      case NeedCategory.lainnya:
        return 'Contoh: All size';
    }
  }

  bool _validate() {
    final quantity = int.tryParse(_quantity.text.trim());
    setState(() {
      _titleError = _title.text.trim().length < 4
          ? 'Judul minimal 4 karakter.'
          : null;
      _descriptionError = _description.text.trim().length < 10
          ? 'Jelaskan kebutuhan minimal 10 karakter.'
          : null;
      _sizeError =
          _size.text.trim().isEmpty ? 'Ukuran wajib diisi.' : null;
      _quantityError = quantity == null || quantity < 1 || quantity > 500
          ? 'Isi jumlah antara 1 dan 500.'
          : null;
      _pointNameError = _pointName.text.trim().isEmpty
          ? 'Nama titik kumpul wajib diisi.'
          : null;
      _pointAddressError = _pointAddress.text.trim().isEmpty
          ? 'Alamat titik kumpul wajib diisi.'
          : null;
      _error = null;
    });
    return _titleError == null &&
        _descriptionError == null &&
        _sizeError == null &&
        _quantityError == null &&
        _pointNameError == null &&
        _pointAddressError == null;
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 120)),
      locale: const Locale('id', 'ID'),
      helpText: 'Tenggat kebutuhan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null && mounted) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    final controller = AppScope.read(context);
    final current = controller.context;
    final organization = current?.organization;
    if (current == null || organization == null) {
      setState(() => _error = 'Sesi mitra tidak ditemukan. Masuk lagi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await controller.repository.createNeed(
        Need(
          id: '',
          organizationId: organization.id,
          organizationName: organization.name,
          organizationVerified: organization.verified,
          title: _title.text.trim(),
          description: _description.text.trim(),
          city: organization.area,
          pointName: _pointName.text.trim(),
          pointAddress: _pointAddress.text.trim(),
          deadline: _deadline,
          items: [
            NeedItem(
              category: _category,
              sizeLabel: _size.text.trim(),
              ageGroup: _ageGroup,
              requestedQty: int.parse(_quantity.text.trim()),
              receivedQty: 0,
            ),
          ],
          createdAt: DateTime.now(),
          urgent: _urgent,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Kebutuhan belum bisa diterbitkan. Coba lagi.';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PkScaffold(
      appBar: const PkAppBar(title: 'Buat kebutuhan', showBack: true),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Terbitkan kebutuhan',
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kebutuhan akan tampil ke donatur karena lembaga ini sudah terverifikasi.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    PkBanner(
                      tone: PkBannerTone.error,
                      label: 'Belum bisa diterbitkan',
                      message: _error!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  PkTextField(
                    label: 'Judul kebutuhan',
                    controller: _title,
                    hint: 'Contoh: Pakaian harian anak',
                    textCapitalization: TextCapitalization.sentences,
                    errorText: _titleError,
                    onChanged: (_) {
                      if (_titleError != null) {
                        setState(() => _titleError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  PkTextField(
                    label: 'Penjelasan',
                    controller: _description,
                    hint: 'Jelaskan siapa penerima dan kondisi pakaian yang dibutuhkan.',
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    errorText: _descriptionError,
                    onChanged: (_) {
                      if (_descriptionError != null) {
                        setState(() => _descriptionError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _SelectField<NeedCategory>(
                    label: 'Kategori',
                    value: _category,
                    values: NeedCategory.values,
                    labelOf: (value) => value.label,
                    onChanged: (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: PkTextField(
                          label: 'Ukuran',
                          controller: _size,
                          hint: _sizeHint,
                          errorText: _sizeError,
                          onChanged: (_) {
                            if (_sizeError != null) {
                              setState(() => _sizeError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PkTextField(
                          label: 'Jumlah',
                          controller: _quantity,
                          hint: '10',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          errorText: _quantityError,
                          onChanged: (_) {
                            if (_quantityError != null) {
                              setState(() => _quantityError = null);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SelectField<String>(
                    label: 'Kelompok usia',
                    value: _ageGroup,
                    values: _ageGroups,
                    labelOf: (value) => value,
                    onChanged: (value) => setState(() => _ageGroup = value),
                  ),
                  const SizedBox(height: 16),
                  _DateField(
                    label: 'Tenggat kebutuhan',
                    value: _deadline,
                    onTap: _pickDeadline,
                  ),
                  const SizedBox(height: 16),
                  PkTextField(
                    label: 'Nama titik kumpul',
                    controller: _pointName,
                    hint: 'Contoh: Posko Tebet',
                    textCapitalization: TextCapitalization.words,
                    errorText: _pointNameError,
                    onChanged: (_) {
                      if (_pointNameError != null) {
                        setState(() => _pointNameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  PkTextField(
                    label: 'Alamat titik kumpul',
                    controller: _pointAddress,
                    hint: 'Alamat yang bisa dituju donatur',
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    errorText: _pointAddressError,
                    onChanged: (_) {
                      if (_pointAddressError != null) {
                        setState(() => _pointAddressError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tandai mendesak',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tampil lebih dulu di beranda donatur.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _urgent,
                          onChanged: (value) =>
                              setState(() => _urgent = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const PkBanner(
                    message:
                        'Data simulasi. Kebutuhan yang dibuat akan hilang saat data demo direset.',
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: PkButton(
              label: 'Terbitkan kebutuhan',
              busy: _busy,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

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
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.muted,
              ),
              style: theme.textTheme.bodyLarge,
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              items: [
                for (final item in values)
                  DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelOf(item)),
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
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

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
          label: '$label, ${formatDate(value)}',
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
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 10),
                    Text(formatDate(value), style: theme.textTheme.bodyLarge),
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
      ],
    );
  }
}
