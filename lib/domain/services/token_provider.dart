import '../../core/constants/app_config.dart';

abstract class TokenProvider {
  Future<String?> getToken();
}

class DevTokenProvider implements TokenProvider {
  @override
  Future<String?> getToken() async {
    if (AppConfig.devJwt.isEmpty) {
      return null;
    }
    return AppConfig.devJwt;
  }
}
