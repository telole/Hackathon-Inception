import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resandang/features/auth/services/auth_service.dart';
import 'package:resandang/features/auth/presentation/auth_state_notifier.dart';
import 'package:resandang/features/donation/services/donation_editor_service.dart';
import 'package:resandang/features/operations/services/workflow_service.dart';
import 'package:resandang/features/needs/models/need.dart';

const uid = '11111111-1111-4111-8111-111111111111';
const did = '22222222-2222-4222-8222-222222222222';
http.Response jsonResponse(
  http.Request request,
  Object body, [
  int status = 200,
]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
  request: request,
);

void main() {
  test(
    'real SDK signedIn during password login finishes loading and role fetch',
    () async {
      final payload = base64Url
          .encode(
            utf8.encode(
              jsonEncode({
                'sub': uid,
                'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
              }),
            ),
          )
          .replaceAll('=', '');
      final transport = MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return jsonResponse(request, {
            'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.signature',
            'refresh_token': 'test-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': uid,
              'aud': 'authenticated',
              'email': 'test@example.test',
              'created_at': '2026-01-01T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          });
        }
        if (request.url.path == '/rest/v1/rpc/my_access') {
          return jsonResponse(request, {
            'roles': ['donatur'],
            'ui': 'user',
          });
        }
        throw StateError('Unexpected request ${request.url}');
      });
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final notifier = AuthStateNotifier(
        authService: AuthService(client: client),
      );
      try {
        final success = await notifier.signIn(
          'test@example.test',
          'test-password',
        );
        expect(success, isTrue, reason: notifier.errorMessage);
        await Future<void>.delayed(Duration.zero);
        expect(notifier.isLoading, isFalse);
        expect(notifier.currentAccess.isDonatur, isTrue);
      } finally {
        notifier.dispose();
        await client.dispose();
      }
    },
  );

  test(
    'need save uses atomic RPC, UTC and server-owned item identities',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        httpClient: MockClient((r) async {
          requests.add(r);
          return jsonResponse(r, did);
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      try {
        expect(
          await WorkflowService(client: client).saveNeed(
            organizationId: uid,
            pointId: did,
            title: 'Kaos anak',
            deadline: DateTime(2027, 1, 1),
            items: const [
              NeedItem(
                id: '',
                needId: '',
                category: 'kaos',
                sizeCode: 'M',
                ageGroup: 'anak',
                requestedQty: 6,
              ),
            ],
          ),
          did,
        );
        final body = jsonDecode(requests.single.body) as Map;
        expect(requests.single.url.path, '/rest/v1/rpc/save_need');
        expect((body['p_deadline'] as String).endsWith('Z'), isTrue);
        expect(body['p_items'][0]['id'], isNull);
        expect(body['p_items'][0]['requested_qty'], 6);
      } finally {
        await client.dispose();
      }
    },
  );

  test(
    'photo registration retries the same id without duplicate writes',
    () async {
      Map<String, dynamic>? row;
      var inserts = 0;
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          expect(r.url.path, '/rest/v1/donation_photos');
          if (r.method == 'POST') {
            row = Map<String, dynamic>.from(jsonDecode(r.body));
            inserts++;
            return http.Response('', 201, request: r);
          }
          return jsonResponse(r, row == null ? [] : [row]);
        }),
      );
      try {
        final service = DonationEditorService(client: client);
        const photo = UploadedDonationPhoto(uid, did, '$uid/$did/photo.png');
        await service.registerPhoto(photo);
        await service.registerPhoto(photo);
        expect(inserts, 1);
        expect(row!['storage_path'], photo.storagePath);
      } finally {
        await client.dispose();
      }
    },
  );

  test('reject invalid or oversized photos before any network request', () {
    expect(
      () => DonationEditorService.imageMime(Uint8List(0)),
      throwsArgumentError,
    );
    expect(
      () => DonationEditorService.imageMime(Uint8List(1048577)),
      throwsArgumentError,
    );
    expect(
      () => DonationEditorService.imageMime(Uint8List.fromList([1, 2, 3, 4])),
      throwsArgumentError,
    );
    expect(
      DonationEditorService.imageMime(
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
      ),
      'image/png',
    );
  });

  test('SDK uploads private bytes before registration and preserves receipt on registration failure', () async {
    var failRegistration = true;
    var uploads = 0;
    Map<String, dynamic>? row;
    final client = SupabaseClient(
      'https://example.test',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        if (r.url.path == '/auth/v1/token') {
          return jsonResponse(r, {
            'access_token': 'test-access',
            'refresh_token': 'test-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': uid,
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          });
        }
        if (r.url.path.startsWith('/storage/v1/object/donation-photos/')) {
          uploads++;
          expect(r.method, 'POST');
          expect(r.headers['authorization'], 'Bearer test-access');
          expect(
            latin1.decode(r.bodyBytes),
            contains(String.fromCharCodes([137, 80, 78, 71, 13, 10, 26, 10])),
          );
          return jsonResponse(r, {'Key': 'donation-photos/file.png'});
        }
        if (r.url.path == '/rest/v1/donation_photos') {
          if (r.method == 'POST') {
            if (failRegistration) {
              return jsonResponse(r, {
                'message': 'Unavailable',
                'code': '503',
              }, 503);
            }
            row = Map<String, dynamic>.from(jsonDecode(r.body));
            return http.Response('', 201, request: r);
          }
          return jsonResponse(r, row == null ? [] : [row]);
        }
        throw StateError('Unexpected ${r.method} ${r.url}');
      }),
    );
    try {
      await client.auth.signInWithPassword(
        email: 'test@example.test',
        password: 'test-password',
      );
      final editor = DonationEditorService(client: client);
      UploadedDonationPhoto? receipt;
      try {
        await editor.uploadPhoto(
          did,
          Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        );
      } on PhotoRegistrationPending catch (e) {
        receipt = e.photo;
      }
      expect(receipt, isNotNull);
      expect(receipt!.storagePath, startsWith('$uid/$did/'));
      failRegistration = false;
      await editor.registerPhoto(receipt);
      expect(row!['id'], receipt.id);
      expect(
        uploads,
        1,
        reason: 'Retry registers the same object without uploading it again',
      );
    } finally {
      await client.dispose();
    }
  });
}
