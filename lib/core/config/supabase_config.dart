class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = 'https://dpqxefmwjfvoysacwgef.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcXhlZm13amZ2b3lzYWN3Z2VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyOTkxMTgsImV4cCI6MjA4NTg3NTExOH0.xzNidmrcNsUhpsTFcaaL_lXtHcx_MWzQHCPF7kY5i90';

  static const String instagramAuthFunction =
      '$supabaseUrl/functions/v1/instagram-auth';
  static const String sendNotificationsFunction =
      '$supabaseUrl/functions/v1/send-notifications';
  static const String instagramRedirectUri = 'pulzapp://instagram-callback';
}
