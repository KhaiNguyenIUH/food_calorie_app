import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/daily_summary.dart';
import '../../data/models/meal_log.dart';
import '../../data/repositories/daily_summary_repository.dart';
import '../../data/repositories/meal_log_repository.dart';
import '../../data/repositories/privacy_repository.dart';
import '../../domain/services/storage_cleanup_service.dart';
import '../shared/widgets/privacy_sheet.dart';

class HomeController extends GetxController {
  HomeController({
    required MealLogRepository mealLogRepository,
    required DailySummaryRepository dailySummaryRepository,
    required PrivacyRepository privacyRepository,
    required StorageCleanupService storageCleanupService,
    this.needsCacheRebuild = false,
  })  : _mealLogRepository = mealLogRepository,
        _dailySummaryRepository = dailySummaryRepository,
        _settingsRepository = privacyRepository,
        _storageCleanupService = storageCleanupService;

  final MealLogRepository _mealLogRepository;
  final DailySummaryRepository _dailySummaryRepository;
  final PrivacyRepository _settingsRepository;
  final StorageCleanupService _storageCleanupService;

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<MealLog> meals = <MealLog>[].obs;
  final Rx<DailySummary> summary = DailySummary.empty(dateKey(DateTime.now())).obs;
  final RxBool isLoading = false.obs;

  final bool needsCacheRebuild;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    isLoading.value = true;
    if (needsCacheRebuild) {
      await _dailySummaryRepository.rebuildRecentCache(days: 14);
    }

    await _seedDemoIfEmpty();
    await _storageCleanupService.cleanupOldImages();
    await loadForDate(selectedDate.value);
    isLoading.value = false;
  }

  Future<void> loadForDate(DateTime date) async {
    selectedDate.value = date;
    meals.value = await _mealLogRepository.getMealsForDate(date);
    summary.value = await _dailySummaryRepository.getSummary(date);
  }

  List<DateTime> get weekDatesList => weekDates(selectedDate.value);

  String formatDayLabel(DateTime date) => DateFormat('E').format(date).substring(0, 1);

  String formatDateNumber(DateTime date) => DateFormat('dd').format(date);

  int get remainingCalories =>
      (summary.value.targetCalories - summary.value.consumedCalories).clamp(0, summary.value.targetCalories).toInt();

  int get remainingProtein => (AppConfig.defaultTargetProtein - summary.value.proteinGram).clamp(0, AppConfig.defaultTargetProtein).toInt();

  int get remainingCarbs => (AppConfig.defaultTargetCarbs - summary.value.carbsGram).clamp(0, AppConfig.defaultTargetCarbs).toInt();

  int get remainingFats => (AppConfig.defaultTargetFats - summary.value.fatsGram).clamp(0, AppConfig.defaultTargetFats).toInt();

  double get calorieProgress {
    if (summary.value.targetCalories == 0) {
      return 0;
    }
    return (summary.value.consumedCalories / summary.value.targetCalories).clamp(0, 1).toDouble();
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

  Future<void> _seedDemoIfEmpty() async {
    final existing = await _mealLogRepository.getAllMeals();
    if (existing.isNotEmpty) {
      return;
    }

    final now = DateTime.now();
    final sampleMeals = [
      MealLog(
        id: 'sample-1',
        name: 'Noodles',
        calories: 45,
        protein: 15,
        carbs: 25,
        fats: 5,
        timestamp: now.subtract(const Duration(hours: 2)),
        imagePath: '',
      ),
      MealLog(
        id: 'sample-2',
        name: 'Salad',
        calories: 320,
        protein: 40,
        carbs: 20,
        fats: 15,
        timestamp: now.subtract(const Duration(hours: 6)),
        imagePath: '',
      ),
    ];

    for (final meal in sampleMeals) {
      await _mealLogRepository.addMeal(meal);
      await _dailySummaryRepository.updateForMealChange(added: meal);
    }
  }
}
