import '../../../../core/error/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use case for registering a new user account.
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) {
    return _repository.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
    );
  }
}
