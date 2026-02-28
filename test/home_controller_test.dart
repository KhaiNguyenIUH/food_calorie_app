import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:food_calorie_app/core/constants/hive_boxes.dart';
import 'package:food_calorie_app/core/utils/date_utils.dart';
import 'package:food_calorie_app/data/models/daily_summary.dart';
import 'package:food_calorie_app/data/models/meal_log.dart';
import 'package:food_calorie_app/data/models/user_profile.dart';
import 'package:food_calorie_app/data/repositories/daily_summary_repository.dart';
import 'package:food_calorie_app/data/repositories/meal_log_repository.dart';
import 'package:food_calorie_app/data/repositories/privacy_repository.dart';
import 'package:food_calorie_app/data/repositories/user_profile_repository.dart';
import 'package:food_calorie_app/domain/services/storage_cleanup_service.dart';
import 'package:food_calorie_app/presentation/home/home_controller.dart';

class _FakePrivacyRepository implements PrivacyRepository {
  @override
  bool get hasPrivacyConsent => true;

  @override
  Future<void> setPrivacyConsent(bool value) async {}
}

class _FakeMealLogRepository implements MealLogRepository {
  final List<MealLog> _items = [];
  final List<String> deletedIds = [];

  @override
  Future<void> addMeal(MealLog meal) async {
    _items.add(meal);
  }

  @override
  Future<void> deleteAll() async {
    _items.clear();
  }

  @override
  Future<void> deleteMeal(String id) async {
    deletedIds.add(id);
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<MealLog>> getAllMeals() async {
    return List<MealLog>.from(_items);
  }

  @override
  Future<List<MealLog>> getMealsForDate(DateTime date) async {
    final key = dateKey(date);
    return _items.where((meal) => dateKey(meal.timestamp) == key).toList();
  }
}

class _TrackingDailySummaryRepository implements DailySummaryRepository {
  MealLog? removedMeal;

  @override
  Future<void> clearAll() async {}

  @override
  Future<DailySummary> getSummary(DateTime date) async {
    return DailySummary.empty(dateKey(date));
  }

  @override
  Future<void> rebuildRecentCache({int days = 14}) async {}

  @override
  Future<void> updateForMealChange({MealLog? added, MealLog? removed}) async {
    removedMeal = removed;
  }

  @override
  Future<void> upsert(DailySummary summary) async {}
}

class _TrackingStorageCleanupService extends StorageCleanupService {
  final List<MealLog> deletedImageMeals = [];

  @override
  Future<void> deleteImagesForMeals(List<MealLog> meals) async {
    deletedImageMeals.addAll(meals);
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('home_controller_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(UserProfileAdapter.typeIdValue)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    await Hive.openBox<UserProfile>(HiveBoxes.userProfile);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test(
    'deleteMealEntry deletes meal, updates summary, and deletes image',
    () async {
      final mealRepository = _FakeMealLogRepository();
      final summaryRepository = _TrackingDailySummaryRepository();
      final storageCleanupService = _TrackingStorageCleanupService();
      final userProfileRepository = UserProfileRepository(
        box: Hive.box<UserProfile>(HiveBoxes.userProfile),
      );
      final meal = MealLog(
        id: 'meal-1',
        name: 'Noodles',
        calories: 300,
        protein: 14,
        carbs: 45,
        fats: 7,
        timestamp: DateTime(2026, 3, 1, 7, 30),
        imagePath: '/tmp/scan_1.jpg',
        healthScore: 6,
        warnings: const ['Estimated values'],
      );
      await mealRepository.addMeal(meal);

      final controller = HomeController(
        mealLogRepository: mealRepository,
        dailySummaryRepository: summaryRepository,
        userProfileRepository: userProfileRepository,
        privacyRepository: _FakePrivacyRepository(),
        storageCleanupService: storageCleanupService,
      );

      await controller.loadForDate(meal.timestamp);
      expect(controller.meals.length, 1);

      await controller.deleteMealEntry(meal);

      expect(mealRepository.deletedIds, ['meal-1']);
      expect(summaryRepository.removedMeal?.id, 'meal-1');
      expect(storageCleanupService.deletedImageMeals.length, 1);
      expect(
        storageCleanupService.deletedImageMeals.first.imagePath,
        '/tmp/scan_1.jpg',
      );
      expect(controller.meals, isEmpty);
    },
  );
}
