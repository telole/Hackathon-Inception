import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/features/donation/services/donation_service.dart';
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

void main() {
  late MockSupabaseClient mockSupabase;
  late DonationService donationService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
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
  });
}
