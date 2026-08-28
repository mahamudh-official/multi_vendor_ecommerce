import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  const UpdateProfileEvent({this.fullName, this.phone, this.avatarUrl});

  @override
  List<Object?> get props => [fullName, phone, avatarUrl];
}
