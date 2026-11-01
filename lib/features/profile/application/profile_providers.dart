import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_client_provider.dart';

final profileDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final uid =
      ref.watch(authUserProvider).value?.id ?? client?.auth.currentUser?.id;
  if (uid == null || client == null) return {};
  return await client
      .from('profiles')
      .select('id, display_name, area')
      .eq('id', uid)
      .single();
});
