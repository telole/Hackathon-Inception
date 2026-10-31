import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_card.dart';
import '../../../core/widgets/stitch_painter.dart';
import '../../home/application/home_models.dart';
import '../../home/application/home_providers.dart';
import '../application/donation_models.dart';
import '../application/donation_photo_picker.dart';
import '../application/donation_providers.dart';

class DonationFlowScreen extends ConsumerStatefulWidget {
  const DonationFlowScreen({
    super.key,
    this.initialCategory,
    this.preferredNeedId,
  });

  final DonationCategory? initialCategory;
  final String? preferredNeedId;

  @override
  ConsumerState<DonationFlowScreen> createState() => _DonationFlowScreenState();
}

class _DonationFlowScreenState extends ConsumerState<DonationFlowScreen> {
  static const _steps = ['Pakaian', 'Detail', 'Penyaluran'];

  final _pageController = PageController();
  final _addressController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _currentStep = 0;
  DonationCategory? _category;
  ClothingType? _clothingType;
  ClothingSize? _size;
  DeliveryMethod? _deliveryMethod;
  DonationPoint? _donationPoint;
  Uint8List? _photoBytes;
  int _quantity = 1;
  bool _isSaving = false;
  bool _isClean = false;
  bool _isIntact = false;
  bool _isNotTorn = false;
  bool _draftStarted = false;
  String? _draftId;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToStep(int step) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(step);
    } else {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _pickPhoto() async {
    try {
      if (_draftStarted) return;
      final picked = await ref.read(donationPhotoPickerProvider).pick();
      if (picked == null) return;
      if (picked.bytes.length > 1048576) {
        _showMessage(
          'Ukuran foto harus maksimal 1 MB. Pilih foto yang lebih kecil.',
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _photoBytes = picked.bytes;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      _showMessage('Foto tidak dapat dibuka. Coba pilih gambar lain. ($error)');
    }
  }

  Future<void> _chooseDonationPoint() async {
    final point = await context.push<DonationPoint>('/points');
    if (!mounted || point == null) return;
    setState(() => _donationPoint = point);
  }

  void _continue() {
    if (_currentStep == 0) {
      if (_category == null) {
        _showMessage('Pilih kategori pakaian terlebih dahulu.');
        return;
      }
      if (_clothingType == null) {
        _showMessage('Pilih jenis pakaian terlebih dahulu.');
        return;
      }
      if (_photoBytes == null) {
        _showMessage('Tambahkan satu foto pakaian untuk melanjutkan.');
        return;
      }
      _goToStep(1);
      return;
    }
    if (_currentStep == 1) {
      if (_size == null) {
        _showMessage('Pilih ukuran pakaian terlebih dahulu.');
        return;
      }
      if (!_isClean || !_isIntact || !_isNotTorn) {
        _showMessage('Pastikan semua pemeriksaan kelayakan sudah dicentang.');
        return;
      }
      _goToStep(2);
      return;
    }
    _saveDonation();
  }

  Future<void> _saveDonation() async {
    if (_deliveryMethod == null) {
      _showMessage('Pilih cara penyaluran donasi.');
      return;
    }
    if (_deliveryMethod == DeliveryMethod.pickup &&
        (_addressController.text.trim().isEmpty ||
            _contactNameController.text.trim().isEmpty ||
            _phoneController.text.trim().isEmpty)) {
      _showMessage('Lengkapi nama, nomor telepon, dan alamat penjemputan.');
      return;
    }
    if (_donationPoint == null) {
      _showMessage('Pilih titik layanan donasi.');
      return;
    }
    final category = _category;
    final clothingType = _clothingType;
    final size = _size;
    final photoBytes = _photoBytes;
    if (category == null ||
        clothingType == null ||
        size == null ||
        photoBytes == null) {
      _showMessage('Lengkapi detail pakaian terlebih dahulu.');
      return;
    }

    setState(() => _isSaving = true);
    _draftId ??= const Uuid().v4();
    _draftStarted = true;
    try {
      final donation = await ref
          .read(donationRepositoryProvider)
          .saveDonation(
            draftId: _draftId!,
            category: category,
            clothingType: clothingType,
            size: size,
            quantity: _quantity,
            deliveryMethod: _deliveryMethod!,
            photoBytes: photoBytes,
            cleanCheck: _isClean,
            intactCheck: _isIntact,
            notTornCheck: _isNotTorn,
            pickupAddress: _addressController.text,
            contactName: _contactNameController.text,
            phone: _phoneController.text,
            donationPoint: _donationPoint!,
            preferredNeedId: widget.preferredNeedId,
          );
      ref.invalidate(donationsProvider);
      ref.invalidate(homeSnapshotProvider);
      if (!mounted) return;
      context.go('/success', extra: donation);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Donasi belum berhasil dikirim. $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donasi pakaian'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          tooltip: 'Kembali ke beranda',
          icon: const Icon(Icons.arrow_back_rounded),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLg,
                tokens.spaceSm,
                tokens.spaceLg,
                tokens.spaceMd,
              ),
              child: _DonationStepper(
                labels: _steps,
                currentStep: _currentStep,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (step) => setState(() => _currentStep = step),
                children: [
                  _ClothingPage(
                    category: _category,
                    onCategorySelected: (value) => setState(() {
                      _category = value;
                      if (value == DonationCategory.batikFormal) {
                        _clothingType = ClothingType.batik;
                      } else if (value == DonationCategory.schoolUniform) {
                        _clothingType = ClothingType.uniform;
                      }
                    }),
                    clothingType: _clothingType,
                    onClothingTypeSelected: (value) =>
                        setState(() => _clothingType = value),
                    photoBytes: _photoBytes,
                    onPickPhoto: _pickPhoto,
                    photoLocked: _draftStarted,
                    onRemovePhoto: () => setState(() => _photoBytes = null),
                  ),
                  _DetailsPage(
                    size: _size,
                    quantity: _quantity,
                    cleanCheck: _isClean,
                    intactCheck: _isIntact,
                    notTornCheck: _isNotTorn,
                    onSizeSelected: (value) => setState(() => _size = value),
                    onQuantityChanged: (value) =>
                        setState(() => _quantity = value),
                    onCleanChanged: (value) => setState(() => _isClean = value),
                    onIntactChanged: (value) =>
                        setState(() => _isIntact = value),
                    onNotTornChanged: (value) =>
                        setState(() => _isNotTorn = value),
                  ),
                  _DeliveryPage(
                    selectedMethod: _deliveryMethod,
                    addressController: _addressController,
                    contactNameController: _contactNameController,
                    phoneController: _phoneController,
                    donationPoint: _donationPoint,
                    onMethodSelected: (method) {
                      setState(() {
                        _deliveryMethod = method;
                      });
                    },
                    onChoosePoint: _chooseDonationPoint,
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: EdgeInsets.fromLTRB(
                tokens.spaceLg,
                tokens.spaceSm,
                tokens.spaceLg,
                tokens.spaceMd,
              ),
              child: PkButton(
                label: _currentStep == _steps.length - 1
                    ? 'Catat donasiku'
                    : 'Lanjutkan',
                icon: _currentStep == _steps.length - 1
                    ? Icons.favorite_border_rounded
                    : Icons.arrow_forward_rounded,
                expanded: true,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationStepper extends StatelessWidget {
  const _DonationStepper({required this.labels, required this.currentStep});

  final List<String> labels;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Column(
      children: [
        Row(
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              Expanded(
                child: _StepLabel(
                  number: index + 1,
                  label: labels[index],
                  active: index == currentStep,
                  complete: index < currentStep,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => CustomPaint(
            size: Size(constraints.maxWidth, 4),
            painter: StitchPainter(
              color: tokens.border,
              shape: StitchShape.horizontal,
              strokeWidth: 2,
              dashLength: 5,
              gapLength: 4,
            ),
            foregroundPainter: StitchPainter(
              color: tokens.accent,
              shape: StitchShape.horizontal,
              strokeWidth: 2,
              dashLength: 5,
              gapLength: 4,
              progress: currentStep / (labels.length - 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({
    required this.number,
    required this.label,
    required this.active,
    required this.complete,
  });

  final int number;
  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final color = active || complete ? tokens.accentStrong : tokens.mutedText;
    return Semantics(
      label: 'Langkah $number: $label${complete ? ', selesai' : ''}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? tokens.accentStrong : tokens.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: active || complete ? tokens.accentStrong : tokens.border,
              ),
            ),
            child: complete
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '$number',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: active ? Colors.white : color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClothingPage extends StatelessWidget {
  const _ClothingPage({
    required this.category,
    required this.onCategorySelected,
    required this.clothingType,
    required this.onClothingTypeSelected,
    required this.photoBytes,
    required this.photoLocked,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final DonationCategory? category;
  final ValueChanged<DonationCategory> onCategorySelected;
  final ClothingType? clothingType;
  final ValueChanged<ClothingType> onClothingTypeSelected;
  final Uint8List? photoBytes;
  final bool photoLocked;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return _StepScrollView(
      children: [
        const _StepIntro(
          eyebrow: 'LANGKAH 1 · PAKAIAN',
          title: 'Mulai dari isi lemari.',
          description: 'Tentukan penerima, jenis pakaian, lalu tambahkan foto untuk pemeriksaan.',
        ),
        SizedBox(height: tokens.spaceLg),
        _CategoryGrid(selected: category, onSelected: onCategorySelected),
        SizedBox(height: tokens.spaceLg),
        Text(
          'Jenis pakaian',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in ClothingType.values)
              _SelectCard(
                selected: clothingType == type,
                onTap: () => onClothingTypeSelected(type),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, size: 18),
                    const SizedBox(width: 6),
                    Text(type.label),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: tokens.spaceLg),
        _PhotoPicker(
          photoBytes: photoBytes,
          locked: photoLocked,
          onPick: onPickPhoto,
          onRemove: onRemovePhoto,
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelected});

  final DonationCategory? selected;
  final ValueChanged<DonationCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - tokens.spaceSm) / 2;
        return Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceSm,
          children: [
            for (final category in DonationCategory.values)
              SizedBox(
                width: width,
                child: _SelectCard(
                  selected: selected == category,
                  onTap: () => onSelected(category),
                  child: Row(
                    children: [
                      Icon(category.icon, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoBytes,
    required this.locked,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? photoBytes;
  final bool locked;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Semantics(
      label: photoBytes == null
          ? 'Tambah foto pakaian, wajib'
          : 'Foto pakaian terpilih',
      child: PkCard(
        onTap: locked ? null : onPick,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 64,
                height: 64,
                child: photoBytes == null
                    ? ColoredBox(
                        color: tokens.accent.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: tokens.accentStrong,
                        ),
                      )
                    : Image.memory(photoBytes!, fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photoBytes == null
                        ? 'Tambah foto wajib'
                        : 'Foto siap dibagikan',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locked
                        ? 'Foto dikunci untuk melanjutkan draf'
                        : 'JPEG, PNG, atau WebP · Maks. 1 MB',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: tokens.mutedText),
                  ),
                ],
              ),
            ),
            if (photoBytes != null && !locked)
              IconButton(
                onPressed: onRemove,
                tooltip: 'Hapus foto',
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                icon: const Icon(Icons.close_rounded),
              )
            else if (photoBytes == null)
              Icon(Icons.chevron_right_rounded, color: tokens.mutedText),
          ],
        ),
      ),
    );
  }
}

class _DetailsPage extends StatelessWidget {
  const _DetailsPage({
    required this.size,
    required this.quantity,
    required this.cleanCheck,
    required this.intactCheck,
    required this.notTornCheck,
    required this.onSizeSelected,
    required this.onQuantityChanged,
    required this.onCleanChanged,
    required this.onIntactChanged,
    required this.onNotTornChanged,
  });

  final ClothingSize? size;
  final int quantity;
  final bool cleanCheck;
  final bool intactCheck;
  final bool notTornCheck;
  final ValueChanged<ClothingSize> onSizeSelected;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<bool> onCleanChanged;
  final ValueChanged<bool> onIntactChanged;
  final ValueChanged<bool> onNotTornChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return _StepScrollView(
      children: [
        const _StepIntro(
          eyebrow: 'LANGKAH 2 · DETAIL',
          title: 'Bantu kami mengenalnya.',
          description: 'Pilih ukuran, kondisi, dan jumlah pakaianmu.',
        ),
        SizedBox(height: tokens.spaceLg),
        Text(
          'Ukuran',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in ClothingSize.values)
              _SizeOption(
                size: option,
                selected: size == option,
                onTap: () => onSizeSelected(option),
              ),
          ],
        ),
        SizedBox(height: tokens.spaceLg),
        Text(
          'Pemeriksaan kelayakan',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: tokens.spaceSm),
        PkCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              _EligibilityCheckbox(
                title: 'Sudah dicuci dan bersih',
                value: cleanCheck,
                onChanged: onCleanChanged,
              ),
              _EligibilityCheckbox(
                title: 'Masih utuh dan berfungsi',
                value: intactCheck,
                onChanged: onIntactChanged,
              ),
              _EligibilityCheckbox(
                title: 'Tidak robek atau berlubang',
                value: notTornCheck,
                onChanged: onNotTornChanged,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceMd),
        _QuantitySelector(quantity: quantity, onChanged: onQuantityChanged),
      ],
    );
  }
}

class _SizeOption extends StatelessWidget {
  const _SizeOption({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final ClothingSize size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Ukuran ${size.label}, ${size.description}',
      child: _SelectCard(
        selected: selected,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          size.label,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EligibilityCheckbox extends StatelessWidget {
  const _EligibilityCheckbox({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: tokens.accentStrong,
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      dense: false,
      visualDensity: VisualDensity.standard,
      checkboxScaleFactor: 1.05,
      minTileHeight: 48,
      side: BorderSide(color: tokens.border),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return PkCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumlah pakaian',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Dalam satu paket donasi',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: tokens.mutedText),
                ),
              ],
            ),
          ),
          _QuantityButton(
            label: 'Kurangi jumlah',
            icon: Icons.remove_rounded,
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 42,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _QuantityButton(
            label: 'Tambah jumlah',
            icon: Icons.add_rounded,
            onPressed: quantity < 99 ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        style: IconButton.styleFrom(
          backgroundColor: tokens.accent.withValues(alpha: 0.1),
          foregroundColor: tokens.accentStrong,
          disabledForegroundColor: tokens.mutedText,
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

class _DeliveryPage extends StatelessWidget {
  const _DeliveryPage({
    required this.selectedMethod,
    required this.addressController,
    required this.contactNameController,
    required this.phoneController,
    required this.donationPoint,
    required this.onMethodSelected,
    required this.onChoosePoint,
  });

  final DeliveryMethod? selectedMethod;
  final TextEditingController addressController;
  final TextEditingController contactNameController;
  final TextEditingController phoneController;
  final DonationPoint? donationPoint;
  final ValueChanged<DeliveryMethod> onMethodSelected;
  final VoidCallback onChoosePoint;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return _StepScrollView(
      children: [
        const _StepIntro(
          eyebrow: 'LANGKAH 3 · PENYALURAN',
          title: 'Pilih cara berbagi.',
          description: 'Kami akan bantu pakaianmu sampai ke tangan yang tepat.',
        ),
        SizedBox(height: tokens.spaceLg),
        for (final method in DeliveryMethod.values) ...[
          _DeliveryOption(
            method: method,
            selected: selectedMethod == method,
            onTap: () => onMethodSelected(method),
          ),
          SizedBox(height: tokens.spaceSm),
        ],
        if (selectedMethod == DeliveryMethod.pickup) ...[
          SizedBox(height: tokens.spaceMd),
          Text(
            'Kontak penjemputan',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: contactNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nama penerima'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nomor telepon'),
          ),
          const SizedBox(height: 12),
          Text(
            'Alamat penjemputan',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: addressController,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Nama jalan, nomor rumah, kelurahan, kecamatan',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jadwal penjemputan ditentukan pengelola setelah donasi tercatat.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: tokens.mutedText),
          ),
        ],
        if (selectedMethod != null) ...[
          SizedBox(height: tokens.spaceMd),
          if (donationPoint == null)
            PkButton(
              label: selectedMethod == DeliveryMethod.pickup
                  ? 'Pilih titik layanan'
                  : 'Pilih titik donasi',
              variant: PkButtonVariant.secondary,
              icon: Icons.map_outlined,
              expanded: true,
              onPressed: onChoosePoint,
            )
          else
            _SelectedPointCard(
              point: donationPoint!,
              onChange: onChoosePoint,
              title: selectedMethod == DeliveryMethod.pickup
                  ? 'Titik layanan'
                  : 'Titik donasi',
            ),
        ],
      ],
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  const _DeliveryOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final DeliveryMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Semantics(
      button: true,
      selected: selected,
      label: '${method.label}. ${method.description}',
      child: _SelectCard(
        selected: selected,
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(method.icon, color: tokens.accentStrong, size: 24),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    method.description,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: tokens.mutedText),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: tokens.accentStrong),
          ],
        ),
      ),
    );
  }
}

class _SelectedPointCard extends StatelessWidget {
  const _SelectedPointCard({
    required this.point,
    required this.onChange,
    required this.title,
  });

  final DonationPoint point;
  final VoidCallback onChange;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return PkCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: tokens.accentStrong, size: 24),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title · ${point.name}',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${point.address}, ${point.area}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: tokens.mutedText),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
  }
}

class _StepIntro extends StatelessWidget {
  const _StepIntro({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tokens.accentStrong,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: tokens.mutedText, height: 1.5),
        ),
      ],
    );
  }
}

class _StepScrollView extends StatelessWidget {
  const _StepScrollView({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceMd,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? tokens.accent.withValues(alpha: 0.1) : tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusControl),
          side: BorderSide(
            color: selected ? tokens.accentStrong : tokens.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(tokens.radiusControl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
