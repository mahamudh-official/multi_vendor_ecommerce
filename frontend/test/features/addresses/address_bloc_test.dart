import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/entities/address.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/usecases/address_usecases.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_bloc.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_event.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_state.dart';

class MockGetAddressesUseCase extends Mock implements GetAddressesUseCase {}
class MockCreateAddressUseCase extends Mock implements CreateAddressUseCase {}
class MockUpdateAddressUseCase extends Mock implements UpdateAddressUseCase {}
class MockDeleteAddressUseCase extends Mock implements DeleteAddressUseCase {}
class MockSetDefaultAddressUseCase extends Mock implements SetDefaultAddressUseCase {}

void main() {
  late MockGetAddressesUseCase mockGetAddressesUseCase;
  late MockCreateAddressUseCase mockCreateAddressUseCase;
  late MockUpdateAddressUseCase mockUpdateAddressUseCase;
  late MockDeleteAddressUseCase mockDeleteAddressUseCase;
  late MockSetDefaultAddressUseCase mockSetDefaultAddressUseCase;
  late AddressBloc addressBloc;

  final sampleAddress = Address(
    id: 'addr-1',
    userId: 'user-1',
    fullName: 'Jane Doe',
    phone: '+14155552671',
    addressLine1: '100 Market St',
    addressLine2: 'Apt 4B',
    city: 'San Francisco',
    state: 'CA',
    postalCode: '94105',
    country: 'US',
    isDefault: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockGetAddressesUseCase = MockGetAddressesUseCase();
    mockCreateAddressUseCase = MockCreateAddressUseCase();
    mockUpdateAddressUseCase = MockUpdateAddressUseCase();
    mockDeleteAddressUseCase = MockDeleteAddressUseCase();
    mockSetDefaultAddressUseCase = MockSetDefaultAddressUseCase();

    addressBloc = AddressBloc(
      getAddressesUseCase: mockGetAddressesUseCase,
      createAddressUseCase: mockCreateAddressUseCase,
      updateAddressUseCase: mockUpdateAddressUseCase,
      deleteAddressUseCase: mockDeleteAddressUseCase,
      setDefaultAddressUseCase: mockSetDefaultAddressUseCase,
    );
  });

  tearDown(() {
    addressBloc.close();
  });

  test('initial state should be AddressInitial', () {
    expect(addressBloc.state, isA<AddressInitial>());
  });

  blocTest<AddressBloc, AddressState>(
    'emits [AddressLoading, AddressLoaded] when LoadAddressesEvent succeeds',
    build: () {
      when(() => mockGetAddressesUseCase()).thenAnswer(
        (_) async => Success([sampleAddress]),
      );
      return addressBloc;
    },
    act: (bloc) => bloc.add(const LoadAddressesEvent()),
    expect: () => [
      isA<AddressLoading>(),
      AddressLoaded(addresses: [sampleAddress], defaultAddress: sampleAddress),
    ],
  );

  blocTest<AddressBloc, AddressState>(
    'emits [AddressLoading, AddressError] when LoadAddressesEvent fails',
    build: () {
      when(() => mockGetAddressesUseCase()).thenAnswer(
        (_) async => const Error(ServerFailure(message: 'Database error')),
      );
      return addressBloc;
    },
    act: (bloc) => bloc.add(const LoadAddressesEvent()),
    expect: () => [
      isA<AddressLoading>(),
      const AddressError('Database error'),
    ],
  );
}
