import '../../../../core/error/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use case for fetching the currently authenticated user's profile.
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call() {
    return _repository.getCurrentUser();
  }
}
