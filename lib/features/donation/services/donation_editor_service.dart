import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/donation.dart';

/// The object is uploaded first. If registration fails, retain this receipt and
/// retry registerPhoto; never delete an object on an ambiguous network timeout.
class UploadedDonationPhoto {
  final String id, donationId, storagePath;
  const UploadedDonationPhoto(this.id, this.donationId, this.storagePath);
}

class PhotoRegistrationPending implements Exception {
  final UploadedDonationPhoto photo;
  final Object cause;
  const PhotoRegistrationPending(this.photo, this.cause);
  @override
  String toString() =>
      'Foto terunggah; pendaftaran perlu dicoba ulang: ${photo.storagePath}';
}

class DonationEditorService {
  final SupabaseClient client;
  DonationEditorService({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;
  static const bucket = 'donation-photos';

  static String imageMime(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > 1048576) {
      throw ArgumentError('Ukuran foto harus 1 byte–1 MB');
    }
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return 'image/jpeg';
    }
    const png = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length >= 8 &&
        List.generate(8, (i) => bytes[i] == png[i]).every((x) => x)) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    throw ArgumentError('Pilih JPEG, PNG, atau WebP');
  }

  String _uuid() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<UploadedDonationPhoto> uploadPhoto(
    String donationId,
    Uint8List bytes,
  ) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');
    final mime = imageMime(bytes);
    final id = _uuid();
    final ext = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
    }[mime];
    final photo = UploadedDonationPhoto(
      id,
      donationId,
      '${user.id}/$donationId/$id.$ext',
    );
    await client.storage
        .from(bucket)
        .uploadBinary(
          photo.storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    try {
      await registerPhoto(photo);
    } catch (e) {
      throw PhotoRegistrationPending(photo, e);
    }
    return photo;
  }

  Future<void> registerPhoto(UploadedDonationPhoto photo) async {
    final existing = await client
        .from('donation_photos')
        .select('id,donation_id,storage_path')
        .eq('id', photo.id)
        .maybeSingle();
    if (existing != null) {
      if (existing['donation_id'] != photo.donationId ||
          existing['storage_path'] != photo.storagePath) {
        throw StateError('Photo identity conflict');
      }
      return;
    }
    try {
      await client.from('donation_photos').insert({
        'id': photo.id,
        'donation_id': photo.donationId,
        'storage_path': photo.storagePath,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
      final row = await client
          .from('donation_photos')
          .select('donation_id,storage_path')
          .eq('id', photo.id)
          .single();
      if (row['donation_id'] != photo.donationId ||
          row['storage_path'] != photo.storagePath) {
        rethrow;
      }
    }
  }

  Future<String> signedPhotoUrl(String path, {int expiresIn = 300}) async {
    if (expiresIn < 1 || expiresIn > 3600) {
      throw ArgumentError('Expiry must be 1–3600 seconds');
    }
    return client.storage.from(bucket).createSignedUrl(path, expiresIn);
  }

  Future<void> removePhoto(UploadedDonationPhoto photo) async {
    // Delete object while ownership is still provable; retries tolerate missing objects.
    await client.storage.from(bucket).remove([photo.storagePath]);
    await client
        .from('donation_photos')
        .delete()
        .eq('id', photo.id)
        .eq('donation_id', photo.donationId);
  }

  Future<Donation?> getDonation(String id) async {
    final row = await client
        .from('donations')
        .select('*,donation_items(*),donation_photos(*)')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Donation.fromJson(row);
  }

  Future<void> updateDraft(
    String id, {
    required String method,
    required String pointId,
    String? preferredNeedId,
    DateTime? scheduledAt,
  }) async {
    await client
        .from('donations')
        .update({
          'method': method,
          'point_id': pointId,
          'preferred_need_id': preferredNeedId,
          'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select('id')
        .single();
  }

  Future<void> updateItem(
    String id, {
    required String category,
    required String sizeCode,
    required String ageGroup,
    required int quantity,
  }) async {
    await client
        .from('donation_items')
        .update({
          'category': category,
          'size_code': sizeCode,
          'age_group': ageGroup,
          'quantity': quantity,
        })
        .eq('id', id)
        .select('id')
        .single();
  }

  Future<void> deleteItem(String id) async {
    await client
        .from('donation_items')
        .delete()
        .eq('id', id)
        .select('id')
        .single();
  }

  Future<void> deleteDraft(String id) async {
    // Storage objects are cleaned by the caller while the draft still exists.
    final draft = await getDonation(id);
    if (draft == null) throw StateError('Donation not found');
    if (draft.status != 'draft') {
      throw StateError('Use cancelDonation to retain submitted history');
    }
    for (final photo in draft.photos) {
      await removePhoto(UploadedDonationPhoto(photo.id, id, photo.storagePath));
    }
    await client.from('donations').delete().eq('id', id).select('id').single();
  }

  Future<void> cancelDonation(String id) async {
    await client.rpc('cancel_donation', params: {'p_id': id});
  }
}
