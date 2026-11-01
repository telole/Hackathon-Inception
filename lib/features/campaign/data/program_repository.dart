import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../../operations/application/operations_providers.dart';
import '../../operations/data/operations_repository.dart';

final programRepositoryProvider = Provider<ProgramRepository>(
  (ref) => ProgramRepository(ref.watch(supabaseClientProvider)),
);
final managedProgramsProvider = FutureProvider<List<OpsRow>>((ref) async {
  final access = await ref.watch(operationsAccessProvider.future);
  return ref.watch(programRepositoryProvider).list(access);
});
final managedProgramProvider = FutureProvider.autoDispose
    .family<OpsRow, String>((ref, id) async {
      final access = await ref.watch(operationsAccessProvider.future);
      final row = await ref.watch(programRepositoryProvider).get(id);
      if (!access.isAdmin &&
          !access.organizations.contains(row['organization_id'])) {
        throw StateError('Program berada di luar lembagamu.');
      }
      return row;
    });

class ProgramRepository {
  ProgramRepository(this.client);
  final SupabaseClient? client;
  SupabaseClient get db =>
      client ?? (throw StateError('Masuk untuk mengelola program.'));
  static const fields =
      'id, organization_id, point_id, incident_id, title, description, deadline_at, status, banner_path, organizations(name), need_items(id, category, size_code, age_group, requested_qty)';
  Future<List<OpsRow>> list(
    OperationsAccess access, {
    int offset = 0,
    int limit = 100,
  }) async {
    if (!access.isAdmin && access.organizations.isEmpty) return [];
    var query = db.from('needs').select(fields);
    if (!access.isAdmin) {
      query = query.inFilter('organization_id', access.organizations);
    }
    final rows = await query
        .order('created_at', ascending: false)
        .order('id')
        .range(offset, offset + limit - 1);
    return [for (final row in rows) await _withBanner(row)];
  }

  Future<OpsRow> get(String id) async =>
      _withBanner(await db.from('needs').select(fields).eq('id', id).single());
  Future<OpsRow> _withBanner(OpsRow row) async {
    final path = row['banner_path'] as String?;
    String? url;
    if (path != null) {
      try {
        url = await db.storage
            .from('program-banners')
            .createSignedUrl(path, 3600);
      } catch (_) {
        /* Placeholder retains layout. */
      }
    }
    return {...row, 'banner_url': url};
  }

  Future<String> save(OpsRow values) async => await db.rpc(
    'save_need',
    params: {
      'p_id': values['id'],
      'p_org': values['organization_id'],
      'p_point': values['point_id'],
      'p_title': values['title'],
      'p_description': values['description'],
      'p_deadline': values['deadline_at'],
      'p_incident': values['incident_id'],
      'p_items': values['items'],
    },
  ) as String;
  Future<String> uploadBanner(String id, Uint8List bytes) async {
    final extension = imageExtension(bytes);
    if (extension == null || bytes.isEmpty || bytes.length > 1048576) {
      throw ArgumentError('Gunakan JPG, PNG, atau WebP maksimal 1 MB.');
    }
    final uid = db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sesi berakhir.');
    final old = await db
        .from('needs')
        .select('banner_path')
        .eq('id', id)
        .single();
    final path = '$uid/$id/${const Uuid().v4()}.$extension';
    await db.storage
        .from('program-banners')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: extension == 'jpg' ? 'image/jpeg' : 'image/$extension',
          ),
        );
    try {
      await db
          .from('needs')
          .update({'banner_path': path})
          .eq('id', id)
          .select('id')
          .single();
    } catch (_) {
      try {
        await db.storage.from('program-banners').remove([path]);
      } catch (_) {}
      rethrow;
    }
    if (old['banner_path'] != null) {
      try {
        await db.storage.from('program-banners').remove([
          old['banner_path'] as String,
        ]);
      } catch (_) {}
    }
    return path;
  }

  Future<void> removeBanner(String id) async {
    final old = await db
        .from('needs')
        .select('banner_path')
        .eq('id', id)
        .single();
    await db
        .from('needs')
        .update({'banner_path': null})
        .eq('id', id)
        .select('id')
        .single();
    if (old['banner_path'] != null) {
      try {
        await db.storage.from('program-banners').remove([
          old['banner_path'] as String,
        ]);
      } catch (_) {}
    }
  }

  Future<void> status(String id, String value) async {
    await db.rpc('set_need_status', params: {'p_id': id, 'p_status': value});
  }

  Future<void> delete(String id) async {
    await db.rpc('delete_need', params: {'p_id': id});
  }
}

String? imageExtension(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71) {
    return 'png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255) {
    return 'jpg';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'webp';
  }
  return null;
}
