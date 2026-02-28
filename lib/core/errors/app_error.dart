import 'dart:io';

/// Unified user-facing error with title, message, and optional retry hint.
class AppError {
  const AppError({
    required this.title,
    required this.message,
    this.isRetryable = false,
  });

  final String title;
  final String message;
  final bool isRetryable;

  @override
  String toString() => '$title: $message';
}

/// Maps raw exceptions to user-friendly [AppError] instances.
class AppErrorMapper {
  const AppErrorMapper._();

  static AppError fromException(Object error) {
    // Network / connectivity
    if (error is SocketException) {
      return const AppError(
        title: 'No Connection',
        message: 'Check your internet connection and try again.',
        isRetryable: true,
      );
    }

    // HTTP status-based errors from ApiClient
    if (error is ApiStatusError) {
      return _fromStatus(error.statusCode, error.serverMessage);
    }

    // Timeout
    if (error is TimeoutException) {
      return const AppError(
        title: 'Request Timeout',
        message: 'The server took too long to respond. Please try again.',
        isRetryable: true,
      );
    }

    // Auth failure from token provider
    if (error is AuthSessionError) {
      return const AppError(
        title: 'Session Error',
        message: 'Unable to authenticate. Please restart the app.',
      );
    }

    // Fallback
    return const AppError(
      title: 'Something Went Wrong',
      message: 'An unexpected error occurred. Please try again.',
      isRetryable: true,
    );
  }

  static AppError _fromStatus(int status, String? serverMessage) {
    switch (status) {
      case 401:
        return const AppError(
          title: 'Session Expired',
          message:
              'Your session has expired. Please restart the app to '
              'continue scanning.',
        );
      case 400:
        return AppError(
          title: 'Invalid Request',
          message:
              serverMessage ??
              'The image could not be processed. '
                  'Try a different photo.',
        );
      case 413:
        return const AppError(
          title: 'Image Too Large',
          message:
              'The image exceeds the size limit (3 MB). '
              'Try a smaller or lower-resolution photo.',
        );
      case 429:
        return const AppError(
          title: 'Scan Limit Reached',
          message:
              'You\'ve reached your daily scan limit. '
              'Try again tomorrow.',
        );
      case 502:
        return const AppError(
          title: 'AI Service Unavailable',
          message:
              'The analysis service is temporarily down. '
              'Please try again in a moment.',
          isRetryable: true,
        );
      case 503:
        return const AppError(
          title: 'Service Unavailable',
          message:
              'The service is temporarily unavailable. '
              'Please try again shortly.',
          isRetryable: true,
        );
      default:
        if (status >= 500) {
          return const AppError(
            title: 'Server Error',
            message: 'Something went wrong on our end. Please try again.',
            isRetryable: true,
          );
        }
        return AppError(
          title: 'Request Failed',
          message: serverMessage ?? 'Please try again.',
          isRetryable: true,
        );
    }
  }
}

/// Thrown by [ApiClient] for any non-2xx HTTP response.
class ApiStatusError implements Exception {
  const ApiStatusError({required this.statusCode, this.serverMessage});

  final int statusCode;
  final String? serverMessage;

  bool get isRateLimited => statusCode == 429;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiStatusError($statusCode): $serverMessage';
}

/// Thrown when the token provider cannot obtain a session.
class AuthSessionError implements Exception {
  const AuthSessionError([this.message = 'Failed to obtain auth session']);
  final String message;

  @override
  String toString() => 'AuthSessionError: $message';
}

/// Wraps [SocketException] timeout for convenience.
class TimeoutException implements Exception {
  const TimeoutException([this.message = 'Request timed out']);
  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}
