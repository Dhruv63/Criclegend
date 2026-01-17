class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? discountPrice;
  final String category;
  final String? brand;
  final List<String> images;
  final int stockQuantity;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.discountPrice,
    required this.category,
    this.brand,
    required this.images,
    required this.stockQuantity,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      category: json['category'],
      brand: json['brand'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      stockQuantity: json['stock_quantity'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'category': category,
      'brand': brand,
      'images': images,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
    };
  }

  // Helper to get primary image
  String? get primaryImage => images.isNotEmpty ? images.first : null;

  // Calculate discount percentage
  int get discountPercentage {
    if (discountPrice == null || discountPrice! >= price) return 0;
    return ((price - discountPrice!) / price * 100).round();
  }
}
