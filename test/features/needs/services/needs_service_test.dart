import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/features/needs/services/needs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final Future<T> _future;
  FakePostgrestTransformBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }
}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  @override
  PostgrestFilterBuilder<T> ilike(String column, String pattern) => this;
  @override
  PostgrestFilterBuilder<T> gt(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<T> range(int from, int to, {String? referencedTable}) => this;
  @override
  PostgrestFilterBuilder<T> order(String column, {bool ascending = false, bool nullsFirst = false, String? referencedTable}) => this;
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

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    final singleFuture = (_future as Future<List<Map<String, dynamic>>>)
        .then((list) => list.isEmpty ? null : list.first);
    return FakePostgrestTransformBuilder<Map<String, dynamic>?>(singleFuture);
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

    test('fetchOpenNeeds filters correctly when category, ageGroup, and sizeCode match on a single item', () async {
      final fakeData = [
        {
          'id': 'need-1',
          'organization_id': 'org-1',
          'point_id': 'point-1',
          'title': 'Kebutuhan Posko A',
          'deadline_at': '2026-11-20T00:00:00Z',
          'status': 'open',
          'created_at': '2026-10-31T08:00:00Z',
          'need_items': [
            {
              'id': 'item-1',
              'need_id': 'need-1',
              'category': 'kaos',
              'size_code': 'M',
              'age_group': 'dewasa',
              'requested_qty': 10,
            },
            {
              'id': 'item-2',
              'need_id': 'need-1',
              'category': 'celana',
              'size_code': 'S',
              'age_group': 'anak',
              'requested_qty': 5,
            }
          ],
        }
      ];

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(fakeData),
      );
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => fakeBuilder);

      final result = await needsService.fetchOpenNeeds(
        category: 'kaos',
        ageGroup: 'dewasa',
        sizeCode: 'M',
      );

      expect(result.length, 1);
      expect(result.first.id, 'need-1');
    });

    test('fetchOpenNeeds excludes need when criteria are distributed across disjoint items but not in a single item', () async {
      final fakeData = [
        {
          'id': 'need-1',
          'organization_id': 'org-1',
          'point_id': 'point-1',
          'title': 'Kebutuhan Posko A',
          'deadline_at': '2026-11-20T00:00:00Z',
          'status': 'open',
          'created_at': '2026-10-31T08:00:00Z',
          'need_items': [
            {
              'id': 'item-1',
              'need_id': 'need-1',
              'category': 'kaos',
              'size_code': 'M',
              'age_group': 'dewasa',
              'requested_qty': 10,
            },
            {
              'id': 'item-2',
              'need_id': 'need-1',
              'category': 'celana',
              'size_code': 'S',
              'age_group': 'anak',
              'requested_qty': 5,
            }
          ],
        }
      ];

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(fakeData),
      );
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => fakeBuilder);

      final result = await needsService.fetchOpenNeeds(
        category: 'kaos',
        ageGroup: 'anak',
        sizeCode: 'S',
      );

      expect(result, isEmpty);
    });

    test('fetchOpenNeeds excludes needs with past deadline', () async {
      final fakeData = [
        {
          'id': 'need-expired',
          'organization_id': 'org-1',
          'point_id': 'point-1',
          'title': 'Kebutuhan Kedaluwarsa',
          'deadline_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'status': 'open',
          'created_at': '2026-10-01T08:00:00Z',
          'need_items': [
            {
              'id': 'item-1',
              'need_id': 'need-expired',
              'category': 'kaos',
              'size_code': 'M',
              'age_group': 'dewasa',
              'requested_qty': 10,
            }
          ],
        }
      ];

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(fakeData),
      );
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => fakeBuilder);

      final result = await needsService.fetchOpenNeeds();
      expect(result, isEmpty);
    });

    test('fetchNeedById queries and returns need by id via maybeSingle', () async {
      final fakeData = [
        {
          'id': 'need-target',
          'organization_id': 'org-1',
          'point_id': 'point-1',
          'title': 'Kebutuhan Khusus',
          'deadline_at': '2026-11-20T00:00:00Z',
          'status': 'open',
          'created_at': '2026-10-31T08:00:00Z',
          'need_items': [],
        }
      ];

      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(fakeData),
      );
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => fakeBuilder);

      final result = await needsService.fetchNeedById('need-target');
      expect(result, isNotNull);
      expect(result!.id, 'need-target');
      expect(result.title, 'Kebutuhan Khusus');
    });

    test('fetchNeedById returns null when maybeSingle yields no row', () async {
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value([]),
      );
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => fakeBuilder);

      final result = await needsService.fetchNeedById('non-existent');
      expect(result, isNull);
    });
  });
}
