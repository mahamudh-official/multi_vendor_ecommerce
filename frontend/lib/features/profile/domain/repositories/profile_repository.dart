import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Result<UserProfile>> getProfile();
  Future<Result<UserProfile>> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  });
}
