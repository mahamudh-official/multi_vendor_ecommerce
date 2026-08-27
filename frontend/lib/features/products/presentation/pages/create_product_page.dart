import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/category.dart';
import '../bloc/category/category_bloc.dart';
import '../bloc/category/category_event.dart';
import '../bloc/category/category_state.dart';
import '../bloc/seller/seller_product_bloc.dart';
import '../bloc/seller/seller_product_event.dart';
import '../bloc/seller/seller_product_state.dart';

/// Form page for sellers to create a new product.
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
  final _comparePriceController = TextEditingController();
  final _stockController = TextEditingController(text: '10');
  final _skuController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategoryId;
  bool _isFeatured = false;

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
    _comparePriceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final price = double.parse(_priceController.text);
    final comparePrice = _comparePriceController.text.isNotEmpty
        ? double.tryParse(_comparePriceController.text)
        : null;
    final stock = int.parse(_stockController.text);

    context.read<SellerProductBloc>().add(
      SellerProductCreateSubmitted(
        name: _nameController.text.trim(),
        description: _descController.text.isNotEmpty
            ? _descController.text.trim()
            : null,
        price: price,
        compareAtPrice: comparePrice,
        stockQuantity: stock,
        sku: _skuController.text.isNotEmpty ? _skuController.text.trim() : null,
        categoryId: _selectedCategoryId!,
        imageUrl: _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        isFeatured: _isFeatured,
        sellerId: authState.user.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: BlocListener<SellerProductBloc, SellerProductState>(
        listener: (context, state) {
          if (state is SellerProductActionSuccess) {
            context.pop();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product Details', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.md),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g. Wireless Noise-Cancelling Headphones',
                  ),
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Required min 2 chars'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Category dropdown
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    List<Category> categories = [];
                    if (state is CategoryLoaded) {
                      categories = state.categories;
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                      ),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategoryId = val),
                      validator: (v) =>
                          v == null ? 'Please select a category' : null,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe key features, specs, and materials...',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text('Pricing & Inventory', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.md),

                // Price & Compare-at price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price (\$)*',
                          prefixText: '\$ ',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final p = double.tryParse(v);
                          if (p == null || p <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _comparePriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Original Price (\$)',
                          prefixText: '\$ ',
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            final cp = double.tryParse(v);
                            final p = double.tryParse(_priceController.text);
                            if (cp == null) return 'Invalid number';
                            if (p != null && cp < p) return 'Must be >= Price';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Stock & SKU
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock Qty *',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final s = int.tryParse(v);
                          if (s == null || s < 0) return 'Must be >= 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU (Optional)',
                          hintText: 'e.g. WH-1000XM4',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                Text('Media & Visibility', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.md),

                // Main Image URL
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Product Image URL',
                    hintText: 'https://images.unsplash.com/...',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Featured Switch
                SwitchListTile(
                  title: const Text('Featured Product'),
                  subtitle: const Text('Highlight on marketplace home banner'),
                  value: _isFeatured,
                  onChanged: (val) => setState(() => _isFeatured = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.xl2),

                // Submit Button
                BlocBuilder<SellerProductBloc, SellerProductState>(
                  builder: (context, state) {
                    final isLoading = state is SellerProductLoading;
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Publish Product'),
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
