import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/models/meal_log.dart';

class StorageCleanupService {
  Future<void> deleteImagesForMeals(List<MealLog> meals) async {
    for (final meal in meals) {
      final file = File(meal.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> cleanupOldImages({Duration maxAge = const Duration(days: 30)}) async {
    final dir = await getTemporaryDirectory();
    if (!await dir.exists()) {
      return;
    }
    final now = DateTime.now();
    final entries = dir.listSync();
    for (final entry in entries) {
      if (entry is File && entry.path.contains('scan_')) {
        final stat = await entry.stat();
        if (now.difference(stat.modified) > maxAge) {
          await entry.delete();
        }
      }
    }
  }
}
