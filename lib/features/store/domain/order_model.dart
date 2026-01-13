import 'cart_item_model.dart';
import 'product_model.dart';

class Order {
  final String id;
  final String userId;
  final String orderNumber;
  final double totalAmount;
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final String paymentStatus;
  final Map<String, dynamic>? shippingAddress;
  final String? contactPhone;
  final DateTime createdAt;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.shippingAddress,
    this.contactPhone,
    required this.createdAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      orderNumber: json['order_number'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      paymentStatus: json['payment_status'],
      shippingAddress: json['shipping_address'],
      contactPhone: json['contact_phone'],
      createdAt: DateTime.parse(json['created_at']),
      items: json['order_items'] != null
          ? (json['order_items'] as List).map((i) => OrderItem.fromJson(i)).toList()
          : null,
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final int quantity;
  final double priceAtPurchase;
  final double subtotal;

  final Product? product;

  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.priceAtPurchase,
    required this.subtotal,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      priceAtPurchase: (json['price_at_purchase'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      product: json['products'] != null ? Product.fromJson(json['products']) : null,
    );
  }
}
