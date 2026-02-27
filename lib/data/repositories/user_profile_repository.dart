import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository({Box<UserProfile>? box})
      : _box = box ?? Hive.box<UserProfile>(HiveBoxes.userProfile);

  static const String currentProfileId = 'current';

  final Box<UserProfile> _box;

  bool get hasProfile => _box.containsKey(currentProfileId);

  Future<UserProfile?> getProfile() async {
    return _box.get(currentProfileId);
  }

  Future<void> upsert(UserProfile profile) async {
    await _box.put(currentProfileId, profile);
  }

  Future<void> clear() async {
    await _box.delete(currentProfileId);
  }
}
