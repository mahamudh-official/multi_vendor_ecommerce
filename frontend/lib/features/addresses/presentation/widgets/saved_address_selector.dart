import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/entities/address.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_bloc.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_event.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_state.dart';

class SavedAddressSelector extends StatelessWidget {
  final Address? selectedAddress;
  final ValueChanged<Address> onAddressSelected;

  const SavedAddressSelector({
    super.key,
    required this.selectedAddress,
    required this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AddressBloc, AddressState>(
      builder: (context, state) {
        List<Address> addresses = [];
        if (state is AddressLoaded) {
          addresses = state.addresses;
        }

        final effectiveAddress =
            selectedAddress ??
            (state is AddressLoaded
                ? state.defaultAddress ?? addresses.firstOrNull
                : null);

        if (effectiveAddress == null && addresses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.add_location_alt_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No delivery address saved',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Add an address to continue checkout',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await context.push('/addresses/add');
                    if (context.mounted) {
                      context.read<AddressBloc>().add(
                        const LoadAddressesEvent(),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Shipping Destination',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showAddressPicker(
                      context,
                      addresses,
                      effectiveAddress,
                    ),
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (effectiveAddress != null) ...[
                Text(
                  '${effectiveAddress.fullName} • ${effectiveAddress.phone}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  effectiveAddress.formattedSummary,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAddressPicker(
    BuildContext context,
    List<Address> addresses,
    Address? currentSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Delivery Address',
                      style: AppTextStyles.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final addr = addresses[idx];
                      final isChosen = currentSelected?.id == addr.id;

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isChosen
                                ? AppColors.primary
                                : AppColors.border,
                            width: isChosen ? 1.5 : 1.0,
                          ),
                        ),
                        title: Text(
                          addr.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          addr.formattedSummary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isChosen
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              )
                            : (addr.isDefault
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'DEFAULT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : null),
                        onTap: () {
                          onAddressSelected(addr);
                          Navigator.pop(bottomSheetCtx);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(bottomSheetCtx);
                      await context.push('/addresses/add');
                      if (context.mounted) {
                        context.read<AddressBloc>().add(
                          const LoadAddressesEvent(),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Address'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
