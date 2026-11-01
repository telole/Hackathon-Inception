import 'package:flutter/material.dart';

import '../../../core/theme/pk_tokens.dart';
import '../../donation/application/donation_models.dart';

/// Presentation only: never invent a server status for partial rejection.
class DonationStatusBadge extends StatelessWidget {
  const DonationStatusBadge({required this.donation, super.key});
  final DonationRecord donation;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PkTokens>()!;
    final (color, icon) = switch (donation.status) {
      'cancelled' => (const Color(0xFFB3261E), Icons.close_rounded),
      'curated' => (tokens.accentStrong, Icons.check_rounded),
      'draft' => (tokens.mutedText, Icons.edit_outlined),
      _ => (const Color(0xFF895900), Icons.schedule_rounded),
    };
    return Semantics(
      label: 'Status donasi: ${donation.statusLabel}',
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              donation.statusLabel,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
