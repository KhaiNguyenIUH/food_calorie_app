import 'package:hive/hive.dart';

class UserProfile extends HiveObject {
  UserProfile({
    required this.id,
    required this.age,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goalType,
    required this.goalDeltaKcal,
    required this.macroProteinPct,
    required this.macroCarbsPct,
    required this.macroFatsPct,
    required this.targetCalories,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatsG,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int age;
  final String sex; // male | female
  final double heightCm;
  final double weightKg;
  final String activityLevel; // sedentary | light | moderate | very | extra
  final String goalType; // maintain | lose | gain
  final int goalDeltaKcal;
  final int macroProteinPct;
  final int macroCarbsPct;
  final int macroFatsPct;
  final int targetCalories;
  final int targetProteinG;
  final int targetCarbsG;
  final int targetFatsG;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  static const int typeIdValue = 3;

  @override
  final int typeId = typeIdValue;

  @override
  UserProfile read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }

    return UserProfile(
      id: fields[0] as String,
      age: fields[1] as int,
      sex: fields[2] as String,
      heightCm: fields[3] as double,
      weightKg: fields[4] as double,
      activityLevel: fields[5] as String,
      goalType: fields[6] as String,
      goalDeltaKcal: fields[7] as int,
      macroProteinPct: fields[8] as int,
      macroCarbsPct: fields[9] as int,
      macroFatsPct: fields[10] as int,
      targetCalories: fields[11] as int,
      targetProteinG: fields[12] as int,
      targetCarbsG: fields[13] as int,
      targetFatsG: fields[14] as int,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.sex)
      ..writeByte(3)
      ..write(obj.heightCm)
      ..writeByte(4)
      ..write(obj.weightKg)
      ..writeByte(5)
      ..write(obj.activityLevel)
      ..writeByte(6)
      ..write(obj.goalType)
      ..writeByte(7)
      ..write(obj.goalDeltaKcal)
      ..writeByte(8)
      ..write(obj.macroProteinPct)
      ..writeByte(9)
      ..write(obj.macroCarbsPct)
      ..writeByte(10)
      ..write(obj.macroFatsPct)
      ..writeByte(11)
      ..write(obj.targetCalories)
      ..writeByte(12)
      ..write(obj.targetProteinG)
      ..writeByte(13)
      ..write(obj.targetCarbsG)
      ..writeByte(14)
      ..write(obj.targetFatsG)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt);
  }
}
