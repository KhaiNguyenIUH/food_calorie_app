import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../errors/app_error.dart';

class ApiClient {
  ApiClient({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final uri = Uri.parse(path);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    developer.log('[ApiClient] POST $uri');

    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    developer.log(
      '[ApiClient] Response: ${response.statusCode} '
      '${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiStatusError(
        statusCode: response.statusCode,
        serverMessage: _extractErrorMessage(response.body),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiStatusError(
      statusCode: response.statusCode,
      serverMessage: 'Invalid JSON response',
    );
  }

  /// Extracts the "error" field from a JSON response body, if present.
  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['error'] as String?;
      }
    } catch (_) {}
    return body.length > 200 ? body.substring(0, 200) : body;
  }
}
