/// Data-layer exceptions.
///
/// These are thrown by DataSources and caught by Repository implementations,
/// which convert them into [Failure] objects for the domain layer.
///
/// Widgets must NEVER catch exceptions directly.
class AppException implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

class ServerException extends AppException {
  const ServerException({required super.message, super.code, this.statusCode});

  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode, $code): $message';
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Authentication required.',
    super.code = 'UNAUTHORIZED',
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Access forbidden.',
    super.code = 'FORBIDDEN',
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found.',
    super.code = 'NOT_FOUND',
  });
}

class ConflictException extends AppException {
  const ConflictException({required super.message, super.code = 'CONFLICT'});
}

class CacheException extends AppException {
  const CacheException({required super.message, super.code = 'CACHE_ERROR'});
}
