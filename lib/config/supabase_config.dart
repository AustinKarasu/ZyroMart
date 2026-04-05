class SupabaseConfig {
  // These should be set via environment variables or a .env file in production.
  // For development, they can be overridden here.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uhlfphrtmaxffchivsip.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}
