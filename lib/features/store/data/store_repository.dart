import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added for Provider
import '../domain/product_model.dart';
import '../domain/cart_item_model.dart';
import '../domain/order_model.dart';

final storeRepositoryProvider = Provider((ref) => StoreRepository());

class StoreRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch all active products with Pagination, Search, Category, and Sorting
  Future<List<Product>> getProducts({
    String? category,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
    String sortBy = 'newest', // 'price_asc', 'price_desc', 'discount', 'newest'
  }) async {
    try {
      // Use dynamic to allow changing from FilterBuilder to TransformBuilder
      dynamic query = _client.from('products').select().eq('is_active', true);

      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      // Sorting Logic
      switch (sortBy) {
        case 'price_asc':
          query = query.order('price', ascending: true);
          break;
        case 'price_desc':
          query = query.order('price', ascending: false);
          break;
        case 'discount':
          // Sort by discount_percentage if using custom logic, or just a placeholder for now
          // Ideally: query.order('discount_percentage', ascending: false);
          query = query.order('created_at', ascending: false); // Fallback
          break;
        case 'newest':
        default:
          query = query.order('created_at', ascending: false);
      }

      // Pagination
      query = query.range(offset, offset + limit - 1);

      final response = await query;

      final data = response as List<dynamic>;
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Failed to load products: $e');
    }
  }

  // Fetch single product details
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', id)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }

  // Fetch similar products
  Future<List<Product>> getSimilarProducts(
    String category,
    String currentId,
  ) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('category', category)
          .neq('id', currentId) // Exclude current product
          .eq('is_active', true)
          .limit(4);

      final data = response as List<dynamic>;
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching similar products: $e');
      return []; // Return empty list on error to not block UI
    }
  }

  // --- CART OPERATIONS ---

  // Fetch Cart Items with Product details
  Future<List<CartItem>> getCart() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('cart')
          .select('*, products(*)') // Join with products table
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => CartItem.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching cart: $e');
      throw Exception('Failed to load cart');
    }
  }

  // Add Item to Cart
  Future<void> addToCart(String productId, int quantity) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      // Check if item exists in cart to update quantity instead
      // Note: 'upsert' works if we have a unique constraint on (user_id, product_id)
      await _client.from('cart').upsert({
        'user_id': userId,
        'product_id': productId,
        'quantity':
            quantity, // In a real app, you might want to increment. Supabase upsert replaces.
        // Ideally, check existence or use a stored procedure/edge function for atomic increment.
        // For MVP: upserting total quantity is fine if flow is simple.
        // BETTER: We will assume UI sends total desired quantity or we handle conflict.
      }, onConflict: 'user_id, product_id');
    } catch (e) {
      print('Error adding to cart: $e');
      throw Exception('Failed to add to cart: $e');
    }
  }

  // Update Cart Item Quantity
  Future<void> updateCartQuantity(String cartId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await removeFromCart(cartId);
      } else {
        await _client
            .from('cart')
            .update({'quantity': newQuantity})
            .eq('id', cartId);
      }
    } catch (e) {
      print('Error updating cart: $e');
      rethrow;
    }
  }

  // Remove Item from Cart
  Future<void> removeFromCart(String cartId) async {
    try {
      await _client.from('cart').delete().eq('id', cartId);
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    }
  }

  // --- ORDER OPERATIONS ---

  // Place Order
  Future<String> placeOrder({
    required double totalAmount,
    required Map<String, dynamic> shippingAddress,
    required String contactPhone,
    required List<CartItem> cartItems,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      // 1. Create Order Record
      // Generate Order Number: CL-YYYYMMDD-XXXX
      final dateStr = DateTime.now()
          .toIso8601String()
          .substring(0, 10)
          .replaceAll('-', '');
      final randomSuffix = DateTime.now().millisecondsSinceEpoch
          .toString()
          .substring(9);
      final orderNumber = 'CL-$dateStr-$randomSuffix';

      final orderResponse = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            'order_number': orderNumber,
            'total_amount': totalAmount,
            'status': 'pending', // Initial status
            'payment_status':
                'cod_pending', // Assuming Cash on Delivery for now
            'shipping_address': shippingAddress,
            'contact_phone': contactPhone,
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      // 2. Create Order Items
      final orderItemsData = cartItems.map((item) {
        final price = item.product?.discountPrice ?? item.product?.price ?? 0;
        return {
          'order_id': orderId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price_at_purchase': price,
          'subtotal': price * item.quantity,
        };
      }).toList();

      await _client.from('order_items').insert(orderItemsData);

      // 3. Clear Cart (After successful order)
      await _client.from('cart').delete().eq('user_id', userId);

      // 4. Update Stock (Simple decrement)
      for (var item in cartItems) {
        final currentStock = item.product?.stockQuantity ?? 0;
        final newStock = currentStock - item.quantity;
        if (newStock >= 0) {
          await _client
              .from('products')
              .update({'stock_quantity': newStock})
              .eq('id', item.productId);
        }
      }

      return orderId;
    } catch (e) {
      print('Error placing order: $e');
      throw Exception('Failed to place order: $e');
    }
  }

  // Fetch My Orders
  Future<List<Order>> getMyOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching orders: $e');
      throw Exception('Failed to fetch orders');
    }
  }
}
