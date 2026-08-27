import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_radius.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_spacing.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';

import '../../domain/entities/admin_entities.dart';
import '../bloc/admin_blocs.dart';
import '../widgets/admin_shell_scaffold.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCategoriesBloc>().add(AdminCategoriesLoadRequested());
  }

  void _showCategoryDialog({AdminCategory? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final imgCtrl = TextEditingController(text: category?.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category == null ? 'Create Category' : 'Edit Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Category Name *'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: imgCtrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              if (category == null) {
                context.read<AdminCategoriesBloc>().add(
                  AdminCategoryCreateRequested(
                    name: name,
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    imageUrl: imgCtrl.text.trim().isEmpty
                        ? null
                        : imgCtrl.text.trim(),
                  ),
                );
              } else {
                context.read<AdminCategoriesBloc>().add(
                  AdminCategoryUpdateRequested(
                    categoryId: category.id,
                    name: name,
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    imageUrl: imgCtrl.text.trim().isEmpty
                        ? null
                        : imgCtrl.text.trim(),
                  ),
                );
              }
              Navigator.of(ctx).pop();
            },
            child: Text(category == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellScaffold(
      title: 'Category Management',
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category'),
        onPressed: () => _showCategoryDialog(),
      ),
      body: BlocBuilder<AdminCategoriesBloc, AdminCategoriesState>(
        builder: (context, state) {
          if (state is AdminCategoriesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminCategoriesError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: () => context.read<AdminCategoriesBloc>().add(
                      AdminCategoriesLoadRequested(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AdminCategoriesLoaded) {
            if (state.categories.isEmpty) {
              return const Center(child: Text('No categories registered yet.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.categories.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final cat = state.categories[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColorsLight.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: const Icon(
                        Icons.category_rounded,
                        color: AppColorsLight.primary,
                      ),
                    ),
                    title: Text(
                      cat.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Slug: ${cat.slug} • Products: ${cat.productCount}',
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          onPressed: () => _showCategoryDialog(category: cat),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppColorsLight.error,
                          ),
                          onPressed: () {
                            if (cat.productCount > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Cannot delete category with ${cat.productCount} product(s).',
                                  ),
                                  backgroundColor: AppColorsLight.error,
                                ),
                              );
                              return;
                            }

                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Category'),
                                content: Text(
                                  'Are you sure you want to delete "${cat.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColorsLight.error,
                                    ),
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      context.read<AdminCategoriesBloc>().add(
                                        AdminCategoryDeleteRequested(cat.id),
                                      );
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
