import 'package:flutter/material.dart';

enum DonationCategory {
  children('anak', 'Anak', Icons.child_care_rounded),
  adults('dewasa', 'Dewasa', Icons.checkroom_rounded),
  batikFormal('batik-formal', 'Batik & formal', Icons.style_rounded),
  schoolUniform('seragam-sekolah', 'Seragam sekolah', Icons.school_rounded);

  const DonationCategory(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

@immutable
class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.partner,
    required this.location,
    this.distanceKm,
    this.bannerUrl,
    required this.category,
    required this.story,
    required this.requestedItems,
    this.receivedItems,
    required this.icon,
  });

  final String id;
  final String title;
  final String partner;
  final String location;
  final double? distanceKm;
  final String? bannerUrl;
  final DonationCategory category;
  final String story;
  final int requestedItems;
  final int? receivedItems;
  final IconData icon;

  double? get progress => requestedItems <= 0 || receivedItems == null
      ? null
      : (receivedItems! / requestedItems).clamp(0.0, 1.0);
}

@immutable
class ImpactStats {
  const ImpactStats({
    required this.receivedItems,
    required this.submittedDonations,
    required this.curatedDonations,
  });

  final int receivedItems;
  final int submittedDonations;
  final int curatedDonations;
}

@immutable
class HomeSnapshot {
  const HomeSnapshot({
    required this.displayName,
    required this.impact,
    required this.campaigns,
  });

  final String displayName;
  final ImpactStats impact;
  final List<Campaign> campaigns;
}
