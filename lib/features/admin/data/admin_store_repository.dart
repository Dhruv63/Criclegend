import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../store/domain/product_model.dart';

final adminStoreRepositoryProvider = Provider(
  (ref) => AdminStoreRepository(Supabase.instance.client),
);

final storeAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminStoreRepositoryProvider);
  return repo.getStoreAnalyticsSummary();
});

class AdminStoreRepository {
  final SupabaseClient _client;

  AdminStoreRepository(this._client);

  // --- Products ---

  Future<List<Product>> getProducts({
    String? query,
    String? category,
    bool? isActive,
  }) async {
    // We must use dynamic or PostgrestFilterBuilder to handle conditional filters properly
    // The type system for chained modifiers can be strict.

    var dbQuery = _client.from('products').select();

    if (query != null && query.isNotEmpty) {
      dbQuery = dbQuery.ilike('name', '%$query%');
    }
    if (category != null && category != 'All') {
      dbQuery = dbQuery.eq('category', category);
    }
    if (isActive != null) {
      dbQuery = dbQuery.eq('is_active', isActive);
    }

    // Sort can be applied to the transform builder
    final response = await dbQuery.order('created_at', ascending: false);
    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<void> createProduct(
    Map<String, dynamic> productData,
    List<XFile> images,
  ) async {
    // 1. Insert Product first
    final insertRes = await _client
        .from('products')
        .insert({...productData, 'images': []})
        .select()
        .single();

    final productId = insertRes['id'];
    List<String> imageUrls = [];

    // 2. Upload Images
    imageUrls = await _uploadImages(productId, images);

    // 3. Update Product with Image URLs
    await _client
        .from('products')
        .update({'images': imageUrls})
        .eq('id', productId);

    // 4. Log Activity
    await _logActivity(
      'create_product',
      productId,
      'Created product ${productData['name']}',
    );
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates, {
    List<XFile>? newImages,
    List<String>? existingImages,
  }) async {
    List<String> finalImages = existingImages ?? [];

    // Upload new images if any
    if (newImages != null && newImages.isNotEmpty) {
      final newUrls = await _uploadImages(productId, newImages);
      finalImages.addAll(newUrls);
    }

    final updateData = {
      ...updates,
      if (newImages != null || existingImages != null) 'images': finalImages,
    };

    await _client.from('products').update(updateData).eq('id', productId);
    await _logActivity(
      'update_product',
      productId,
      'Updated product $productId',
    );
  }

  Future<List<String>> _uploadImages(
    String productId,
    List<XFile> images,
  ) async {
    List<String> urls = [];
    for (var image in images) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final path = 'products/$productId/$fileName';

      final bytes = await image.readAsBytes();
      await _client.storage
          .from('product-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: image.mimeType,
            ), // Important for web
          );

      final publicUrl = _client.storage
          .from('product-images')
          .getPublicUrl(path);
      urls.add(publicUrl);
    }
    return urls;
  }

  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
    await _logActivity(
      'delete_product',
      productId,
      'Deleted product $productId',
    );
  }

  Future<void> bulkDeleteProducts(List<String> productIds) async {
    await _client.from('products').delete().filter('id', 'in', productIds);
    await _logActivity(
      'bulk_delete_products',
      null, // Bulk action
      'Deleted ${productIds.length} products',
    );
  }

  Future<void> bulkUpdateProductStatus(
    List<String> productIds,
    bool isActive,
  ) async {
    await _client
        .from('products')
        .update({'is_active': isActive})
        .filter('id', 'in', productIds);
    await _logActivity(
      'bulk_update_status',
      null, // Bulk action
      'Set ${productIds.length} products to ${isActive ? 'Active' : 'Inactive'}',
    );
  }

  // --- Orders ---

  Future<List<Map<String, dynamic>>> getAllOrders({String? status}) async {
    var query = _client.from('orders').select('*, order_items(*, products(*))');

    if (status != null && status != 'All') {
      query = query.eq('status', status);
    }

    // Sort logic moved to end
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // 1. Validate Transition (Basic check, detailed logic can be in UI or here)
      // For now, relying on UI to pass valid next status.

      print('Attempting to update order $orderId to $newStatus with $extraData');

      // 2. Perform Update
      // 2. Perform Update
      final Map<String, dynamic> updates = {'status': newStatus};
      if (extraData != null) {
        updates.addAll(extraData);
      }

      await _client.from('orders').update(updates).eq('id', orderId);
      
      // 3. Verify Update (Double Check)
      final verify = await _client
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .single();
      
      if (verify['status'] != newStatus) {
        throw Exception("Database verification failed. Status is still ${verify['status']}");
      }

      print('Order $orderId successfully updated to $newStatus in DB.');

      // 4. Log Activity
      await _logActivity(
        'update_order_status',
        orderId,
        'Updated status to $newStatus',
      );
    } catch (e) {
      print('CRITICAL: Failed to update order status: $e');
      // Rethrow so UI knows it failed
      throw Exception('Failed to update status: $e');
    }
  }

  Future<void> bulkUpdateOrderStatus(
    List<String> orderIds,
    String status,
  ) async {
    await _client
        .from('orders')
        .update({'status': status})
        .filter('id', 'in', orderIds);
    await _logActivity(
      'bulk_update_order_status',
      null, // Bulk action
      'Updated ${orderIds.length} orders to $status',
    );
  }

  // --- Analytics ---

  Future<Map<String, dynamic>> getStoreStats() async {
    final productsCount = await _client
        .from('products')
        .count(CountOption.exact);
    final ordersCount = await _client.from('orders').count(CountOption.exact);
    return {'products': productsCount, 'orders': ordersCount};
  }

  Future<Map<String, dynamic>> getStoreAnalyticsSummary() async {
    try {
      // 1. Total Revenue & Avg Order Value (from Delivered orders)
      final deliveredOrdersResponse = await _client
          .from('orders')
          .select('total_amount')
          .eq('status', 'Delivered');
      
      final deliveredOrders = List<Map<String, dynamic>>.from(deliveredOrdersResponse);
      final double totalRevenue = deliveredOrders.fold(0.0, (sum, item) => sum + (item['total_amount'] as num).toDouble());
      final int totalDelivered = deliveredOrders.length;
      final double avgOrderValue = totalDelivered > 0 ? totalRevenue / totalDelivered : 0.0;

      // 2. Total Orders Count
      final totalOrdersCount = await _client.from('orders').count(CountOption.exact);

      // 3. Active Products Count (Replacing Product Views)
      final activeProductsCount = await _client
          .from('products')
          .count(CountOption.exact)
          .eq('is_active', true);

      // 4. Revenue Trend (Last 7 Days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final recentOrdersResponse = await _client
          .from('orders')
          .select('created_at, total_amount')
          .eq('status', 'Delivered')
          .gte('created_at', sevenDaysAgo)
          .order('created_at', ascending: true);
      
      final recentOrders = List<Map<String, dynamic>>.from(recentOrdersResponse);
      
      // Group by Date for Chart
      // Map<String, double>
      
      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrdersCount,
        'avgOrderValue': avgOrderValue,
        'activeProducts': activeProductsCount,
        'recentOrders': recentOrders, // List of {created_at, total_amount}
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      return {
        'totalRevenue': 0.0,
        'totalOrders': 0,
        'avgOrderValue': 0.0,
        'activeProducts': 0,
        'recentOrders': [],
      };
    }
  }

  // --- Logging ---

  Future<void> _logActivity(
    String action,
    String? targetId,
    String description,
  ) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from('admin_activity_log').insert({
        'admin_id': user.id,
        'action_type': action,
        if (targetId != null) 'target_id': targetId,
        'description': description,
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }
}
