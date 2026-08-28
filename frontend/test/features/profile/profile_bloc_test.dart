import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_vendor_ecommerce/core/error/failures.dart';
import 'package:multi_vendor_ecommerce/core/error/result.dart';
import 'package:multi_vendor_ecommerce/features/profile/domain/entities/user_profile.dart';
import 'package:multi_vendor_ecommerce/features/profile/domain/usecases/profile_usecases.dart';
import 'package:multi_vendor_ecommerce/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:multi_vendor_ecommerce/features/profile/presentation/bloc/profile_event.dart';
import 'package:multi_vendor_ecommerce/features/profile/presentation/bloc/profile_state.dart';

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

void main() {
  late MockGetProfileUseCase mockGetProfileUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late ProfileBloc profileBloc;

  final sampleProfile = UserProfile(
    id: 'user-1',
    email: 'customer@example.com',
    fullName: 'Jane Customer',
    phone: '+14155552671',
    avatarUrl: 'https://example.com/avatar.jpg',
    role: 'customer',
    sellerStatus: null,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockGetProfileUseCase = MockGetProfileUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();
    profileBloc = ProfileBloc(
      getProfileUseCase: mockGetProfileUseCase,
      updateProfileUseCase: mockUpdateProfileUseCase,
    );
  });

  tearDown(() {
    profileBloc.close();
  });

  test('initial state should be ProfileInitial', () {
    expect(profileBloc.state, isA<ProfileInitial>());
  });

  blocTest<ProfileBloc, ProfileState>(
    'emits [ProfileLoading, ProfileLoaded] when LoadProfileEvent succeeds',
    build: () {
      when(
        () => mockGetProfileUseCase(),
      ).thenAnswer((_) async => Success(sampleProfile));
      return profileBloc;
    },
    act: (bloc) => bloc.add(const LoadProfileEvent()),
    expect: () => [isA<ProfileLoading>(), ProfileLoaded(sampleProfile)],
  );

  blocTest<ProfileBloc, ProfileState>(
    'emits [ProfileLoading, ProfileError] when LoadProfileEvent fails',
    build: () {
      when(() => mockGetProfileUseCase()).thenAnswer(
        (_) async => const Error(ServerFailure(message: 'User not found')),
      );
      return profileBloc;
    },
    act: (bloc) => bloc.add(const LoadProfileEvent()),
    expect: () => [isA<ProfileLoading>(), const ProfileError('User not found')],
  );

  blocTest<ProfileBloc, ProfileState>(
    'emits [ProfileUpdating, ProfileUpdateSuccess, ProfileLoaded] when UpdateProfileEvent succeeds',
    seed: () => ProfileLoaded(sampleProfile),
    build: () {
      final updated = sampleProfile.copyWith(fullName: 'Jane Updated');
      when(
        () => mockUpdateProfileUseCase(
          fullName: 'Jane Updated',
          phone: null,
          avatarUrl: null,
        ),
      ).thenAnswer((_) async => Success(updated));
      return profileBloc;
    },
    act: (bloc) => bloc.add(const UpdateProfileEvent(fullName: 'Jane Updated')),
    expect: () => [
      ProfileUpdating(sampleProfile),
      ProfileUpdateSuccess(sampleProfile.copyWith(fullName: 'Jane Updated')),
      ProfileLoaded(sampleProfile.copyWith(fullName: 'Jane Updated')),
    ],
  );
}
