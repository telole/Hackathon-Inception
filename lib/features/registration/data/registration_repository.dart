import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../../operations/data/operations_repository.dart';

final registrationRepositoryProvider = Provider<RegistrationRepository>(
  (ref) => RegistrationRepository(ref.watch(supabaseClientProvider)),
);

class RegistrationRepository {
  RegistrationRepository(this.client);
  final SupabaseClient? client;
  SupabaseClient get db =>
      client ?? (throw StateError('Masuk untuk mengirim pengajuan.'));
  Future<void> volunteer(String id, String message) async {
    await db.rpc('apply_volunteer', params: {'p_id': id, 'p_message': message});
  }

  Future<void> saveOrganization(String id, OpsRow payload) async {
    await db.rpc(
      'save_organization_application',
      params: {'p_id': id, 'p_payload': payload},
    );
  }

  Future<String> uploadDocument(String id, Uint8List bytes) async {
    final format = verificationDocumentType(bytes);
    if (format == null || bytes.length > 5242880) {
      throw ArgumentError('Pilih PDF, JPG atau PNG maksimal 5 MB.');
    }
    final path =
        '${db.auth.currentUser!.id}/$id/${const Uuid().v4()}.${format.$1}';
    await db.storage
        .from('verification-documents')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: format.$2),
        );
    return path;
  }

  Future<void> submitOrganization(String id, String document) async {
    await db.rpc(
      'submit_organization_application',
      params: {'p_id': id, 'p_document': document},
    );
  }

  Future<String> documentUrl(String path) =>
      db.storage.from('verification-documents').createSignedUrl(path, 300);
  Future<void> member(
    String org, {
    String? email,
    String? user,
    required bool active,
  }) async {
    await db.rpc(
      'manage_organization_member',
      params: {
        'p_org': org,
        'p_email': email,
        'p_user': user,
        'p_active': active,
      },
    );
  }

  Future<void> savePoint({
    String? id,
    required String org,
    required String name,
    required String address,
    required String hours,
    required bool active,
  }) async {
    await db.rpc(
      'save_collection_point',
      params: {
        'p_id': id,
        'p_org': org,
        'p_name': name,
        'p_address': address,
        'p_hours': hours,
        'p_active': active,
      },
    );
  }
}

(String, String)? verificationDocumentType(Uint8List bytes) {
  if (bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-') {
    return ('pdf', 'application/pdf');
  }
  if (bytes.length >= 8 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71) {
    return ('png', 'image/png');
  }
  if (bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255) {
    return ('jpg', 'image/jpeg');
  }
  return null;
}
