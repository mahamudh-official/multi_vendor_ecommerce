import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Use case for logging out and wiping session data.
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() {
    return _repository.logout();
  }
}
