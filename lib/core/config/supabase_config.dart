class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tiekssrrvsyossageoiu.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpZWtzc3JydnN5b3NzYWdlb2l1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0MTY2MTIsImV4cCI6MjEwODk5MjYxMn0.i0Pw_gY-rDR7QSR1pusDsKdT7fLPi9GsczNR16d54T4',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
