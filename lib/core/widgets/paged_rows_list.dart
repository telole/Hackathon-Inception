import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/rows_pager.dart';
import '../../features/operations/data/operations_repository.dart';
import 'pk_card.dart';

class PagedRowsList extends ConsumerWidget {
  const PagedRowsList({
    required this.resource,
    required this.emptyMessage,
    required this.itemBuilder,
    this.header = const [],
    super.key,
  });
  final String resource, emptyMessage;
  final Widget Function(OpsRow) itemBuilder;
  final List<Widget> header;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pager = ref.watch(rowsPagerProvider(resource));
    return ListenableBuilder(
      listenable: pager,
      builder: (context, _) => RefreshIndicator(
        onRefresh: pager.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: header.length + pager.rows.length + 1,
          itemBuilder: (context, index) {
            if (index < header.length) return header[index];
            final rowIndex = index - header.length;
            if (rowIndex < pager.rows.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: itemBuilder(pager.rows[rowIndex]),
              );
            }
            return Column(
              children: [
                if (pager.error != null) ...[
                  const Text(
                    'Data belum dapat dimuat. Data yang sudah tampil tetap tersedia.',
                  ),
                  TextButton(
                    onPressed: pager.rows.isEmpty ? pager.refresh : pager.more,
                    child: const Text('Coba lagi'),
                  ),
                ] else if (pager.loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                else if (pager.rows.isEmpty)
                  PkCard(child: Text(emptyMessage))
                else if (pager.hasMore)
                  OutlinedButton(
                    onPressed: pager.more,
                    child: const Text('Muat berikutnya'),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('${pager.rows.length} data sudah ditampilkan'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
