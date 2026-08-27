import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/category/category_bloc.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/category/category_event.dart';
import 'package:multi_vendor_ecommerce/features/products/presentation/bloc/category/category_state.dart';
import 'package:multi_vendor_ecommerce/features/seller/presentation/bloc/seller_products/seller_products_bloc.dart';

class EditProductPage extends StatefulWidget {
  final String productId;

  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _skuController;
  late final TextEditingController _imageUrlController;

  String? _selectedCategoryId;
  bool _isActive = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();
    _skuController = TextEditingController();
    _imageUrlController = TextEditingController();

    context.read<CategoryBloc>().add(const CategoriesRequested());
    context.read<SellerProductsBloc>().add(
      SellerProductDetailsRequested(productId: widget.productId),
    );
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
      SellerProductUpdated(
        productId: widget.productId,
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
          'Edit Product',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocConsumer<SellerProductsBloc, SellerProductsState>(
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
          } else if (state is SellerProductDetailsLoaded && !_isInitialized) {
            final p = state.product;
            _nameController.text = p.name;
            _descController.text = p.description ?? '';
            _priceController.text = p.price.toStringAsFixed(2);
            _stockController.text = p.stockQuantity.toString();
            _skuController.text = p.sku ?? '';
            _imageUrlController.text = p.imageUrl ?? '';
            _selectedCategoryId = p.categoryId;
            _isActive = p.isActive;
            _isInitialized = true;
          }
        },
        builder: (context, state) {
          if (state is SellerProductsLoading && !_isInitialized) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          return SingleChildScrollView(
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
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Product name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, catState) {
                      final categories = catState is CategoryLoaded
                          ? catState.categories
                          : [];
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
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

                  // Price & Stock
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL (Optional)',
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
                          errorBuilder: (_, _, _) =>
                              const Center(child: Text('Image Preview Failed')),
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
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Active switch
                  SwitchListTile(
                    title: const Text('Active Listing'),
                    subtitle: const Text(
                      'When active, the product is visible to marketplace customers',
                    ),
                    value: _isActive,
                    activeThumbColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state is SellerProductActionLoading
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: state is SellerProductActionLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
