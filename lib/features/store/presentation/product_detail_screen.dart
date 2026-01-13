import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/cart_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // For sharing potential

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _incrementQuantity() {
    if (_quantity < widget.product.stockQuantity) {
      setState(() => _quantity++);
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final hasDiscount = p.discountPercentage > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(p.brand != null ? p.brand!.toUpperCase() : 'Product Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
          IconButton(
            onPressed: () {},
            icon: Badge(
              label: const Text('0'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Gallery Placeholder (For now single image)
                    Container(
                      height: 350,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey.shade50),
                      child: p.primaryImage != null
                          ? Image.network(
                              p.primaryImage!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
                                        SizedBox(height: 12),
                                        Text(
                                          'Could not load product image',
                                          style: TextStyle(color: Colors.grey, fontSize: 16),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '(CORS or 404 Error)',
                                          style: TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : const Center(child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey)),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Product Info Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.brand != null)
                            Text(p.brand!.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                          
                          const SizedBox(height: 16),
                          
                          // Price Row
                          Row(
                            children: [
                              Text(
                                '₹${p.discountPrice?.toInt() ?? p.price.toInt()}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '₹${p.price.toInt()}',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[500], decoration: TextDecoration.lineThrough),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${p.discountPercentage}% OFF',
                                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Stock Indicator
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.stockQuantity > 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                p.stockQuantity > 0 ? 'In Stock' : 'Out of Stock',
                                style: TextStyle(
                                  color: p.stockQuantity > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(
                            p.description ?? 'No description available.',
                            style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.6),
                          ),
                          const SizedBox(height: 100), // Bottom padding for sticky button
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Sticky Bottom Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: Row(
                children: [
                  // Quantity
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(onPressed: p.stockQuantity > 0 ? _decrementQuantity : null, icon: const Icon(Icons.remove, size: 20)),
                        Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(onPressed: p.stockQuantity > 0 ? _incrementQuantity : null, icon: const Icon(Icons.add, size: 20)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add to Cart Button
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        return ElevatedButton(
                          onPressed: p.stockQuantity > 0
                              ? () async {
                                  try {
                                    await ref
                                        .read(cartProvider.notifier)
                                        .addToCart(p.id, _quantity);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$_quantity x ${p.name} added to cart!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to add to cart: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            p.stockQuantity > 0 ? 'Add to Cart' : 'Notify Me',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
