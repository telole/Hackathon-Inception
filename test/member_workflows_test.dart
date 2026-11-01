import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pakaiankita/core/router/app_router.dart';
import 'package:pakaiankita/core/widgets/pk_button.dart';
import 'package:pakaiankita/features/campaign/data/program_repository.dart';
import 'package:pakaiankita/features/donation/data/local_draft_store.dart';
import 'package:pakaiankita/main.dart';
import 'package:pakaiankita/features/operations/application/operations_providers.dart';
import 'package:pakaiankita/features/operations/data/demo_operations_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'draft survives store recreation and remains scoped to account and edit ID',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await LocalDraftStore(
        preferences,
        'alice',
        null,
      ).save({'draftId': 'same-id', 'quantity': 4, 'photo': 'AA=='});
      expect(
        LocalDraftStore(preferences, 'alice', null).read()?['draftId'],
        'same-id',
      );
      expect(LocalDraftStore(preferences, 'bob', null).read(), isNull);
      expect(
        LocalDraftStore(preferences, 'alice', 'other-donation').read(),
        isNull,
      );
      await LocalDraftStore(preferences, 'bob', null).save({'quantity': 1});
      await LocalDraftStore.clearAccount('alice');
      expect(LocalDraftStore(preferences, 'alice', null).read(), isNull);
      expect(LocalDraftStore(preferences, 'bob', null).read()?['quantity'], 1);
    },
  );
  test('banner validates real file signature', () {
    expect(
      imageExtension(Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10])),
      'png',
    );
    expect(imageExtension(Uint8List.fromList([255, 216, 255])), 'jpg');
    expect(
      imageExtension(Uint8List.fromList('not a photograph'.codeUnits)),
      isNull,
    );
  });
  testWidgets(
    'new password rejects short and mismatched values without a request',
    (tester) async {
      appRouter.go('/account/password');
      await tester.pumpWidget(const ProviderScope(child: PakaiankitaApp()));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PkButton, 'Simpan kata sandi'));
      await tester.pumpAndSettle();
      expect(find.text('Minimal 8 karakter.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'long-password');
      await tester.enterText(find.byType(TextFormField).at(1), 'different');
      await tester.tap(find.widgetWithText(PkButton, 'Simpan kata sandi'));
      await tester.pumpAndSettle();
      expect(find.text('Kata sandi belum sama.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('program editor validates title before writing a program', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appRouter.go('/operations/programs/new');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          operationsRepositoryProvider.overrideWithValue(
            DemoOperationsRepository(),
          ),
        ],
        child: const PakaiankitaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(PkButton, 'Simpan program'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.widgetWithText(PkButton, 'Simpan program')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PkButton, 'Simpan program'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Nama program wajib diisi.'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nama program wajib diisi.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
