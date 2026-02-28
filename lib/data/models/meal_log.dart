import 'package:hive/hive.dart';

class MealLog extends HiveObject {
  MealLog({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.timestamp,
    required this.imagePath,
    this.healthScore = 0,
    this.warnings = const <String>[],
  });

  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final DateTime timestamp;
  final String imagePath;
  final int healthScore;
  final List<String> warnings;
}

class MealLogAdapter extends TypeAdapter<MealLog> {
  static const int typeIdValue = 1;

  @override
  final int typeId = typeIdValue;

  @override
  MealLog read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    final warningsRaw = fields[9];
    return MealLog(
      id: fields[0] as String,
      name: fields[1] as String,
      calories: fields[2] as int,
      protein: fields[3] as int,
      carbs: fields[4] as int,
      fats: fields[5] as int,
      timestamp: fields[6] as DateTime,
      imagePath: fields[7] as String,
      healthScore: (fields[8] as int?) ?? 0,
      warnings: warningsRaw is List
          ? warningsRaw.map((item) => item.toString()).toList()
          : const <String>[],
    );
  }

  @override
  void write(BinaryWriter writer, MealLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.calories)
      ..writeByte(3)
      ..write(obj.protein)
      ..writeByte(4)
      ..write(obj.carbs)
      ..writeByte(5)
      ..write(obj.fats)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.healthScore)
      ..writeByte(9)
      ..write(obj.warnings);
  }
}
