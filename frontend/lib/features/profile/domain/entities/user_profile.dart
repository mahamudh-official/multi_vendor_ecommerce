import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final String? sellerStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.sellerStatus,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? phone,
    String? avatarUrl,
    String? sellerStatus,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sellerStatus: sellerStatus ?? this.sellerStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    role,
    phone,
    avatarUrl,
    sellerStatus,
    isActive,
    createdAt,
    updatedAt,
  ];
}
