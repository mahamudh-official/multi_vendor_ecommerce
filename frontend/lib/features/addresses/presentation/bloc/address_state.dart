import 'package:equatable/equatable.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/entities/address.dart';

abstract class AddressState extends Equatable {
  const AddressState();

  @override
  List<Object?> get props => [];
}

class AddressInitial extends AddressState {
  const AddressInitial();
}

class AddressLoading extends AddressState {
  const AddressLoading();
}

class AddressLoaded extends AddressState {
  final List<Address> addresses;
  final Address? defaultAddress;

  const AddressLoaded({required this.addresses, this.defaultAddress});

  @override
  List<Object?> get props => [addresses, defaultAddress];
}

class AddressActionInProgress extends AddressState {
  final List<Address> currentAddresses;

  const AddressActionInProgress(this.currentAddresses);

  @override
  List<Object?> get props => [currentAddresses];
}

class AddressActionSuccess extends AddressState {
  final String message;

  const AddressActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AddressError extends AddressState {
  final String message;

  const AddressError(this.message);

  @override
  List<Object?> get props => [message];
}
