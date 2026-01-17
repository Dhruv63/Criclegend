import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../store/domain/product_model.dart';
import '../../data/admin_store_repository.dart';
import 'add_edit_product_screen.dart';
import '../../../../core/presentation/widgets/loading/shimmer_list.dart';
import '../../../../core/presentation/widgets/error/error_banner.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

final adminProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, String?>((ref, query) async {
      final repo = ref.watch(adminStoreRepositoryProvider);
      return repo.getProducts(query: query);
    });

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive
  String _categoryFilter = 'All'; // All, Bats, Balls, etc.
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedProductIds = {};

  @override
  Widget build(BuildContext context) {
    // Pass filters to provider (updated provider signature needed or handle locally)
    // For now, we fetch all and filter client side if list is small, or update provider.
    // Let's update provider to accept more params or just filter here for MVP responsiveness.
    // Provider currently only takes query. Let's filter locally for now since we have full list.
    
    final productsAsync = ref.watch(adminProductsProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => _openAddEditProduct(context),
            icon: const Icon(Icons.add),
            tooltip: "Add Product",
          )
        ],
      ),
      backgroundColor: Colors.grey[50], // Consistent background
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Filters & Search
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  hintText: 'Search products by name...',
                                  border: InputBorder.none,
                                  isDense: true, 
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                onChanged: (val) {
                                  setState(() => _searchQuery = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Status Filter
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _statusFilter,
                                decoration: const InputDecoration(
                                  labelText: "Status",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                ),
                                items: ['All', 'Active', 'Inactive']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) => setState(() => _statusFilter = val!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Category Filter
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _categoryFilter,
                                decoration: const InputDecoration(
                                  labelText: "Category",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                ),
                                items: ['All', 'Bats', 'Balls', 'Kit', 'Clothing', 'Accessories']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) => setState(() => _categoryFilter = val!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Table
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: productsAsync.when(
                      data: (allProducts) {
                        // Apply Filters
                        final products = allProducts.where((p) {
                          final matchesStatus = _statusFilter == 'All' ||
                              (_statusFilter == 'Active' ? p.isActive : !p.isActive);
                          final matchesCategory = _categoryFilter == 'All' ||
                              p.category == _categoryFilter;
                          return matchesStatus && matchesCategory;
                        }).toList();

                        if (products.isEmpty) {
                          return const Center(child: Text("No products found matching filters."));
                        }
                        
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                              columns: const [
                                DataColumn(label: Text("Product")),
                                DataColumn(label: Text("Category")),
                                DataColumn(label: Text("Price")),
                                DataColumn(label: Text("Stock")),
                                DataColumn(label: Text("Status")),
                                DataColumn(label: Text("Actions")),
                              ],
                              onSelectAll: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedProductIds.addAll(products.map((p) => p.id));
                                  } else {
                                    _selectedProductIds.clear();
                                  }
                                });
                              },
                              rows: products.map((product) {
                                final isSelected = _selectedProductIds.contains(product.id);
                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedProductIds.add(product.id);
                                      } else {
                                        _selectedProductIds.remove(product.id);
                                      }
                                    });
                                  },
                                  cells: [
                                    DataCell(
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(4),
                                              color: Colors.grey.shade200,
                                              image: product.primaryImage != null
                                                  ? DecorationImage(
                                                      image: CachedNetworkImageProvider(product.primaryImage!),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(product.category)),
                                    DataCell(Text('₹${product.price}')),
                                    DataCell(
                                      Text(
                                        '${product.stockQuantity}',
                                        style: TextStyle(
                                          color: product.stockQuantity < 10 ? Colors.red : Colors.black,
                                          fontWeight: product.stockQuantity < 10 ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: product.isActive ? Colors.green.shade100 : Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          product.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: product.isActive ? Colors.green.shade800 : Colors.red.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                            onPressed: () => _openAddEditProduct(context, product: product),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                      error: (err, stack) => Center(child: ErrorBanner(message: "Error: $err", onRetry: () => ref.refresh(adminProductsProvider(_searchQuery)))),
                      loading: () => const ShimmerList(itemCount: 8, itemHeight: 60),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bulk Actions Bar
          if (_selectedProductIds.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${_selectedProductIds.length} Selected",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 24),
                      TextButton.icon(
                        onPressed: () => _updateBulkStatus(true),
                        icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                        label: const Text("Activate", style: TextStyle(color: Colors.greenAccent)),
                      ),
                      TextButton.icon(
                        onPressed: () => _updateBulkStatus(false),
                        icon: const Icon(Icons.cancel, color: Colors.orangeAccent),
                        label: const Text("Deactivate", style: TextStyle(color: Colors.orangeAccent)),
                      ),
                      Container(height: 20, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8)),
                      TextButton.icon(
                        onPressed: _confirmBulkDelete,
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        label: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _selectedProductIds.clear()),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updateBulkStatus(bool isActive) async {
      await ref.read(adminStoreRepositoryProvider).bulkUpdateProductStatus(
        _selectedProductIds.toList(),
        isActive,
      );
      setState(() => _selectedProductIds.clear());
      ref.refresh(adminProductsProvider(_searchQuery));
  }

  Future<void> _confirmBulkDelete() async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete ${_selectedProductIds.length} Products?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
       await ref.read(adminStoreRepositoryProvider).bulkDeleteProducts(_selectedProductIds.toList());
       setState(() => _selectedProductIds.clear());
       ref.refresh(adminProductsProvider(_searchQuery));
    }
  }

  void _openAddEditProduct(BuildContext context, {Product? product}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
    );
    ref.refresh(adminProductsProvider(_searchQuery));
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product?"),
        content: Text(
          "Are you sure you want to delete '${product.name}'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(adminStoreRepositoryProvider)
                  .deleteProduct(product.id);
              ref.refresh(adminProductsProvider(_searchQuery));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product deleted")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
