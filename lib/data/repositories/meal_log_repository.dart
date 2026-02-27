import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import '../../core/utils/date_utils.dart';
import '../models/meal_log.dart';

abstract class MealLogRepository {
  Future<List<MealLog>> getMealsForDate(DateTime date);
  Future<List<MealLog>> getAllMeals();
  Future<void> addMeal(MealLog meal);
  Future<void> deleteMeal(String id);
  Future<void> deleteAll();
}

class HiveMealLogRepository implements MealLogRepository {
  HiveMealLogRepository({Box<MealLog>? box})
      : _box = box ?? Hive.box<MealLog>(HiveBoxes.mealLogs);

  final Box<MealLog> _box;

  @override
  Future<List<MealLog>> getMealsForDate(DateTime date) async {
    final key = dateKey(date);
    return _box.values
        .where((meal) => dateKey(meal.timestamp) == key)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<MealLog>> getAllMeals() async {
    return _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> addMeal(MealLog meal) async {
    await _box.put(meal.id, meal);
  }

  @override
  Future<void> deleteMeal(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteAll() async {
    await _box.clear();
  }
}
