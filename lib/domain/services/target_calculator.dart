class TargetResult {
  TargetResult({
    required this.targetCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  final int targetCalories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
}

class TargetCalculator {
  static TargetResult calculate({
    required int age,
    required String sex,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goalType,
    required int goalDeltaKcal,
    required int proteinPct,
    required int carbsPct,
    required int fatsPct,
  }) {
    final bmr = _bmr(age, sex, heightCm, weightKg);
    final tdee = bmr * _activityMultiplier(activityLevel);

    final adjustedCalories = _applyGoal(
      tdee.round(),
      goalType,
      goalDeltaKcal,
    );

    final proteinG = ((adjustedCalories * proteinPct / 100) / 4).round();
    final carbsG = ((adjustedCalories * carbsPct / 100) / 4).round();
    final fatsG = ((adjustedCalories * fatsPct / 100) / 9).round();

    return TargetResult(
      targetCalories: adjustedCalories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatsG: fatsG,
    );
  }

  static double _bmr(int age, String sex, double heightCm, double weightKg) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return sex == 'male' ? base + 5 : base - 161;
  }

  static double _activityMultiplier(String level) {
    switch (level) {
      case 'sedentary':
        return 1.2;
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'very':
        return 1.725;
      case 'extra':
        return 1.9;
      default:
        return 1.2;
    }
  }

  static int _applyGoal(int tdee, String goalType, int delta) {
    switch (goalType) {
      case 'lose':
        return tdee - delta;
      case 'gain':
        return tdee + delta;
      default:
        return tdee;
    }
  }
}
