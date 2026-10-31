import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../donations/models/donation.dart';
import '../models/need.dart';

class DonationSheet extends StatefulWidget {
  const DonationSheet({super.key, required this.need});

  final Need need;

  @override
  State<DonationSheet> createState() => _DonationSheetState();
}

class _DonationSheetState extends State<DonationSheet> {
  final _note = TextEditingController();

  late NeedCategory _category;
  late String _size;
  late DateTime _scheduledAt;
  late final List<DateTime> _dateOptions;

  int _step = 0;
  int _quantity = 1;
  bool _clean = false;
  bool _intact = false;
  bool _wearable = false;
  bool _conditionsError = false;
  bool _busy = false;
  String? _error;
  DonationMethod _method = DonationMethod.dropOff;

  @override
  void initState() {
    super.initState();
    final first = widget.need.items.first;
    _category = first.category;
    final sizes = _sizesFor(_category);
    _size = sizes.contains(first.sizeLabel) ? first.sizeLabel : sizes.first;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dateOptions = [
      today.add(const Duration(days: 1)),
      today.add(const Duration(days: 3)),
      today.add(const Duration(days: 5)),
    ];
    _scheduledAt = _dateOptions.first;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _maxQuantity => widget.need.remainingQty.clamp(1, 20);

  List<String> _sizesFor(NeedCategory category) {
    switch (category) {
      case NeedCategory.bayi:
        return ['0–3 bulan', '3–6 bulan', '6–12 bulan', '1–2 tahun'];
      case NeedCategory.anak:
        return ['4–6 tahun', '7–8 tahun', '9–10 tahun', '11–12 tahun'];
      case NeedCategory.sekolah:
        return ['S', 'M', 'L', 'XL'];
      case NeedCategory.dewasa:
        return ['S', 'M', 'L', 'XL', 'XXL'];
      case NeedCategory.lainnya:
        return ['All size', 'S', 'M', 'L', 'XL'];
    }
  }

  void _next() {
    if (!_clean || !_intact || !_wearable) {
      setState(() {
        _conditionsError = true;
        _error = null;
      });
      return;
    }
    setState(() {
      _conditionsError = false;
      _error = null;
      _step = 1;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final controller = AppScope.read(context);
    final current = controller.context;
    if (current == null) {
      setState(() => _error = 'Sesi berakhir. Silakan masuk lagi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await controller.repository.createDonation(
        Donation(
          id: '',
          userId: current.userId,
          needId: widget.need.id,
          needTitle: widget.need.title,
          organizationName: widget.need.organizationName,
          category: _category.label,
          sizeLabel: _size,
          quantity: _quantity,
          method: _method,
          scheduledAt: _scheduledAt,
          status: DonationStatus.submitted,
          createdAt: DateTime.now(),
          note: _note.text.trim(),
        ),
      );
      if (mounted) {
        setState(() {
          _step = 2;
          _busy = false;
        });
      }
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
          _error = 'Donasi belum bisa dicatat. Coba lagi.';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9 - bottomInset;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        color: AppColors.paper,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _step == 2 ? 'Donasi tercatat' : 'Donasi untuk',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            if (_step != 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.need.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PkProgressBar(value: (_step + 1) / 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_step + 1} dari 2',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(20, 4, 20, _step == 2 ? 24 : 16),
                child: _step == 0
                    ? _stepItems(context)
                    : _step == 1
                        ? _stepSchedule(context)
                        : _stepSuccess(context),
              ),
            ),
            if (_step != 2) _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _stepItems(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pilih pakaian', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Pakaian akan diperiksa ulang oleh relawan sebelum disalurkan.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        if (_error != null) ...[
          PkBanner(
            tone: PkBannerTone.error,
            label: 'Belum bisa dilanjutkan',
            message: _error!,
          ),
          const SizedBox(height: 14),
        ],
        _SheetDropdown<NeedCategory>(
          label: 'Kategori pakaian',
          value: _category,
          values: NeedCategory.values,
          labelOf: (value) => value.label,
          onChanged: (value) {
            setState(() {
              _category = value;
              final sizes = _sizesFor(value);
              if (!sizes.contains(_size)) _size = sizes.first;
            });
          },
        ),
        const SizedBox(height: 16),
        _SheetDropdown<String>(
          label: 'Ukuran',
          value: _size,
          values: _sizesFor(_category),
          labelOf: (value) => value,
          onChanged: (value) => setState(() => _size = value),
        ),
        const SizedBox(height: 16),
        Text(
          'Jumlah',
          style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 7),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Kurangi jumlah',
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity -= 1)
                    : null,
                icon: const Icon(Icons.remove_rounded, size: 19),
              ),
              Expanded(
                child: Text(
                  '$_quantity pakaian',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tambah jumlah',
                onPressed: _quantity < _maxQuantity
                    ? () => setState(() => _quantity += 1)
                    : null,
                icon: const Icon(Icons.add_rounded, size: 19),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sisa kebutuhan saat ini: ${widget.need.remainingQty} pakaian.',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 22),
        Text('Pemeriksaan mandiri', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        PkCheckboxRow(
          value: _clean,
          onChanged: (value) => setState(() {
            _clean = value;
            _conditionsError = false;
          }),
          label: 'Pakaian sudah dicuci dan kering.',
        ),
        PkCheckboxRow(
          value: _intact,
          onChanged: (value) => setState(() {
            _intact = value;
            _conditionsError = false;
          }),
          label: 'Tidak ada lubang, noda berat, atau resleting rusak.',
        ),
        PkCheckboxRow(
          value: _wearable,
          onChanged: (value) => setState(() {
            _wearable = value;
            _conditionsError = false;
          }),
          label: 'Masih layak dipakai sehari-hari.',
        ),
        if (_conditionsError) ...[
          const SizedBox(height: 5),
          Text(
            'Centang ketiga pemeriksaan sebelum melanjutkan.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.clay),
          ),
        ],
      ],
    );
  }

  Widget _stepSchedule(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Jadwal penyerahan', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Pilih cara dan tanggal yang paling mudah untukmu.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        if (_error != null) ...[
          PkBanner(
            tone: PkBannerTone.error,
            label: 'Belum bisa dikirim',
            message: _error!,
          ),
          const SizedBox(height: 14),
        ],
        _MethodOption(
          icon: Icons.storefront_outlined,
          title: DonationMethod.dropOff.label,
          description: 'Antar sendiri ke titik kumpul mitra sesuai jam buka.',
          selected: _method == DonationMethod.dropOff,
          onTap: () => setState(() => _method = DonationMethod.dropOff),
        ),
        const SizedBox(height: 10),
        _MethodOption(
          icon: Icons.local_shipping_outlined,
          title: DonationMethod.pickup.label,
          description:
              'Relawan akan menghubungi lewat kontak akun untuk mengambil pakaian.',
          selected: _method == DonationMethod.pickup,
          onTap: () => setState(() => _method = DonationMethod.pickup),
        ),
        const SizedBox(height: 22),
        Text('Tanggal', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final date in _dateOptions)
              _DateChip(
                date: date,
                selected: _scheduledAt == date,
                onTap: () => setState(() => _scheduledAt = date),
              ),
          ],
        ),
        const SizedBox(height: 20),
        PkTextField(
          label: 'Catatan untuk relawan',
          controller: _note,
          hint: 'Contoh: titip ke posko sore hari',
          optional: true,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        PkCard(
          color: AppColors.parchment,
          borderColor: const Color(0xFFE7DDC8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ringkasan donasi', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              PkKeyValue(label: 'Kebutuhan', value: widget.need.title),
              PkKeyValue(
                label: 'Pakaian',
                value: '$_quantity · ${_category.label} · $_size',
              ),
              PkKeyValue(label: 'Metode', value: _method.label),
              PkKeyValue(label: 'Tanggal', value: formatDate(_scheduledAt)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepSuccess(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.sage,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 28,
            color: AppColors.forest,
          ),
        ),
        const SizedBox(height: 16),
        Text('Terima kasih', style: theme.textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(
          'Donasimu tercatat. Mitra akan mengkurasi pakaian lalu memperbarui statusnya di Donasiku.',
          style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        PkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.need.title,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const PkStatusChip(
                    label: 'Menunggu kurasi',
                    tone: PkStatusTone.warning,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PkKeyValue(
                label: 'Pakaian',
                value: '$_quantity · ${_category.label} · $_size',
              ),
              PkKeyValue(label: 'Metode', value: _method.label),
              PkKeyValue(label: 'Tanggal', value: formatDate(_scheduledAt)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PkButton(
          label: 'Lihat Donasiku',
          onPressed: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 4),
        PkButton(
          label: 'Tutup',
          variant: PkButtonVariant.ghost,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: _step == 0
          ? PkButton(label: 'Lanjut ke jadwal', onPressed: _next)
          : Row(
              children: [
                Expanded(
                  child: PkButton(
                    label: 'Kembali',
                    variant: PkButtonVariant.secondary,
                    onPressed: _busy ? null : () => setState(() => _step = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PkButton(
                    label: 'Kirim donasi',
                    busy: _busy,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SheetDropdown<T> extends StatelessWidget {
  const _SheetDropdown({
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

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 21,
              color: selected ? AppColors.forest : AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.forest : AppColors.surface,
                border: Border.all(
                  color: selected ? AppColors.forest : AppColors.line,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: '${relativeDay(date)}, ${formatDate(date)}',
      child: Material(
        color: selected ? AppColors.sage : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.forest : AppColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relativeDay(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.forest : AppColors.ink,
                  ),
                ),
                Text(
                  formatDateShort(date),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
