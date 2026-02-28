import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:food_calorie_app/core/constants/hive_boxes.dart';
import 'package:food_calorie_app/presentation/home/home_controller.dart';
import 'package:food_calorie_app/presentation/home/home_screen.dart';
import 'package:food_calorie_app/presentation/shared/widgets/activity_card.dart';
import 'package:food_calorie_app/presentation/shared/widgets/macro_card.dart';
import 'package:food_calorie_app/core/constants/app_config.dart';
import 'package:food_calorie_app/data/models/daily_summary.dart';
import 'package:food_calorie_app/data/models/meal_log.dart';
import 'package:food_calorie_app/data/models/user_profile.dart';
import 'package:food_calorie_app/data/repositories/daily_summary_repository.dart';
import 'package:food_calorie_app/data/repositories/meal_log_repository.dart';
import 'package:food_calorie_app/data/repositories/privacy_repository.dart';
import 'package:food_calorie_app/data/repositories/user_profile_repository.dart';
import 'package:food_calorie_app/domain/services/storage_cleanup_service.dart';
import 'package:food_calorie_app/core/utils/date_utils.dart';

class FakePrivacyRepository implements PrivacyRepository {
  bool _consent = false;

  @override
  bool get hasPrivacyConsent => _consent;

  @override
  Future<void> setPrivacyConsent(bool value) async {
    _consent = value;
  }
}

class FakeUserProfileRepository extends UserProfileRepository {
  UserProfile? profile;

  FakeUserProfileRepository({this.profile});

  @override
  bool get hasProfile => profile != null;

  @override
  Future<UserProfile?> getProfile() async => profile;

  @override
  Future<void> upsert(UserProfile profile) async {
    this.profile = profile;
  }

  @override
  Future<void> clear() async {
    profile = null;
  }
}

class FakeMealLogRepository implements MealLogRepository {
  final List<MealLog> _meals = [];

  @override
  Future<void> addMeal(MealLog meal) async {
    _meals.add(meal);
  }

  @override
  Future<void> deleteAll() async {
    _meals.clear();
  }

  @override
  Future<void> deleteMeal(String id) async {
    _meals.removeWhere((meal) => meal.id == id);
  }

  @override
  Future<List<MealLog>> getAllMeals() async {
    return List<MealLog>.from(_meals);
  }

  @override
  Future<List<MealLog>> getMealsForDate(DateTime date) async {
    final key = dateKey(date);
    return _meals.where((meal) => dateKey(meal.timestamp) == key).toList();
  }
}

class FakeDailySummaryRepository implements DailySummaryRepository {
  final Map<String, DailySummary> _summaries = {};

  @override
  Future<void> clearAll() async {
    _summaries.clear();
  }

  @override
  Future<DailySummary> getSummary(DateTime date) async {
    final key = dateKey(date);
    return _summaries[key] ?? DailySummary.empty(key);
  }

  @override
  Future<void> rebuildRecentCache({int days = 14}) async {}

  @override
  Future<void> updateForMealChange({MealLog? added, MealLog? removed}) async {}

  @override
  Future<void> upsert(DailySummary summary) async {
    _summaries[summary.dateKey] = summary;
  }
}

class TestHomeController extends HomeController {
  TestHomeController({
    required super.mealLogRepository,
    required super.dailySummaryRepository,
    required super.userProfileRepository,
    required super.privacyRepository,
  }) : super(storageCleanupService: StorageCleanupService());

  @override
  // ignore: must_call_super
  void onInit() {
    isLoading.value = false;
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    Get.testMode = true;
    tempDir = await Directory.systemTemp.createTemp('widget_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(UserProfileAdapter.typeIdValue)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    await Hive.openBox<UserProfile>(HiveBoxes.userProfile);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('MacroCard displays label and amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MacroCard(
            amount: '100 g',
            label: 'Protein left',
            percent: 0.5,
            color: Colors.blue,
            icon: Icons.egg_outlined,
          ),
        ),
      ),
    );

    expect(find.text('100 g'), findsOneWidget);
    expect(find.text('Protein left'), findsOneWidget);
  });

  testWidgets('ActivityCard formats calories and macros', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ActivityCard(
            title: 'Salad',
            time: '7:30 PM',
            calories: 320,
            protein: 40,
            carbs: 20,
            fats: 15,
          ),
        ),
      ),
    );

    expect(find.text('Salad'), findsOneWidget);
    expect(find.text('+ 320 Calories'), findsOneWidget);
    expect(find.text('40g'), findsOneWidget);
    expect(find.text('20g'), findsOneWidget);
    expect(find.text('15g'), findsOneWidget);
  });

  testWidgets('ActivityCard calls onTap when pressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityCard(
            title: 'Chicken',
            time: '8:10 AM',
            calories: 420,
            protein: 35,
            carbs: 28,
            fats: 18,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ActivityCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('Home screen renders sections', (tester) async {
    final mealRepo = FakeMealLogRepository();
    final summaryRepo = FakeDailySummaryRepository();
    final privacyRepo = FakePrivacyRepository();
    final profileRepo = FakeUserProfileRepository(
      profile: UserProfile(
        id: 'current',
        age: 25,
        sex: 'female',
        heightCm: 165,
        weightKg: 60,
        activityLevel: 'moderate',
        goalType: 'maintain',
        goalDeltaKcal: 0,
        macroProteinPct: 30,
        macroCarbsPct: 40,
        macroFatsPct: 30,
        targetCalories: 2000,
        targetProteinG: 150,
        targetCarbsG: 200,
        targetFatsG: 70,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final controller = TestHomeController(
      mealLogRepository: mealRepo,
      dailySummaryRepository: summaryRepo,
      userProfileRepository: profileRepo,
      privacyRepository: privacyRepo,
    );

    controller.profile.value = profileRepo.profile;
    controller.summary.value = DailySummary(
      dateKey: dateKey(DateTime.now()),
      targetCalories: AppConfig.defaultTargetCalories,
      consumedCalories: 1822,
      proteinGram: 60,
      carbsGram: 90,
      fatsGram: 20,
    );
    controller.meals.assignAll([
      MealLog(
        id: '1',
        name: 'Noodles',
        calories: 45,
        protein: 15,
        carbs: 25,
        fats: 5,
        timestamp: DateTime.now(),
        imagePath: '',
      ),
    ]);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: HomeScreen(controller: controller)),
      ),
    );

    expect(find.text("Today's Activity"), findsOneWidget);
    expect(find.text('Calories today'), findsOneWidget);
    expect(find.text('Noodles'), findsOneWidget);
  });
}
