import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../data/operations_repository.dart';

final operationsRepositoryProvider = Provider<OperationsRepository>((ref) {
  ref.watch(authUserProvider.select((state) => state.value?.id));
  return SupabaseOperationsRepository(ref.watch(supabaseClientProvider));
});
final operationsAccessProvider = FutureProvider<OperationsAccess>(
  (ref) => ref.watch(operationsRepositoryProvider).access(),
);
final operationsDataProvider = FutureProvider.family<List<OpsRow>, String>(
  (ref, resource) => ref.watch(operationsRepositoryProvider).load(resource),
);
