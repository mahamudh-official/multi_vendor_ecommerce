import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/features/profile/domain/entities/user_profile.dart';
import 'package:multi_vendor_ecommerce/features/profile/domain/usecases/profile_usecases.dart';
import 'package:multi_vendor_ecommerce/features/profile/presentation/bloc/profile_event.dart';
import 'package:multi_vendor_ecommerce/features/profile/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;

  ProfileBloc({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
  }) : super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final result = await getProfileUseCase();
    result.fold(
      onSuccess: (profile) => emit(ProfileLoaded(profile)),
      onError: (failure) => emit(ProfileError(failure.message)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    UserProfile? current;
    if (state is ProfileLoaded) {
      current = (state as ProfileLoaded).profile;
    } else if (state is ProfileUpdateSuccess) {
      current = (state as ProfileUpdateSuccess).updatedProfile;
    }

    if (current != null) {
      emit(ProfileUpdating(current));
    } else {
      emit(const ProfileLoading());
    }

    final result = await updateProfileUseCase(
      fullName: event.fullName,
      phone: event.phone,
      avatarUrl: event.avatarUrl,
    );

    result.fold(
      onSuccess: (updated) {
        emit(ProfileUpdateSuccess(updated));
        emit(ProfileLoaded(updated));
      },
      onError: (failure) => emit(ProfileError(failure.message)),
    );
  }
}
