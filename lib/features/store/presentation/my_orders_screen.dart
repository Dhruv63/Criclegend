import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import '../../../../core/theme/app_colors.dart';
import '../data/store_repository.dart';
import '../domain/order_model.dart';
import 'providers/cart_provider.dart';

final myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  return await ref.read(storeRepositoryProvider).getMyOrders();
});

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      backgroundColor: Colors.grey.shade50,
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
             return const Center(child: Text('No orders yet.')); 
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(order.createdAt);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.status == 'delivered' ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    color: order.status == 'delivered' ? Colors.green.shade700 : Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Placed on $dateStr', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const Divider(height: 24),
          if (order.items != null) ...[
             for (var item in order.items!.take(2)) // Show first 2 items preview
               Padding(
                 padding: const EdgeInsets.only(bottom: 4),
                     // Product with Image
                     child: Row(
                       children: [
                         // Image
                         Container(
                           width: 50,
                           height: 50,
                           decoration: BoxDecoration(
                             color: Colors.grey.shade100,
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(color: Colors.grey.shade200),
                           ),
                           child: item.product?.primaryImage != null
                               ? ClipRRect(
                                   borderRadius: BorderRadius.circular(8),
                                   child: Image.network(
                                     item.product!.primaryImage!,
                                     fit: BoxFit.cover,
                                     errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                   ),
                                 )
                               : const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                         ),
                         const SizedBox(width: 12),
                         // Details
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 item.product?.name ?? 'Unknown Product',
                                 style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                               Text(
                                 'Qty: ${item.quantity}',
                                 style: TextStyle(color: Colors.grey[600], fontSize: 12),
                               ),
                             ],
                           ),
                         ),
                         Text(
                            '₹${item.subtotal.toInt()}',
                             style: const TextStyle(fontWeight: FontWeight.w600),
                         ),
                       ],
                     ),
               ),
              if (order.items!.length > 2)
                 Text('+ ${order.items!.length - 2} more items', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
               Text('₹${order.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
             ],
          ),
        ],
      ),
    );
  }
}
