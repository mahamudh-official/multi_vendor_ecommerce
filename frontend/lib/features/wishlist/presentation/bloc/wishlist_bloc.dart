import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/add_to_wishlist_usecase.dart';
import '../../domain/usecases/clear_wishlist_usecase.dart';
import '../../domain/usecases/get_wishlist_usecase.dart';
import '../../domain/usecases/remove_from_wishlist_usecase.dart';
import 'wishlist_event.dart';
import 'wishlist_state.dart';

/// BLoC managing customer saved wishlist items and quick toggling.
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  WishlistBloc({
    required this.getWishlistUseCase,
    required this.addToWishlistUseCase,
    required this.removeFromWishlistUseCase,
    required this.clearWishlistUseCase,
  }) : super(const WishlistInitial()) {
    on<WishlistRequested>(_onWishlistRequested);
    on<WishlistRefreshed>(_onWishlistRefreshed);
    on<AddToWishlist>(_onAddToWishlist);
    on<RemoveFromWishlist>(_onRemoveFromWishlist);
    on<ToggleWishlist>(_onToggleWishlist);
    on<ClearWishlist>(_onClearWishlist);
    on<WishlistReset>(_onWishlistReset);
  }

  final GetWishlistUseCase getWishlistUseCase;
  final AddToWishlistUseCase addToWishlistUseCase;
  final RemoveFromWishlistUseCase removeFromWishlistUseCase;
  final ClearWishlistUseCase clearWishlistUseCase;

  Future<void> _onWishlistRequested(
    WishlistRequested event,
    Emitter<WishlistState> emit,
  ) async {
    emit(const WishlistLoading());
    final result = await getWishlistUseCase();
    result.fold(
      onSuccess: (items) => emit(WishlistLoaded(items: items)),
      onError: (failure) => emit(WishlistFailure(failure.message)),
    );
  }

  Future<void> _onWishlistRefreshed(
    WishlistRefreshed event,
    Emitter<WishlistState> emit,
  ) async {
    final result = await getWishlistUseCase();
    result.fold(
      onSuccess: (items) => emit(WishlistLoaded(items: items)),
      onError: (failure) => emit(WishlistFailure(failure.message)),
    );
  }

  Future<void> _onAddToWishlist(
    AddToWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    final result = await addToWishlistUseCase(event.productId);
    await result.fold(
      onSuccess: (_) async {
        final listResult = await getWishlistUseCase();
        listResult.fold(
          onSuccess: (items) =>
              emit(WishlistLoaded(items: items, message: 'Added to wishlist!')),
          onError: (failure) => emit(WishlistFailure(failure.message)),
        );
      },
      onError: (failure) async => emit(WishlistFailure(failure.message)),
    );
  }

  Future<void> _onRemoveFromWishlist(
    RemoveFromWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    final result = await removeFromWishlistUseCase(event.productId);
    await result.fold(
      onSuccess: (_) async {
        final listResult = await getWishlistUseCase();
        listResult.fold(
          onSuccess: (items) => emit(
            WishlistLoaded(items: items, message: 'Removed from wishlist.'),
          ),
          onError: (failure) => emit(WishlistFailure(failure.message)),
        );
      },
      onError: (failure) async => emit(WishlistFailure(failure.message)),
    );
  }

  Future<void> _onToggleWishlist(
    ToggleWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    final isPresent =
        state is WishlistLoaded &&
        (state as WishlistLoaded).containsProduct(event.productId);

    if (isPresent) {
      add(RemoveFromWishlist(event.productId));
    } else {
      add(AddToWishlist(event.productId));
    }
  }

  Future<void> _onClearWishlist(
    ClearWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    emit(const WishlistLoading());
    final result = await clearWishlistUseCase();
    result.fold(
      onSuccess: (_) =>
          emit(const WishlistLoaded(items: [], message: 'Wishlist cleared.')),
      onError: (failure) => emit(WishlistFailure(failure.message)),
    );
  }

  void _onWishlistReset(WishlistReset event, Emitter<WishlistState> emit) {
    emit(const WishlistInitial());
  }
}
