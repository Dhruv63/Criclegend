import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/admin_store_repository.dart';
import '../../data/admin_repository.dart';

final adminOrdersProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, status) async {
      final repo = ref.watch(adminStoreRepositoryProvider);
      return repo.getAllOrders(status: status);
    });

class OrderManagementScreen extends ConsumerStatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  ConsumerState<OrderManagementScreen> createState() =>
      _OrderManagementScreenState();
}

class _OrderManagementScreenState extends ConsumerState<OrderManagementScreen> {
  String _selectedStatus = 'All';
  final Set<String> _selectedOrderIds = {};
  final List<String> _statuses = [
    'All',
    'Pending',
    'Confirmed',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider(_selectedStatus));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Status Tabs
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
                          if (selected) {
                            setState(() {
                              _selectedStatus = status;
                              _selectedOrderIds.clear(); // Clear selection on filter change
                            });
                          }
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        backgroundColor: Colors.white,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Orders Table
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ordersAsync.when(
                      data: (orders) {
                        if (orders.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  "No orders found",
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                              columns: const [
                                DataColumn(label: Text("Order ID")),
                                DataColumn(label: Text("Customer")),
                                DataColumn(label: Text("Date")),
                                DataColumn(label: Text("Total")),
                                DataColumn(label: Text("Status")),
                                DataColumn(label: Text("Actions")),
                              ],
                              onSelectAll: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedOrderIds.addAll(orders.map((o) => o['id'].toString()));
                                  } else {
                                    _selectedOrderIds.clear();
                                  }
                                });
                              },
                              rows: orders.map((order) {
                                final id = order['id'].toString();
                                final isSelected = _selectedOrderIds.contains(id);
                                final address = order['shipping_address'] is Map
                                    ? order['shipping_address']
                                    : {};
                                final customerName = address['fullName'] ?? 'Customer';
                                final date = DateTime.parse(order['created_at']);
                                final rawStatus = order['status'] ?? 'Pending';
                                final status = rawStatus.isNotEmpty 
                                    ? rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase() 
                                    : 'Pending';

                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedOrderIds.add(id);
                                      } else {
                                        _selectedOrderIds.remove(id);
                                      }
                                    });
                                  },
                                  cells: [
                                    DataCell(Text('#${id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(customerName)),
                                    DataCell(Text(DateFormat('MMM dd, hh:mm a').format(date))),
                                    DataCell(Text('₹${order['total_amount']}')),
                                    DataCell(_StatusBadge(status: status)),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.visibility, color: Colors.blue),
                                            tooltip: 'View Details',
                                            onPressed: () => _showOrderDetail(context, order),
                                          ),
                                          if (status == 'Pending')
                                            IconButton(
                                              icon: const Icon(Icons.check_circle, color: Colors.green),
                                              tooltip: 'Confirm Order',
                                              onPressed: () => _updateOrderStatus(order, 'Confirmed'),
                                            ),
                                          if (status == 'Confirmed')
                                            IconButton(
                                              icon: const Icon(Icons.local_shipping, color: Colors.purple),
                                              tooltip: 'Mark Shipped',
                                              onPressed: () => _updateOrderStatus(order, 'Shipped'),
                                            ),
                                          if (status == 'Shipped')
                                            IconButton(
                                              icon: const Icon(Icons.done_all, color: Colors.green),
                                              tooltip: 'Mark Delivered',
                                              onPressed: () => _updateOrderStatus(order, 'Delivered'),
                                            ),
                                          if (status == 'Pending' || status == 'Confirmed')
                                            IconButton(
                                              icon: const Icon(Icons.cancel, color: Colors.red),
                                              tooltip: 'Cancel Order',
                                              onPressed: () => _updateOrderStatus(order, 'Cancelled'),
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
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      loading: () => const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bulk Actions Bar
          if (_selectedOrderIds.isNotEmpty)
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
                        "${_selectedOrderIds.length} Selected",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 24),
                      _BulkActionButton(
                        label: 'Mark Confirmed',
                        color: Colors.blueAccent,
                        onTap: () => _updateBulkStatus('Confirmed'),
                      ),
                      const SizedBox(width: 8),
                      _BulkActionButton(
                        label: 'Mark Shipped',
                        color: Colors.purpleAccent,
                        onTap: () => _updateBulkStatus('Shipped'),
                      ),
                       const SizedBox(width: 8),
                      _BulkActionButton(
                        label: 'Mark Delivered',
                        color: Colors.greenAccent,
                        onTap: () => _updateBulkStatus('Delivered'),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => setState(() => _selectedOrderIds.clear()),
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

  Future<void> _updateBulkStatus(String status) async {
    await ref.read(adminStoreRepositoryProvider).bulkUpdateOrderStatus(
      _selectedOrderIds.toList(),
      status,
    );
    setState(() => _selectedOrderIds.clear());
    ref.refresh(adminOrdersProvider(_selectedStatus));
  }

  Future<void> _updateOrderStatus(Map<String, dynamic> order, String newStatus) async {
    try {
      await ref.read(adminStoreRepositoryProvider).updateOrderStatus(order['id'].toString(), newStatus);
      if (mounted) {
        // Refresh local list
        ref.invalidate(adminOrdersProvider(_selectedStatus));
        // Refresh dashboard stats
        ref.invalidate(adminDashboardStatsProvider);
        // Refresh store analytics
        ref.invalidate(storeAnalyticsProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order #${order['id'].toString().substring(0, 8)} updated to $newStatus")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOrderDetail(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: _AdminOrderDetailDialog(
          order: order,
          onStatusUpdate: () {
            ref.invalidate(adminOrdersProvider(_selectedStatus));
            ref.invalidate(adminDashboardStatsProvider);
            ref.invalidate(storeAnalyticsProvider);
          },
        ),
      ),
    );
  }
}

class _AdminOrderDetailDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onStatusUpdate;

  const _AdminOrderDetailDialog({
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  ConsumerState<_AdminOrderDetailDialog> createState() =>
      _AdminOrderDetailDialogState();
}

class _AdminOrderDetailDialogState
    extends ConsumerState<_AdminOrderDetailDialog> {
  late Map<String, dynamic> _currentOrder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = Map.from(widget.order);
  }

  Future<void> _handleStatusUpdate(String newStatus) async {
    Map<String, dynamic>? extraData;

    // 1. Conditional Dialogs
    if (newStatus == 'Cancelled') {
      final reason = await _showCancellationDialog();
      if (reason == null) return; // User cancelled
      extraData = {'rejection_reason': reason};
    } else if (newStatus == 'Shipped') {
      final tracking = await _showShippingDialog();
      if (tracking == null) return; // User cancelled
      extraData = {'tracking_number': tracking};
    } else {
      // Simple Confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Confirm Update'),
          content: Text(
              'Are you sure you want to update order #${_currentOrder['id'].toString().substring(0, 8)} to $newStatus?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // 2. Perform Update
    setState(() => _isLoading = true);
    try {
      await ref.read(adminStoreRepositoryProvider).updateOrderStatus(
            _currentOrder['id'].toString(),
            newStatus,
            extraData: extraData,
          );
      widget.onStatusUpdate();
      if (mounted) {
        setState(() {
          _currentOrder['status'] = newStatus;
          if (extraData != null) {
            _currentOrder.addAll(extraData);
          }
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order updated to $newStatus"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showCancellationDialog() async {
    String? selectedReason;
    final reasons = [
      'Out of Stock',
      'Address Issue',
      'Customer Request',
      'Payment Failed',
      'Other'
    ];
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Order"),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Reason'),
                items: reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedReason = v),
              ),
              if (selectedReason == 'Other')
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Specify Reason'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Back")),
          TextButton(
            onPressed: () {
              if (selectedReason == null) return;
              final finalReason = selectedReason == 'Other'
                  ? controller.text
                  : selectedReason;
              Navigator.pop(ctx, finalReason);
            },
            child: const Text("Confirm Cancel",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showShippingDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Mark as Shipped"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text("Please enter the tracking number (optional)."),
             const SizedBox(height: 12),
             TextField(
               controller: controller,
               decoration: const InputDecoration(
                 labelText: 'Tracking Number',
                 border: OutlineInputBorder(),
               ),
             ),
          ],
        ),
        actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
           TextButton(
             onPressed: () => Navigator.pop(ctx, controller.text.isNotEmpty ? controller.text : 'No Tracking'),
             child: const Text("Confirm"),
           ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing build method remains the same, assuming _InfoRow isn't inside it differently than expected)
        String status = _currentOrder['status'] ?? 'Pending';
    // Fix: Normalize status casing (pending -> Pending) to match UI checks
    if (status.isNotEmpty) {
      status = status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
    final items = (_currentOrder['order_items'] as List?) ?? [];
    final addressRaw = _currentOrder['shipping_address'];
    final address = addressRaw is Map ? addressRaw : <String, dynamic>{};

    final customerName = address['fullName'] ??
        address['delivery_name'] ??
        'Not Provided';
    final phone = address['phone'] ??
        address['contact_phone'] ??
        _currentOrder['contact_phone'] ??
        'Not Provided';
    final fullAddress = address['addressLine1'] != null
        ? "${address['addressLine1']}\n${address['city'] ?? ''} ${address['pincode'] ?? ''}"
        : 'Not Provided';

    // Responsive Layout
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          width: 800,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // 1. Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order #${_currentOrder['id'].toString().substring(0, 8)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm').format(
                              DateTime.parse(_currentOrder['created_at'])),
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 2. Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusTimeline(currentStatus: status),
                      const SizedBox(height: 32),
                      if (isMobile) ...[
                        _buildItemsList(items),
                        const SizedBox(height: 24),
                        _buildCustomerDetails(customerName, phone, fullAddress),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Expanded(flex: 3, child: _buildItemsList(items)),
                             const SizedBox(width: 24),
                             Expanded(flex: 2, child: _buildCustomerDetails(customerName, phone, fullAddress)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // 3. Footer Actions
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      _buildActionButtons(status),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ... (keeping _buildItemsList, _buildCustomerDetails, _buildActionButtons same)
  Widget _buildItemsList(List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Ordered Items",
            style: TextStyle(
                color: Colors.grey[800], fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...items.map((item) {
          final product = item['products'];
          final name =
              product != null ? product['name'] : 'Unknown Product';
          final img = product != null &&
                  product['images'] != null &&
                  (product['images'] as List).isNotEmpty
              ? product['images'][0]
              : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: img != null
                        ? DecorationImage(
                            image: NetworkImage(img), fit: BoxFit.cover)
                        : null,
                  ),
                  child: img == null
                      ? const Icon(Icons.image_not_supported, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                          "Qty: ${item['quantity'] ?? 1}  x  ₹${item['price_at_purchase'] ?? 0}",
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Text(
                  "₹${((item['quantity'] ?? 1) as num) * ((item['price_at_purchase'] ?? 0) as num)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total Amount",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("₹${_currentOrder['total_amount']}",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerDetails(
      String name, String phone, String address) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Customer Details",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _InfoRow(
             icon: Icons.person_outline, 
             text: name, 
             onTap: () {} 
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.phone_outlined, 
            text: phone, 
            isCopyable: true,
            // Simple logic: if it starts with +, allow call intent later. For now just copy.
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.location_on_outlined, text: address, isCopyable: true),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String currentStatus) {
    // ... same as before
    final List<Widget> buttons = [];

    if (currentStatus == 'Pending') {
      buttons.add(OutlinedButton.icon(
        icon: const Icon(Icons.close, color: Colors.red),
        label: const Text("Cancel Order", style: TextStyle(color: Colors.red)),
        onPressed: () => _handleStatusUpdate('Cancelled'),
      ));
      buttons.add(const SizedBox(width: 12));
      buttons.add(ElevatedButton.icon(
        icon: const Icon(Icons.check),
        label: const Text("Confirm Order"),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, foregroundColor: Colors.white),
        onPressed: () => _handleStatusUpdate('Confirmed'),
      ));
    } else if (currentStatus == 'Confirmed') {
      buttons.add(OutlinedButton.icon(
        icon: const Icon(Icons.close, color: Colors.red),
        label: const Text("Cancel Order", style: TextStyle(color: Colors.red)),
        onPressed: () => _handleStatusUpdate('Cancelled'),
      ));
      buttons.add(const SizedBox(width: 12));
      buttons.add(ElevatedButton.icon(
        icon: const Icon(Icons.local_shipping),
        label: const Text("Mark Shipped"),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple, foregroundColor: Colors.white),
        onPressed: () => _handleStatusUpdate('Shipped'),
      ));
    } else if (currentStatus == 'Shipped') {
      buttons.add(ElevatedButton.icon(
        icon: const Icon(Icons.done_all),
        label: const Text("Mark Delivered"),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, foregroundColor: Colors.white),
        onPressed: () => _handleStatusUpdate('Delivered'),
      ));
    }

    if (buttons.isEmpty) {
      return Text("Order is $currentStatus",
          style: const TextStyle(fontWeight: FontWeight.bold));
    }

    return Row(children: buttons);
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
  const _StatusTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'Cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration( color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Text("Start Cancelled", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      );
    }
    
    final steps = ['Pending', 'Confirmed', 'Shipped', 'Delivered'];
    int currentIndex = steps.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0; // Default

    return Row(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final label = entry.value;
        final isCompleted = idx <= currentIndex;
        final isLast = idx == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                   Container(
                     width: 30, height: 30,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: isCompleted ? Colors.green : Colors.grey[300],
                     ),
                     child: Icon(Icons.check, size: 16, color: isCompleted ? Colors.white : Colors.grey[500]),
                   ),
                   const SizedBox(height: 4),
                   Text(label, style: TextStyle(fontSize: 12, color: isCompleted ? Colors.black : Colors.grey)),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: idx < currentIndex ? Colors.green : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 14), // align with dot center roughly
                    alignment: Alignment.center,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color _getColor() {
    switch(status) {
      case 'Pending': return Colors.orange;
      case 'Confirmed': return Colors.blue;
      case 'Shipped': return Colors.purple;
      case 'Delivered': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status, 
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isCopyable;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon, 
    required this.text, 
    this.isCopyable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) onTap!();
        if (isCopyable) {
          // TODO: Clipboard functionality (not added as per strict flutter rules without context or plugin, assuming selection area or similar)
          // For now, just SelectableText logic
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: isCopyable 
              ? SelectableText(text, style: const TextStyle(fontSize: 13, height: 1.3))
              : Text(text, style: const TextStyle(fontSize: 13, height: 1.3)),
          ),
          if (isCopyable || onTap != null)
             Icon(isCopyable ? Icons.copy : Icons.chevron_right, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BulkActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
       style: TextButton.styleFrom(
         backgroundColor: color.withOpacity(0.1),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
       ),
      child: Text(label, style: TextStyle(color: color)),
    );
  }
}
