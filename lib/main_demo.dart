import 'features/operations/application/operations_providers.dart';
import 'features/operations/data/demo_operations_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/supabase_client_provider.dart';
import 'features/donation/application/donation_providers.dart';
import 'features/donation/data/donation_repository.dart';
import 'features/home/application/home_providers.dart';
import 'features/home/data/home_repository.dart';
import 'main.dart' show PakaiankitaApp;

/// Explicit, offline demonstration. No Supabase credentials or transactions.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        operationsRepositoryProvider.overrideWithValue(
          DemoOperationsRepository(),
        ),
        supabaseClientProvider.overrideWithValue(null),
        homeRepositoryProvider.overrideWithValue(
          const InMemoryHomeRepository(),
        ),
        donationRepositoryProvider.overrideWithValue(
          InMemoryDonationRepository.instance,
        ),
      ],
      child: const PakaiankitaApp(demoMode: true),
    ),
  );
}
