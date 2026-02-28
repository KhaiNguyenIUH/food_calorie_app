class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: false,
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String defaultVisionDetail = 'low';
  static const int maxImageSize = 800;
  static const int jpegQuality = 85;

  static const int defaultTargetCalories = 2353;
  static const int defaultTargetProtein = 150;
  static const int defaultTargetCarbs = 200;
  static const int defaultTargetFats = 70;
}
