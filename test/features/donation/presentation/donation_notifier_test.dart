import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:resandang/features/donation/models/donation.dart';
import 'package:resandang/features/donation/presentation/donation_notifier.dart';
import 'package:resandang/features/donation/services/donation_service.dart';

class MockDonationService extends Mock implements IDonationService {}

void main() {
  late MockDonationService mockDonationService;
  late DonationNotifier notifier;

  setUp(() {
    mockDonationService = MockDonationService();
    notifier = DonationNotifier(donationService: mockDonationService);
  });

  group('DonationNotifier', () {
    test('initial state has empty donations and timeline', () {
      expect(notifier.isLoading, isFalse);
      expect(notifier.myDonations, isEmpty);
      expect(notifier.timeline, isEmpty);
      expect(notifier.errorMessage, isNull);
    });

    test('loadMyDonations loads donations on success', () async {
      final fakeDonations = [
        Donation(
          id: 'don-1',
          donorId: 'u-1',
          trackingCode: 'PK-1234',
          method: 'dropoff',
          status: 'submitted',
          cleanCheck: true,
          intactCheck: true,
          notTornCheck: true,
          createdAt: DateTime.now(),
        )
      ];

      when(() => mockDonationService.fetchMyDonations())
          .thenAnswer((_) async => fakeDonations);

      await notifier.loadMyDonations();

      expect(notifier.isLoading, isFalse);
      expect(notifier.myDonations.length, 1);
      expect(notifier.myDonations.first.trackingCode, 'PK-1234');
      expect(notifier.errorMessage, isNull);
    });

    test('startNewDraft calls createDraftDonation and returns created id', () async {
      when(
        () => mockDonationService.createDraftDonation(
          method: 'dropoff',
          pointId: 'p-1',
          preferredNeedId: 'n-1',
        ),
      ).thenAnswer((_) async => 'created-don-id');

      final id = await notifier.startNewDraft(
        method: 'dropoff',
        pointId: 'p-1',
        preferredNeedId: 'n-1',
      );

      expect(id, 'created-don-id');
      expect(notifier.isLoading, isFalse);
    });

    test('submitDraft calls submitDonation and reloads donations', () async {
      when(() => mockDonationService.submitDonation('don-1'))
          .thenAnswer((_) async {});
      when(() => mockDonationService.fetchMyDonations())
          .thenAnswer((_) async => []);

      final success = await notifier.submitDraft('don-1');

      expect(success, isTrue);
      verify(() => mockDonationService.submitDonation('don-1')).called(1);
    });

    test('loadTimeline loads timeline events for donation', () async {
      final fakeEvents = [
        DonationEvent(
          id: 1,
          donationId: 'don-1',
          eventType: 'submitted',
          summary: 'Donasi diajukan',
          createdAt: DateTime.now(),
        )
      ];

      when(() => mockDonationService.fetchDonationTimeline('don-1'))
          .thenAnswer((_) async => fakeEvents);

      await notifier.loadTimeline('don-1');

      expect(notifier.timeline.length, 1);
      expect(notifier.timeline.first.eventType, 'submitted');
    });
  });
}
