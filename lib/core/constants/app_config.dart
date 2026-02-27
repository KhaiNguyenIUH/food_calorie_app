class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://example.com',
  );

  static const bool useMockApi = bool.fromEnvironment('USE_MOCK_API', defaultValue: true);

  static const String defaultVisionDetail = 'low';
  static const String appProxySecret = String.fromEnvironment('APP_PROXY_SECRET', defaultValue: '');
  static const int maxImageSize = 800;
  static const int jpegQuality = 85;

  static const int defaultTargetCalories = 2353;
  static const int defaultTargetProtein = 150;
  static const int defaultTargetCarbs = 200;
  static const int defaultTargetFats = 70;

  static const String devJwt = String.fromEnvironment('DEV_JWT', defaultValue: '');
}
