import 'package:dio/dio.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/addresses/data/datasources/address_remote_datasource.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/entities/address.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource remoteDataSource;

  AddressRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<Address>>> getAddresses() async {
    try {
      final list = await remoteDataSource.getAddresses();
      return Success(list);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['detail'] ??
          e.message ??
          'Failed to fetch addresses';
      return Error(ServerFailure(message: msg.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Address>> getAddress(String addressId) async {
    try {
      final addr = await remoteDataSource.getAddress(addressId);
      return Success(addr);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['detail'] ?? e.message ?? 'Failed to fetch address';
      return Error(ServerFailure(message: msg.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Address>> createAddress({
    required String fullName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    bool isDefault = false,
  }) async {
    try {
      final payload = {
        'full_name': fullName,
        'phone': phone,
        'address_line_1': addressLine1,
        'address_line_2': addressLine2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'is_default': isDefault,
      };
      final addr = await remoteDataSource.createAddress(payload);
      return Success(addr);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['detail'] ??
          e.message ??
          'Failed to create address';
      return Error(ServerFailure(message: msg.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Address>> updateAddress({
    required String addressId,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (fullName != null) payload['full_name'] = fullName;
      if (phone != null) payload['phone'] = phone;
      if (addressLine1 != null) payload['address_line_1'] = addressLine1;
      if (addressLine2 != null) payload['address_line_2'] = addressLine2;
      if (city != null) payload['city'] = city;
      if (state != null) payload['state'] = state;
      if (postalCode != null) payload['postal_code'] = postalCode;
      if (country != null) payload['country'] = country;
      if (isDefault != null) payload['is_default'] = isDefault;

      final addr = await remoteDataSource.updateAddress(addressId, payload);
      return Success(addr);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['detail'] ??
          e.message ??
          'Failed to update address';
      return Error(ServerFailure(message: msg.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteAddress(String addressId) async {
    try {
      await remoteDataSource.deleteAddress(addressId);
      return const Success(null);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['detail'] ??
          e.message ??
          'Failed to delete address';
      return Error(ServerFailure(message: msg.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Address>> setDefaultAddress(String addressId) async {
    try {
      final addr = await remoteDataSource.setDefaultAddress(addressId);
      return Success(addr);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['detail'] ??
          e.message ??
          'Failed to set default address';
      return Error(ServerFailure(message: msg.toString()));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}
