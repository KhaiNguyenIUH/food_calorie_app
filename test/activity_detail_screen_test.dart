import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:food_calorie_app/data/models/meal_log.dart';
import 'package:food_calorie_app/presentation/activity/activity_detail_screen.dart';

void main() {
  setUpAll(() {
    Get.testMode = true;
  });

  testWidgets('renders health score and warnings when provided', (
    tester,
  ) async {
    final meal = MealLog(
      id: 'meal-1',
      name: 'Salmon Bowl',
      calories: 540,
      protein: 32,
      carbs: 45,
      fats: 18,
      timestamp: DateTime(2026, 3, 1, 12, 30),
      imagePath: '',
      healthScore: 7,
      warnings: const ['High sodium', 'Added sugar'],
    );

    await tester.pumpWidget(
      GetMaterialApp(home: ActivityDetailScreen(meal: meal)),
    );

    expect(find.text('Activity Detail'), findsOneWidget);
    expect(find.text('Salmon Bowl'), findsOneWidget);
    expect(find.text('540 kcal'), findsOneWidget);
    expect(find.text('7/10'), findsOneWidget);
    expect(find.text('Warnings'), findsOneWidget);
    expect(find.text('High sodium'), findsOneWidget);
    expect(find.text('Added sugar'), findsOneWidget);
    expect(find.byIcon(Icons.fastfood), findsOneWidget);
  });

  testWidgets('renders fallback for legacy meal metadata', (tester) async {
    final legacyMeal = MealLog(
      id: 'legacy-meal',
      name: 'Legacy Meal',
      calories: 220,
      protein: 10,
      carbs: 24,
      fats: 8,
      timestamp: DateTime(2026, 3, 1, 8, 15),
      imagePath: '',
    );

    await tester.pumpWidget(
      GetMaterialApp(home: ActivityDetailScreen(meal: legacyMeal)),
    );

    expect(find.text('Legacy Meal'), findsOneWidget);
    expect(find.text('Health score'), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget);
    expect(find.text('Warnings'), findsNothing);
  });
}
