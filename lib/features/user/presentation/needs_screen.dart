import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pk_widgets.dart';
import '../../needs/models/need.dart';
import '../../needs/presentation/need_card.dart';

class NeedsScreen extends StatefulWidget {
  const NeedsScreen({super.key, required this.onOpenNeed});

  final ValueChanged<Need> onOpenNeed;

  @override
  State<NeedsScreen> createState() => _NeedsScreenState();
}

class _NeedsScreenState extends State<NeedsScreen> {
  static const _allCities = 'Semua kota';
  static const _allSizes = 'Semua ukuran';

  final _search = TextEditingController();
  NeedCategory? _category;
  String _city = _allCities;
  String _size = _allSizes;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() {
    _search.clear();
    setState(() {
      _category = null;
      _city = _allCities;
      _size = _allSizes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.watch(context);
    final all = controller.repository.publishedNeeds;
    final cities = all.map((need) => need.city).toSet().toList()..sort();
    final sizes = all
        .expand((need) => need.items.map((item) => item.sizeLabel))
        .toSet()
        .toList()
      ..sort();

    final activeCity = cities.contains(_city) ? _city : _allCities;
    final activeSize = sizes.contains(_size) ? _size : _allSizes;

    final query = _search.text.trim().toLowerCase();
    final filtered = all.where((need) {
      final categoryMatch = _category == null ||
          need.items.any((item) => item.category == _category);
      final cityMatch = activeCity == _allCities || need.city == activeCity;
      final sizeMatch = activeSize == _allSizes ||
          need.items.any((item) => item.sizeLabel == activeSize);
      final queryMatch = query.isEmpty ||
          need.title.toLowerCase().contains(query) ||
          need.organizationName.toLowerCase().contains(query) ||
          need.description.toLowerCase().contains(query);
      return categoryMatch && cityMatch && sizeMatch && queryMatch;
    }).toList();

    final hasFilter = _category != null ||
        _city != _allCities ||
        _size != _allSizes ||
        query.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kebutuhan', style: theme.textTheme.displaySmall),
                  const SizedBox(height: 3),
                  Text(
                    '${all.length} kebutuhan terbuka dari mitra terverifikasi',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (hasFilter)
              TextButton(
                onPressed: _reset,
                child: const Text('Reset'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        PkTextField(
          label: 'Cari kebutuhan',
          controller: _search,
          hint: 'Nama kebutuhan atau lembaga',
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in <NeedCategory?>[null, ...NeedCategory.values])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category?.label ?? 'Semua kategori'),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FilterSelect(
                label: 'Wilayah',
                value: activeCity,
                options: [_allCities, ...cities],
                onChanged: (value) => setState(() => _city = value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FilterSelect(
                label: 'Ukuran',
                value: activeSize,
                options: [_allSizes, ...sizes],
                onChanged: (value) => setState(() => _size = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '${filtered.length} hasil',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.forest,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.verified_outlined,
              size: 13,
              color: AppColors.forest,
            ),
            const SizedBox(width: 4),
            Text(
              'Mitra terverifikasi',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          PkEmptyState(
            title: 'Belum ada kebutuhan yang cocok',
            message:
                'Coba ubah kategori, wilayah, atau ukuran. Kebutuhan baru akan muncul setelah mitra terverifikasi menerbitkannya.',
            icon: Icons.filter_alt_off_outlined,
            action: PkButton(
              label: 'Hapus filter',
              variant: PkButtonVariant.secondary,
              onPressed: _reset,
            ),
          )
        else
          for (final need in filtered) ...[
            NeedCard(need: need, onTap: () => widget.onOpenNeed(need)),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _FilterSelect extends StatelessWidget {
  const _FilterSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 11),
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
                size: 18,
                color: AppColors.muted,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              items: [
                for (final option in options)
                  DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
