import 'package:equatable/equatable.dart';

abstract class AddressEvent extends Equatable {
  const AddressEvent();

  @override
  List<Object?> get props => [];
}

class LoadAddressesEvent extends AddressEvent {
  const LoadAddressesEvent();
}

class AddAddressEvent extends AddressEvent {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;

  const AddAddressEvent({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
  });

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
    isDefault,
  ];
}

class EditAddressEvent extends AddressEvent {
  final String addressId;
  final String? fullName;
  final String? phone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final bool? isDefault;

  const EditAddressEvent({
    required this.addressId,
    this.fullName,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.isDefault,
  });

  @override
  List<Object?> get props => [
    addressId,
    fullName,
    phone,
    addressLine1,
    addressLine2,
    city,
    state,
    postalCode,
    country,
    isDefault,
  ];
}

class DeleteAddressEvent extends AddressEvent {
  final String addressId;

  const DeleteAddressEvent(this.addressId);

  @override
  List<Object?> get props => [addressId];
}

class SetDefaultAddressEvent extends AddressEvent {
  final String addressId;

  const SetDefaultAddressEvent(this.addressId);

  @override
  List<Object?> get props => [addressId];
}
