import 'dart:math';
import 'package:hive/hive.dart';
import '../../core/constants/app_config.dart';
import '../../core/constants/hive_boxes.dart';
import '../../core/utils/date_utils.dart';
import '../models/daily_summary.dart';
import '../models/meal_log.dart';
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
  })  : _box = box ?? Hive.box<DailySummary>(HiveBoxes.dailySummary),
        _mealLogRepository = mealLogRepository;

  final Box<DailySummary> _box;
  final MealLogRepository _mealLogRepository;

  @override
  Future<DailySummary> getSummary(DateTime date) async {
    final key = dateKey(date);
    return _box.get(key) ?? DailySummary.empty(key);
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
    final current = _box.get(key) ?? DailySummary.empty(key);

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
      final summary = _summaryFromMeals(date, meals);
      await upsert(summary);
    }
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }

  DailySummary _summaryFromMeals(DateTime date, List<MealLog> meals) {
    final key = dateKey(date);
    final calories = meals.fold<int>(0, (sum, m) => sum + m.calories);
    final protein = meals.fold<int>(0, (sum, m) => sum + m.protein);
    final carbs = meals.fold<int>(0, (sum, m) => sum + m.carbs);
    final fats = meals.fold<int>(0, (sum, m) => sum + m.fats);

    return DailySummary(
      dateKey: key,
      targetCalories: AppConfig.defaultTargetCalories,
      consumedCalories: calories,
      proteinGram: protein,
      carbsGram: carbs,
      fatsGram: fats,
    );
  }
}
