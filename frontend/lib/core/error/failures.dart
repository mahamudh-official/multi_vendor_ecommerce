import 'package:equatable/equatable.dart';

/// Base class for all domain-layer failures.
///
/// Failures represent business rule violations or recoverable errors.
/// Widgets should never catch raw exceptions — they catch [Failure] subtypes.
abstract class Failure extends Equatable {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Network-related failure (connection, timeout, etc.).
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Server returned an unexpected status code.
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code, this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Request was unauthorized (401).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Authentication required. Please log in.',
    super.code = 'UNAUTHORIZED',
  });
}

/// Forbidden access (403).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    super.message = 'You do not have permission to perform this action.',
    super.code = 'FORBIDDEN',
  });
}

/// Requested resource was not found (404).
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
    super.code = 'NOT_FOUND',
  });
}

/// Conflict — resource already exists (409).
class ConflictFailure extends Failure {
  const ConflictFailure({required super.message, super.code = 'CONFLICT'});
}

/// Cache or local storage failure.
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code = 'CACHE_ERROR'});
}

/// Unknown or unexpected failure.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'UNKNOWN',
  });
}
