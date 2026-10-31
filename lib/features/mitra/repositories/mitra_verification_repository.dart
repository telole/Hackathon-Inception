import '../models/mitra_application.dart';

abstract class MitraVerificationRepository {
  Future<MitraApplication?> getMine(String userId);

  Future<MitraApplication> saveDraft(MitraApplication application);

  Future<MitraApplication> submit(MitraApplication application);

  Future<List<MitraApplication>> list({MitraApplicationStatus? status});

  Future<void> approve(String applicationId, {required String adminId});

  Future<void> reject(
    String applicationId, {
    required String adminId,
    required String reason,
  });
}
