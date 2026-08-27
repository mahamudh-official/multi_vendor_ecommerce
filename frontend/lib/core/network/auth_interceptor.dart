import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor that attaches the Bearer access token to outgoing requests
/// and handles token refreshing upon encountering 401 Unauthorized responses.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.secureStorage, required this.dio});

  final SecureStorageService secureStorage;
  final Dio dio;

  bool _isRefreshing = false;

  static const List<String> _publicEndpoints = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip attaching token for public auth endpoints
    final isPublic = _publicEndpoints.any(
      (path) => options.path.contains(path),
    );
    if (isPublic) {
      return handler.next(options);
    }

    final token = await secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final isPublic = _publicEndpoints.any(
      (path) => err.requestOptions.path.contains(path),
    );
    final isRetry = err.requestOptions.extra['isRetry'] == true;

    // Handle 401 on authenticated endpoints that haven't been retried yet
    if (statusCode == 401 && !isPublic && !isRetry) {
      if (_isRefreshing) {
        return handler.next(err);
      }

      _isRefreshing = true;
      try {
        final refreshToken = await secureStorage.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await secureStorage.clearAuthData();
          _isRefreshing = false;
          return handler.next(err);
        }

        // Dedicated refresh Dio instance to avoid recursive interceptor loops
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: err.requestOptions.baseUrl.isNotEmpty
                ? err.requestOptions.baseUrl
                : AppConstants.apiBaseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
          ),
        );

        final response = await refreshDio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        if (response.statusCode == 200 && response.data != null) {
          final newAccessToken = response.data!['access_token'] as String?;
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await secureStorage.saveAccessToken(newAccessToken);

            // Retry original request with fresh token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';
            options.extra['isRetry'] = true;

            final retryResponse = await dio.fetch<dynamic>(options);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          }
        }
      } catch (_) {
        await secureStorage.clearAuthData();
      } finally {
        _isRefreshing = false;
      }
    }

    return handler.next(err);
  }
}
