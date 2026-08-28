import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/domain/usecases/seller_analytics_usecases.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/presentation/bloc/seller_analytics_event.dart';
import 'package:multi_vendor_ecommerce/features/seller_analytics/presentation/bloc/seller_analytics_state.dart';

class SellerAnalyticsBloc extends Bloc<SellerAnalyticsEvent, SellerAnalyticsState> {
  final GetSellerAnalyticsOverviewUseCase getOverviewUseCase;
  final GetSellerSalesAnalyticsUseCase getSalesAnalyticsUseCase;
  final GetSellerProductAnalyticsUseCase getProductAnalyticsUseCase;

  SellerAnalyticsBloc({
    required this.getOverviewUseCase,
    required this.getSalesAnalyticsUseCase,
    required this.getProductAnalyticsUseCase,
  }) : super(const SellerAnalyticsInitial()) {
    on<LoadSellerAnalyticsEvent>(_onLoadAnalytics);
    on<ChangeSalesPeriodEvent>(_onChangeSalesPeriod);
  }

  Future<void> _onLoadAnalytics(
    LoadSellerAnalyticsEvent event,
    Emitter<SellerAnalyticsState> emit,
  ) async {
    emit(const SellerAnalyticsLoading());

    final overviewResult = await getOverviewUseCase();
    final salesResult = await getSalesAnalyticsUseCase(period: event.period);
    final productsResult = await getProductAnalyticsUseCase(limit: 10);

    if (overviewResult.isSuccess && salesResult.isSuccess && productsResult.isSuccess) {
      emit(
        SellerAnalyticsLoaded(
          overview: overviewResult.dataOrNull!,
          salesTimeline: salesResult.dataOrNull!,
          topProducts: productsResult.dataOrNull!,
          activePeriod: event.period,
        ),
      );
    } else {
      final errorMsg = overviewResult.failureOrNull?.message ??
          salesResult.failureOrNull?.message ??
          productsResult.failureOrNull?.message ??
          'Failed to load analytics';
      emit(SellerAnalyticsError(errorMsg));
    }
  }

  Future<void> _onChangeSalesPeriod(
    ChangeSalesPeriodEvent event,
    Emitter<SellerAnalyticsState> emit,
  ) async {
    if (state is SellerAnalyticsLoaded) {
      final current = state as SellerAnalyticsLoaded;
      final salesResult = await getSalesAnalyticsUseCase(period: event.period);
      salesResult.fold(
        onSuccess: (items) {
          emit(current.copyWith(salesTimeline: items, activePeriod: event.period));
        },
        onError: (failure) => emit(SellerAnalyticsError(failure.message)),
      );
    }
  }
}
