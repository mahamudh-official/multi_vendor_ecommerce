import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';
import 'package:multi_vendor_ecommerce/features/addresses/domain/entities/address.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_bloc.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_event.dart';
import 'package:multi_vendor_ecommerce/features/addresses/presentation/bloc/address_state.dart';

class AddEditAddressPage extends StatefulWidget {
  final Address? existingAddress;

  const AddEditAddressPage({super.key, this.existingAddress});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _line1Controller;
  late TextEditingController _line2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalController;
  late TextEditingController _countryController;
  bool _isDefault = false;

  bool get isEditing => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _nameController = TextEditingController(text: addr?.fullName ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _line1Controller = TextEditingController(text: addr?.addressLine1 ?? '');
    _line2Controller = TextEditingController(text: addr?.addressLine2 ?? '');
    _cityController = TextEditingController(text: addr?.city ?? '');
    _stateController = TextEditingController(text: addr?.state ?? '');
    _postalController = TextEditingController(text: addr?.postalCode ?? '');
    _countryController = TextEditingController(text: addr?.country ?? 'US');
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
        elevation: 0,
      ),
      body: BlocListener<AddressBloc, AddressState>(
        listener: (context, state) {
          if (state is AddressActionSuccess) {
            context.pop();
          } else if (state is AddressError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Recipient Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Full name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Contact Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _line1Controller,
                decoration: InputDecoration(
                  labelText: 'Address Line 1',
                  prefixIcon: const Icon(Icons.home_outlined),
                  hintText: 'Street address, P.O. box',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'Please enter street address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _line2Controller,
                decoration: InputDecoration(
                  labelText: 'Address Line 2 (Optional)',
                  prefixIcon: const Icon(Icons.apartment_outlined),
                  hintText: 'Apt, suite, unit, building, floor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State / Province',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'State is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postalController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Postal / ZIP Code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Postal code is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Country is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default delivery address'),
                value: _isDefault,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 28),
              BlocBuilder<AddressBloc, AddressState>(
                builder: (context, state) {
                  final inProgress = state is AddressActionInProgress;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: inProgress ? null : _saveAddress,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: inProgress
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Address' : 'Save Address',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAddress() {
    if (_formKey.currentState?.validate() ?? false) {
      if (isEditing) {
        context.read<AddressBloc>().add(
          EditAddressEvent(
            addressId: widget.existingAddress!.id,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            addressLine1: _line1Controller.text.trim(),
            addressLine2: _line2Controller.text.trim().isNotEmpty
                ? _line2Controller.text.trim()
                : null,
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            postalCode: _postalController.text.trim(),
            country: _countryController.text.trim(),
            isDefault: _isDefault,
          ),
        );
      } else {
        context.read<AddressBloc>().add(
          AddAddressEvent(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            addressLine1: _line1Controller.text.trim(),
            addressLine2: _line2Controller.text.trim().isNotEmpty
                ? _line2Controller.text.trim()
                : null,
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            postalCode: _postalController.text.trim(),
            country: _countryController.text.trim(),
            isDefault: _isDefault,
          ),
        );
      }
    }
  }
}
