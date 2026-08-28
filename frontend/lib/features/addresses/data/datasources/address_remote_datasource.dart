import 'package:multi_vendor_ecommerce/core/network/dio_client.dart';
import 'package:multi_vendor_ecommerce/features/addresses/data/models/address_model.dart';

abstract class AddressRemoteDataSource {
  Future<List<AddressModel>> getAddresses();
  Future<AddressModel> getAddress(String addressId);
  Future<AddressModel> createAddress(Map<String, dynamic> data);
  Future<AddressModel> updateAddress(
    String addressId,
    Map<String, dynamic> data,
  );
  Future<void> deleteAddress(String addressId);
  Future<AddressModel> setDefaultAddress(String addressId);
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final DioClient dioClient;

  AddressRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<AddressModel>> getAddresses() async {
    final response = await dioClient.get<Map<String, dynamic>>('/addresses');
    final items = response.data!['items'] as List<dynamic>;
    return items
        .map((json) => AddressModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AddressModel> getAddress(String addressId) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      '/addresses/$addressId',
    );
    return AddressModel.fromJson(response.data!);
  }

  @override
  Future<AddressModel> createAddress(Map<String, dynamic> data) async {
    final response = await dioClient.post<Map<String, dynamic>>(
      '/addresses',
      data: data,
    );
    return AddressModel.fromJson(response.data!);
  }

  @override
  Future<AddressModel> updateAddress(
    String addressId,
    Map<String, dynamic> data,
  ) async {
    final response = await dioClient.patch<Map<String, dynamic>>(
      '/addresses/$addressId',
      data: data,
    );
    return AddressModel.fromJson(response.data!);
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    await dioClient.delete<dynamic>('/addresses/$addressId');
  }

  @override
  Future<AddressModel> setDefaultAddress(String addressId) async {
    final response = await dioClient.patch<Map<String, dynamic>>(
      '/addresses/$addressId/default',
    );
    return AddressModel.fromJson(response.data!);
  }
}
