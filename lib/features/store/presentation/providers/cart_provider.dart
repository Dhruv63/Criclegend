import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/store_repository.dart';
import '../../domain/cart_item_model.dart';

final cartProvider = AsyncNotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

class CartNotifier extends AsyncNotifier<List<CartItem>> {
  @override
  Future<List<CartItem>> build() async {
    final repo = ref.read(storeRepositoryProvider);
    return await repo.getCart();
  }

  // Refresh cart
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref.read(storeRepositoryProvider).getCart();
    });
  }

  // Add Item
  Future<void> addToCart(String productId, int quantity) async {
    await ref.read(storeRepositoryProvider).addToCart(productId, quantity);
    await refresh(); // Reload to get updated IDs and details
  }

  // Update Quantity
  Future<void> updateQuantity(String cartId, int newQuantity) async {
    // Optimistic Update
    final previousState = state.value;
    if (previousState != null) {
      state = AsyncValue.data(
        previousState.map((item) {
          if (item.id == cartId) {
            return CartItem(
              id: item.id,
              userId: item.userId,
              productId: item.productId,
              quantity: newQuantity,
              product: item.product,
            );
          }
          return item;
        }).toList(),
      );
    }

    try {
      if (newQuantity <= 0) {
        await ref.read(storeRepositoryProvider).removeFromCart(cartId);
      } else {
        await ref
            .read(storeRepositoryProvider)
            .updateCartQuantity(cartId, newQuantity);
      }
      await refresh(); // Ensure sync
    } catch (e) {
      // Revert on error
      if (previousState != null) state = AsyncValue.data(previousState);
      rethrow;
    }
  }

  // Remove Item
  Future<void> removeItem(String cartId) async {
    // Optimistic Update
    final previousState = state.value;
    if (previousState != null) {
      state = AsyncValue.data(
        previousState.where((item) => item.id != cartId).toList(),
      );
    }

    try {
      await ref.read(storeRepositoryProvider).removeFromCart(cartId);
      await refresh();
    } catch (e) {
      if (previousState != null) state = AsyncValue.data(previousState);
      rethrow;
    }
  }

  // Calculations
  double get subtotal {
    if (state.value == null) return 0;
    return state.value!.fold(0, (sum, item) {
      final price = item.product?.discountPrice ?? item.product?.price ?? 0;
      return sum + (price * item.quantity);
    });
  }

  double get deliveryCharge {
    if (subtotal == 0) return 0;
    return subtotal > 1000 ? 0 : 50;
  }

  bool get hasFreeDelivery => subtotal > 1000;
  double get remainingForFreeDelivery => subtotal > 1000 ? 0 : 1000 - subtotal;

  double get totalAmount => subtotal + deliveryCharge;

  int get itemCount {
    if (state.value == null) return 0;
    return state.value!.fold(0, (sum, item) => sum + item.quantity);
  }
}
