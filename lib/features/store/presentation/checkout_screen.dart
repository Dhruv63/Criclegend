import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'providers/cart_provider.dart';
import '../data/store_repository.dart'; // Added import for storeRepositoryProvider

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);

    try {
      final cartItems = ref.read(cartProvider).value ?? [];
      final subtotal = ref.read(cartProvider.notifier).subtotal;
      final delivery = ref.read(cartProvider.notifier).deliveryCharge;
      final total = ref.read(cartProvider.notifier).totalAmount;

      final address = {
        'fullName': _nameController.text, // Store Name in Address JSON
        'addressLine1': _addressController.text,
        'city': _cityController.text,
        'pincode': _zipController.text,
        'state': '', // Optional if you add a state field
        'phone': _phoneController.text, // Store Phone in Address JSON too
      };

      await ref
          .read(storeRepositoryProvider)
          .placeOrder(
            totalAmount: total,
            shippingAddress: address,
            contactPhone: _phoneController.text,
            cartItems: cartItems,
          );

      // Refresh cart to clear it locally
      ref.read(cartProvider.notifier).refresh();

      if (mounted) {
        // Show Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text(
                  'Order Placed!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your order has been placed successfully. You can track it in My Orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/store');
                      // Optional: Redirect to My Orders?
                      // context.push('/store/orders');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Continue Shopping'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 1) {
      setState(() => _currentStep++);
    } else {
      _placeOrder();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: cartAsync.when(
        data: (cartItems) {
          if (cartItems.isEmpty) {
            return const Center(child: Text('Cart is empty'));
          }

          return Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder
                            ? null
                            : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isPlacingOrder
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentStep == 2
                                    ? 'PAY & PLACE ORDER'
                                    : 'CONTINUE',
                              ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isPlacingOrder
                              ? null
                              : details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('BACK'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              // Step 1: Shipping
              Step(
                title: const Text('Shipping'),
                state: _currentStep > 0
                    ? StepState.complete
                    : StepState.indexed,
                isActive: _currentStep >= 0,
                content: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address Line 1',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _zipController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Pincode',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),

              // Step 2: Review
              Step(
                title: const Text('Review Order'),
                state: _currentStep > 1
                    ? StepState.complete
                    : StepState.indexed,
                isActive: _currentStep >= 1,
                content: Column(
                  children: [
                    ...cartItems.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                            image: item.product?.primaryImage != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      item.product!.primaryImage!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                        title: Text(
                          item.product?.name ?? 'Unknown',
                          maxLines: 1,
                        ),
                        subtitle: Text('Qty: ${item.quantity}'),
                        trailing: Text(
                          '₹${((item.product?.discountPrice ?? item.product?.price ?? 0) * item.quantity).toInt()}',
                        ),
                      ),
                    ),
                    const Divider(),
                    _SummaryRow(
                      label: 'Total Amount',
                      value:
                          '₹${ref.read(cartProvider.notifier).totalAmount.toInt()}',
                      isBold: true,
                    ),
                  ],
                ),
              ),

              // Step 3: Payment
              Step(
                title: const Text('Payment'),
                isActive: _currentStep >= 2,
                content: Column(
                  children: [
                    RadioListTile(
                      value: 'cod',
                      groupValue: 'cod',
                      onChanged: (_) {},
                      title: const Text('Cash on Delivery'),
                      subtitle: const Text('Pay with cash upon delivery'),
                      activeColor: AppColors.primary,
                      secondary: const Icon(Icons.money),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'More payment options coming soon!',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.primary : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
