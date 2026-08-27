import 'package:equatable/equatable.dart';

/// Publicly safe seller summary.
class SellerSummary extends Equatable {
  const SellerSummary({required this.id, required this.fullName});

  final String id;
  final String fullName;

  @override
  List<Object?> get props => [id, fullName];
}
