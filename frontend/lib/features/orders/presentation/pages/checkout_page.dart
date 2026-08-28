import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/product_image_placeholder.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/presentation/bloc/address_bloc.dart';
import '../../../addresses/presentation/bloc/address_event.dart';
import '../../../addresses/presentation/widgets/saved_address_selector.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../domain/entities/shipping_address.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

/// Premium Checkout screen collecting shipping details and submitting orders.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'USA');
  final _noteController = TextEditingController();

  Address? _selectedSavedAddress;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _fullNameController.text = authState.user.fullName;
    }
    context.read<AddressBloc>().add(const LoadAddressesEvent());
  }

  void _applySavedAddress(Address addr) {
    setState(() {
      _selectedSavedAddress = addr;
      _fullNameController.text = addr.fullName;
      _phoneController.text = addr.phone;
      _address1Controller.text = addr.addressLine1;
      _address2Controller.text = addr.addressLine2 ?? '';
      _cityController.text = addr.city;
      _stateController.text = addr.state;
      _postalCodeController.text = addr.postalCode;
      _countryController.text = addr.country;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onPlaceOrder() {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please check and fill in all required shipping fields.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final shippingAddress = ShippingAddress(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine1: _address1Controller.text.trim(),
      addressLine2: _address2Controller.text.trim().isNotEmpty
          ? _address2Controller.text.trim()
          : null,
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
    );

    context.read<OrderBloc>().add(
      CheckoutSubmitted(
        shippingAddress: shippingAddress,
        customerNote: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is CheckoutLoading) {
            setState(() => _isSubmitting = true);
          } else if (state is CheckoutSuccess) {
            setState(() => _isSubmitting = false);
            // Refresh cart so the badge resets to 0 and cart is empty
            context.read<CartBloc>().add(const CartRequested());

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Order #${state.order.orderNumber} placed successfully!',
                ),
                backgroundColor: AppColorsLight.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );

            // Navigate directly to Demo Payment screen
            context.go('/payment/${state.order.id}');
          } else if (state is OrderFailure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColorsLight.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            if (cartState is! CartLoaded || cartState.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.remove_shopping_cart_outlined, size: 64),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Your cart is empty',
                        style: AppTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Add items to your cart before proceeding to checkout.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Go Shopping'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final cart = cartState;
            final shippingFee = cart.subtotal >= 50.0 ? 0.0 : 5.0;
            final totalAmount = cart.subtotal + shippingFee;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Shipping Address ─────────────────────────────────
                    _buildSectionCard(
                      context,
                      title: '1. Shipping Address',
                      icon: Icons.local_shipping_outlined,
                      child: Column(
                        children: [
                          SavedAddressSelector(
                            selectedAddress: _selectedSavedAddress,
                            onAddressSelected: _applySavedAddress,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name *',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Full name is required'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().length < 5
                                ? 'Enter a valid phone number'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _address1Controller,
                            decoration: const InputDecoration(
                              labelText: 'Street Address *',
                              prefixIcon: Icon(Icons.home_outlined, size: 20),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Street address is required'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _address2Controller,
                            decoration: const InputDecoration(
                              labelText: 'Apt / Suite / Unit (Optional)',
                              prefixIcon: Icon(
                                Icons.apartment_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    labelText: 'City *',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'City required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _stateController,
                                  decoration: const InputDecoration(
                                    labelText: 'State / Prov *',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'State required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _postalCodeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Postal Code *',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Postal code required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _countryController,
                                  decoration: const InputDecoration(
                                    labelText: 'Country *',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Country required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── 2. Order Items Review ──────────────────────────────
                    _buildSectionCard(
                      context,
                      title: '2. Review Items (${cart.itemCount})',
                      icon: Icons.inventory_2_outlined,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: item.product.imageUrl != null
                                      ? Image.network(
                                          item.product.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const ProductImagePlaceholder(
                                                    size: 48,
                                                  ),
                                        )
                                      : const ProductImagePlaceholder(size: 48),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.titleSmall,
                                    ),
                                    Text(
                                      'Qty: ${item.quantity} × \$${item.product.price.toStringAsFixed(2)}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isDark
                                            ? AppColorsDark.onSurfaceVariant
                                            : AppColorsLight.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${item.lineTotal.toStringAsFixed(2)}',
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── 3. Payment Method Placeholder ──────────────────────
                    _buildSectionCard(
                      context,
                      title: '3. Payment Method',
                      icon: Icons.payment_outlined,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_atm_rounded,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cash on Delivery',
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Pay conveniently when your order arrives. Online payment gateways will unlock in Step 6.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColorsDark.onSurfaceVariant
                                          : AppColorsLight.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── 4. Customer Note ───────────────────────────────────
                    _buildSectionCard(
                      context,
                      title: '4. Delivery Instructions (Optional)',
                      icon: Icons.note_alt_outlined,
                      child: TextFormField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Leave package by the garage door',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── 5. Price Breakdown Summary ─────────────────────────
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark
                              ? AppColorsDark.outline
                              : AppColorsLight.outline,
                        ),
                        boxShadow: isDark ? AppShadows.smDark : AppShadows.sm,
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow('Subtotal', cart.subtotal),
                          const SizedBox(height: AppSpacing.xs),
                          _buildPriceRow(
                            'Shipping',
                            shippingFee,
                            isFree: shippingFee == 0.0,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _buildPriceRow('Estimated Tax', 0.0),
                          const Divider(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: AppTextStyles.titleMedium,
                              ),
                              Text(
                                '\$${totalAmount.toStringAsFixed(2)}',
                                style: AppTextStyles.price.copyWith(
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // ── 6. Place Order Button ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _onPlaceOrder,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          _isSubmitting
                              ? 'Placing Order...'
                              : 'Place Order • \$${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl4),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColorsDark.outline : AppColorsLight.outline,
        ),
        boxShadow: isDark ? AppShadows.smDark : AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          isFree ? 'FREE' : '\$${amount.toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isFree ? AppColorsLight.success : null,
          ),
        ),
      ],
    );
  }
}
