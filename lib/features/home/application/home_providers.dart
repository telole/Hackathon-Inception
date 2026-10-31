import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../application/home_models.dart';
import '../data/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return const _UnconfiguredHomeRepository();
  }
  return SupabaseHomeRepository(client);
});

final homeSnapshotProvider = FutureProvider<HomeSnapshot>(
  (ref) => ref.watch(homeRepositoryProvider).fetchHome(),
);

final campaignProvider = FutureProvider.family<Campaign?, String>(
  (ref, id) => ref.watch(homeRepositoryProvider).fetchCampaign(id),
);

class _UnconfiguredHomeRepository implements HomeRepository {
  const _UnconfiguredHomeRepository();

  @override
  Future<HomeSnapshot> fetchHome() => Future.error(
    StateError(
      'Backend belum dikonfigurasi. Jalankan aplikasi dengan '
      '--dart-define-from-file=env.json.',
    ),
  );

  @override
  Future<Campaign?> fetchCampaign(String id) =>
      Future.error(StateError('Backend belum dikonfigurasi.'));
}
