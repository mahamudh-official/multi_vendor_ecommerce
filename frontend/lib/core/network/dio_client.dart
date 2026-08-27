import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../error/exceptions.dart';

/// Configured Dio HTTP client.
///
/// All API requests in the application must go through this client.
/// Widgets must never instantiate Dio directly.
class DioClient {
  DioClient() {
    _dio = Dio(_baseOptions);
    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  late final Dio _dio;

  static final BaseOptions _baseOptions = BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    sendTimeout: AppConstants.sendTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  Dio get client => _dio;

  // ── Auth token injection ───────────────────────────────────────────────
  /// Attach a Bearer token to all subsequent requests.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remove the auth token (on logout).
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

// ── Logging Interceptor ────────────────────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // Only log in debug mode
      // ignore: avoid_print
      print(
        '[DIO] → ${options.method} ${options.uri}'
        '\n  Headers: ${options.headers}'
        '${options.data != null ? '\n  Body: ${options.data}' : ''}',
      );
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print(
        '[DIO] ← ${response.statusCode} ${response.requestOptions.uri}'
        '\n  Data: ${response.data}',
      );
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print(
        '[DIO] ✗ ${err.response?.statusCode} ${err.requestOptions.uri}'
        '\n  Error: ${err.message}',
      );
      return true;
    }());
    handler.next(err);
  }
}

// ── Error Interceptor ──────────────────────────────────────────────────────
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapDioError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
        message: exception.message,
      ),
    );
  }

  AppException _mapDioError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return const NetworkException(
        message: 'Connection failed. Please check your internet connection.',
        code: 'NETWORK_ERROR',
      );
    }

    final statusCode = err.response?.statusCode;
    final detail = err.response?.data?['detail']?.toString();

    return switch (statusCode) {
      401 => const UnauthorizedException(),
      403 => const ForbiddenException(),
      404 => NotFoundException(message: detail ?? 'Resource not found.'),
      409 => ConflictException(message: detail ?? 'Resource already exists.'),
      _ => ServerException(
          message: detail ?? 'Server error. Please try again.',
          statusCode: statusCode,
          code: 'SERVER_ERROR',
        ),
    };
  }
}
