import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_request_models.dart';

/// Implementation of [AuthRepository] combining remote datasource and secure storage.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.dioClient,
  });

  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;
  final DioClient dioClient;

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final userModel = await remoteDataSource.register(
        RegisterRequestModel(
          fullName: fullName,
          email: email,
          password: password,
          role: role,
        ),
      );
      return Success(userModel.toEntity());
    } on AppException catch (e) {
      return Error(_mapExceptionToFailure(e));
    } catch (e) {
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.login(
        LoginRequestModel(email: email, password: password),
      );

      // Save tokens securely
      await secureStorage.saveTokens(
        accessToken: result.token.accessToken,
        refreshToken: result.token.refreshToken,
      );

      // Attach token to Dio client headers
      dioClient.setAuthToken(result.token.accessToken);

      return Success(result.user.toEntity());
    } on AppException catch (e) {
      return Error(_mapExceptionToFailure(e));
    } catch (e) {
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AuthUser>> getCurrentUser() async {
    try {
      final token = await secureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        return const Error(UnauthorizedFailure(message: 'No active session.'));
      }
      dioClient.setAuthToken(token);

      final userModel = await remoteDataSource.getCurrentUser();
      return Success(userModel.toEntity());
    } on AppException catch (e) {
      if (e is UnauthorizedException) {
        await secureStorage.clearAuthData();
        dioClient.clearAuthToken();
      }
      return Error(_mapExceptionToFailure(e));
    } catch (e) {
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> refreshToken() async {
    try {
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return const Error(
          UnauthorizedFailure(message: 'No refresh token available.'),
        );
      }

      final tokenModel = await remoteDataSource.refreshToken(refreshToken);
      await secureStorage.saveAccessToken(tokenModel.accessToken);
      dioClient.setAuthToken(tokenModel.accessToken);

      return const Success(null);
    } on AppException catch (e) {
      await secureStorage.clearAuthData();
      dioClient.clearAuthToken();
      return Error(_mapExceptionToFailure(e));
    } catch (e) {
      await secureStorage.clearAuthData();
      dioClient.clearAuthToken();
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      await secureStorage.clearAuthData();
      dioClient.clearAuthToken();
    }
    return const Success(null);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await secureStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Failure _mapExceptionToFailure(AppException e) {
    return switch (e) {
      NetworkException(:final message, :final code) => NetworkFailure(
        message: message,
        code: code,
      ),
      ServerException(:final message, :final code, :final statusCode) =>
        ServerFailure(message: message, code: code, statusCode: statusCode),
      UnauthorizedException(:final message, :final code) => UnauthorizedFailure(
        message: message,
        code: code,
      ),
      ForbiddenException(:final message, :final code) => ForbiddenFailure(
        message: message,
        code: code,
      ),
      NotFoundException(:final message, :final code) => NotFoundFailure(
        message: message,
        code: code,
      ),
      ConflictException(:final message, :final code) => ConflictFailure(
        message: message,
        code: code,
      ),
      CacheException(:final message, :final code) => CacheFailure(
        message: message,
        code: code,
      ),
      _ => UnknownFailure(message: e.message, code: e.code),
    };
  }
}
