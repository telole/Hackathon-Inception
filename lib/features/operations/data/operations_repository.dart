import 'package:supabase_flutter/supabase_flutter.dart';

typedef OpsRow = Map<String, dynamic>;

class OperationsAccess {
  const OperationsAccess({
    this.roles = const [],
    this.organizations = const [],
  });
  final List<String> roles;
  final List<String> organizations;
  bool get isAdmin => roles.contains('admin');
  bool allows(String role) => isAdmin || roles.contains(role);
  factory OperationsAccess.fromMap(OpsRow data) => OperationsAccess(
    roles: List<String>.from(data['roles'] as List? ?? const []),
    organizations: [
      for (final row in data['memberships'] as List? ?? const [])
        if (row['active'] == true && row['verified'] == true)
          row['organization_id'] as String,
    ],
  );
}

abstract interface class OperationsRepository {
  Future<OperationsAccess> access();
  Future<List<OpsRow>> load(String resource);
  Future<void> act(String action, OpsRow input, String requestKey);
}

class SupabaseOperationsRepository implements OperationsRepository {
  SupabaseOperationsRepository(this.client);
  final SupabaseClient? client;
  SupabaseClient get db =>
      client ?? (throw StateError('Backend belum dikonfigurasi.'));
  List<OpsRow> _rows(dynamic result) => [
    for (final row in result as List) Map<String, dynamic>.from(row as Map),
  ];

  @override
  Future<OperationsAccess> access() async {
    if (db.auth.currentUser == null) return const OperationsAccess();
    final result = Map<String, dynamic>.from(await db.rpc('my_access') as Map);
    final memberships = await db
        .from('organization_members')
        .select(
          'organization_id, active, organizations!inner(verified, active)',
        )
        .eq('user_id', db.auth.currentUser!.id)
        .eq('active', true);
    result['memberships'] = [
      for (final m in memberships)
        {
          'organization_id': m['organization_id'],
          'active': m['active'],
          'verified':
              m['organizations']['verified'] == true &&
              m['organizations']['active'] == true,
        },
    ];
    return OperationsAccess.fromMap(result);
  }

  @override
  Future<List<OpsRow>> load(String resource) async {
    var offset = 0;
    int? pageLimit;
    if (resource.startsWith('page:')) {
      final parts = resource.split(':');
      offset = int.parse(parts[1]);
      pageLimit = int.parse(parts[2]);
      resource = parts.skip(3).join(':');
    }
    if (resource == 'notifications') {
      final user = db.auth.currentUser;
      if (user == null) return [];
      return _rows(
        await db
            .from('notifications')
            .select('id, title, body, route, read_at, created_at')
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .order('id')
            .range(offset, offset + (pageLimit ?? 26) - 1),
      );
    }
    if (resource == 'myRoleRequests') {
      return _rows(
        await db
            .from('role_requests')
            .select()
            .eq('user_id', db.auth.currentUser!.id)
            .order('created_at', ascending: false)
            .order('id')
            .range(offset, offset + (pageLimit ?? 26) - 1),
      );
    }
    if (resource == 'myOrganizationApplications') {
      return _rows(
        await db
            .from('organization_applications')
            .select()
            .eq('applicant_id', db.auth.currentUser!.id)
            .order('created_at', ascending: false)
            .order('id')
            .range(offset, offset + (pageLimit ?? 26) - 1),
      );
    }
    if (resource == 'pendingVolunteers' || resource == 'pendingOrganizations') {
      final table = resource == 'pendingVolunteers'
          ? 'role_requests'
          : 'organization_applications';
      return _rows(
        await db
            .from(table)
            .select()
            .eq('status', 'pending')
            .order('created_at')
            .order('id')
            .range(offset, offset + (pageLimit ?? 26) - 1),
      );
    }
    if (resource.startsWith('registration:')) {
      final parts = resource.split(':');
      final table = parts[1] == 'volunteer'
          ? 'role_requests'
          : 'organization_applications';
      return _rows(await db.from(table).select().eq('id', parts[2]));
    }
    if (resource == 'myOrganizations') {
      final accessInfo = await access();
      if (!accessInfo.isAdmin && accessInfo.organizations.isEmpty) return [];
      var q = db
          .from('organizations')
          .select(
            'id, name, kind, area, organization_members(user_id, active, member_role)',
          );
      if (!accessInfo.isAdmin) q = q.inFilter('id', accessInfo.organizations);
      return _rows(
        await q
            .order('name')
            .order('id')
            .range(offset, offset + (pageLimit ?? 100) - 1),
      );
    }
    if (resource.startsWith('members:')) {
      return _rows(
        await db.rpc(
          'list_organization_members',
          params: {
            'p_org': resource.substring(8),
            'p_offset': offset,
            'p_limit': pageLimit ?? 26,
          },
        ),
      );
    }
    if (resource.startsWith('organizationPoints:')) {
      return _rows(
        await db
            .from('collection_points')
            .select(
              'id, organization_id, name, public_address, opening_hours, active',
            )
            .eq('organization_id', resource.substring(19))
            .order('name')
            .order('id')
            .range(offset, offset + (pageLimit ?? 100) - 1),
      );
    }
    if (resource == 'myDonations') {
      return _rows(
        await db
            .from('donations')
            .select('id, tracking_code, method, status, created_at')
            .eq('donor_id', db.auth.currentUser!.id)
            .order('created_at', ascending: false)
            .order('id')
            .range(offset, offset + (pageLimit ?? 26) - 1),
      );
    }

    if (resource.startsWith('point:')) {
      return _rows(
        await db
            .from('collection_points')
            .select(
              'id, organization_id, name, public_address, opening_hours, active',
            )
            .eq('id', resource.substring(6)),
      );
    }
    if (resource.startsWith('task:')) {
      final rows = _rows(
        await db
            .from('logistics_tasks')
            .select(
              'id, donation_id, point_id, kind, status, scheduled_at, notes, donations(tracking_code), collection_points(name)',
            )
            .eq('id', resource.substring(5))
            .eq('assigned_to', db.auth.currentUser!.id),
      );
      return [
        for (final row in rows)
          {
            ...row,
            'tracking_code': (row['donations'] as Map?)?['tracking_code'],
            'point_name': (row['collection_points'] as Map?)?['name'],
          },
      ];
    }
    if (resource.startsWith('adminTask:')) {
      return _rows(
        await db
            .from('logistics_tasks')
            .select(
              'id, donation_id, point_id, assigned_to, kind, status, scheduled_at, notes, profiles!logistics_tasks_assigned_to_fkey(display_name), donations(tracking_code)',
            )
            .eq('id', resource.substring(10)),
      );
    }
    if (resource == 'tasks') {
      final user = db.auth.currentUser;
      if (user == null) throw StateError('Silakan masuk kembali.');
      final rows = _rows(
        await db
            .from('logistics_tasks')
            .select(
              'id, donation_id, point_id, kind, status, scheduled_at, notes, donations(tracking_code), collection_points(name)',
            )
            .eq('assigned_to', user.id)
            .order('created_at', ascending: false)
            .order('id')
            .range(offset, offset + (pageLimit ?? 100) - 1),
      );
      return [
        for (final row in rows)
          {
            ...row,
            'tracking_code': (row['donations'] as Map?)?['tracking_code'],
            'point_name': (row['collection_points'] as Map?)?['name'],
          },
      ];
    }
    if (resource == 'points') {
      final context = await access();
      if (!context.isAdmin && context.organizations.isEmpty) return [];
      var query = db
          .from('collection_points')
          .select('id, name, organization_id')
          .eq('active', true);
      if (!context.isAdmin) {
        query = query.inFilter('organization_id', context.organizations);
      }
      return _rows(
        await query
            .order('name')
            .order('id')
            .range(offset, offset + (pageLimit ?? 100) - 1),
      );
    }
    if (resource.startsWith('inventory:')) {
      final rows = _rows(
        await db
            .from('inventory_batches')
            .select(
              'id, point_id, category, size_code, age_group, on_hand_qty, reserved_qty',
            )
            .eq('point_id', resource.substring(10))
            .order('id')
            .range(offset, offset + (pageLimit ?? 100) - 1),
      );
      return [
        for (final row in rows)
          {
            ...row,
            'available_qty':
                (row['on_hand_qty'] as int) - (row['reserved_qty'] as int),
          },
      ];
    }
    if (resource.startsWith('contact:')) {
      final value = await db.rpc(
        'get_donation_contact',
        params: {'p_id': resource.substring(8)},
      );
      return value == null ? [] : [Map<String, dynamic>.from(value as Map)];
    }
    if (resource == 'scheduleQueue') {
      return _rows(
        await db
            .from('donations')
            .select(
              'id, tracking_code, point_id, method, status, scheduled_at, donation_items(quantity), logistics_tasks(id, assigned_to, kind, status)',
            )
            .inFilter('status', ['submitted', 'scheduled', 'received'])
            .order('created_at')
            .order('id')
            .range(offset, offset + (pageLimit ?? 100) - 1),
      );
    }
    if (resource == 'volunteers') {
      return _rows(await db.rpc('list_assignable_volunteers'));
    }
    if (resource == 'allocations') {
      return _rows(
        await db
            .from('allocations')
            .select(
              'id, batch_id, need_item_id, quantity, status, shipment_items(shipment_id)',
            )
            .eq('status', 'reserved')
            .order('created_at', ascending: false)
            .order('id')
            .range(offset, offset + (pageLimit ?? 100) - 1),
      );
    }
    if (resource == 'needLines') {
      return _rows(
        await db
            .from('need_items')
            .select(
              'id, category, size_code, age_group, requested_qty, needs!inner(title, status, deadline_at)',
            )
            .eq('needs.status', 'open')
            .gt('needs.deadline_at', DateTime.now().toUtc().toIso8601String())
            .order('id')
            .range(offset, offset + (pageLimit ?? 100) - 1),
      );
    }
    if (resource.startsWith('donation:')) {
      return _rows(
        await db
            .from('donations')
            .select(
              'id, tracking_code, status, point_id, method, scheduled_at, donation_items(id, category, size_code, quantity, inspections(id))',
            )
            .eq('id', resource.substring(9)),
      );
    }
    if (resource.startsWith('review:')) {
      final row = await db
          .from('donations')
          .select(
            'id, tracking_code, point_id, method, status, scheduled_at, clean_check, intact_check, not_torn_check, donation_items(id, category, size_code, quantity), donation_events(event_type, summary, created_at), donation_photos(storage_path)',
          )
          .eq('id', resource.substring(7))
          .single();
      final photos = <String>[];
      for (final photo in row['donation_photos'] as List) {
        photos.add(
          await db.storage
              .from('donation-photos')
              .createSignedUrl(photo['storage_path'] as String, 300),
        );
      }
      return [
        {...row, 'photo_urls': photos},
      ];
    }
    if (resource == 'adminTasks') {
      return _rows(
        await db
            .from('logistics_tasks')
            .select(
              'id, donation_id, point_id, assigned_to, kind, status, scheduled_at, notes, profiles!logistics_tasks_assigned_to_fkey(display_name), donations(tracking_code)',
            )
            .order('created_at', ascending: false)
            .order('id')
            .range(offset, offset + (pageLimit ?? 100) - 1),
      );
    }
    if (resource == 'queue') {
      return _rows(
        await db
            .from('donations')
            .select(
              'id, tracking_code, status, created_at, donation_items(quantity)',
            )
            .eq('status', 'submitted')
            .order('created_at')
            .order('id')
            .range(offset, offset + (pageLimit ?? 50) - 1),
      );
    }
    if (resource == 'organizations') {
      return _rows(
        await db
            .from('organizations')
            .select('id, name, kind, area, verified, active')
            .eq('verified', false)
            .eq('active', true)
            .order('name')
            .range(offset, offset + (pageLimit ?? 50) - 1),
      );
    }
    if (resource == 'users') {
      return _rows(
        await db
            .from('profiles')
            .select(
              'id, display_name, area, user_roles!user_roles_user_id_fkey(role)',
            )
            .order('display_name')
            .order('id')
            .range(offset, offset + (pageLimit ?? 50) - 1),
      );
    }
    if (resource == 'shipments' || resource.startsWith('shipment:')) {
      final context = await access();
      var q = db
          .from('shipments')
          .select(
            'id, status, assigned_to, source_point_id, destination_point_id, source:collection_points!shipments_source_point_id_fkey(organization_id), destination:collection_points!shipments_destination_point_id_fkey(organization_id), shipment_items(quantity, received_good, rejected, missing)',
          );
      if (resource.startsWith('shipment:')) {
        q = q.eq('id', resource.substring(9));
      }
      final rows = _rows(
        await q
            .order('created_at', ascending: false)
            .order('id')
            .range(offset, offset + (pageLimit ?? 50) - 1),
      );
      return [
        for (final row in rows)
          {
            ...row,
            'can_dispatch':
                context.isAdmin ||
                context.organizations.contains(
                  (row['source'] as Map?)?['organization_id'],
                ) ||
                row['assigned_to'] == db.auth.currentUser?.id,
            'can_receive':
                context.isAdmin ||
                context.organizations.contains(
                  (row['destination'] as Map?)?['organization_id'],
                ),
          },
      ];
    }
    throw ArgumentError('Data operasional tidak dikenal.');
  }

  @override
  Future<void> act(String action, OpsRow input, String requestKey) async {
    if (action == 'verify') {
      if (!(await access()).isAdmin) {
        throw StateError('Akses admin diperlukan.');
      }
      final approved = input['decision'] == 'approve';
      await db
          .from('organizations')
          .update({'verified': approved, 'active': approved})
          .eq('id', input['id'] as String)
          .eq('verified', false)
          .select('id')
          .single();
      return;
    }
    final (rpc, params) = switch (action) {
      'reviewRegistration' => (
        'review_registration',
        {
          'p_type': input['type'],
          'p_id': input['id'],
          'p_approve': input['approve'],
          'p_reason': input['reason'],
        },
      ),
      'accept' || 'decline' => (
        'respond_task',
        {
          'p_id': input['id'],
          'p_status': action == 'accept' ? 'accepted' : 'declined',
        },
      ),
      'receive' => (
        'advance_donation',
        {'p_id': input['id'], 'p_status': 'received'},
      ),
      'inspect' => (
        'record_inspection',
        {
          'p_item': input['id'],
          'p_passed': input['good'],
          'p_rejected': input['bad'],
          'p_reason': input['reason'],
        },
      ),
      'startTask' || 'finishTask' || 'failTask' => (
        'respond_task',
        {
          'p_id': input['id'],
          'p_status': action == 'startTask'
              ? 'in_progress'
              : action == 'finishTask'
              ? 'completed'
              : 'failed',
        },
      ),
      'dispatch' => ('dispatch_shipment', {'p_id': input['id']}),
      'receipt' => (
        'confirm_receipt',
        {
          'p_id': input['id'],
          'p_good': input['good'],
          'p_rejected': input['bad'],
          'p_missing': input['missing'],
        },
      ),
      'revise' => (
        'request_donation_revision',
        {'p_id': input['id'], 'p_note': input['reason'], 'p_key': requestKey},
      ),
      'cancel' => ('cancel_donation', {'p_id': input['id']}),
      'schedule' => (
        'schedule_donation',
        {'p_id': input['id'], 'p_at': input['at']},
      ),
      'assign' => (
        'assign_logistics_task',
        {
          'p_id': input['task_id'],
          'p_donation': input['id'],
          'p_point': input['point_id'],
          'p_volunteer': input['volunteer'],
          'p_kind': input['kind'],
          'p_at': input['at'],
          'p_notes': input['notes'],
        },
      ),
      'reserve' => (
        'reserve_allocation',
        {
          'p_batch': input['batch'],
          'p_need_item': input['need_item'],
          'p_qty': input['quantity'],
          'p_key': requestKey,
        },
      ),
      'createShipment' => (
        'create_shipment',
        {
          'p_allocation': input['allocation'],
          'p_volunteer': input['volunteer'],
        },
      ),
      'role' => (
        'admin_set_role',
        {
          'p_user': input['id'],
          'p_role': input['role'],
          'p_grant': input['grant'],
        },
      ),
      _ => throw ArgumentError('Tindakan tidak dikenal.'),
    };
    await db.rpc(rpc, params: params);
  }
}
