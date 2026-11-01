import 'package:shared_preferences/shared_preferences.dart';

import '../../operations/presentation/operations_widgets.dart';
import '../../donation/data/local_draft_store.dart';
import '../../../core/providers/supabase_client_provider.dart';

import 'package:flutter/material.dart';

import 'donation_status_badge.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_button.dart';
import '../../../core/widgets/pk_card.dart';
import '../../../core/widgets/stitch_painter.dart';
import '../../donation/application/donation_models.dart';
import '../../donation/application/donation_providers.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({this.initialId, super.key});
  final String? initialId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  String? _selectedId;
  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialId;
  }

  static const _stages = [
    _TrackingStage(
      title: 'Diajukan',
      description: 'Pengajuanmu sudah tercatat dan menunggu tindak lanjut.',
      icon: Icons.inventory_2_outlined,
    ),
    _TrackingStage(
      title: 'Diterima',
      description: 'Pakaian tiba di titik layanan yang dipilih.',
      icon: Icons.checkroom_outlined,
    ),
    _TrackingStage(
      title: 'Dipilah',
      description: 'Relawan mencatat hasil pemeriksaan fisik.',
      icon: Icons.volunteer_activism_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final donationsState = ref.watch(donationsProvider);
    if (donationsState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lacak donasi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (donationsState.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lacak donasi')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: PkCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 36),
                  SizedBox(height: tokens.spaceSm),
                  Text(
                    'Riwayat donasi belum dapat dimuat.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  PkButton(
                    label: 'Coba lagi',
                    onPressed: () => ref.invalidate(donationsProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    var donations = donationsState.value ?? const <DonationRecord>[];
    if (_selectedId != null && !donations.any((d) => d.id == _selectedId)) {
      final selected = ref.watch(singleDonationProvider(_selectedId!));
      if (selected.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (selected.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Lacak donasi')),
          body: Center(
            child: TextButton(
              onPressed: () =>
                  ref.invalidate(singleDonationProvider(_selectedId!)),
              child: const Text('Donasi belum dapat dimuat. Coba lagi.'),
            ),
          ),
        );
      }
      if (selected.value != null) donations = [selected.value!, ...donations];
    }
    final latestDonation = donations.isEmpty
        ? null
        : donations.firstWhere(
            (donation) => donation.id == _selectedId,
            orElse: () => donations.first,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Lacak donasi')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceXl,
          ),
          children: [
            Text(
              latestDonation == null
                  ? 'Setiap pakaian punya perjalanan baru.'
                  : 'Perjalanan baikmu dimulai.',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              latestDonation == null
                  ? 'Di sini kamu bisa mengikuti perjalanan donasi dari awal hingga sampai.'
                  : 'Kami akan memberi kabar saat pakaianmu melangkah ke tahap berikutnya.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: tokens.mutedText, height: 1.5),
            ),
            SizedBox(height: tokens.spaceLg),
            if (donations.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: latestDonation?.id,
                key: ValueKey(latestDonation?.id),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Pilih donasi'),
                items: [
                  for (final donation in donations)
                    DropdownMenuItem(
                      value: donation.id,
                      child: Text(
                        donation.trackingCode ?? donation.id,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => setState(() => _selectedId = id),
              ),
              const SizedBox(height: 16),
            ],
            if (latestDonation == null)
              PkCard(
                stitchedBorder: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      color: tokens.accentStrong,
                    ),
                    SizedBox(width: tokens.spaceSm),
                    Expanded(
                      child: Text(
                        'Belum ada donasi untuk dilacak. Setelah kamu '
                        'mencatat donasi, statusnya akan muncul di sini.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _DonationSummary(donation: latestDonation),
              const SizedBox(height: 16),
              PkCard(child: DonationStatusBadge(donation: latestDonation)),
              if (['draft', 'needs_revision'].contains(latestDonation.status))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: PkButton(
                    label: latestDonation.status == 'needs_revision'
                        ? 'Perbaiki pengajuan'
                        : 'Lanjutkan draf',
                    onPressed: () =>
                        context.go('/donate?edit=${latestDonation.id}'),
                  ),
                ),
              if ([
                'draft',
                'submitted',
                'needs_revision',
                'scheduled',
              ].contains(latestDonation.status))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OperationButton(
                    action: 'cancel',
                    label: 'Batalkan donasi',
                    secondary: true,
                    values: () => {'id': latestDonation.id},
                    onSuccess: () async {
                      final uid = ref
                          .read(supabaseClientProvider)
                          ?.auth
                          .currentUser
                          ?.id;
                      if (uid != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await LocalDraftStore(
                          prefs,
                          uid,
                          latestDonation.id,
                        ).clear();
                      }
                      if (mounted) {
                        ref.read(donationFormEpochProvider.notifier).reset();
                      }
                    },
                  ),
                ),
              if (latestDonation.status == 'needs_revision')
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Donasi perlu diperbaiki. Periksa catatan petugas pada riwayat di atas.',
                  ),
                ),
              if (latestDonation.status == 'cancelled')
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Donasi dibatalkan. Tidak ada tahap selanjutnya untuk pengajuan ini.',
                  ),
                ),
            ],
            SizedBox(height: tokens.spaceLg),
            if (latestDonation != null &&
                latestDonation.status != 'cancelled' &&
                latestDonation.status != 'draft') ...[
              Text(
                'Tahapan donasi',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: tokens.spaceMd),
              PkCard(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                child: Column(
                  children: [
                    for (var index = 0; index < _stages.length; index++)
                      _TrackingTimelineStep(
                        stage: _stages[index],
                        isCurrent:
                            latestDonation.status != 'curated' &&
                            _stageIndex(latestDonation.status) == index,
                        isComplete:
                            latestDonation.status == 'curated' ||
                            _stageIndex(latestDonation.status) > index,
                        isLast: index == _stages.length - 1,
                      ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spaceLg),
            ],
            PkButton(
              label: 'Mulai donasi',
              icon: Icons.favorite_border_rounded,
              expanded: true,
              onPressed: () => context.go('/donate'),
            ),
          ],
        ),
      ),
    );
  }

  static int _stageIndex(String? status) => switch (status) {
    'submitted' || 'needs_revision' || 'scheduled' => 0,
    'received' => 1,
    'curated' => 2,
    _ => -1,
  };
}

class _DonationSummary extends StatelessWidget {
  const _DonationSummary({required this.donation});

  final DonationRecord donation;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return PkCard(
      color: tokens.deepGreen,
      stitchedBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DONASI YANG DIPILIH',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tokens.orange,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            donation.trackingCode ?? donation.id,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${donation.quantity} pakaian · ${donation.category.label}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 12),
          Text(
            '${donation.statusLabel} · '
            '${donation.deliveryMethod == DeliveryMethod.pickup ? 'Jemput di rumah' : 'Antar ke ${donation.donationPoint?.name ?? 'titik layanan'}'}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 8),
          for (final event in donation.events)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                event.summary,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.78)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackingStage {
  const _TrackingStage({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _TrackingTimelineStep extends StatelessWidget {
  const _TrackingTimelineStep({
    required this.stage,
    required this.isCurrent,
    required this.isComplete,
    required this.isLast,
  });

  final _TrackingStage stage;
  final bool isCurrent;
  final bool isComplete;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return Semantics(
      label:
          '${stage.title}${isCurrent ? ', status saat ini' : ''}. ${stage.description}',
      child: SizedBox(
        height: isLast ? 76 : 94,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? tokens.accentStrong
                          : isCurrent
                          ? tokens.orange
                          : tokens.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isComplete ? tokens.accentStrong : tokens.border,
                      ),
                    ),
                    child: Icon(
                      isComplete
                          ? Icons.check_rounded
                          : isCurrent
                          ? Icons.schedule_rounded
                          : stage.icon,
                      size: 16,
                      color: isComplete
                          ? Colors.white
                          : isCurrent
                          ? tokens.onSurface
                          : tokens.mutedText,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: CustomPaint(
                        size: const Size(2, 1),
                        painter: StitchPainter(
                          color: isComplete ? tokens.accent : tokens.border,
                          shape: StitchShape.vertical,
                          strokeWidth: 2,
                          dashLength: 4,
                          gapLength: 4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stage.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isComplete
                                      ? tokens.accentStrong
                                      : tokens.onSurface,
                                ),
                          ),
                        ),
                        if (isCurrent)
                          Text(
                            'SAAT INI',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: tokens.accentStrong,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stage.description,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: tokens.mutedText, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
