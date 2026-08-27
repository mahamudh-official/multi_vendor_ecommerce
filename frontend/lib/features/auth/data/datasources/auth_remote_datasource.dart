import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_request_models.dart';
import '../models/auth_token_model.dart';
import '../models/auth_user_model.dart';

/// Contract for remote authentication API data source.
abstract interface class AuthRemoteDataSource {
  Future<AuthUserModel> register(RegisterRequestModel request);
  Future<({AuthUserModel user, AuthTokenModel token})> login(
    LoginRequestModel request,
  );
  Future<AuthUserModel> getCurrentUser();
  Future<AuthTokenModel> refreshToken(String refreshToken);
  Future<void> logout();
}

/// Implementation of [AuthRemoteDataSource] using [DioClient].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  Dio get _dio => _dioClient.client;

  @override
  Future<AuthUserModel> register(RegisterRequestModel request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: request.toJson(),
      );
      if (response.data == null) {
        throw const ServerException(message: 'Empty response from server');
      }
      return AuthUserModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw ServerException(message: e.message ?? 'Registration failed');
    }
  }

  @override
  Future<({AuthUserModel user, AuthTokenModel token})> login(
    LoginRequestModel request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'Empty response from server');
      }
      final user = AuthUserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = AuthTokenModel.fromJson(data);
      return (user: user, token: token);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw ServerException(message: e.message ?? 'Login failed');
    }
  }

  @override
  Future<AuthUserModel> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      if (response.data == null) {
        throw const ServerException(message: 'Empty response from server');
      }
      return AuthUserModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw ServerException(message: e.message ?? 'Failed to get current user');
    }
  }

  @override
  Future<AuthTokenModel> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (response.data == null) {
        throw const ServerException(message: 'Empty response from server');
      }
      return AuthTokenModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw ServerException(message: e.message ?? 'Token refresh failed');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } catch (_) {
      // Stateless logout: ignoring network errors on logout
    }
  }
}
