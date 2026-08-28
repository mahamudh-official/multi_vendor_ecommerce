import 'package:equatable/equatable.dart';

abstract class SellerAnalyticsEvent extends Equatable {
  const SellerAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSellerAnalyticsEvent extends SellerAnalyticsEvent {
  final String period;

  const LoadSellerAnalyticsEvent({this.period = 'daily'});

  @override
  List<Object?> get props => [period];
}

class ChangeSalesPeriodEvent extends SellerAnalyticsEvent {
  final String period;

  const ChangeSalesPeriodEvent({required this.period});

  @override
  List<Object?> get props => [period];
}
