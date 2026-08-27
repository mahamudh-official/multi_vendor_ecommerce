import 'package:equatable/equatable.dart';

/// User account entity in the domain layer.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String role; // 'customer', 'seller', 'admin'
  final bool isActive;
  final DateTime createdAt;

  bool get isSeller => role == 'seller';
  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';

  @override
  List<Object?> get props => [id, email, fullName, role, isActive, createdAt];
}
