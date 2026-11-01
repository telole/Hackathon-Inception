import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakaiankita/core/router/app_router.dart';
import 'package:pakaiankita/features/donation/application/donation_models.dart';
import 'package:pakaiankita/features/donation/application/donation_providers.dart';
import 'package:pakaiankita/features/donation/data/donation_repository.dart';
import 'package:pakaiankita/features/home/application/home_models.dart';
import 'package:pakaiankita/features/home/application/home_providers.dart';
import 'package:pakaiankita/features/home/data/home_repository.dart';
import 'package:pakaiankita/main.dart';

class _History extends Fake implements DonationRepository {
  _History(this.records);
  final List<DonationRecord> records;
  @override
  Future<List<DonationRecord>> fetchDonations() async => records;
}

DonationRecord record(String id, String status) => DonationRecord(
  id: id,
  category: DonationCategory.children,
  size: ClothingSize.m,
  quantity: 5,
  deliveryMethod: DeliveryMethod.dropOff,
  createdAt: DateTime(2026, 11, 1),
  status: status,
);

Future<void> open(
  WidgetTester tester,
  String route, {
  List<DonationRecord> records = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  appRouter.go(route);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeRepositoryProvider.overrideWithValue(
          const InMemoryHomeRepository(),
        ),
        donationRepositoryProvider.overrideWithValue(_History(records)),
      ],
      child: const PakaiankitaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'onboarding swipe changes only the active dot and supports going back',
    (tester) async {
      await open(tester, '/onboarding');
      expect(find.text('PAKAIANMU, CERITA BARU'), findsNothing);
      double? dotWidth(int i) => tester
          .widget<AnimatedContainer>(find.byKey(ValueKey('onboarding-dot-$i')))
          .constraints
          ?.maxWidth;
      expect([dotWidth(0), dotWidth(1), dotWidth(2)], [24, 8, 8]);
      await tester.drag(
        find.byKey(const ValueKey('onboarding-pages')),
        const Offset(-350, 0),
      );
      await tester.pumpAndSettle();
      expect([dotWidth(0), dotWidth(1), dotWidth(2)], [8, 24, 8]);
      await tester.drag(
        find.byKey(const ValueKey('onboarding-pages')),
        const Offset(-350, 0),
      );
      await tester.pumpAndSettle();
      expect([dotWidth(0), dotWidth(1), dotWidth(2)], [8, 8, 24]);
      await tester.drag(
        find.byKey(const ValueKey('onboarding-pages')),
        const Offset(350, 0),
      );
      await tester.pumpAndSettle();
      expect([dotWidth(0), dotWidth(1), dotWidth(2)], [8, 24, 8]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('needs list searches partner and opens the matching detail', (
    tester,
  ) async {
    await open(tester, '/needs');
    await tester.enterText(find.byType(TextField), 'Pelita');
    await tester.pump(const Duration(milliseconds:400));
    await tester.pumpAndSettle();
    expect(find.text('Seragam sekolah untuk Cianjur'), findsOneWidget);
    expect(find.text('Pakaian hangat keluarga'), findsNothing);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Seragam sekolah untuk Cianjur')),
      alignment: 0.1,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seragam sekolah untuk Cianjur'));
    await tester.pumpAndSettle();
    expect(find.text('Cerita kampanye'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled donation shows close icon and no ongoing timeline', (
    tester,
  ) async {
    await open(
      tester,
      '/tracking',
      records: [record('PK-CANCEL', 'cancelled')],
    );
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Tahapan donasi'), findsNothing);
    expect(find.textContaining('Tidak ada tahap selanjutnya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tracking switches between donations instead of only showing latest',
    (tester) async {
      await open(
        tester,
        '/tracking',
        records: [record('PK-ONE', 'submitted'), record('PK-TWO', 'curated')],
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PK-TWO').last);
      await tester.pumpAndSettle();
      expect(find.text('Selesai dikurasi'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty tracking does not fabricate completed or pending stages', (
    tester,
  ) async {
    await open(tester, '/tracking');
    expect(find.text('Tahapan donasi'), findsNothing);
    expect(
      find.textContaining('Belum ada donasi untuk dilacak.'),
      findsOneWidget,
    );
  });
}
