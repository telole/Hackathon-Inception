import 'package:flutter/material.dart';

import 'dart:typed_data';

import '../../home/application/home_models.dart';

enum ClothingSize {
  xs('XS', 'Ekstra kecil'),
  s('S', 'Kecil'),
  m('M', 'Sedang'),
  l('L', 'Besar'),
  xl('XL', 'Ekstra besar'),
  allSize('All size', 'Ukuran bebas');

  const ClothingSize(this.label, this.description);

  final String label;
  final String description;
}

enum ClothingType {
  tops('kaos', 'Kaos / atasan', Icons.checkroom_outlined),
  shirt('kemeja', 'Kemeja', Icons.dry_cleaning_outlined),
  pants('celana', 'Celana', Icons.checkroom_rounded),
  batik('batik', 'Batik / formal', Icons.style_rounded),
  uniform('seragam', 'Seragam sekolah', Icons.school_outlined);

  const ClothingType(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;
}

enum DeliveryMethod {
  pickup(
    'Jemput di rumah',
    'Kurir datang sesuai jadwalmu',
    Icons.home_outlined,
  ),
  dropOff(
    'Antar ke titik donasi',
    'Pilih lokasi yang paling dekat',
    Icons.location_on_outlined,
  );

  const DeliveryMethod(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

@immutable
class DonationPoint {
  const DonationPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    this.distanceKm,
    required this.openingHours,
    required this.icon,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final String area;
  final double? distanceKm;
  final String openingHours;
  final IconData icon;
  final double? latitude;
  final double? longitude;
}

@immutable
class DonationRecord {
  const DonationRecord({
    required this.id,
    this.backendId,
    this.trackingCode,
    required this.category,
    this.clothingType,
    required this.size,
    required this.quantity,
    this.acceptedQuantity = 0,
    required this.deliveryMethod,
    required this.createdAt,
    this.status = 'submitted',
    this.events = const [],
    this.donorName,
    this.pickupAddress,
    this.donationPoint,
    this.preferredNeedId,
  });

  final String id;
  final String? backendId;
  final String? trackingCode;
  final DonationCategory category;
  final ClothingType? clothingType;
  final ClothingSize size;
  final int quantity;
  final int acceptedQuantity;
  final DeliveryMethod deliveryMethod;
  final DateTime createdAt;
  final String status;
  final List<DonationEvent> events;
  final String? donorName;
  final String? pickupAddress;
  final DonationPoint? donationPoint;
  final String? preferredNeedId;

  String get statusLabel => switch (status) {
    'draft' => 'Draf',
    'submitted' => 'Diajukan',
    'needs_revision' => 'Perlu revisi',
    'scheduled' => 'Terjadwal',
    'received' => 'Diterima di titik',
    'curated' => 'Selesai dikurasi',
    'cancelled' => 'Dibatalkan',
    _ => status,
  };
}

@immutable
class DonationEvent {
  const DonationEvent({
    required this.eventType,
    required this.summary,
    required this.createdAt,
  });

  final String eventType;
  final String summary;
  final DateTime createdAt;
}

@immutable
class PickedDonationPhoto {
  const PickedDonationPhoto({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
