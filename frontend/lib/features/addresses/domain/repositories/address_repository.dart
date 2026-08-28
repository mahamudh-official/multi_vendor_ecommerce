import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/entities/address.dart';

abstract class AddressRepository {
  Future<Result<List<Address>>> getAddresses();
  Future<Result<Address>> getAddress(String addressId);
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
  });
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
  });
  Future<Result<void>> deleteAddress(String addressId);
  Future<Result<Address>> setDefaultAddress(String addressId);
}
