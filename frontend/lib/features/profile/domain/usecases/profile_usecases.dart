import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/profile/domain/entities/user_profile.dart';
import 'package:multi_vendor_ecommerce/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<Result<UserProfile>> call() {
    return repository.getProfile();
  }
}

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Result<UserProfile>> call({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) {
    return repository.updateProfile(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }
}
