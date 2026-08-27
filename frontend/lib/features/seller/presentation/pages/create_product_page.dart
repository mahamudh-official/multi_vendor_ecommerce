import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/category/category_bloc.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/category/category_event.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/category/category_state.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/bloc/seller_products/seller_products_bloc.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategoryId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const CategoriesRequested());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    context.read<SellerProductsBloc>().add(
      SellerProductCreated(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        price: price,
        stockQuantity: stock,
        categoryId: _selectedCategoryId!,
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Product',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocListener<SellerProductsBloc, SellerProductsState>(
        listener: (context, state) {
          if (state is SellerProductActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            context.pop();
          } else if (state is SellerProductsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g. Wireless Noise-Cancelling Headphones',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Product name is required';
                    }
                    if (val.trim().length < 2) {
                      return 'Must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    final categories = state is CategoryLoaded
                        ? state.categories
                        : [];
                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        hintText: 'Select category',
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategoryId = val);
                      },
                      validator: (val) =>
                          val == null ? 'Please select a category' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Price & Stock Quantity Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price (\$) *',
                          hintText: '99.99',
                          prefixText: '\$ ',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Price is required';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter valid price > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity *',
                          hintText: '10',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Stock is required';
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Enter valid stock >= 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // SKU & Image URL
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU (Optional)',
                    hintText: 'e.g. HEAD-001',
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (Optional)',
                    hintText: 'https://example.com/image.jpg',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_imageUrlController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      child: Image.network(
                        _imageUrlController.text.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text(
                            'Image Preview Failed',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Describe your product features and details...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Active toggle
                SwitchListTile(
                  title: const Text('Active Listing'),
                  subtitle: const Text(
                    'When active, the product is visible to marketplace customers',
                  ),
                  value: _isActive,
                  activeColor: primaryColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                const SizedBox(height: 24),

                // Submit Button
                BlocBuilder<SellerProductsBloc, SellerProductsState>(
                  builder: (context, state) {
                    final isLoading = state is SellerProductActionLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Product Listing',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
