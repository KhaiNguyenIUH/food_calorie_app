import 'dart:math';
import 'package:hive/hive.dart';
import '../../core/constants/app_config.dart';
import '../../core/constants/hive_boxes.dart';
import '../../core/utils/date_utils.dart';
import '../models/daily_summary.dart';
import '../models/meal_log.dart';
import 'user_profile_repository.dart';
import 'meal_log_repository.dart';

abstract class DailySummaryRepository {
  Future<DailySummary> getSummary(DateTime date);
  Future<void> upsert(DailySummary summary);
  Future<void> updateForMealChange({MealLog? added, MealLog? removed});
  Future<void> rebuildRecentCache({int days = 14});
  Future<void> clearAll();
}

class HiveDailySummaryRepository implements DailySummaryRepository {
  HiveDailySummaryRepository({
    Box<DailySummary>? box,
    required MealLogRepository mealLogRepository,
    required UserProfileRepository userProfileRepository,
  })  : _box = box ?? Hive.box<DailySummary>(HiveBoxes.dailySummary),
        _mealLogRepository = mealLogRepository,
        _userProfileRepository = userProfileRepository;

  final Box<DailySummary> _box;
  final MealLogRepository _mealLogRepository;
  final UserProfileRepository _userProfileRepository;

  @override
  Future<DailySummary> getSummary(DateTime date) async {
    final key = dateKey(date);
    return _box.get(key) ?? await _defaultSummary(key);
  }

  @override
  Future<void> upsert(DailySummary summary) async {
    await _box.put(summary.dateKey, summary);
  }

  @override
  Future<void> updateForMealChange({MealLog? added, MealLog? removed}) async {
    final meal = added ?? removed;
    if (meal == null) {
      return;
    }

    final key = dateKey(meal.timestamp);
    final current = _box.get(key) ?? await _defaultSummary(key);

    final deltaCalories = (added?.calories ?? 0) - (removed?.calories ?? 0);
    final deltaProtein = (added?.protein ?? 0) - (removed?.protein ?? 0);
    final deltaCarbs = (added?.carbs ?? 0) - (removed?.carbs ?? 0);
    final deltaFats = (added?.fats ?? 0) - (removed?.fats ?? 0);

    final updated = current.copyWith(
      consumedCalories: max(0, current.consumedCalories + deltaCalories),
      proteinGram: max(0, current.proteinGram + deltaProtein),
      carbsGram: max(0, current.carbsGram + deltaCarbs),
      fatsGram: max(0, current.fatsGram + deltaFats),
    );

    await upsert(updated);
  }

  @override
  Future<void> rebuildRecentCache({int days = 14}) async {
    final now = DateTime.now();
    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final meals = await _mealLogRepository.getMealsForDate(date);
      final summary = await _summaryFromMeals(date, meals);
      await upsert(summary);
    }
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<DailySummary> _summaryFromMeals(DateTime date, List<MealLog> meals) async {
    final key = dateKey(date);
    final calories = meals.fold<int>(0, (sum, m) => sum + m.calories);
    final protein = meals.fold<int>(0, (sum, m) => sum + m.protein);
    final carbs = meals.fold<int>(0, (sum, m) => sum + m.carbs);
    final fats = meals.fold<int>(0, (sum, m) => sum + m.fats);

    final targetCalories = await _targetCalories();

    return DailySummary(
      dateKey: key,
      targetCalories: targetCalories,
      consumedCalories: calories,
      proteinGram: protein,
      carbsGram: carbs,
      fatsGram: fats,
    );
  }

  Future<DailySummary> _defaultSummary(String key) async {
    final targetCalories = await _targetCalories();
    return DailySummary(
      dateKey: key,
      targetCalories: targetCalories,
      consumedCalories: 0,
      proteinGram: 0,
      carbsGram: 0,
      fatsGram: 0,
    );
  }

  Future<int> _targetCalories() async {
    final profile = await _userProfileRepository.getProfile();
    return profile?.targetCalories ?? AppConfig.defaultTargetCalories;
  }
}

