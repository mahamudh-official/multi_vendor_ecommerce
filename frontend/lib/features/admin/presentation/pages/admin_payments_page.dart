import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_radius.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';

import '../../domain/entities/admin_entities.dart';
import '../bloc/admin_blocs.dart';
import '../widgets/admin_shell_scaffold.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  void _loadPayments() {
    context.read<AdminPaymentsBloc>().add(
      AdminPaymentsLoadRequested(status: _selectedStatus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AdminShellScaffold(
      title: 'Payment Gateway Monitoring',
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: isDark ? AppColorsDark.surface : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String?>(
                    value: _selectedStatus,
                    hint: const Text('All Payment Statuses'),
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Payment Statuses'),
                      ),
                      DropdownMenuItem(
                        value: 'succeeded',
                        child: Text('Succeeded'),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(value: 'failed', child: Text('Failed')),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedStatus = val);
                      _loadPayments();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadPayments,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Payments List
          Expanded(
            child: BlocBuilder<AdminPaymentsBloc, AdminPaymentsState>(
              builder: (context, state) {
                if (state is AdminPaymentsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminPaymentsError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: _loadPayments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AdminPaymentsLoaded) {
                  if (state.payments.isEmpty) {
                    return const Center(
                      child: Text('No payment records found.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.payments.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final payment = state.payments[index];
                      return _buildPaymentCard(context, payment);
                    },
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

  Widget _buildPaymentCard(BuildContext context, AdminPayment payment) {
    final status = payment.status.toLowerCase();
    Color badgeColor = Colors.orange;
    if (status == 'succeeded') badgeColor = Colors.green;
    if (status == 'failed') badgeColor = Colors.red;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor.withValues(alpha: 0.15),
          child: Icon(Icons.payment_rounded, color: badgeColor),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${payment.amount.toStringAsFixed(2)} ${payment.currency}',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                payment.status.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Order: ${payment.orderNumber ?? payment.orderId} • Provider: ${payment.provider.toUpperCase()}',
              style: AppTextStyles.bodySmall,
            ),
            if (payment.customerEmail != null)
              Text(
                'Customer: ${payment.customerEmail}',
                style: AppTextStyles.bodySmall,
              ),
            Text(
              'Date: ${payment.createdAt.toLocal().toString().split('.')[0]}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
