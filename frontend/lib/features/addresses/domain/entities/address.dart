import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedSummary {
    final line2Part = (addressLine2 != null && addressLine2!.isNotEmpty)
        ? ', $addressLine2'
        : '';
    return '$addressLine1$line2Part, $city, $state $postalCode, $country';
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    fullName,
    phone,
    addressLine1,
    addressLine2,
    city,
    state,
    postalCode,
    country,
    isDefault,
    createdAt,
    updatedAt,
  ];
}
