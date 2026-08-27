import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Use case for refreshing access tokens.
class RefreshTokenUseCase {
  const RefreshTokenUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() {
    return _repository.refreshToken();
  }
}
