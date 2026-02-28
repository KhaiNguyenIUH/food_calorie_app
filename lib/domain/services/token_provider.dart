import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_error.dart';

abstract class TokenProvider {
  Future<String?> getToken();
}

class SupabaseTokenProvider implements TokenProvider {
  @override
  Future<String?> getToken() async {
    final client = Supabase.instance.client;
    var session = client.auth.currentSession;

    // No session → sign in anonymously
    if (session == null) {
      developer.log('[TokenProvider] No session, signing in anonymously');
      final response = await client.auth.signInAnonymously();
      session = response.session;
    }

    if (session == null) {
      developer.log('[TokenProvider] Failed to obtain session');
      throw const AuthSessionError();
    }

    // Refresh if token expires within 60 seconds
    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiresIn =
          expiresAt - DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (expiresIn < 60) {
        developer.log('[TokenProvider] Token near expiry, refreshing');
        final refreshed = await client.auth.refreshSession();
        session = refreshed.session;
      }
    }

    return session?.accessToken;
  }
}
