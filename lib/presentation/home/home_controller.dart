import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/daily_summary.dart';
import '../../data/models/meal_log.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/daily_summary_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/repositories/meal_log_repository.dart';
import '../../data/repositories/privacy_repository.dart';
import '../../domain/services/storage_cleanup_service.dart';
import '../shared/widgets/privacy_sheet.dart';

class HomeController extends GetxController {
  HomeController({
    required MealLogRepository mealLogRepository,
    required DailySummaryRepository dailySummaryRepository,
    required UserProfileRepository userProfileRepository,
    required PrivacyRepository privacyRepository,
    required StorageCleanupService storageCleanupService,
    this.needsCacheRebuild = false,
  })  : _mealLogRepository = mealLogRepository,
        _dailySummaryRepository = dailySummaryRepository,
        _userProfileRepository = userProfileRepository,
        _settingsRepository = privacyRepository,
        _storageCleanupService = storageCleanupService;

  final MealLogRepository _mealLogRepository;
  final DailySummaryRepository _dailySummaryRepository;
  final UserProfileRepository _userProfileRepository;
  final PrivacyRepository _settingsRepository;
  final StorageCleanupService _storageCleanupService;

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<MealLog> meals = <MealLog>[].obs;
  final Rx<DailySummary> summary = DailySummary.empty(dateKey(DateTime.now())).obs;
  final Rxn<UserProfile> profile = Rxn<UserProfile>();
  final RxBool isLoading = false.obs;

  final bool needsCacheRebuild;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    isLoading.value = true;
    profile.value = await _userProfileRepository.getProfile();
    if (profile.value == null) {
      isLoading.value = false;
      return;
    }
    if (needsCacheRebuild) {
      await _dailySummaryRepository.rebuildRecentCache(days: 14);
    }

    await _storageCleanupService.cleanupOldImages();
    await loadForDate(selectedDate.value);
    isLoading.value = false;
  }

  Future<void> applyProfile(UserProfile newProfile) async {
    profile.value = newProfile;
    await _dailySummaryRepository.rebuildRecentCache(days: 14);
    await loadForDate(selectedDate.value);
  }

  Future<void> loadForDate(DateTime date) async {
    selectedDate.value = date;
    meals.value = await _mealLogRepository.getMealsForDate(date);
    summary.value = await _dailySummaryRepository.getSummary(date);
  }

  List<DateTime> get weekDatesList => weekDates(selectedDate.value);

  String formatDayLabel(DateTime date) => DateFormat('E').format(date).substring(0, 1);

  String formatDateNumber(DateTime date) => DateFormat('dd').format(date);

  int get remainingCalories {
    final target = profile.value?.targetCalories ?? summary.value.targetCalories;
    return (target - summary.value.consumedCalories).clamp(0, target).toInt();
  }

  int get remainingProtein {
    final target = profile.value?.targetProteinG ?? AppConfig.defaultTargetProtein;
    return (target - summary.value.proteinGram).clamp(0, target).toInt();
  }

  int get remainingCarbs {
    final target = profile.value?.targetCarbsG ?? AppConfig.defaultTargetCarbs;
    return (target - summary.value.carbsGram).clamp(0, target).toInt();
  }

  int get remainingFats {
    final target = profile.value?.targetFatsG ?? AppConfig.defaultTargetFats;
    return (target - summary.value.fatsGram).clamp(0, target).toInt();
  }

  int get targetCalories => profile.value?.targetCalories ?? summary.value.targetCalories;

  int get targetProtein => profile.value?.targetProteinG ?? AppConfig.defaultTargetProtein;
  int get targetCarbs => profile.value?.targetCarbsG ?? AppConfig.defaultTargetCarbs;
  int get targetFats => profile.value?.targetFatsG ?? AppConfig.defaultTargetFats;

  double get calorieProgress {
    if (targetCalories == 0) {
      return 0;
    }
    return (summary.value.consumedCalories / targetCalories).clamp(0, 1).toDouble();
  }

  void openPrivacySheet() {
    Get.bottomSheet(
      PrivacySheet(
        hasConsent: _settingsRepository.hasPrivacyConsent,
        onDeleteAll: deleteAllScanData,
        onAcceptConsent: () async {
          await _settingsRepository.setPrivacyConsent(true);
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> deleteAllScanData() async {
    final allMeals = await _mealLogRepository.getAllMeals();
    await _mealLogRepository.deleteAll();
    await _dailySummaryRepository.clearAll();
    await _storageCleanupService.deleteImagesForMeals(allMeals);
    await loadForDate(selectedDate.value);
    Get.snackbar('Deleted', 'All scan data has been removed.');
  }

  Future<void> deleteMealEntry(MealLog meal) async {
    await _mealLogRepository.deleteMeal(meal.id);
    await _dailySummaryRepository.updateForMealChange(removed: meal);
    await _storageCleanupService.deleteImagesForMeals([meal]);
    await loadForDate(selectedDate.value);
  }

}
