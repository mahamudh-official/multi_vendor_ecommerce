import '../../domain/entities/shipping_address.dart';

class ShippingAddressModel extends ShippingAddress {
  const ShippingAddressModel({
    required super.fullName,
    required super.phone,
    required super.addressLine1,
    super.addressLine2,
    required super.city,
    required super.state,
    required super.postalCode,
    required super.country,
  });

  factory ShippingAddressModel.fromJson(Map<String, dynamic> json) {
    return ShippingAddressModel(
      fullName:
          (json['shipping_full_name'] ?? json['full_name'] ?? '') as String,
      phone: (json['shipping_phone'] ?? json['phone'] ?? '') as String,
      addressLine1:
          (json['shipping_address_line1'] ?? json['address_line1'] ?? '')
              as String,
      addressLine2:
          (json['shipping_address_line2'] ?? json['address_line2']) as String?,
      city: (json['shipping_city'] ?? json['city'] ?? '') as String,
      state: (json['shipping_state'] ?? json['state'] ?? '') as String,
      postalCode:
          (json['shipping_postal_code'] ?? json['postal_code'] ?? '') as String,
      country: (json['shipping_country'] ?? json['country'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'city': city,
    'state': state,
    'postal_code': postalCode,
    'country': country,
  };

  factory ShippingAddressModel.fromEntity(ShippingAddress entity) {
    return ShippingAddressModel(
      fullName: entity.fullName,
      phone: entity.phone,
      addressLine1: entity.addressLine1,
      addressLine2: entity.addressLine2,
      city: entity.city,
      state: entity.state,
      postalCode: entity.postalCode,
      country: entity.country,
    );
  }
}
