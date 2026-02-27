import '../../core/constants/app_config.dart';
import '../../core/network/api_client.dart';
import '../../data/models/nutrition_result.dart';
import 'token_provider.dart';

class NutritionService {
  NutritionService({
    required ApiClient apiClient,
    required TokenProvider tokenProvider,
  })  : _apiClient = apiClient,
        _tokenProvider = tokenProvider;

  final ApiClient _apiClient;
  final TokenProvider _tokenProvider;

  Future<NutritionResult> analyzeImage({
    required String imageBase64,
    String? detail,
    required String timezone,
    required DateTime clientTimestamp,
  }) async {
    if (AppConfig.useMockApi) {
      return _mockResult(imageBase64);
    }

    final token = await _tokenProvider.getToken();
    final response = await _apiClient.postJson(
      '${AppConfig.apiBaseUrl}/api/vision/analyze',
      token: token,
      body: {
        'image_base64': imageBase64,
        'detail': detail ?? AppConfig.defaultVisionDetail,
        'client_timestamp': clientTimestamp.toIso8601String(),
        'timezone': timezone,
      },
      appSecret: AppConfig.appProxySecret,
    );

    return NutritionResult.fromJson(response);
  }

  NutritionResult _mockResult(String imageBase64) {
    final samples = <NutritionResult>[
      NutritionResult(
        name: 'Vanilla Ice Cream',
        calories: 210,
        protein: 5,
        carbs: 24,
        fats: 10,
        healthScore: 5,
        confidence: 0.62,
        warnings: const ['Estimated values'],
      ),
      NutritionResult(
        name: 'Pasta',
        calories: 560,
        protein: 18,
        carbs: 72,
        fats: 20,
        healthScore: 6,
        confidence: 0.71,
        warnings: const [],
      ),
      NutritionResult(
        name: 'Grilled Chicken Salad',
        calories: 350,
        protein: 32,
        carbs: 18,
        fats: 12,
        healthScore: 8,
        confidence: 0.78,
        warnings: const [],
      ),
    ];

    final index = imageBase64.isEmpty ? 0 : imageBase64.length % samples.length;
    return samples[index];
  }
}
