import '../models/donation.dart';

abstract class DonationsRepository {
  Future<List<Donation>> listMine(String userId);

  Future<Donation> createDonation(Donation donation);
}
