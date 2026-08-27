import 'package:equatable/equatable.dart';

class ShippingAddress extends Equatable {
  const ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  String get formattedAddress {
    final line2 = addressLine2 != null && addressLine2!.isNotEmpty
        ? ', $addressLine2'
        : '';
    return '$addressLine1$line2, $city, $state $postalCode, $country';
  }

  @override
  List<Object?> get props => [
    fullName,
    phone,
    addressLine1,
    addressLine2,
    city,
    state,
    postalCode,
    country,
  ];
}
