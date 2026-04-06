import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/catalog_service.dart';
import '../../services/input_security_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';

class StoreProductsScreen extends StatefulWidget {
  const StoreProductsScreen({super.key});

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  static const int _maxProductNameLength = 80;
  static const int _maxUnitLength = 20;
  static const int _maxDescriptionLength = 220;

  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final catalog = context.watch<CatalogService>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Sign in as a store owner to manage products.'),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: SupabaseService.isInitialized
          ? SupabaseService.getStoreByOwner(user.id)
          : Future.value(null),
      builder: (context, storeSnapshot) {
        final storeRow = storeSnapshot.data;
        final storeId = (storeRow?['id'] ?? '').toString();
        final categoryList = catalog.categories;
        final visibleProducts = catalog.products.where((product) {
          final belongsToStore =
              storeId.isNotEmpty && product.storeId == storeId;
          final matchesCategory =
              _selectedCategory == 'all' ||
              product.categoryId == _selectedCategory;
          final matchesSearch =
              _searchQuery.isEmpty ||
              product.name.toLowerCase().contains(_searchQuery.toLowerCase());
          return belongsToStore && matchesCategory && matchesSearch;
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Manage Products')),
          body: Column(
            children: [
              if (storeId.isEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Complete store profile setup first. Product publishing unlocks after your store is created.',
                    style: TextStyle(
                      color: Color(0xFF7A3F00),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Search your products',
                    prefixIcon: Icon(Icons.search, color: AppTheme.textLight),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildFilterChip('all', 'All'),
                    ...categoryList.map(
                      (category) =>
                          _buildFilterChip(category.id, category.name),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${visibleProducts.length} products',
                      style: const TextStyle(color: AppTheme.textMedium),
                    ),
                    TextButton.icon(
                      onPressed: storeId.isEmpty || _isSaving
                          ? null
                          : () => _showProductDialog(
                              context,
                              categoryList: categoryList,
                              storeId: storeId,
                            ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'No live products found for this store.',
                          style: TextStyle(
                            color: AppTheme.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: catalog.load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: visibleProducts.length,
                          itemBuilder: (context, index) {
                            final product = visibleProducts[index];
                            return _ProductTile(
                              product: product,
                              onEdit: () => _showProductDialog(
                                context,
                                categoryList: categoryList,
                                storeId: storeId,
                                initial: product,
                              ),
                              onToggleStock: () =>
                                  _toggleStock(context, product, catalog),
                              onDelete: () => _deleteProduct(
                                context,
                                product: product,
                                catalog: catalog,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMedium,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = id),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryRed,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryRed : AppTheme.divider,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleStock(
    BuildContext context,
    Product product,
    CatalogService catalog,
  ) async {
    if (!SupabaseService.isInitialized) return;
    setState(() => _isSaving = true);
    try {
      await SupabaseService.updateProduct(product.id, {
        'in_stock': !product.inStock,
      });
      await catalog.load();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update stock status. $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteProduct(
    BuildContext context, {
    required Product product,
    required CatalogService catalog,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Delete ${product.name} from this store catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    if (!SupabaseService.isInitialized) return;
    setState(() => _isSaving = true);
    try {
      await SupabaseService.deleteProduct(product.id);
      await catalog.load();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete product. $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showProductDialog(
    BuildContext context, {
    required List<Category> categoryList,
    required String storeId,
    Product? initial,
  }) async {
    if (!SupabaseService.isInitialized) return;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initial?.name ?? '');
    final descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    final priceController = TextEditingController(
      text: initial == null ? '' : initial.price.toStringAsFixed(0),
    );
    final unitController = TextEditingController(
      text: initial?.unit ?? 'piece',
    );
    final imageController = TextEditingController(
      text: initial?.imageUrl ?? '',
    );
    var categoryId =
        initial?.categoryId ??
        (categoryList.isNotEmpty ? categoryList.first.id : '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initial == null ? 'Add Product' : 'Edit Product'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        maxLength: _maxProductNameLength,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                        ),
                        validator: (value) {
                          final sanitized =
                              InputSecurityService.sanitizePlainText(
                                value ?? '',
                                maxLength: _maxProductNameLength,
                              );
                          if (sanitized.length < 2) {
                            return 'Enter a valid product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        maxLength: _maxDescriptionLength,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Price'),
                        validator: (value) {
                          final price = double.tryParse((value ?? '').trim());
                          if (price == null || price <= 0 || price > 100000) {
                            return 'Enter a valid price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: unitController,
                        maxLength: _maxUnitLength,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        validator: (value) {
                          final sanitized =
                              InputSecurityService.sanitizePlainText(
                                value ?? '',
                                maxLength: _maxUnitLength,
                              );
                          if (sanitized.isEmpty) {
                            return 'Enter a valid unit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: categoryId.isEmpty ? null : categoryId,
                        items: categoryList
                            .map(
                              (category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => categoryId = value ?? ''),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Choose a category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: imageController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL (optional)',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final name = InputSecurityService.sanitizePlainText(
                        nameController.text,
                        maxLength: _maxProductNameLength,
                      );
                      final description =
                          InputSecurityService.sanitizePlainText(
                            descriptionController.text,
                            maxLength: _maxDescriptionLength,
                          );
                      final unit = InputSecurityService.sanitizePlainText(
                        unitController.text,
                        maxLength: _maxUnitLength,
                      );
                      final imageUrl = imageController.text.trim();
                      final price = double.parse(priceController.text.trim());
                      final payload = <String, dynamic>{
                        'name': name,
                        'description': description,
                        'price': price,
                        'unit': unit,
                        'image_url': imageUrl,
                        'category_id': categoryId,
                        'store_id': storeId,
                        'in_stock': true,
                        'stock_quantity': initial?.stockQuantity ?? 100,
                      };

                      Navigator.pop(dialogContext);
                      setState(() => _isSaving = true);
                      final catalog = context.read<CatalogService>();
                      try {
                        if (initial == null) {
                          await SupabaseService.addProduct(payload);
                        } else {
                          await SupabaseService.updateProduct(
                            initial.id,
                            payload,
                          );
                        }
                        await catalog.load();
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                initial == null
                                    ? 'Could not add product. $error'
                                    : 'Could not update product. $error',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isSaving = false);
                        }
                      }
                    },
              child: Text(initial == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onToggleStock,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onToggleStock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AppImage(
            imageUrl: product.imageUrl,
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${product.price.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: product.inStock
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : AppTheme.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.inStock ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 11,
                          color: product.inStock
                              ? AppTheme.success
                              : AppTheme.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.unit,
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textLight),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                  break;
                case 'toggle':
                  onToggleStock();
                  break;
                case 'delete':
                  onDelete();
                  break;
                default:
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'toggle', child: Text('Toggle Stock')),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.primaryRed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
