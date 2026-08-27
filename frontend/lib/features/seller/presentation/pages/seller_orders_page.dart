import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/features/orders/domain/entities/order_status.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/bloc/seller_orders/seller_orders_bloc.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/widgets/seller_order_card.dart';

class SellerOrdersPage extends StatefulWidget {
  final String? initialStatus;

  const SellerOrdersPage({super.key, this.initialStatus});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _fetchOrders();
  }

  void _fetchOrders() {
    context.read<SellerOrdersBloc>().add(
      SellerOrdersRequested(
        status: _selectedStatus,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final filterStatuses = [
      null,
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Orders',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by order number...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchOrders();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              onSubmitted: (_) => _fetchOrders(),
            ),
          ),

          // ── Status Filter Chips ─────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: filterStatuses.map((st) {
                final isSelected = _selectedStatus == st;
                final label = st == null
                    ? 'All'
                    : OrderStatus.fromString(st).displayName;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedStatus = val ? st : null;
                      });
                      _fetchOrders();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 16),

          // ── Orders List ─────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<SellerOrdersBloc, SellerOrdersState>(
              builder: (context, state) {
                if (state is SellerOrdersLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (state is SellerOrdersFailure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchOrders,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is SellerOrdersLoaded) {
                  if (state.orders.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No seller orders found.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Orders containing your items will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: primaryColor,
                    onRefresh: () async => _fetchOrders(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) {
                        final order = state.orders[index];
                        return SellerOrderCard(
                          order: order,
                          onTap: () =>
                              context.push('/seller/orders/${order.id}'),
                        );
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
  }
}
