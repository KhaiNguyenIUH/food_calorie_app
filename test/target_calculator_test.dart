import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_app/domain/services/target_calculator.dart';

void main() {
  test('TargetCalculator computes calories and macros', () {
    final result = TargetCalculator.calculate(
      age: 30,
      sex: 'male',
      heightCm: 180,
      weightKg: 80,
      activityLevel: 'moderate',
      goalType: 'maintain',
      goalDeltaKcal: 0,
      proteinPct: 30,
      carbsPct: 40,
      fatsPct: 30,
    );

    expect(result.targetCalories, greaterThan(0));
    expect(result.proteinG, greaterThan(0));
    expect(result.carbsG, greaterThan(0));
    expect(result.fatsG, greaterThan(0));
  });
}
