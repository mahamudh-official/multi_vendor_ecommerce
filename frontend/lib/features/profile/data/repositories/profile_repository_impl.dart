import 'package:dio/dio.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:multi_vendor_ecommerce/features/profile/domain/entities/user_profile.dart';
import 'package:multi_vendor_ecommerce/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<UserProfile>> getProfile() async {
    try {
      final profile = await remoteDataSource.getProfile();
      return Success(profile);
    } on DioException catch (e) {
      final message =
          e.response?.data?['detail'] ?? e.message ?? 'Failed to fetch profile';
      return Error(ServerFailure(message: message.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<UserProfile>> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updated = await remoteDataSource.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      return Success(updated);
    } on DioException catch (e) {
      final message =
          e.response?.data?['detail'] ??
          e.message ??
          'Failed to update profile';
      return Error(ServerFailure(message: message.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}
