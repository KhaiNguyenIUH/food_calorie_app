import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import 'privacy_repository.dart';

class SettingsRepository implements PrivacyRepository {
  SettingsRepository({Box? box}) : _box = box ?? Hive.box(HiveBoxes.settings);

  final Box _box;

  @override
  bool get hasPrivacyConsent =>
      _box.get(HiveBoxes.privacyConsentKey, defaultValue: false) as bool;

  @override
  Future<void> setPrivacyConsent(bool value) async {
    await _box.put(HiveBoxes.privacyConsentKey, value);
  }
}
