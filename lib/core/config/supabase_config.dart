class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dpqxefmwjfvoysacwgef.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String instagramAuthFunction =
      '$supabaseUrl/functions/v1/instagram-auth';
  static const String sendNotificationsFunction =
      '$supabaseUrl/functions/v1/send-notifications';
  static const String instagramRedirectUri = 'pulzapp://instagram-callback';
}
