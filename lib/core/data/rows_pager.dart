import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/operations/application/operations_providers.dart';
import '../../features/operations/data/operations_repository.dart';
import '../../features/campaign/data/program_repository.dart';
import '../../features/home/application/home_providers.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/home/application/home_models.dart';

typedef RowLoader = Future<List<OpsRow>> Function(
  String resource,
  int offset,
  int limit,
);
final rowLoaderProvider = Provider<RowLoader>((ref) {
  final operations = ref.watch(operationsRepositoryProvider);
  final programs = ref.watch(programRepositoryProvider);
  final home = ref.watch(homeRepositoryProvider);
  return (resource, offset, limit) async {
    if (resource == 'managedPrograms') {
      return programs.list(
        await operations.access(),
        offset: offset,
        limit: limit,
      );
    }
    if (resource.startsWith('catalog:')) {
      final pieces = resource.split(':');
      final query = Uri.decodeComponent(pieces[1]);
      final category = DonationCategory.values
          .where((c) => c.name == pieces[2])
          .firstOrNull;
      List<Campaign> rows;
      if (home is SupabaseHomeRepository) {
        rows = await home.fetchCampaignPage(
          offset: offset,
          limit: limit,
          query: query,
          category: category,
        );
      } else {
        rows = (await home.fetchHome()).campaigns
            .where(
              (c) =>
                  (category == null || c.category == category) &&
                  '${c.title} ${c.partner} ${c.location}'
                      .toLowerCase()
                      .contains(query.toLowerCase()),
            )
            .skip(offset)
            .take(limit)
            .toList();
      }
      return [
        for (final row in rows) {'id': row.id, 'campaign': row},
      ];
    }
    if (operations is SupabaseOperationsRepository) {
      return operations.load('page:$offset:$limit:$resource');
    }
    return (await operations.load(resource)).skip(offset).take(limit).toList();
  };
});

final rowsPagerProvider = Provider.autoDispose.family<RowsPager, String>((
  ref,
  resource,
) {
  final loader = ref.watch(rowLoaderProvider);
  final pager = RowsPager((offset, limit) => loader(resource, offset, limit));
  ref.onDispose(pager.dispose);
  unawaited(pager.refresh());
  return pager;
});

class RowsPager extends ChangeNotifier {
  RowsPager(this.loader, {this.pageSize = 25});
  final Future<List<OpsRow>> Function(int offset, int limit) loader;
  final int pageSize;
  List<OpsRow> rows = [];
  bool loading = false, hasMore = true, _disposed = false;
  Object? error;
  int _offset = 0, _generation = 0;
  Future<void> refresh() => _fetch(true);
  Future<void> more() => _fetch(false);
  Future<void> _fetch(bool reset) async {
    if (_disposed || (!reset && (loading || !hasMore))) return;
    final generation = reset ? ++_generation : _generation;
    final offset = reset ? 0 : _offset;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await loader(offset, pageSize + 1);
      if (_disposed || generation != _generation) return;
      final existing = reset ? <OpsRow>[] : List<OpsRow>.from(rows);
      final keys = existing.map((r) => r['id'] ?? r['user_id']).toSet();
      for (final row in result.take(pageSize)) {
        final key = row['id'] ?? row['user_id'];
        if (key == null || keys.add(key)) existing.add(row);
      }
      rows = existing;
      _offset = offset + pageSize;
      hasMore = result.length > pageSize;
    } catch (failure) {
      if (!_disposed && generation == _generation) error = failure;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
