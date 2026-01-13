import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/admin_store_repository.dart';

final adminOrdersProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String?>((ref, status) async {
  final repo = ref.watch(adminStoreRepositoryProvider);
  return repo.getAllOrders(status: status);
});

class OrderManagementScreen extends ConsumerStatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  ConsumerState<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends ConsumerState<OrderManagementScreen> {
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider(_selectedStatus));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Orders", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),

            // Filters
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statuses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final status = _statuses[index];
                  final isSelected = status == _selectedStatus;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedStatus = status);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    backgroundColor: Colors.white,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // List
            Expanded(
              child: ordersAsync.when(
                data: (orders) {
                   if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("No orders found", style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      );
                    }
                  
                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _AdminOrderCard(
                        order: order,
                        onStatusUpdate: () => ref.refresh(adminOrdersProvider(_selectedStatus)),
                      );
                    },
                  );
                },
                error: (err, stack) => Center(child: Text('Error: $err')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerWidget {
  final Map<String, dynamic> order;
  final VoidCallback onStatusUpdate;

  const _AdminOrderCard({required this.order, required this.onStatusUpdate});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Confirmed': return Colors.blue;
      case 'Shipped': return Colors.purple;
      case 'Delivered': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = order['status'] ?? 'Pending';
    final date = DateTime.parse(order['created_at']);
    final total = order['total_amount'] ?? 0;
    final items = (order['order_items'] as List?) ?? [];
    
    // Extract customer info broadly since metadata structure varies
    final address = order['shipping_address'] is Map ? order['shipping_address'] : {};
    final customerName = address['fullName'] ?? 'Customer';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Text('#${order['id'].toString().substring(0, 8)}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('₹$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text('$customerName • ${DateFormat('MMM dd, yyyy hh:mm a').format(date)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text("Items", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map((item) {
             final product = item['products']; // Nested due to query
             final name = product != null ? product['name'] : 'Unknown Product';
             final price = (item['unit_price'] as num?) ?? 0;
             final qty = (item['quantity'] as num?) ?? 0;
             return Padding(
               padding: const EdgeInsets.symmetric(vertical: 4),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text('${qty}x $name', style: const TextStyle(fontSize: 14)),
                   Text('₹${price * qty}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                 ],
               ),
             );
          }).toList(),
          const Divider(),
          const Text("Update Status", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'].map((s) {
              final isCurrent = s == status;
              return ActionChip(
                label: Text(s),
                backgroundColor: isCurrent ? _getStatusColor(s).withOpacity(0.2) : Colors.grey.shade100,
                labelStyle: TextStyle(color: isCurrent ? _getStatusColor(s) : Colors.black87),
                onPressed: isCurrent ? null : () async {
                   await ref.read(adminStoreRepositoryProvider).updateOrderStatus(order['id'], s);
                   onStatusUpdate();
                },
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
