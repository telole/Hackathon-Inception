import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/paged_rows_list.dart';
import '../../../core/widgets/pk_card.dart';
import '../../home/application/home_models.dart';
import 'campaign_banner.dart';

class CampaignListScreen extends ConsumerStatefulWidget {
  const CampaignListScreen({super.key});
  @override
  ConsumerState<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends ConsumerState<CampaignListScreen> {
  String _query = '';
  DonationCategory? _category;
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kebutuhan terbuka')),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cari program atau lembaga',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) setState(() => _query = value.trim());
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final category in DonationCategory.values)
                  ChoiceChip(
                    label: Text(category.label),
                    selected: _category == category,
                    onSelected: (selected) =>
                        setState(() => _category = selected ? category : null),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PagedRowsList(
              resource:
                  'catalog:${Uri.encodeComponent(_query)}:${_category?.name ?? ''}',
              emptyMessage: 'Belum ada kebutuhan yang cocok. Coba kata kunci atau kategori lain.',
              itemBuilder: (row) {
                final need = row['campaign'] as Campaign;
                return PkCard(
                  onTap: () => context.push('/campaign/${need.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CampaignBanner(campaign: need),
                      const SizedBox(height: 12),
                      Text(
                        need.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        need.partner,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(need.location),
                      const SizedBox(height: 12),
                      Text('${need.requestedItems} pakaian dibutuhkan'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
