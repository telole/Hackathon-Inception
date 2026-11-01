import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakaiankita/core/data/rows_pager.dart';
import 'package:pakaiankita/core/router/app_router.dart';
import 'package:pakaiankita/core/widgets/pk_button.dart';
import 'package:pakaiankita/features/notifications/notification_center.dart';
import 'package:pakaiankita/features/registration/data/registration_repository.dart';
import 'package:pakaiankita/features/operations/data/demo_operations_repository.dart';
import 'package:pakaiankita/features/operations/data/operations_repository.dart';
import 'package:pakaiankita/features/operations/application/operations_providers.dart';
import 'package:pakaiankita/main.dart';

class _Applicant extends DemoOperationsRepository {
  int loads = 0;
  @override
  Future<OperationsAccess> access() async =>
      const OperationsAccess(roles: ['donatur']);
  @override
  Future<List<OpsRow>> load(String resource) async {
    loads++;
    return [];
  }
}

void main() {
  test(
    'pagination keeps boundary rows, deduplicates and retries failed next page',
    () async {
      var fail = false;
      final calls = <int>[];
      final pager = RowsPager((offset, limit) async {
        calls.add(offset);
        if (fail) throw StateError('network');
        return [
          for (var i = offset; i < 7 && i < offset + limit; i++) {'id': '$i'},
        ];
      }, pageSize: 3);
      await pager.refresh();
      expect(pager.rows.map((r) => r['id']), ['0', '1', '2']);
      expect(pager.hasMore, isTrue);
      fail = true;
      await pager.more();
      expect(pager.rows.length, 3);
      expect(pager.error, isNotNull);
      fail = false;
      await pager.more();
      expect(pager.rows.length, 6);
      await pager.more();
      expect(pager.rows.length, 7);
      expect(pager.hasMore, isFalse);
      expect(calls, [0, 3, 3, 6]);
      pager.dispose();
    },
  );
  test('late responses cannot overwrite a refreshed page', () async {
    final first = Completer<List<OpsRow>>();
    var count = 0;
    final pager = RowsPager((offset, limit) {
      count++;
      return count == 1
          ? first.future
          : Future.value([
              {'id': 'fresh'},
            ]);
    });
    final pending = pager.refresh();
    await pager.refresh();
    first.complete([
      {'id': 'stale'},
    ]);
    await pending;
    expect(pager.rows.single['id'], 'fresh');
    pager.dispose();
  });
  test('notification navigation rejects external URLs and preserves internal detail', () {
    expect(safeNotificationRoute('https://evil.example'), isNull);
    expect(safeNotificationRoute('//evil.example'), isNull);
    expect(
      safeNotificationRoute('/auth?redirect=https://evil.example'),
      isNull,
    );
    expect(
      safeNotificationRoute('/tracking?donation=123'),
      '/tracking?donation=123',
    );
  });
  test('verification documents accept supported signatures only', () {
    expect(
      verificationDocumentType(Uint8List.fromList('%PDF-1.7'.codeUnits))?.$2,
      'application/pdf',
    );
    expect(
      verificationDocumentType(Uint8List.fromList('executable'.codeUnits)),
      isNull,
    );
  });
  testWidgets('volunteer form validates motivation before submission', (
    tester,
  ) async {
    appRouter.go('/join/volunteer');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          operationsRepositoryProvider.overrideWithValue(_Applicant()),
        ],
        child: const PakaiankitaApp(demoMode: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(PkButton, 'Kirim pengajuan relawan'),
    );
    await tester.tap(find.widgetWithText(PkButton, 'Kirim pengajuan relawan'));
    await tester.pumpAndSettle();
    expect(find.text('Tulis sedikitnya 10 karakter.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'applicant cannot fetch registration review data through a direct route',
    (tester) async {
      final applicant = _Applicant();
      appRouter.go('/operations/registrations/organization/id');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            operationsRepositoryProvider.overrideWithValue(applicant),
          ],
          child: const PakaiankitaApp(demoMode: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('belum memiliki izin'), findsOneWidget);
      expect(applicant.loads, 0);
    },
  );
}
