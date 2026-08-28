import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/entities/address.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/repositories/address_repository.dart';

class GetAddressesUseCase {
  final AddressRepository repository;
  GetAddressesUseCase(this.repository);

  Future<Result<List<Address>>> call() => repository.getAddresses();
}

class CreateAddressUseCase {
  final AddressRepository repository;
  CreateAddressUseCase(this.repository);

  Future<Result<Address>> call({
    required String fullName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    bool isDefault = false,
  }) {
    return repository.createAddress(
      fullName: fullName,
      phone: phone,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      isDefault: isDefault,
    );
  }
}

class UpdateAddressUseCase {
  final AddressRepository repository;
  UpdateAddressUseCase(this.repository);

  Future<Result<Address>> call({
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
  }) {
    return repository.updateAddress(
      addressId: addressId,
      fullName: fullName,
      phone: phone,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      isDefault: isDefault,
    );
  }
}

class DeleteAddressUseCase {
  final AddressRepository repository;
  DeleteAddressUseCase(this.repository);

  Future<Result<void>> call(String addressId) =>
      repository.deleteAddress(addressId);
}

class SetDefaultAddressUseCase {
  final AddressRepository repository;
  SetDefaultAddressUseCase(this.repository);

  Future<Result<Address>> call(String addressId) =>
      repository.setDefaultAddress(addressId);
}
