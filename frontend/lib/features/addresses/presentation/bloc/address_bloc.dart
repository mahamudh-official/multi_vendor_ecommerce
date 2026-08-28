import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/entities/address.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/usecases/address_usecases.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_event.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final GetAddressesUseCase getAddressesUseCase;
  final CreateAddressUseCase createAddressUseCase;
  final UpdateAddressUseCase updateAddressUseCase;
  final DeleteAddressUseCase deleteAddressUseCase;
  final SetDefaultAddressUseCase setDefaultAddressUseCase;

  AddressBloc({
    required this.getAddressesUseCase,
    required this.createAddressUseCase,
    required this.updateAddressUseCase,
    required this.deleteAddressUseCase,
    required this.setDefaultAddressUseCase,
  }) : super(const AddressInitial()) {
    on<LoadAddressesEvent>(_onLoadAddresses);
    on<AddAddressEvent>(_onAddAddress);
    on<EditAddressEvent>(_onEditAddress);
    on<DeleteAddressEvent>(_onDeleteAddress);
    on<SetDefaultAddressEvent>(_onSetDefaultAddress);
  }

  Future<void> _onLoadAddresses(
    LoadAddressesEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());
    final result = await getAddressesUseCase();
    result.fold(
      onSuccess: (list) {
        final def = list.where((a) => a.isDefault).firstOrNull;
        emit(AddressLoaded(addresses: list, defaultAddress: def));
      },
      onError: (failure) => emit(AddressError(failure.message)),
    );
  }

  Future<void> _onAddAddress(
    AddAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    final currentList = _getCurrentAddresses();
    emit(AddressActionInProgress(currentList));

    final result = await createAddressUseCase(
      fullName: event.fullName,
      phone: event.phone,
      addressLine1: event.addressLine1,
      addressLine2: event.addressLine2,
      city: event.city,
      state: event.state,
      postalCode: event.postalCode,
      country: event.country,
      isDefault: event.isDefault,
    );

    result.fold(
      onSuccess: (newAddr) {
        emit(const AddressActionSuccess('Address added successfully!'));
        add(const LoadAddressesEvent());
      },
      onError: (failure) => emit(AddressError(failure.message)),
    );
  }

  Future<void> _onEditAddress(
    EditAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    final currentList = _getCurrentAddresses();
    emit(AddressActionInProgress(currentList));

    final result = await updateAddressUseCase(
      addressId: event.addressId,
      fullName: event.fullName,
      phone: event.phone,
      addressLine1: event.addressLine1,
      addressLine2: event.addressLine2,
      city: event.city,
      state: event.state,
      postalCode: event.postalCode,
      country: event.country,
      isDefault: event.isDefault,
    );

    result.fold(
      onSuccess: (updated) {
        emit(const AddressActionSuccess('Address updated successfully!'));
        add(const LoadAddressesEvent());
      },
      onError: (failure) => emit(AddressError(failure.message)),
    );
  }

  Future<void> _onDeleteAddress(
    DeleteAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    final currentList = _getCurrentAddresses();
    emit(AddressActionInProgress(currentList));

    final result = await deleteAddressUseCase(event.addressId);
    result.fold(
      onSuccess: (_) {
        emit(const AddressActionSuccess('Address deleted successfully!'));
        add(const LoadAddressesEvent());
      },
      onError: (failure) => emit(AddressError(failure.message)),
    );
  }

  Future<void> _onSetDefaultAddress(
    SetDefaultAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    final currentList = _getCurrentAddresses();
    emit(AddressActionInProgress(currentList));

    final result = await setDefaultAddressUseCase(event.addressId);
    result.fold(
      onSuccess: (_) {
        emit(const AddressActionSuccess('Default address updated!'));
        add(const LoadAddressesEvent());
      },
      onError: (failure) => emit(AddressError(failure.message)),
    );
  }

  List<Address> _getCurrentAddresses() {
    if (state is AddressLoaded) {
      return (state as AddressLoaded).addresses;
    } else if (state is AddressActionInProgress) {
      return (state as AddressActionInProgress).currentAddresses;
    }
    return [];
  }
}
