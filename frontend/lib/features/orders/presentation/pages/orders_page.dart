import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/order_status.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/order_card.dart';

/// Premium Order History page supporting status filtering and pull-to-refresh.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  OrderStatus? _selectedStatus;
  String _selectedSort = 'newest';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<OrderBloc>().add(
      OrdersRequested(
        status: _selectedStatus,
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        sort: _selectedSort,
      ),
    );
  }

  void _onStatusFilterSelected(OrderStatus? status) {
    setState(() => _selectedStatus = status);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Orders')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 64),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sign In to View Orders',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Please sign in to track your current purchases and view past order history.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: () => context.push('/auth/login'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('My Orders')),
          body: Column(
            children: [
              // ── Search & Sort Bar ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search order number (e.g. ORD-...)',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      initialValue: _selectedSort,
                      icon: const Icon(Icons.sort_rounded),
                      tooltip: 'Sort Orders',
                      onSelected: (val) {
                        setState(() => _selectedSort = val);
                        _applyFilters();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'newest',
                          child: Text('Newest First'),
                        ),
                        PopupMenuItem(
                          value: 'oldest',
                          child: Text('Oldest First'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Status Filter Chips ──────────────────────────────────────
              SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedStatus == null,
                      onSelected: (_) => _onStatusFilterSelected(null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...OrderStatus.values.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          avatar: Icon(
                            status.icon,
                            size: 14,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : status.color,
                          ),
                          label: Text(status.displayName),
                          selected: isSelected,
                          onSelected: (_) => _onStatusFilterSelected(status),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Order List / States ──────────────────────────────────────
              Expanded(
                child: BlocBuilder<OrderBloc, OrderState>(
                  builder: (context, state) {
                    if (state is OrderLoading || state is OrderInitial) {
                      return _buildLoadingSkeleton(isDark);
                    }

                    if (state is OrderFailure) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: AppColorsLight.error,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Failed to load orders',
                                style: AppTextStyles.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(state.message, textAlign: TextAlign.center),
                              const SizedBox(height: AppSpacing.lg),
                              FilledButton.tonal(
                                onPressed: () => context.read<OrderBloc>().add(
                                  OrdersRequested(status: _selectedStatus),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is OrdersLoaded) {
                      if (state.orders.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xl4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColorsDark.surfaceContainer
                                        : AppColorsLight.surfaceContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    size: 56,
                                    color: isDark
                                        ? AppColorsDark.onSurfaceVariant
                                        : AppColorsLight.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                Text(
                                  _selectedStatus == null
                                      ? 'No Orders Yet'
                                      : 'No ${_selectedStatus!.displayName} Orders',
                                  style: AppTextStyles.headlineSmall,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Explore our marketplace catalog and order items with one-tap checkout.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColorsDark.onSurfaceVariant
                                        : AppColorsLight.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl2),
                                FilledButton(
                                  onPressed: () => context.go('/home'),
                                  child: const Text('Start Shopping'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<OrderBloc>().add(
                            OrdersRefreshed(status: _selectedStatus),
                          );
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: state.orders.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            return OrderCard(order: state.orders[index]);
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: isDark
                ? AppColorsDark.surfaceContainer
                : AppColorsLight.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
