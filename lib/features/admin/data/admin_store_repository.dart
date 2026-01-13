import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../store/domain/product_model.dart';

final adminStoreRepositoryProvider = Provider((ref) => AdminStoreRepository(Supabase.instance.client));

class AdminStoreRepository {
  final SupabaseClient _client;

  AdminStoreRepository(this._client);

  // --- Products ---

  Future<List<Product>> getProducts({String? query, String? category, bool? isActive}) async {
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

  Future<void> createProduct(Map<String, dynamic> productData, List<XFile> images) async {
    // 1. Insert Product first
    final insertRes = await _client.from('products').insert({
      ...productData,
      'images': [],
    }).select().single();
    
    final productId = insertRes['id'];
    List<String> imageUrls = [];

    // 2. Upload Images
    imageUrls = await _uploadImages(productId, images);

    // 3. Update Product with Image URLs
    await _client.from('products').update({
      'images': imageUrls,
    }).eq('id', productId);

    // 4. Log Activity
    await _logActivity('create_product', productId, 'Created product ${productData['name']}');
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> updates, {List<XFile>? newImages, List<String>? existingImages}) async {
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
    await _logActivity('update_product', productId, 'Updated product $productId');
  }

  Future<List<String>> _uploadImages(String productId, List<XFile> images) async {
    List<String> urls = [];
    for (var image in images) {
       final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
       final path = 'products/$productId/$fileName';
       
       final bytes = await image.readAsBytes();
       await _client.storage.from('product-images').uploadBinary(
         path,
         bytes,
         fileOptions: FileOptions(contentType: image.mimeType), // Important for web
       );
       
       final publicUrl = _client.storage.from('product-images').getPublicUrl(path);
       urls.add(publicUrl);
    }
    return urls;
  }
  
  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
    await _logActivity('delete_product', productId, 'Deleted product $productId');
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

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _client.from('orders').update({'status': newStatus}).eq('id', orderId);
    await _logActivity('update_order_status', orderId, 'Updated status to $newStatus');
  }

  // --- Analytics ---
  
  Future<Map<String, dynamic>> getStoreStats() async {
    final productsCount = await _client.from('products').count(CountOption.exact);
    final ordersCount = await _client.from('orders').count(CountOption.exact);
    return {
      'products': productsCount,
      'orders': ordersCount,
    };
  }

  // --- Logging ---

  Future<void> _logActivity(String action, String targetId, String description) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from('admin_activity_log').insert({
        'admin_id': user.id,
        'action_type': action,
        'target_id': targetId,
        'description': description,
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }
}
