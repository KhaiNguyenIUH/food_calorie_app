// ignore_for_file: implementation_imports

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';

import 'package:food_calorie_app/data/models/meal_log.dart';

void main() {
  group('MealLogAdapter', () {
    test('writes and reads health score and warnings', () {
      final adapter = MealLogAdapter();
      final original = MealLog(
        id: 'meal-1',
        name: 'Grilled Chicken',
        calories: 410,
        protein: 36,
        carbs: 20,
        fats: 14,
        timestamp: DateTime(2026, 3, 1, 11, 0),
        imagePath: '/tmp/scan_1.jpg',
        healthScore: 8,
        warnings: const ['Estimated values'],
      );

      final writer = BinaryWriterImpl(Hive);
      adapter.write(writer, original);
      final reader = BinaryReaderImpl(writer.toBytes(), Hive);
      final decoded = adapter.read(reader);

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.calories, original.calories);
      expect(decoded.protein, original.protein);
      expect(decoded.carbs, original.carbs);
      expect(decoded.fats, original.fats);
      expect(decoded.timestamp, original.timestamp);
      expect(decoded.imagePath, original.imagePath);
      expect(decoded.healthScore, 8);
      expect(decoded.warnings, const ['Estimated values']);
    });

    test('reads legacy payload with defaults for new fields', () {
      final writer = BinaryWriterImpl(Hive)
        ..writeByte(8)
        ..writeByte(0)
        ..write('legacy-id')
        ..writeByte(1)
        ..write('Legacy Meal')
        ..writeByte(2)
        ..write(180)
        ..writeByte(3)
        ..write(8)
        ..writeByte(4)
        ..write(22)
        ..writeByte(5)
        ..write(6)
        ..writeByte(6)
        ..write(DateTime(2026, 2, 28, 20, 30))
        ..writeByte(7)
        ..write('/tmp/legacy.jpg');

      final reader = BinaryReaderImpl(writer.toBytes(), Hive);
      final decoded = MealLogAdapter().read(reader);

      expect(decoded.id, 'legacy-id');
      expect(decoded.name, 'Legacy Meal');
      expect(decoded.healthScore, 0);
      expect(decoded.warnings, isEmpty);
    });
  });
}
