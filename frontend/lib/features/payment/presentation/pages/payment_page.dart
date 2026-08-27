import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_radius.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';
import 'package:multi_vendor_ecommerce/features/payment/presentation/bloc/payment_bloc.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;

  const PaymentPage({super.key, required this.orderId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _simulateFailure = false;

  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(
      PaymentIntentRequested(orderId: widget.orderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Payment'), centerTitle: true),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccessState) {
            context.go('/payment/success', extra: state.result);
          } else if (state is PaymentFailureState) {
            context.go(
              '/payment/failure',
              extra: {
                'message': state.message,
                'paymentId': state.paymentId,
                'orderId': widget.orderId,
              },
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentCreatingIntent || state is PaymentInitial) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppSpacing.md),
                  Text('Initializing payment gateway...'),
                ],
              ),
            );
          }

          if (state is PaymentProcessingState) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppSpacing.md),
                  Text('Processing demo transaction...'),
                ],
              ),
            );
          }

          if (state is PaymentIntentCreatedState) {
            final intent = state.intent;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Demo Banner ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Demo Payment Mode: No real charges will occur. This is a sandbox testing environment.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Order & Payment Summary Card ───────────────────────────
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      side: BorderSide(
                        color: isDark
                            ? AppColorsDark.outline
                            : AppColorsLight.outline,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Summary',
                            style: AppTextStyles.titleMedium,
                          ),
                          const Divider(height: AppSpacing.lg),
                          _buildRow(
                            'Order ID',
                            widget.orderId.substring(0, 8).toUpperCase(),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildRow(
                            'Gateway Provider',
                            intent.provider.toUpperCase(),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildRow('Currency', intent.currency),
                          const Divider(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Due',
                                style: AppTextStyles.titleLarge,
                              ),
                              Text(
                                '\$${intent.amount.toStringAsFixed(2)}',
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: AppColorsLight.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Testing Simulation Controls ───────────────────────────
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(
                        color: isDark
                            ? AppColorsDark.outline
                            : AppColorsLight.outline,
                      ),
                    ),
                    child: SwitchListTile(
                      title: const Text('Simulate Payment Failure'),
                      subtitle: const Text(
                        'Tests the failure handler and retry mechanisms',
                      ),
                      value: _simulateFailure,
                      onChanged: (val) {
                        setState(() => _simulateFailure = val);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Pay Now Button ────────────────────────────────────────
                  ElevatedButton(
                    onPressed: () {
                      context.read<PaymentBloc>().add(
                        PaymentProcessRequested(
                          paymentId: intent.paymentId,
                          simulateFailure: _simulateFailure,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      backgroundColor: AppColorsLight.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      'Pay \$${intent.amount.toStringAsFixed(2)} (Demo)',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
