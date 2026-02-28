import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../data/repositories/daily_summary_repository.dart';
import '../../data/repositories/meal_log_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/privacy_repository.dart';
import '../../domain/services/image_processing_service.dart';
import '../../domain/services/image_storage_service.dart';
import '../../domain/services/nutrition_service.dart';
import '../../domain/services/storage_cleanup_service.dart';
import '../../domain/services/token_provider.dart';
import '../../presentation/home/home_controller.dart';
import '../../presentation/onboarding/onboarding_controller.dart';
import '../../presentation/scanner/scanner_controller.dart';

class InitialBinding extends Bindings {
  InitialBinding({required this.needsCacheRebuild});

  final bool needsCacheRebuild;

  @override
  void dependencies() {
    Get.put<MealLogRepository>(HiveMealLogRepository());
    Get.put(UserProfileRepository());
    Get.put<DailySummaryRepository>(
      HiveDailySummaryRepository(
        mealLogRepository: Get.find(),
        userProfileRepository: Get.find(),
      ),
    );
    Get.put<PrivacyRepository>(SettingsRepository());
    Get.put(StorageCleanupService());
    Get.put(ImageProcessingService());
    Get.put(ImageStorageService());
    Get.put<TokenProvider>(SupabaseTokenProvider());
    Get.put(ApiClient());
    Get.put(
      NutritionService(
        apiClient: Get.find<ApiClient>(),
        tokenProvider: Get.find<TokenProvider>(),
      ),
    );

    Get.put(
      HomeController(
        mealLogRepository: Get.find(),
        dailySummaryRepository: Get.find(),
        userProfileRepository: Get.find(),
        privacyRepository: Get.find(),
        storageCleanupService: Get.find(),
        needsCacheRebuild: needsCacheRebuild,
      ),
    );

    Get.lazyPut(
      () => OnboardingController(
        userProfileRepository: Get.find(),
        dailySummaryRepository: Get.find(),
      ),
    );

    Get.lazyPut(
      () => ScannerController(
        nutritionService: Get.find(),
        imageProcessingService: Get.find(),
        imageStorageService: Get.find(),
        mealLogRepository: Get.find(),
        dailySummaryRepository: Get.find(),
        privacyRepository: Get.find(),
      ),
      fenix: true,
    );
  }
}
