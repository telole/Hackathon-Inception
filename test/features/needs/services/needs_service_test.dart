import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/features/needs/services/needs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final Future<T> _future;
  FakePostgrestFilterBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }
}

class MockSupabaseQueryBuilder extends Mock
    implements SupabaseQueryBuilder {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late NeedsService needsService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    when(() => mockSupabase.from('needs')).thenAnswer((_) => mockQueryBuilder);
    needsService = NeedsService(client: mockSupabase);
  });

  group('NeedsService', () {
    test('fetchOpenNeeds parses list of open needs from query result', () async {
      final fakeData = [
        {
          'id': 'need-1',
          'organization_id': 'org-1',
          'point_id': 'point-1',
          'title': 'Kebutuhan Baju Bayi',
          'deadline_at': '2026-11-20T00:00:00Z',
          'status': 'open',
          'created_at': '2026-10-31T08:00:00Z',
          'need_items': [
            {
              'id': 'item-1',
              'need_id': 'need-1',
              'category': 'baby_wear',
              'size_code': 'S',
              'age_group': 'infant',
              'requested_qty': 30,
            }
          ],
        }
      ];

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(fakeData),
      );
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => fakeBuilder);

      final result = await needsService.fetchOpenNeeds();

      expect(result.length, 1);
      expect(result.first.id, 'need-1');
      expect(result.first.title, 'Kebutuhan Baju Bayi');
      expect(result.first.items.first.category, 'baby_wear');
    });
  });
}
