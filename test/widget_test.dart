// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pakaiankita/core/router/app_router.dart';
import 'package:pakaiankita/core/widgets/pk_logo.dart';
import 'package:pakaiankita/features/donation/application/donation_models.dart';
import 'package:pakaiankita/features/donation/application/donation_photo_picker.dart';
import 'package:pakaiankita/features/donation/application/donation_providers.dart';
import 'package:pakaiankita/features/donation/data/donation_repository.dart';
import 'package:pakaiankita/features/home/application/home_providers.dart';
import 'package:pakaiankita/features/home/application/home_models.dart';
import 'package:pakaiankita/features/home/data/home_repository.dart';
import 'package:pakaiankita/main.dart';

void main() {
  testWidgets('onboarding continues to the populated home shell', (
    tester,
  ) async {
    appRouter.go('/onboarding');
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Yang layak pakai'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Satu donasi bisa'), findsOneWidget);

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bersama kita kurangi'), findsOneWidget);
    await tester.tap(find.text('Mulai berbagi'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Nadia'), findsOneWidget);
    expect(find.text('Dampak Kamu'), findsOneWidget);
    expect(find.text('Donasi Pakaian'), findsOneWidget);
    expect(find.text('Pilih kategori'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kebutuhan terbuka'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kebutuhan terbuka'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Seragam sekolah untuk Cianjur'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Seragam sekolah untuk Cianjur'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Donasi'), findsOneWidget);
    expect(find.text('Lacak'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Donasi'));
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, '/donate');

    appRouter.go('/home');
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 2000),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pilih kategori'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lencana kebaikan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lencana kebaikan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Penyelamat 10 Baju'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Penyelamat 10 Baju'), findsOneWidget);
    expect(appRouter.routeInformationProvider.value.uri.path, '/profile');
  });

  testWidgets('loads the provided SVG brand assets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              PkLogo(width: 120),
              PkLogo(width: 120, onDark: true),
              PkLogoMark(size: 48),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('records a drop-off donation with its selected point', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = InMemoryDonationRepository.instance;
    final initialDonationCount = repository.donations.length;
    appRouter.go('/donate');
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Anak'));
    await tester.tap(find.text('Kaos / atasan'));
    await tester.ensureVisible(find.text('Tambah foto wajib'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah foto wajib'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.text('Bantu kami mengenalnya.'), findsOneWidget);
    await tester.tap(find.text('M'));
    await tester.ensureVisible(find.text('Sudah dicuci dan bersih'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sudah dicuci dan bersih'));
    await tester.ensureVisible(find.text('Masih utuh dan berfungsi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masih utuh dan berfungsi'));
    await tester.ensureVisible(find.text('Tidak robek atau berlubang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tidak robek atau berlubang'));
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih cara berbagi.'), findsOneWidget);

    await tester.ensureVisible(find.text('Antar ke titik donasi'));
    await tester.tap(find.text('Antar ke titik donasi'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih titik donasi'), findsOneWidget);
    await tester.tap(find.text('Pilih titik donasi'));
    await tester.pumpAndSettle();
    expect(find.text('Rumah Sandang Dago'), findsOneWidget);
    await tester.tap(find.text('Rumah Sandang Dago'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catat donasiku'));
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, '/success');
    expect(find.text('Terima kasih, Nadia Putri.'), findsOneWidget);
    expect(find.text('SERTIFIKAT DAMPAK'), findsOneWidget);
    expect(find.text('Bagikan sertifikat dampak'), findsOneWidget);
    expect(appRouter.routeInformationProvider.value.uri.path, '/success');
    expect(repository.donations, hasLength(initialDonationCount + 1));
    expect(repository.donations.first.quantity, 1);
    expect(repository.donations.first.donationPoint?.id, 'rumah-sandang-dago');
    await tester.tap(find.text('Lacak perjalanan donasi'));
    await tester.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, '/tracking');
  });

  testWidgets('campaign card opens its story and donation category', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    appRouter.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('Halo, Nadia'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Seragam sekolah untuk Cianjur'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Seragam sekolah untuk Cianjur')),
      alignment: 0.2,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seragam sekolah untuk Cianjur'));
    await tester.pumpAndSettle();

    expect(find.text('Cerita kampanye'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kebutuhan pakaian'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kebutuhan pakaian'), findsOneWidget);
    expect(
      find.textContaining('Awal tahun ajaran baru semakin dekat.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Donasi untuk kebutuhan ini'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Donasi untuk kebutuhan ini'));
    await tester.pumpAndSettle();

    expect(
      appRouter.routeInformationProvider.value.uri.queryParameters['kategori'],
      'seragam-sekolah',
    );
    expect(appRouter.routeInformationProvider.value.uri.path, '/donate');
  });

  testWidgets('tracking screen shows the stitched donation timeline', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(repository: _TrackingFixture()));
    appRouter.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lacak'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tahapan donasi'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tahapan donasi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Diterima'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Diterima'), findsOneWidget);
    expect(find.text('Dipilah'), findsOneWidget);
  });

  testWidgets('profile respects the system dark theme', (tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );

    await tester.pumpWidget(_testApp());
    appRouter.go('/profile');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lencana kebaikan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      Theme.of(tester.element(find.text('Lencana kebaikan'))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({DonationRepository? repository}) {
  return ProviderScope(
    overrides: [
      homeRepositoryProvider.overrideWithValue(const InMemoryHomeRepository()),
      donationRepositoryProvider.overrideWithValue(
        repository ?? InMemoryDonationRepository.instance,
      ),
      donationPhotoPickerProvider.overrideWithValue(_TestDonationPhotoPicker()),
    ],
    child: const PakaiankitaApp(),
  );
}

class _TestDonationPhotoPicker implements DonationPhotoPicker {
  static final _photoBytes = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/r/8AAAAASUVORK5CYII=',
    ),
  );

  @override
  Future<PickedDonationPhoto?> pick() async =>
      PickedDonationPhoto(name: 'pakaian.png', bytes: _photoBytes);
}

class _TrackingFixture extends Fake implements DonationRepository {
  @override
  Future<List<DonationRecord>> fetchDonations() async => [
    DonationRecord(
      id: 'PK-TEST',
      category: DonationCategory.children,
      size: ClothingSize.m,
      quantity: 5,
      deliveryMethod: DeliveryMethod.dropOff,
      createdAt: DateTime(2026),
      status: 'received',
    ),
  ];
}
