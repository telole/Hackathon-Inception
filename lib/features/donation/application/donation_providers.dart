import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../application/donation_models.dart';
import '../data/donation_repository.dart';
import '../../home/application/home_models.dart';

final donationFormEpochProvider = NotifierProvider<DonationFormEpoch, int>(
  DonationFormEpoch.new,
);

class DonationFormEpoch extends Notifier<int> {
  @override
  int build() => 0;
  void reset() => state++;
}

final donationRepositoryProvider = Provider<DonationRepository>((ref) {
  // Recreate user-scoped repositories when the signed-in account changes.
  ref.watch(authUserProvider.select((state) => state.value?.id));
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const _UnconfiguredDonationRepository();
  return SupabaseDonationRepository(client);
});

final donationsProvider = FutureProvider<List<DonationRecord>>(
  (ref) => ref.watch(donationRepositoryProvider).fetchDonations(),
);

final donationPointsProvider = FutureProvider<List<DonationPoint>>(
  (ref) => ref.watch(donationRepositoryProvider).fetchDonationPoints(),
);

class _UnconfiguredDonationRepository implements DonationRepository {
  const _UnconfiguredDonationRepository();

  @override
  Future<List<DonationRecord>> fetchDonations() =>
      Future.error(StateError('Backend Supabase belum dikonfigurasi.'));

  @override
  Future<List<DonationPoint>> fetchDonationPoints() =>
      Future.error(StateError('Backend Supabase belum dikonfigurasi.'));

  @override
  Future<DonationRecord> saveDonation({
    required String draftId,
    required DonationCategory category,
    required ClothingType clothingType,
    required ClothingSize size,
    required int quantity,
    required DeliveryMethod deliveryMethod,
    required Uint8List photoBytes,
    required bool cleanCheck,
    required bool intactCheck,
    required bool notTornCheck,
    required String? pickupAddress,
    required String? contactName,
    required String? phone,
    required DonationPoint donationPoint,
    String? preferredNeedId,
  }) => Future.error(StateError('Backend Supabase belum dikonfigurasi.'));
}

final singleDonationProvider = FutureProvider.autoDispose
    .family<DonationRecord, String>((ref, id) async {
      final repo = ref.watch(donationRepositoryProvider);
      if (repo is SupabaseDonationRepository) return repo.fetchDonation(id);
      return (await repo.fetchDonations()).firstWhere((d) => d.id == id);
    });
