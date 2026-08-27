import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../bloc/category/category_bloc.dart';
import '../bloc/category/category_event.dart';
import '../bloc/category/category_state.dart';
import '../bloc/seller/seller_product_bloc.dart';
import '../bloc/seller/seller_product_event.dart';
import '../bloc/seller/seller_product_state.dart';

/// Form page for sellers to edit an existing product.
class EditProductPage extends StatefulWidget {
  const EditProductPage({super.key, required this.product});

  final Product product;

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _comparePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _skuController;
  late final TextEditingController _imageUrlController;

  late String _selectedCategoryId;
  late bool _isFeatured;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descController = TextEditingController(
      text: widget.product.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product.price.toStringAsFixed(2),
    );
    _comparePriceController = TextEditingController(
      text: widget.product.compareAtPrice != null
          ? widget.product.compareAtPrice!.toStringAsFixed(2)
          : '',
    );
    _stockController = TextEditingController(
      text: widget.product.stockQuantity.toString(),
    );
    _skuController = TextEditingController(text: widget.product.sku ?? '');
    _imageUrlController = TextEditingController(
      text: widget.product.imageUrl ?? '',
    );
    _selectedCategoryId = widget.product.category.id;
    _isFeatured = widget.product.isFeatured;
    _isActive = widget.product.isActive;

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

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final price = double.parse(_priceController.text);
    final comparePrice = _comparePriceController.text.isNotEmpty
        ? double.tryParse(_comparePriceController.text)
        : null;
    final stock = int.parse(_stockController.text);

    context.read<SellerProductBloc>().add(
      SellerProductUpdateSubmitted(
        id: widget.product.id,
        name: _nameController.text.trim(),
        description: _descController.text.isNotEmpty
            ? _descController.text.trim()
            : null,
        price: price,
        compareAtPrice: comparePrice,
        stockQuantity: stock,
        sku: _skuController.text.isNotEmpty ? _skuController.text.trim() : null,
        categoryId: _selectedCategoryId,
        imageUrl: _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        isFeatured: _isFeatured,
        isActive: _isActive,
        sellerId: authState.user.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
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
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategoryId = val);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
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
                        decoration: const InputDecoration(labelText: 'SKU'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                Text('Media & Status', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.md),

                // Image URL
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Product Image URL',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Active Switch
                SwitchListTile(
                  title: const Text('Active Listing'),
                  subtitle: const Text(
                    'Visible to shoppers in marketplace search',
                  ),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  contentPadding: EdgeInsets.zero,
                ),

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
                            : const Text('Save Changes'),
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
