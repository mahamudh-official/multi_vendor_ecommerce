import 'package:multi_vendor_ecommerce/core/network/dio_client.dart';
import 'package:multi_vendor_ecommerce/features/profile/data/models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile();
  Future<UserProfileModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient dioClient;

  ProfileRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserProfileModel> getProfile() async {
    final response = await dioClient.get<Map<String, dynamic>>('/profile');
    return UserProfileModel.fromJson(response.data!);
  }

  @override
  Future<UserProfileModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (phone != null) data['phone'] = phone;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    final response = await dioClient.patch<Map<String, dynamic>>(
      '/profile',
      data: data,
    );
    return UserProfileModel.fromJson(response.data!);
  }
}
