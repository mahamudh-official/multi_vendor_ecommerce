import 'package:equatable/equatable.dart';

/// Authentication token pair entity in the domain layer.
class AuthToken extends Equatable {
  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType, expiresIn];
}
