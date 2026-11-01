import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pakaiankita/features/operations/data/operations_repository.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late SupabaseOperationsRepository repository;
  final requests = <Map<String, dynamic>>[];
  const uid = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const org = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  var failReservation = false;
  setUp(() async {
    requests.clear();
    failReservation = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final raw = await utf8.decoder.bind(request).join();
      final body = raw.isEmpty ? null : jsonDecode(raw);
      requests.add({
        'path': request.uri.path,
        'query': request.uri.queryParameters,
        'body': body,
      });
      dynamic response;
      switch (request.uri.path) {
        case '/auth/v1/token':
          String encode(Object value) => base64Url
              .encode(utf8.encode(jsonEncode(value)))
              .replaceAll('=', '');
          final token =
              '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({'sub': uid, 'exp': 4102444800, 'aud': 'authenticated', 'role': 'authenticated'})}.test';
          response = {
            'access_token': token,
            'refresh_token': 'test-refresh',
            'expires_in': 3600,
            'token_type': 'bearer',
            'user': {
              'id': uid,
              'aud': 'authenticated',
              'app_metadata': <String, dynamic>{},
              'user_metadata': <String, dynamic>{},
              'created_at': '2026-01-01T00:00:00Z',
            },
          };
        case '/rest/v1/rpc/my_access':
          response = {
            'roles': ['mitra'],
            'ui': 'user',
          };
        case '/rest/v1/organization_members':
          response = [
            {
              'organization_id': org,
              'active': true,
              'organizations': {'verified': true, 'active': true},
            },
          ];
        case '/rest/v1/inventory_batches':
          response = [
            {'id': 'batch', 'on_hand_qty': 17, 'reserved_qty': 5},
          ];
        case '/rest/v1/logistics_tasks':
          response = [
            {
              'id': 'task',
              'donations': {'tracking_code': 'PK-1'},
              'collection_points': {'name': 'Posko'},
            },
          ];
        case '/rest/v1/rpc/reserve_allocation':
          if (failReservation) {
            request.response.statusCode = 400;
            response = {
              'code': 'P0001',
              'message': 'Insufficient stock or need',
              'details': null,
              'hint': null,
            };
          } else {
            response = 'allocation-id';
          }
        default:
          if (request.uri.path.startsWith('/rest/v1/rpc/')) {
            response = null;
          } else {
            request.response.statusCode = 404;
            response = {'code': 'UNEXPECTED', 'message': 'Unexpected endpoint'};
          }
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test-client-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await client.auth.setSession('test-refresh');
    repository = SupabaseOperationsRepository(client);
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test(
    'access uses installed my_access RPC and own verified memberships',
    () async {
      final access = await repository.access();
      expect(access.roles, ['mitra']);
      expect(access.organizations, [org]);
      final request = requests.firstWhere(
        (r) => r['path'] == '/rest/v1/organization_members',
      );
      expect(request['query']['user_id'], 'eq.$uid');
      expect(
        requests.any((r) => r['path'] == '/rest/v1/rpc/get_my_context'),
        isFalse,
      );
    },
  );
  test('task query is scoped to signed-in volunteer', () async {
    final rows = await repository.load('tasks');
    expect(rows.single['tracking_code'], 'PK-1');
    expect(rows.single['point_name'], 'Posko');
    expect(requests.last['query']['assigned_to'], 'eq.$uid');
  });
  test('stock derives available from actual database columns', () async {
    final rows = await repository.load('inventory:point-id');
    expect(rows.single['available_qty'], 12);
    expect(requests.last['query']['point_id'], 'eq.point-id');
  });
  test('schedule and assignment send exact deployed parameter names', () async {
    await repository.act('schedule', {
      'id': 'donation',
      'at': '2026-12-01T10:00:00Z',
    }, 'key');
    expect(requests.last['path'], '/rest/v1/rpc/schedule_donation');
    expect(requests.last['body'], {
      'p_id': 'donation',
      'p_at': '2026-12-01T10:00:00Z',
    });
    await repository.act('assign', {
      'id': 'donation',
      'point_id': 'point',
      'volunteer': uid,
      'kind': 'curation',
      'at': null,
      'notes': 'Periksa',
    }, 'key');
    expect(requests.last['path'], '/rest/v1/rpc/assign_logistics_task');
    expect(requests.last['body'], {
      'p_id': null,
      'p_donation': 'donation',
      'p_point': 'point',
      'p_volunteer': uid,
      'p_kind': 'curation',
      'p_at': null,
      'p_notes': 'Periksa',
    });
  });
  test(
    'reservation retains request key and propagates stock conflict',
    () async {
      final input = {'batch': 'batch', 'need_item': 'line', 'quantity': 3};
      await repository.act('reserve', input, 'stable-key');
      expect(requests.last['body'], {
        'p_batch': 'batch',
        'p_need_item': 'line',
        'p_qty': 3,
        'p_key': 'stable-key',
      });
      failReservation = true;
      await expectLater(
        repository.act('reserve', input, 'stable-key'),
        throwsA(isA<PostgrestException>()),
      );
    },
  );
  test('shipment creation and revision use installed RPCs', () async {
    await repository.act('createShipment', {
      'allocation': 'allocation',
      'volunteer': uid,
    }, 'key');
    expect(requests.last['path'], '/rest/v1/rpc/create_shipment');
    expect(requests.last['body'], {
      'p_allocation': 'allocation',
      'p_volunteer': uid,
    });
    await repository.act('revise', {'id': 'donation', 'reason': 'Foto perlu diperjelas'}, 'key');
    expect(requests.last['path'], '/rest/v1/rpc/request_donation_revision');
    expect(requests.last['body'], {
      'p_id': 'donation',
      'p_note': 'Foto perlu diperjelas',
      'p_key': 'key',
    });
  });
}
