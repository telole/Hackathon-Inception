import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../home/application/home_models.dart';
import '../application/donation_models.dart';

abstract interface class DonationRepository {
  Future<List<DonationRecord>> fetchDonations();
  Future<List<DonationPoint>> fetchDonationPoints();

  Future<DonationRecord> saveDonation({
    required String draftId,
    required DonationCategory category,
    required ClothingType clothingType,
    required ClothingSize size,
    required int quantity,
    required DeliveryMethod deliveryMethod,
    required Uint8List photoBytes,
    required bool cleanCheck,
    required bool intactCheck,
    required bool notTornCheck,
    required String? pickupAddress,
    required String? contactName,
    required String? phone,
    required DonationPoint donationPoint,
    String? preferredNeedId,
  });
}

class SupabaseDonationRepository implements DonationRepository {
  SupabaseDonationRepository(this._client);

  static const _photoBucket = 'donation-photos';

  final SupabaseClient _client;
  final Map<String, _PendingPhoto> _pendingPhotos = {};

  @override
  Future<List<DonationPoint>> fetchDonationPoints() async {
    final response = await _client
        .from('collection_points')
        .select('''
          id, name, public_address, latitude, longitude, opening_hours,
          organizations!inner(verified, active)
        ''')
        .eq('active', true)
        .eq('organizations.verified', true)
        .eq('organizations.active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(response)
        .map(_pointFromMap)
        .toList(growable: false);
  }

  @override
  Future<List<DonationRecord>> fetchDonations() async {
    final user = _requireUser();
    final response = await _client
        .from('donations')
        .select('''
          id, tracking_code, point_id, preferred_need_id, method, status,
          clean_check, intact_check, not_torn_check, scheduled_at, created_at,
          donation_items(id, category, size_code, age_group, quantity, inspections(passed_qty)),
          donation_events(id, event_type, summary, created_at),
          collection_points(id, name, public_address, opening_hours, latitude, longitude)
        ''')
        .eq('donor_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map(_recordFromMap)
        .toList(growable: false);
  }

  @override
  Future<DonationRecord> saveDonation({
    required String draftId,
    required DonationCategory category,
    required ClothingType clothingType,
    required ClothingSize size,
    required int quantity,
    required DeliveryMethod deliveryMethod,
    required Uint8List photoBytes,
    required bool cleanCheck,
    required bool intactCheck,
    required bool notTornCheck,
    required String? pickupAddress,
    required String? contactName,
    required String? phone,
    required DonationPoint donationPoint,
    String? preferredNeedId,
  }) async {
    final user = _requireUser();
    _validateDonation(
      quantity: quantity,
      photoBytes: photoBytes,
      cleanCheck: cleanCheck,
      intactCheck: intactCheck,
      notTornCheck: notTornCheck,
      deliveryMethod: deliveryMethod,
      pickupAddress: pickupAddress,
      contactName: contactName,
      phone: phone,
    );

    final draft = await _ensureDraft(
      draftId: draftId,
      userId: user.id,
      pointId: donationPoint.id,
      deliveryMethod: deliveryMethod,
      preferredNeedId: preferredNeedId,
    );

    if (draft['status'] == 'submitted') {
      return _fetchDonationById(draftId);
    }
    if (draft['status'] != 'draft') {
      throw StateError('Draf donasi ini tidak lagi dapat dikirim.');
    }

    await _saveItem(
      donationId: draftId,
      category: clothingType.apiValue,
      sizeCode: _sizeCode(size),
      ageGroup: _ageGroup(category),
      quantity: quantity,
    );

    await _client
        .from('donations')
        .update({
          'clean_check': cleanCheck,
          'intact_check': intactCheck,
          'not_torn_check': notTornCheck,
        })
        .eq('id', draftId)
        .eq('donor_id', user.id)
        .eq('status', 'draft')
        .select('id')
        .single();

    if (deliveryMethod == DeliveryMethod.pickup) {
      await _client.rpc(
        'save_donation_contact',
        params: {
          'p_id': draftId,
          'p_address': pickupAddress!.trim(),
          'p_name': contactName!.trim(),
          'p_phone': phone!.trim(),
        },
      );
    }

    await _uploadAndRegisterPhoto(
      donationId: draftId,
      userId: user.id,
      bytes: photoBytes,
    );
    await _client.rpc('submit_donation', params: {'p_id': draftId});
    return _fetchDonationById(draftId);
  }

  Future<Map<String, dynamic>> _ensureDraft({
    required String draftId,
    required String userId,
    required String pointId,
    required DeliveryMethod deliveryMethod,
    String? preferredNeedId,
  }) async {
    try {
      return await _client
          .from('donations')
          .insert({
            'id': draftId,
            'donor_id': userId,
            'point_id': pointId,
            'preferred_need_id': preferredNeedId,
            'method': deliveryMethod == DeliveryMethod.pickup
                ? 'pickup'
                : 'dropoff',
            'status': 'draft',
          })
          .select('id, tracking_code, status')
          .single();
    } catch (error, stackTrace) {
      final existing = await _client
          .from('donations')
          .select('id, tracking_code, status')
          .eq('id', draftId)
          .eq('donor_id', userId)
          .maybeSingle();
      if (existing == null) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      return existing;
    }
  }

  Future<void> _saveItem({
    required String donationId,
    required String category,
    required String sizeCode,
    required String ageGroup,
    required int quantity,
  }) async {
    final existing = await _client
        .from('donation_items')
        .select('id')
        .eq('donation_id', donationId)
        .maybeSingle();
    final values = {
      'category': category,
      'size_code': sizeCode,
      'age_group': ageGroup,
      'quantity': quantity,
    };

    if (existing == null) {
      await _client.from('donation_items').insert({
        'donation_id': donationId,
        ...values,
      });
    } else {
      await _client
          .from('donation_items')
          .update(values)
          .eq('id', existing['id'] as String)
          .eq('donation_id', donationId);
    }
  }

  Future<void> _uploadAndRegisterPhoto({
    required String donationId,
    required String userId,
    required Uint8List bytes,
  }) async {
    final alreadyRegistered = await _client
        .from('donation_photos')
        .select('id')
        .eq('donation_id', donationId)
        .maybeSingle();
    if (alreadyRegistered != null) return;

    final pending = _pendingPhotos.putIfAbsent(
      donationId,
      () => _PendingPhoto.create(
        userId: userId,
        donationId: donationId,
        bytes: bytes,
      ),
    );
    final folder = '$userId/$donationId';
    final objects = await _client.storage.from(_photoBucket).list(path: folder);
    final objectExists = objects.any(
      (object) => object.name == pending.fileName,
    );
    if (!objectExists) {
      await _client.storage
          .from(_photoBucket)
          .uploadBinary(
            pending.storagePath,
            pending.bytes,
            fileOptions: FileOptions(
              contentType: pending.mimeType,
              upsert: false,
            ),
          );
    }

    final existingPending = await _client
        .from('donation_photos')
        .select('id, donation_id, storage_path')
        .eq('id', pending.id)
        .maybeSingle();
    if (existingPending == null) {
      await _client.from('donation_photos').insert({
        'id': pending.id,
        'donation_id': donationId,
        'storage_path': pending.storagePath,
      });
    } else if (existingPending['donation_id'] != donationId ||
        existingPending['storage_path'] != pending.storagePath) {
      throw StateError('Identitas foto donasi tidak cocok.');
    }
    _pendingPhotos.remove(donationId);
  }

  Future<DonationRecord> _fetchDonationById(String donationId) async {
    final response = await _client
        .from('donations')
        .select('''
          id, tracking_code, point_id, preferred_need_id, method, status,
          clean_check, intact_check, not_torn_check, scheduled_at, created_at,
          donation_items(id, category, size_code, age_group, quantity, inspections(passed_qty)),
          donation_events(id, event_type, summary, created_at),
          collection_points(id, name, public_address, opening_hours, latitude, longitude)
        ''')
        .eq('id', donationId)
        .single();
    return _recordFromMap(response);
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Silakan masuk terlebih dahulu.');
    }
    return user;
  }

  DonationRecord _recordFromMap(Map<String, dynamic> map) {
    final rawItems = map['donation_items'] as List<dynamic>? ?? const [];
    final firstItem = rawItems.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(rawItems.first as Map);
    final quantity = rawItems.fold<int>(
      0,
      (sum, item) => sum + (((item as Map)['quantity'] as num?)?.toInt() ?? 0),
    );
    final acceptedQuantity = rawItems.fold<int>(0, (sum, item) {
      final rawInspections = (item as Map)['inspections'];
      final inspections = rawInspections is List
          ? rawInspections
          : rawInspections is Map
          ? [rawInspections]
          : const [];
      return sum +
          inspections.fold<int>(
            0,
            (total, inspection) =>
                total +
                (((inspection as Map)['passed_qty'] as num?)?.toInt() ?? 0),
          );
    });
    final rawEvents = map['donation_events'] as List<dynamic>? ?? const [];
    final events =
        rawEvents
            .map((event) {
              final item = Map<String, dynamic>.from(event as Map);
              return DonationEvent(
                eventType: item['event_type'] as String? ?? '',
                summary: item['summary'] as String? ?? '',
                createdAt:
                    DateTime.tryParse(item['created_at'] as String? ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0),
              );
            })
            .toList(growable: false)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final rawPoint = map['collection_points'];
    final point = rawPoint is Map
        ? _pointFromMap(Map<String, dynamic>.from(rawPoint))
        : null;
    final trackingCode = map['tracking_code'] as String? ?? map['id'] as String;
    final userName = _client.auth.currentUser?.userMetadata?['display_name'];

    return DonationRecord(
      id: trackingCode,
      backendId: map['id'] as String,
      trackingCode: trackingCode,
      category: _donationCategory(
        firstItem['category'] as String? ?? '',
        firstItem['age_group'] as String? ?? '',
      ),
      clothingType: _clothingType(firstItem['category'] as String? ?? ''),
      size: _clothingSize(firstItem['size_code'] as String? ?? ''),
      quantity: quantity,
      acceptedQuantity: acceptedQuantity,
      deliveryMethod: map['method'] == 'pickup'
          ? DeliveryMethod.pickup
          : DeliveryMethod.dropOff,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: map['status'] as String? ?? 'draft',
      events: events,
      donorName: userName is String && userName.isNotEmpty ? userName : null,
      donationPoint: point,
      preferredNeedId: map['preferred_need_id'] as String?,
    );
  }

  DonationPoint _pointFromMap(Map<String, dynamic> map) {
    return DonationPoint(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Titik donasi',
      address: map['public_address'] as String? ?? '',
      area: '',
      distanceKm: null,
      openingHours:
          map['opening_hours'] as String? ?? 'Jam operasional belum diatur',
      icon: Icons.location_on_outlined,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  String _sizeCode(ClothingSize size) =>
      size == ClothingSize.allSize ? 'ALL' : size.label;

  String _ageGroup(DonationCategory category) => switch (category) {
    DonationCategory.children => 'anak',
    DonationCategory.schoolUniform => 'remaja',
    DonationCategory.adults || DonationCategory.batikFormal => 'dewasa',
  };

  DonationCategory _donationCategory(String category, String ageGroup) {
    final normalizedCategory = category.toLowerCase();
    final normalizedAgeGroup = ageGroup.toLowerCase();
    if (normalizedCategory.contains('seragam')) {
      return DonationCategory.schoolUniform;
    }
    if (normalizedCategory.contains('batik') ||
        normalizedCategory.contains('formal')) {
      return DonationCategory.batikFormal;
    }
    if (normalizedAgeGroup == 'anak') return DonationCategory.children;
    return DonationCategory.adults;
  }

  ClothingType? _clothingType(String category) {
    for (final type in ClothingType.values) {
      if (type.apiValue == category.toLowerCase()) return type;
    }
    return null;
  }

  ClothingSize _clothingSize(String sizeCode) {
    if (sizeCode.toLowerCase() == 'all') return ClothingSize.allSize;
    for (final size in ClothingSize.values) {
      if (size.label.toLowerCase() == sizeCode.toLowerCase()) return size;
    }
    return ClothingSize.m;
  }

  void _validateDonation({
    required int quantity,
    required Uint8List photoBytes,
    required bool cleanCheck,
    required bool intactCheck,
    required bool notTornCheck,
    required DeliveryMethod deliveryMethod,
    required String? pickupAddress,
    required String? contactName,
    required String? phone,
  }) {
    if (quantity < 1 || quantity > 99) {
      throw ArgumentError.value(quantity, 'quantity', 'Jumlah harus 1–99.');
    }
    if (!cleanCheck || !intactCheck || !notTornCheck) {
      throw ArgumentError('Checklist pakaian layak pakai harus lengkap.');
    }
    _PendingPhoto.validateMime(photoBytes);
    if (deliveryMethod == DeliveryMethod.pickup &&
        (pickupAddress == null ||
            pickupAddress.trim().isEmpty ||
            contactName == null ||
            contactName.trim().isEmpty ||
            phone == null ||
            phone.trim().isEmpty)) {
      throw ArgumentError('Kontak penjemputan belum lengkap.');
    }
  }
}

class InMemoryDonationRepository implements DonationRepository {
  InMemoryDonationRepository._();

  static final instance = InMemoryDonationRepository._();

  final List<DonationRecord> _donations = [];

  static const _points = [
    DonationPoint(
      id: 'rumah-sandang-dago',
      name: 'Rumah Sandang Dago',
      address: 'Jl. Ir. H. Juanda No. 87',
      area: 'Coblong, Bandung',
      distanceKm: 1.8,
      openingHours: 'Setiap hari · 09.00–17.00',
      icon: Icons.storefront_outlined,
    ),
    DonationPoint(
      id: 'bank-pakaian-sukajadi',
      name: 'Bank Pakaian Sukajadi',
      address: 'Jl. Sukajadi No. 142',
      area: 'Sukajadi, Bandung',
      distanceKm: 4.6,
      openingHours: 'Senin–Sabtu · 09.00–16.00',
      icon: Icons.volunteer_activism_outlined,
    ),
    DonationPoint(
      id: 'pos-peduli-cicendo',
      name: 'Pos Peduli Cicendo',
      address: 'Jl. Pajajaran No. 31',
      area: 'Cicendo, Bandung',
      distanceKm: 8.3,
      openingHours: 'Setiap hari · 08.00–18.00',
      icon: Icons.location_city_outlined,
    ),
  ];

  List<DonationRecord> get donations => List.unmodifiable(_donations);

  @override
  Future<List<DonationRecord>> fetchDonations() async =>
      List.unmodifiable(_donations);

  @override
  Future<List<DonationPoint>> fetchDonationPoints() async =>
      List.unmodifiable(_points);

  @override
  Future<DonationRecord> saveDonation({
    required String draftId,
    required DonationCategory category,
    required ClothingType clothingType,
    required ClothingSize size,
    required int quantity,
    required DeliveryMethod deliveryMethod,
    required Uint8List photoBytes,
    required bool cleanCheck,
    required bool intactCheck,
    required bool notTornCheck,
    required String? pickupAddress,
    required String? contactName,
    required String? phone,
    required DonationPoint donationPoint,
    String? preferredNeedId,
  }) async {
    if (quantity < 1 ||
        photoBytes.isEmpty ||
        !cleanCheck ||
        !intactCheck ||
        !notTornCheck) {
      throw ArgumentError('Lengkapi foto, jumlah, dan checklist kelayakan.');
    }
    if (deliveryMethod == DeliveryMethod.pickup &&
        (pickupAddress == null ||
            pickupAddress.trim().isEmpty ||
            contactName == null ||
            contactName.trim().isEmpty ||
            phone == null ||
            phone.trim().isEmpty)) {
      throw ArgumentError('Kontak penjemputan belum lengkap.');
    }

    final record = DonationRecord(
      id: 'PK-${DateTime.now().microsecondsSinceEpoch}',
      trackingCode: 'PK-${DateTime.now().microsecondsSinceEpoch}',
      backendId: draftId,
      category: category,
      clothingType: clothingType,
      size: size,
      quantity: quantity,
      deliveryMethod: deliveryMethod,
      createdAt: DateTime.now(),
      status: 'submitted',
      donorName: contactName != null && contactName.trim().isNotEmpty
          ? contactName.trim()
          : 'Nadia Putri',
      pickupAddress: deliveryMethod == DeliveryMethod.pickup
          ? pickupAddress!.trim()
          : null,
      donationPoint: donationPoint,
      preferredNeedId: preferredNeedId,
      events: [
        DonationEvent(
          eventType: 'submitted',
          summary: 'Donasi diajukan',
          createdAt: DateTime.now(),
        ),
      ],
    );
    _donations.insert(0, record);
    return record;
  }
}

class _PendingPhoto {
  const _PendingPhoto({
    required this.id,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String id;
  final String storagePath;
  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  factory _PendingPhoto.create({
    required String userId,
    required String donationId,
    required Uint8List bytes,
  }) {
    final mime = validateMime(bytes);
    final extension = switch (mime) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw ArgumentError('Format foto tidak didukung.'),
    };
    final id = const Uuid().v4();
    final fileName = '$id.$extension';
    return _PendingPhoto(
      id: id,
      storagePath: '$userId/$donationId/$fileName',
      fileName: fileName,
      mimeType: mime,
      bytes: bytes,
    );
  }

  static String validateMime(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > 1048576) {
      throw ArgumentError('Ukuran foto harus 1 byte–1 MB.');
    }
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return 'image/jpeg';
    }
    const png = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length >= 8 &&
        List.generate(
          8,
          (index) => bytes[index] == png[index],
        ).every((x) => x)) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    throw ArgumentError('Pilih foto berformat JPEG, PNG, atau WebP.');
  }
}
