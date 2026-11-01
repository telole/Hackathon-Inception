import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../../core/widgets/pk_card.dart';
import '../application/operations_providers.dart';
import '../data/operations_repository.dart';
import 'operations_widgets.dart';

class OperationsHomeScreen extends ConsumerWidget {
  const OperationsHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(operationsAccessProvider).value;
    final tokens = Theme.of(context).extension<PkTokens>()!;
    return OperationsPage(
      title: access?.isAdmin == true ? 'Ruang admin' : 'Ruang operasional',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PkCard(
            color: tokens.deepGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bersama, sampai tujuan.',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: PkPalette.cream),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih pekerjaan yang sesuai dengan izin akunmu.',
                  style: TextStyle(color: PkPalette.cream),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (access?.allows('relawan') == true)
            _MenuTile(
              'Tugas relawan',
              'Penjemputan, penerimaan dan kurasi',
              Icons.volunteer_activism_outlined,
              '/operations/tasks',
            ),
          if (access?.allows('relawan') == true)
            _MenuTile(
              'Kiriman tugasmu',
              'Catat keberangkatan kiriman yang ditugaskan',
              Icons.local_shipping_outlined,
              '/operations/shipments',
            ),
          if (access?.allows('mitra') == true) ...[
            _MenuTile(
              'Stok lembaga',
              'Pakaian lolos kurasi di titik layananmu',
              Icons.inventory_2_outlined,
              '/operations/stock',
            ),
            _MenuTile(
              'Kiriman',
              'Siapkan pengiriman dan catat penerimaan',
              Icons.local_shipping_outlined,
              '/operations/shipments',
            ),
          ],
          if (access?.allows('mitra') == true) ...[
            _MenuTile(
              'Alokasi pakaian',
              'Reservasi stok untuk kebutuhan yang sesuai',
              Icons.swap_horiz,
              '/operations/allocate',
            ),
            _MenuTile(
              'Buat kiriman',
              'Teruskan alokasi ke relawan pengiriman',
              Icons.add_box_outlined,
              '/operations/shipments/new',
            ),
          ],
          if (access?.allows('mitra') == true)
            _MenuTile(
              'Program lembaga',
              'Kelola kebutuhan dan banner program',
              Icons.campaign_outlined,
              '/operations/programs',
            ),
          if (access?.allows('mitra') == true)
            _MenuTile(
              'Lembaga dan anggota',
              'Atur anggota dan titik layanan',
              Icons.business_outlined,
              '/organization',
            ),
          if (access?.isAdmin == true) ...[
            _MenuTile(
              'Pengajuan relawan',
              'Tinjau dan berikan izin relawan',
              Icons.person_add_alt_outlined,
              '/operations/registrations/volunteer',
            ),
            _MenuTile(
              'Pendaftaran lembaga',
              'Periksa dokumen dan keputusan',
              Icons.domain_verification_outlined,
              '/operations/registrations/organization',
            ),
            _MenuTile(
              'Kelola penugasan',
              'Periksa tugas dan pilih ulang relawan',
              Icons.assignment_ind_outlined,
              '/operations/admin-tasks',
            ),
            _MenuTile(
              'Jadwal dan penugasan',
              'Atur penyerahan serta relawan',
              Icons.event_outlined,
              '/operations/schedule',
            ),
            _MenuTile(
              'Tinjau donasi',
              'Pengajuan baru dan permintaan perbaikan',
              Icons.fact_check_outlined,
              '/operations/reviews',
            ),
            _MenuTile(
              'Verifikasi lembaga',
              'Periksa organisasi yang mendaftar',
              Icons.verified_outlined,
              '/operations/organizations',
            ),
            _MenuTile(
              'Hak akses pengguna',
              'Kelola izin relawan, mitra dan admin',
              Icons.admin_panel_settings_outlined,
              '/operations/users',
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.title, this.subtitle, this.icon, this.route);
  final String title, subtitle, route;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: PkCard(
      onTap: () => context.push(route),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).extension<PkTokens>()!.accentStrong,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class VolunteerTasksScreen extends StatelessWidget {
  const VolunteerTasksScreen({super.key});
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Tugas relawan',
    permission: 'relawan',
    child: OperationsList(
      resource: 'tasks',
      emptyMessage: 'Belum ada tugas yang ditugaskan kepadamu.',
      itemBuilder: (task) => PkCard(
        onTap: () => context.push('/operations/tasks/${task['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskLabel(task['kind'] as String?),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${task['tracking_code'] ?? 'Kiriman'} · ${task['point_name'] ?? 'Titik layanan'}',
            ),
            if (task['scheduled_at'] != null) ...[
              const SizedBox(height: 8),
              Text(_date(task['scheduled_at'])),
            ],
            const SizedBox(height: 12),
            OperationStatus(task['status'] as String),
          ],
        ),
      ),
    ),
  );
}

class VolunteerTaskDetailScreen extends StatelessWidget {
  const VolunteerTaskDetailScreen({required this.taskId, super.key});
  final String taskId;
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Detail tugas',
    permission: 'relawan',
    child: OperationsData(
      resource: 'task:$taskId',
      builder: (tasks) {
        final found = tasks.where((row) => row['id'] == taskId).firstOrNull;
        if (found == null) {
          return const OperationsMessage(
            message: 'Tugas tidak ditemukan atau sudah tidak dapat diakses.',
          );
        }
        final status = found['status'];

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskLabel(found['kind'] as String?),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  OperationStatus(status as String),
                  const SizedBox(height: 12),
                  Text(
                    '${found['tracking_code'] ?? 'Kiriman'}\n${found['point_name'] ?? ''}',
                  ),
                  if (found['scheduled_at'] != null)
                    Text(_date(found['scheduled_at'])),
                  if (found['notes'] != null) ...[
                    const SizedBox(height: 12),
                    Text(found['notes'] as String),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (['accepted', 'in_progress'].contains(status) &&
                found['donation_id'] != null)
              OperationsData(
                resource: 'contact:${found['donation_id']}',
                builder: (rows) => PkCard(
                  child: Text(
                    rows.isEmpty
                        ? 'Tidak ada kontak penjemputan.'
                        : '${rows.first['contact_name'] ?? ''}\n${rows.first['phone'] ?? ''}\n${rows.first['address'] ?? ''}',
                  ),
                ),
              )
            else
              const PkCard(
                child: Text(
                  'Kontak penjemputan tersedia ketika tugas aktif dan akses diizinkan.',
                ),
              ),
            const SizedBox(height: 24),
            if (status == 'accepted') ...[
              OperationButton(
                action: 'startTask',
                label: 'Mulai tugas',
                values: () => {'id': taskId},
              ),
              const SizedBox(height: 12),
            ],
            if (status == 'in_progress') ...[
              OperationButton(
                action: 'failTask',
                label: 'Laporkan tugas gagal',
                secondary: true,
                values: () => {'id': taskId},
              ),
              const SizedBox(height: 12),
            ],
            if (status == 'assigned') ...[
              OperationButton(
                action: 'accept',
                label: 'Terima tugas',
                values: () => {'id': taskId},
              ),
              const SizedBox(height: 12),
              OperationButton(
                action: 'decline',
                label: 'Tolak tugas',
                secondary: true,
                values: () => {'id': taskId},
              ),
            ],
            if (['accepted', 'in_progress'].contains(status) &&
                found['donation_id'] != null)
              OperationsData(
                resource: 'donation:${found['donation_id']}',
                builder: (rows) {
                  if (rows.isEmpty) {
                    return const Text('Detail donasi belum tersedia.');
                  }
                  final donation = rows.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (status == 'in_progress' &&
                          ((found['kind'] == 'pickup' &&
                                  [
                                    'received',
                                    'curated',
                                  ].contains(donation['status'])) ||
                              (found['kind'] == 'curation' &&
                                  donation['status'] == 'curated'))) ...[
                        OperationButton(
                          action: 'finishTask',
                          label: 'Selesaikan tugas',
                          values: () => {'id': taskId},
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (donation['status'] == 'scheduled')
                        OperationButton(
                          action: 'receive',
                          label: 'Catat pakaian diterima',
                          values: () => {'id': donation['id']},
                        ),
                      if (donation['status'] == 'received') ...[
                        const Text(
                          'Pakaian telah diterima. Catat pemeriksaan setiap item.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => context.push(
                            '/operations/curation/${donation['id']}',
                          ),
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Mulai kurasi fisik'),
                        ),
                      ],
                      if (donation['status'] == 'curated')
                        const Text('Pakaian ini sudah selesai dikurasi.'),
                    ],
                  );
                },
              ),
          ],
        );
      },
    ),
  );
}

class PhysicalCurationScreen extends StatelessWidget {
  const PhysicalCurationScreen({required this.donationId, super.key});
  final String donationId;
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Kurasi fisik',
    permission: 'relawan',
    child: OperationsData(
      resource: 'donation:$donationId',
      builder: (rows) {
        if (rows.isEmpty) {
          return const OperationsMessage(message: 'Donasi tidak ditemukan.');
        }
        final donation = rows.first;
        final items = donation['donation_items'] as List? ?? [];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              donation['tracking_code'] as String? ?? 'Pemeriksaan pakaian',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Periksa kebersihan, keutuhan dan kondisi fisik setiap item.',
            ),
            const SizedBox(height: 24),
            if (donation['status'] != 'received' &&
                donation['status'] != 'curated')
              const PkCard(
                child: Text(
                  'Pakaian perlu dicatat diterima sebelum bisa dikurasi.',
                ),
              )
            else
              for (final item in items) ...[
                if ((item['inspections'] is Map ||
                    (item['inspections'] is List &&
                        (item['inspections'] as List).isNotEmpty)))
                  PkCard(
                    child: Text(
                      '${item['category']} · ${item['size_code']} — sudah diperiksa',
                    ),
                  )
                else
                  QuantityReviewForm(
                    key: ValueKey(item['id']),
                    id: item['id'] as String,
                    total: (item['quantity'] as num).toInt(),
                    title: '${item['category']} · ${item['size_code']}',
                    receipt: false,
                  ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    ),
  );
}

class PartnerStockScreen extends ConsumerStatefulWidget {
  const PartnerStockScreen({super.key});
  @override
  ConsumerState<PartnerStockScreen> createState() => _PartnerStockScreenState();
}

class _PartnerStockScreenState extends ConsumerState<PartnerStockScreen> {
  String? _point;
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Stok lembaga',
    permission: 'mitra',
    child: OperationsData(
      resource: 'points',
      builder: (points) {
        if (points.isEmpty) {
          return const OperationsMessage(
            message:
                'Belum ada titik layanan pada lembaga yang dapat kamu kelola.',
          );
        }
        final selected = points.any((p) => p['id'] == _point)
            ? _point!
            : points.first['id'] as String;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: DropdownButtonFormField<String>(
                key: ValueKey(selected),
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Titik layanan'),
                items: [
                  for (final point in points)
                    DropdownMenuItem(
                      value: point['id'] as String,
                      child: Text(point['name'] as String),
                    ),
                ],
                onChanged: (value) => setState(() => _point = value),
              ),
            ),
            Expanded(
              child: OperationsList(
                resource: 'inventory:$selected',
                emptyMessage: 'Belum ada stok lolos kurasi di titik ini.',
                itemBuilder: (batch) => PkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${batch['category']} · ${batch['size_code']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${batch['age_group']} · ${batch['available_qty']} tersedia',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${batch['on_hand_qty']} di posko · ${batch['reserved_qty']} direservasi',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class PartnerShipmentsScreen extends StatelessWidget {
  const PartnerShipmentsScreen({super.key});
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Daftar kiriman',
    child: OperationsList(
      resource: 'shipments',
      emptyMessage: 'Belum ada kiriman yang dapat diakses.',
      itemBuilder: (shipment) => PkCard(
        onTap: () => context.push('/operations/shipments/${shipment['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kiriman ${_short(shipment['id'])}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            OperationStatus(shipment['status'] as String),
            const SizedBox(height: 8),
            Text('${_shipmentQuantity(shipment)} potong pakaian'),
          ],
        ),
      ),
    ),
  );
}

class ShipmentDetailScreen extends StatelessWidget {
  const ShipmentDetailScreen({required this.shipmentId, super.key});
  final String shipmentId;
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Detail kiriman',
    child: OperationsData(
      resource: 'shipment:$shipmentId',
      builder: (shipments) {
        final shipment = shipments
            .where((s) => s['id'] == shipmentId)
            .firstOrNull;
        if (shipment == null) {
          return const OperationsMessage(message: 'Kiriman tidak ditemukan.');
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kiriman ${_short(shipmentId)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  OperationStatus(shipment['status'] as String),
                  const SizedBox(height: 16),
                  Text('${_shipmentQuantity(shipment)} potong pakaian'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (shipment['status'] == 'ready' &&
                shipment['can_dispatch'] == true)
              OperationButton(
                action: 'dispatch',
                label: 'Catat keberangkatan kiriman',
                values: () => {'id': shipmentId},
              ),
            if (shipment['status'] == 'in_transit' &&
                shipment['can_receive'] == true)
              QuantityReviewForm(
                id: shipmentId,
                total: _shipmentQuantity(shipment),
                title: 'Hasil penerimaan',
                receipt: true,
              ),
            if (shipment['status'] == 'received' ||
                shipment['status'] == 'disputed')
              const PkCard(
                child: Text(
                  'Hasil penerimaan sudah tercatat. Hubungi admin jika diperlukan tindak lanjut.',
                ),
              ),
          ],
        );
      },
    ),
  );
}

class QuantityReviewForm extends StatefulWidget {
  const QuantityReviewForm({
    required this.id,
    required this.total,
    required this.title,
    required this.receipt,
    super.key,
  });
  final String id, title;
  final int total;
  final bool receipt;
  @override
  State<QuantityReviewForm> createState() => _QuantityReviewFormState();
}

class _QuantityReviewFormState extends State<QuantityReviewForm> {
  final _form = GlobalKey<FormState>();
  final _good = TextEditingController(text: '0'),
      _bad = TextEditingController(text: '0'),
      _missing = TextEditingController(text: '0'),
      _reason = TextEditingController();
  String? _error;
  @override
  void dispose() {
    for (final c in [_good, _bad, _missing, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  int _value(TextEditingController c) => int.tryParse(c.text) ?? -1;
  bool _validate() {
    if (!_form.currentState!.validate()) return false;
    final count =
        _value(_good) + _value(_bad) + (widget.receipt ? _value(_missing) : 0);
    final valid = count == widget.total;
    setState(
      () => _error = valid
          ? null
          : 'Total hasil harus ${widget.total} potong; saat ini $count.',
    );
    return valid;
  }

  Widget _quantity(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (value) {
        final n = int.tryParse(value ?? '');
        return n == null || n < 0 || n > widget.total
            ? 'Isi angka 0 sampai ${widget.total}.'
            : null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => PkCard(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('${widget.total} potong harus diperiksa'),
          const SizedBox(height: 24),
          _quantity(widget.receipt ? 'Diterima baik' : 'Lolos kurasi', _good),
          _quantity(widget.receipt ? 'Ditolak / rusak' : 'Tidak lolos', _bad),
          if (widget.receipt) _quantity('Tidak diterima', _missing),
          if (!widget.receipt)
            TextFormField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan / catatan',
              ),
              maxLines: 3,
              validator: (value) =>
                  _value(_bad) > 0 && (value ?? '').trim().isEmpty
                  ? 'Alasan wajib untuk pakaian tidak lolos.'
                  : null,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          OperationButton(
            action: widget.receipt ? 'receipt' : 'inspect',
            label: widget.receipt ? 'Simpan penerimaan' : 'Simpan hasil kurasi',
            validate: _validate,
            values: () => {
              'id': widget.id,
              'good': _value(_good),
              'bad': _value(_bad),
              'missing': _value(_missing),
              'reason': _reason.text.trim(),
            },
          ),
        ],
      ),
    ),
  );
}

class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Tinjau pengajuan',
    permission: 'admin',
    child: OperationsList(
      resource: 'queue',
      emptyMessage: 'Semua pengajuan sudah ditinjau.',
      itemBuilder: (row) =>
          _DonationReviewCard(key: ValueKey(row['id']), donation: row),
    ),
  );
}

class _DonationReviewCard extends StatelessWidget {
  const _DonationReviewCard({required this.donation, super.key});
  final OpsRow donation;
  @override
  Widget build(BuildContext context) => PkCard(
    onTap: () => context.push('/operations/reviews/${donation['id']}'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          donation['tracking_code'] as String? ?? 'Pengajuan pakaian',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        OperationStatus(donation['status'] as String),
        const SizedBox(height: 16),
        const Text(
          'Buka untuk meninjau, menentukan jadwal, dan menugaskan relawan.',
        ),
        const SizedBox(height: 8),
        const Icon(Icons.arrow_forward),
      ],
    ),
  );
}

class AdminOrganizationsScreen extends StatelessWidget {
  const AdminOrganizationsScreen({super.key});
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Verifikasi lembaga',
    permission: 'admin',
    child: OperationsList(
      resource: 'organizations',
      emptyMessage: 'Tidak ada lembaga yang menunggu verifikasi.',
      itemBuilder: (row) => PkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              row['name'] as String,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(row['area'] as String? ?? 'Wilayah belum diisi'),
            const SizedBox(height: 16),
            OperationButton(
              action: 'verify',
              label: 'Setujui lembaga',
              values: () => {'id': row['id'], 'decision': 'approve'},
            ),
            const SizedBox(height: 12),
            OperationButton(
              action: 'verify',
              label: 'Tolak pendaftaran',
              secondary: true,
              values: () => {'id': row['id'], 'decision': 'reject'},
            ),
          ],
        ),
      ),
    ),
  );
}

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});
  @override
  Widget build(BuildContext context) => OperationsPage(
    title: 'Hak akses pengguna',
    permission: 'admin',
    child: OperationsList(
      resource: 'users',
      emptyMessage: 'Belum ada pengguna yang dapat dimuat.',
      itemBuilder: (user) {
        final roles = [
          for (final r in user['user_roles'] as List? ?? []) r['role'],
        ];
        return PkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                (user['display_name'] as String?)?.isNotEmpty == true
                    ? user['display_name'] as String
                    : 'Pengguna',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(user['area'] as String? ?? 'Wilayah belum diisi'),
              for (final role in ['relawan', 'mitra', 'admin']) ...[
                const SizedBox(height: 16),
                OperationButton(
                  action: 'role',
                  secondary: true,
                  label:
                      '${roles.contains(role) ? 'Cabut' : 'Berikan'} izin $role',
                  values: () => {
                    'id': user['id'],
                    'role': role,
                    'grant': !roles.contains(role),
                  },
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

int _shipmentQuantity(OpsRow shipment) =>
    (shipment['shipment_items'] as List? ?? []).fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as num).toInt(),
    );
String _short(dynamic id) {
  final s = id.toString();
  return s.length > 8 ? s.substring(0, 8).toUpperCase() : s;
}

String _date(dynamic raw) {
  final date = DateTime.tryParse(raw.toString())?.toLocal();
  if (date == null) return 'Jadwal belum ditentukan';
  return '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
