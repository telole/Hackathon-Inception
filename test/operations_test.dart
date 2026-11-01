import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakaiankita/core/router/app_router.dart';
import 'package:pakaiankita/core/widgets/pk_button.dart';
import 'package:pakaiankita/features/operations/application/operations_providers.dart';
import 'package:pakaiankita/features/operations/data/demo_operations_repository.dart';
import 'package:pakaiankita/features/operations/data/operations_repository.dart';
import 'package:pakaiankita/main.dart';

class _DonorOnly extends DemoOperationsRepository {
  int loads = 0;
  @override
  Future<OperationsAccess> access() async =>
      const OperationsAccess(roles: ['donatur']);
  @override
  Future<List<OpsRow>> load(String resource) async {
    loads++;
    return super.load(resource);
  }
}

class _WorkflowRepository extends DemoOperationsRepository {
  final actions = <String>[];
  @override
  Future<List<OpsRow>> load(String resource) async {
    switch (resource) {
      case 'donation:scheduled':
        return [
          {
            'id': 'scheduled',
            'tracking_code': 'PK-NEW',
            'point_id': 'demo-point',
            'status': 'submitted',
            'method': 'pickup',
            'donation_items': [
              {'category': 'kaos', 'size_code': 'M', 'quantity': 5},
            ],
          },
        ];
      case 'needLines':
        return [
          {
            'id': 'need-line',
            'category': 'kaos',
            'size_code': 'M',
            'age_group': 'anak',
            'requested_qty': 10,
            'needs': {'title': 'Program sekolah'},
          },
        ];
      case 'volunteers':
        return [
          {'user_id': 'volunteer', 'display_name': 'Rina Relawan'},
        ];
      case 'allocations':
        return [
          {'id': 'allocation-test', 'quantity': 4, 'shipment_items': []},
        ];
      default:
        return super.load(resource);
    }
  }

  @override
  Future<void> act(String action, OpsRow input, String requestKey) async {
    actions.add(action);
  }
}

Future<void> open(
  WidgetTester tester,
  String route,
  OperationsRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  appRouter.go(route);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [operationsRepositoryProvider.overrideWithValue(repository)],
      child: const PakaiankitaApp(demoMode: true),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('schedule requires a future date before sending to backend', (
    tester,
  ) async {
    final repository = _WorkflowRepository();
    await open(tester, '/operations/schedule/scheduled', repository);
    await tester.ensureVisible(find.text('Konfirmasi jadwal'));
    await tester.tap(find.text('Konfirmasi jadwal'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih jadwal yang belum lewat.'), findsOneWidget);
    expect(repository.actions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'allocation filters matching clothing and validates available quantity',
    (tester) async {
      final repository = _WorkflowRepository();
      await open(tester, '/operations/allocate', repository);
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('kaos · M · anak').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reservasi pakaian'));
      await tester.tap(find.text('Reservasi pakaian'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Pilih tujuan dan isi jumlah'),
        findsOneWidget,
      );
      expect(repository.actions, isEmpty);
      await tester.ensureVisible(find.text('Program tujuan'));
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Program sekolah').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '4');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reservasi pakaian'));
      await tester.tap(find.text('Reservasi pakaian'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi'));
      await tester.pumpAndSettle();
      expect(repository.actions, ['reserve']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'create shipment requires allocation and volunteer before confirmation',
    (tester) async {
      final repository = _WorkflowRepository();
      await open(tester, '/operations/shipments/new', repository);
      await tester.ensureVisible(find.widgetWithText(PkButton, 'Buat kiriman'));
      await tester.tap(find.widgetWithText(PkButton, 'Buat kiriman'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih alokasi dan relawan pengantar.'), findsOneWidget);
      expect(repository.actions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('donor cannot load admin data through a direct route', (
    tester,
  ) async {
    final repository = _DonorOnly();
    await open(tester, '/operations/reviews', repository);
    expect(find.textContaining('belum memiliki izin'), findsOneWidget);
    expect(repository.loads, 0);
  });

  testWidgets(
    'curation rejects an unbalanced count and commits once after confirmation',
    (tester) async {
      final repository = DemoOperationsRepository();
      await open(tester, '/operations/curation/demo-donation-1', repository);
      await tester.ensureVisible(find.text('Simpan hasil kurasi'));
      await tester.tap(find.text('Simpan hasil kurasi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Total hasil harus 5'), findsOneWidget);
      expect(find.text('Konfirmasi'), findsNothing);
      await tester.enterText(find.byType(TextFormField).at(0), '4');
      await tester.enterText(find.byType(TextFormField).at(1), '1');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Robek pada bagian lengan.',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Simpan hasil kurasi'));
      await tester.tap(find.text('Simpan hasil kurasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('sudah diperiksa'), findsOneWidget);
      final stock = await repository.load('inventory:demo-point');
      expect(stock.first['on_hand_qty'], 44);
      expect(stock.first['available_qty'], 34);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('declining a confirmation leaves the task unchanged', (
    tester,
  ) async {
    final repository = DemoOperationsRepository();
    await open(tester, '/operations/tasks/demo-task-2', repository);
    await tester.ensureVisible(find.text('Terima tugas'));
    await tester.tap(find.text('Terima tugas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect((await repository.load('tasks')).last['status'], 'assigned');
    await tester.tap(find.text('Terima tugas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi'));
    await tester.pumpAndSettle();
    expect((await repository.load('tasks')).last['status'], 'accepted');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dashboard connects to stock and stock shows reserved quantities',
    (tester) async {
      await open(tester, '/operations', DemoOperationsRepository());
      await tester.tap(find.text('Stok lembaga'));
      await tester.pumpAndSettle();
      expect(find.text('30 tersedia', findRichText: true), findsNothing);
      expect(find.textContaining('30 tersedia'), findsOneWidget);
      expect(find.text('40 di posko · 10 direservasi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
