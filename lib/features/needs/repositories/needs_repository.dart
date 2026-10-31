import '../models/need.dart';

abstract class NeedsRepository {
  Future<List<Need>> listPublished();

  Future<List<Need>> listAll();

  Future<List<Need>> listForOrganization(String organizationId);

  Future<Need> createNeed(Need need);
}
