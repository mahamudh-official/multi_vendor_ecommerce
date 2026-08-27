import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/entities/seller_dashboard_stats.dart';
import 'package:multi_vendor_ecommerce/features/seller/domain/usecases/get_seller_dashboard_usecase.dart';

// ── Events ──────────────────────────────────────────────────────────────────
abstract class SellerDashboardEvent extends Equatable {
  const SellerDashboardEvent();

  @override
  List<Object?> get props => [];
}

class SellerDashboardRequested extends SellerDashboardEvent {
  const SellerDashboardRequested();
}

class SellerDashboardRefreshed extends SellerDashboardEvent {
  const SellerDashboardRefreshed();
}

class SellerDashboardReset extends SellerDashboardEvent {
  const SellerDashboardReset();
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class SellerDashboardState extends Equatable {
  const SellerDashboardState();

  @override
  List<Object?> get props => [];
}

class SellerDashboardInitial extends SellerDashboardState {
  const SellerDashboardInitial();
}

class SellerDashboardLoading extends SellerDashboardState {
  const SellerDashboardLoading();
}

class SellerDashboardLoaded extends SellerDashboardState {
  final SellerDashboard dashboard;

  const SellerDashboardLoaded({required this.dashboard});

  @override
  List<Object?> get props => [dashboard];
}

class SellerDashboardFailure extends SellerDashboardState {
  final String message;

  const SellerDashboardFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────────────────────
class SellerDashboardBloc
    extends Bloc<SellerDashboardEvent, SellerDashboardState> {
  final GetSellerDashboardUseCase getDashboardUseCase;

  SellerDashboardBloc({required this.getDashboardUseCase})
    : super(const SellerDashboardInitial()) {
    on<SellerDashboardRequested>(_onDashboardRequested);
    on<SellerDashboardRefreshed>(_onDashboardRefreshed);
    on<SellerDashboardReset>(_onDashboardReset);
  }

  Future<void> _onDashboardRequested(
    SellerDashboardRequested event,
    Emitter<SellerDashboardState> emit,
  ) async {
    emit(const SellerDashboardLoading());
    final result = await getDashboardUseCase();
    result.fold(
      onSuccess: (dashboard) =>
          emit(SellerDashboardLoaded(dashboard: dashboard)),
      onError: (failure) =>
          emit(SellerDashboardFailure(message: failure.message)),
    );
  }

  Future<void> _onDashboardRefreshed(
    SellerDashboardRefreshed event,
    Emitter<SellerDashboardState> emit,
  ) async {
    final result = await getDashboardUseCase();
    result.fold(
      onSuccess: (dashboard) =>
          emit(SellerDashboardLoaded(dashboard: dashboard)),
      onError: (failure) =>
          emit(SellerDashboardFailure(message: failure.message)),
    );
  }

  void _onDashboardReset(
    SellerDashboardReset event,
    Emitter<SellerDashboardState> emit,
  ) {
    emit(const SellerDashboardInitial());
  }
}
