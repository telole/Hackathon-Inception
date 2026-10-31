import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/features/donation/services/donation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

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

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> order(String column, {bool ascending = false, bool nullsFirst = false, String? referencedTable}) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([String columns = '*']) =>
      FakePostgrestTransformBuilder<List<Map<String, dynamic>>>(_future as dynamic);
}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final Future<T> _future;
  FakePostgrestTransformBuilder(this._future);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    final singleFuture = (_future as Future<List<Map<String, dynamic>>>)
        .then((list) => list.first);
    return FakePostgrestTransformBuilder<Map<String, dynamic>>(singleFuture);
  }
}

class MockSupabaseQueryBuilder extends Mock
    implements SupabaseQueryBuilder {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockDonationsQuery;
  late MockSupabaseQueryBuilder mockEventsQuery;
  late DonationService donationService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockDonationsQuery = MockSupabaseQueryBuilder();
    mockEventsQuery = MockSupabaseQueryBuilder();

    when(() => mockUser.id).thenReturn('donor-uuid-1');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockSupabase.auth).thenReturn(mockAuth);

    when(() => mockSupabase.from('donations')).thenAnswer((_) => mockDonationsQuery);
    when(() => mockSupabase.from('donation_events')).thenAnswer((_) => mockEventsQuery);

    donationService = DonationService(client: mockSupabase);
  });

  group('DonationService', () {
    test('submitDonation calls submit_donation RPC with correct p_id', () async {
      const donationId = '11111111-1111-1111-1111-111111111111';
      final builder = FakePostgrestFilterBuilder<dynamic>(Future.value(null));
      when(() => mockSupabase.rpc('submit_donation', params: {'p_id': donationId}))
          .thenAnswer((_) => builder);

      await donationService.submitDonation(donationId);

      verify(() => mockSupabase.rpc('submit_donation', params: {'p_id': donationId}))
          .called(1);
    });

    test('saveDonationContact calls save_donation_contact RPC with correct params', () async {
      const donationId = '11111111-1111-1111-1111-111111111111';
      final builder = FakePostgrestFilterBuilder<dynamic>(Future.value(null));
      when(
        () => mockSupabase.rpc(
          'save_donation_contact',
          params: {
            'p_id': donationId,
            'p_address': 'Jl. Merdeka No. 1',
            'p_name': 'Budi Santoso',
            'p_phone': '08123456789',
          },
        ),
      ).thenAnswer((_) => builder);

      await donationService.saveDonationContact(
        donationId: donationId,
        address: 'Jl. Merdeka No. 1',
        contactName: 'Budi Santoso',
        phone: '08123456789',
      );

      verify(
        () => mockSupabase.rpc(
          'save_donation_contact',
          params: {
            'p_id': donationId,
            'p_address': 'Jl. Merdeka No. 1',
            'p_name': 'Budi Santoso',
            'p_phone': '08123456789',
          },
        ),
      ).called(1);
    });

    test('getDonationContact calls get_donation_contact RPC and returns contact map', () async {
      const donationId = '11111111-1111-1111-1111-111111111111';
      final expectedMap = {
        'address': 'Jl. Merdeka No. 1',
        'contact_name': 'Budi Santoso',
        'phone': '08123456789',
      };
      final builder = FakePostgrestFilterBuilder<dynamic>(Future.value(expectedMap));
      when(() => mockSupabase.rpc('get_donation_contact', params: {'p_id': donationId}))
          .thenAnswer((_) => builder);

      final result = await donationService.getDonationContact(donationId);

      expect(result, expectedMap);
      verify(() => mockSupabase.rpc('get_donation_contact', params: {'p_id': donationId}))
          .called(1);
    });

    test('createDraftDonation inserts draft donation row and returns created id', () async {
      final fakeInsertedRow = {
        'id': 'don-draft-1',
        'method': 'dropoff',
        'status': 'draft',
      };
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value([fakeInsertedRow]),
      );
      when(() => mockDonationsQuery.insert(any())).thenAnswer((_) => fakeBuilder);

      final id = await donationService.createDraftDonation(
        method: 'dropoff',
        pointId: 'point-1',
      );

      expect(id, 'don-draft-1');
    });

    test('fetchDonationTimeline returns list of timeline events', () async {
      final fakeEvents = [
        {
          'id': 1,
          'donation_id': 'don-1',
          'event_type': 'submitted',
          'summary': 'Donasi diajukan',
          'actor_id': 'donor-1',
          'created_at': '2026-10-31T09:00:00Z',
        }
      ];
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
        Future.value(fakeEvents),
      );
      when(() => mockEventsQuery.select(any())).thenAnswer((_) => fakeBuilder);

      final timeline = await donationService.fetchDonationTimeline('don-1');

      expect(timeline.length, 1);
      expect(timeline.first.eventType, 'submitted');
    });
  });
}
