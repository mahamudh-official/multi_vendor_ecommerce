import '../repositories/auth_repository.dart';

/// Use case to check if a valid session exists in secure storage.
class CheckAuthStatusUseCase {
  const CheckAuthStatusUseCase(this._repository);

  final AuthRepository _repository;

  Future<bool> call() {
    return _repository.isAuthenticated();
  }
}
