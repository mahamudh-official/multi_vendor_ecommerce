/// Request payload model for registration.
class RegisterRequestModel {
  const RegisterRequestModel({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  final String fullName;
  final String email;
  final String password;
  final String role;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'role': role,
    };
  }
}

/// Request payload model for login.
class LoginRequestModel {
  const LoginRequestModel({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return {'email': email.trim().toLowerCase(), 'password': password};
  }
}
