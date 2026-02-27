abstract class PrivacyRepository {
  bool get hasPrivacyConsent;
  Future<void> setPrivacyConsent(bool value);
}
