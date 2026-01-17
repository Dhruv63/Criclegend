import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/order_model.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = [
      'pending',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
    ];
    // Logic to determine active step index.
    // If cancelled, show that separately.
    int activeStep = steps.indexOf(order.status.toLowerCase());
    if (activeStep == -1) activeStep = 0;

    final isCancelled = order.status.toLowerCase() == 'cancelled';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order.orderNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              order.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Placed on ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Timeline (Simplified for UI)
            if (!isCancelled) _OrderTimeline(currentStatus: order.status),
            if (isCancelled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'This order was cancelled.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Ordered Items
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items?.length ?? 0,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = order.items![index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        image: item.product?.primaryImage != null
                            ? DecorationImage(
                                image: NetworkImage(
                                  item.product!.primaryImage!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item.product?.primaryImage == null
                          ? const Icon(
                              Icons.image,
                              size: 20,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    title: Text(
                      item.product?.name ?? 'Product Unavailable',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Qty: ${item.quantity}  ×  ₹${item.priceAtPurchase.toInt()}',
                    ),
                    trailing: Text(
                      '₹${((item.priceAtPurchase) * item.quantity).toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Shipping & Payment Info
            const Text(
              'Shipping Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shipping Address',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.shippingAddress?['address_line1'] ?? ''}, ${order.shippingAddress?['city'] ?? ''} - ${order.shippingAddress?['zip_code'] ?? ''}',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Phone Number',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.contactPhone ?? 'N/A',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${order.totalAmount.toInt()}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _OrderTimeline extends StatelessWidget {
  final String currentStatus;

  const _OrderTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final steps = ['pending', 'processing', 'shipped', 'delivered'];
    int currentIndex = steps.indexOf(currentStatus.toLowerCase());
    if (currentIndex == -1) currentIndex = 0; // default

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentIndex;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              // Circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.primary : Colors.grey.shade300,
                  border: Border.all(
                    color: isActive ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: isActive
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              // Line
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 3,
                    color: index < currentIndex
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
