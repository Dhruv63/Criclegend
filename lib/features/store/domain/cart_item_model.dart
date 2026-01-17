import 'product_model.dart';

class CartItem {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final Product? product; // Joined product data

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      quantity: json['quantity'] ?? 1,
      // Handle joined product data via 'products' key used in Supabase select
      product: json['products'] != null
          ? Product.fromJson(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    };
  }
}
