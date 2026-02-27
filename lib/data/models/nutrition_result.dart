class NutritionResult {
  NutritionResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.healthScore,
    required this.confidence,
    required this.warnings,
  });

  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int healthScore;
  final double confidence;
  final List<String> warnings;

  factory NutritionResult.fromJson(Map<String, dynamic> json) {
    return NutritionResult(
      name: json['name'] as String? ?? 'Unknown',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fats: (json['fats'] as num?)?.toInt() ?? 0,
      healthScore: (json['health_score'] as num?)?.toInt() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      warnings: (json['warnings'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
    );
  }

  NutritionResult copyWith({
    String? name,
    int? calories,
    int? protein,
    int? carbs,
    int? fats,
    int? healthScore,
    double? confidence,
    List<String>? warnings,
  }) {
    return NutritionResult(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      healthScore: healthScore ?? this.healthScore,
      confidence: confidence ?? this.confidence,
      warnings: warnings ?? this.warnings,
    );
  }
}
