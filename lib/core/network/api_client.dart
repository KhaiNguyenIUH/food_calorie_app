import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
    String? appSecret,
  }) async {
    final uri = Uri.parse(path);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (appSecret != null && appSecret.isNotEmpty) 'x-app-secret': appSecret,
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

    if (response.statusCode == 429) {
      throw RateLimitException(message: response.body);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Invalid JSON response',
    );
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class RateLimitException implements Exception {
  RateLimitException({required this.message});

  final String message;

  @override
  String toString() => 'RateLimitException: $message';
}
