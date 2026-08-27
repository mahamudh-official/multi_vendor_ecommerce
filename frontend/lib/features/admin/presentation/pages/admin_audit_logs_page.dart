import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_radius.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';

import '../../domain/entities/admin_entities.dart';
import '../bloc/admin_blocs.dart';
import '../widgets/admin_shell_scaffold.dart';

class AdminAuditLogsPage extends StatefulWidget {
  const AdminAuditLogsPage({super.key});

  @override
  State<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends State<AdminAuditLogsPage> {
  String? _selectedAction;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    context.read<AdminAuditLogsBloc>().add(
      AdminAuditLogsLoadRequested(action: _selectedAction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AdminShellScaffold(
      title: 'Platform Audit Trail',
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
                    value: _selectedAction,
                    hint: const Text('All Audit Actions'),
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Audit Actions'),
                      ),
                      DropdownMenuItem(
                        value: 'seller_approved',
                        child: Text('Seller Approved'),
                      ),
                      DropdownMenuItem(
                        value: 'seller_suspended',
                        child: Text('Seller Suspended'),
                      ),
                      DropdownMenuItem(
                        value: 'user_activated',
                        child: Text('User Activated'),
                      ),
                      DropdownMenuItem(
                        value: 'user_deactivated',
                        child: Text('User Deactivated'),
                      ),
                      DropdownMenuItem(
                        value: 'product_activated',
                        child: Text('Product Activated'),
                      ),
                      DropdownMenuItem(
                        value: 'product_deactivated',
                        child: Text('Product Deactivated'),
                      ),
                      DropdownMenuItem(
                        value: 'category_created',
                        child: Text('Category Created'),
                      ),
                      DropdownMenuItem(
                        value: 'category_updated',
                        child: Text('Category Updated'),
                      ),
                      DropdownMenuItem(
                        value: 'category_deleted',
                        child: Text('Category Deleted'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedAction = val);
                      _loadLogs();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadLogs,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Audit Logs List
          Expanded(
            child: BlocBuilder<AdminAuditLogsBloc, AdminAuditLogsState>(
              builder: (context, state) {
                if (state is AdminAuditLogsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminAuditLogsError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: _loadLogs,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AdminAuditLogsLoaded) {
                  if (state.logs.isEmpty) {
                    return const Center(child: Text('No audit logs recorded.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.logs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final log = state.logs[index];
                      return _buildAuditLogCard(context, log);
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

  Widget _buildAuditLogCard(BuildContext context, AdminAuditLog log) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColorsLight.primary.withValues(alpha: 0.15),
          child: const Icon(
            Icons.security_rounded,
            color: AppColorsLight.primary,
          ),
        ),
        title: Row(
          children: [
            Text(
              log.action.replaceAll('_', ' ').toUpperCase(),
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Entity: ${log.entityType} (${log.entityId}) • ${log.createdAt.toLocal().toString().split('.')[0]}',
          style: AppTextStyles.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin User ID: ${log.adminUserId ?? 'System'}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Metadata:',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    log.metadata.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
