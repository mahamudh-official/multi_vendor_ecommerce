import 'package:equatable/equatable.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/entities/seller_analytics.dart';

abstract class SellerAnalyticsState extends Equatable {
  const SellerAnalyticsState();

  @override
  List<Object?> get props => [];
}

class SellerAnalyticsInitial extends SellerAnalyticsState {
  const SellerAnalyticsInitial();
}

class SellerAnalyticsLoading extends SellerAnalyticsState {
  const SellerAnalyticsLoading();
}

class SellerAnalyticsLoaded extends SellerAnalyticsState {
  final SellerAnalyticsOverview overview;
  final List<SellerSalesPeriodItem> salesTimeline;
  final List<SellerProductAnalyticsItem> topProducts;
  final String activePeriod;

  const SellerAnalyticsLoaded({
    required this.overview,
    required this.salesTimeline,
    required this.topProducts,
    required this.activePeriod,
  });

  SellerAnalyticsLoaded copyWith({
    SellerAnalyticsOverview? overview,
    List<SellerSalesPeriodItem>? salesTimeline,
    List<SellerProductAnalyticsItem>? topProducts,
    String? activePeriod,
  }) {
    return SellerAnalyticsLoaded(
      overview: overview ?? this.overview,
      salesTimeline: salesTimeline ?? this.salesTimeline,
      topProducts: topProducts ?? this.topProducts,
      activePeriod: activePeriod ?? this.activePeriod,
    );
  }

  @override
  List<Object?> get props => [overview, salesTimeline, topProducts, activePeriod];
}

class SellerAnalyticsError extends SellerAnalyticsState {
  final String message;

  const SellerAnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
