import 'package:hive/hive.dart';
import '../../core/constants/app_config.dart';

class DailySummary extends HiveObject {
  DailySummary({
    required this.dateKey,
    required this.targetCalories,
    required this.consumedCalories,
    required this.proteinGram,
    required this.carbsGram,
    required this.fatsGram,
  });

  final String dateKey;
  final int targetCalories;
  final int consumedCalories;
  final int proteinGram;
  final int carbsGram;
  final int fatsGram;

  DailySummary copyWith({
    String? dateKey,
    int? targetCalories,
    int? consumedCalories,
    int? proteinGram,
    int? carbsGram,
    int? fatsGram,
  }) {
    return DailySummary(
      dateKey: dateKey ?? this.dateKey,
      targetCalories: targetCalories ?? this.targetCalories,
      consumedCalories: consumedCalories ?? this.consumedCalories,
      proteinGram: proteinGram ?? this.proteinGram,
      carbsGram: carbsGram ?? this.carbsGram,
      fatsGram: fatsGram ?? this.fatsGram,
    );
  }

  static DailySummary empty(String dateKey) {
    return DailySummary(
      dateKey: dateKey,
      targetCalories: AppConfig.defaultTargetCalories,
      consumedCalories: 0,
      proteinGram: 0,
      carbsGram: 0,
      fatsGram: 0,
    );
  }
}

class DailySummaryAdapter extends TypeAdapter<DailySummary> {
  static const int typeIdValue = 2;

  @override
  final int typeId = typeIdValue;

  @override
  DailySummary read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return DailySummary(
      dateKey: fields[0] as String,
      targetCalories: fields[1] as int,
      consumedCalories: fields[2] as int,
      proteinGram: fields[3] as int,
      carbsGram: fields[4] as int,
      fatsGram: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailySummary obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.targetCalories)
      ..writeByte(2)
      ..write(obj.consumedCalories)
      ..writeByte(3)
      ..write(obj.proteinGram)
      ..writeByte(4)
      ..write(obj.carbsGram)
      ..writeByte(5)
      ..write(obj.fatsGram);
  }
}
