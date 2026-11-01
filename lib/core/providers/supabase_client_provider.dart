import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

final authUserProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return Stream.value(null);

  return Stream<User?>.multi((controller) {
    controller.add(client.auth.currentUser);
    final subscription = client.auth.onAuthStateChange.listen(
      (state) => controller.add(state.session?.user),
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });
});
