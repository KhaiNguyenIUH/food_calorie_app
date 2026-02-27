import 'package:hive_flutter/hive_flutter.dart';
import '../constants/hive_boxes.dart';
import '../../data/models/meal_log.dart';
import '../../data/models/daily_summary.dart';
import '../../data/models/user_profile.dart';

class HiveService {
  static const int currentSchemaVersion = 2;

  static Future<bool> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(MealLogAdapter.typeIdValue)) {
      Hive.registerAdapter(MealLogAdapter());
    }
    if (!Hive.isAdapterRegistered(DailySummaryAdapter.typeIdValue)) {
      Hive.registerAdapter(DailySummaryAdapter());
    }
    if (!Hive.isAdapterRegistered(UserProfileAdapter.typeIdValue)) {
      Hive.registerAdapter(UserProfileAdapter());
    }

    await Hive.openBox<MealLog>(HiveBoxes.mealLogs);
    await Hive.openBox<DailySummary>(HiveBoxes.dailySummary);
    await Hive.openBox<UserProfile>(HiveBoxes.userProfile);
    final settings = await Hive.openBox(HiveBoxes.settings);

    final storedVersion = settings.get(HiveBoxes.schemaVersionKey, defaultValue: 0) as int;
    final needsRebuild = storedVersion != currentSchemaVersion;
    if (needsRebuild) {
      await settings.put(HiveBoxes.schemaVersionKey, currentSchemaVersion);
    }

    return needsRebuild;
  }
}
