import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository(Supabase.instance.client));

final adminDashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDashboardStats();
});

class AdminRepository {
  final SupabaseClient _client;

  AdminRepository(this._client);

  // --- Logging ---

  Future<void> logActivity(String action, String? targetId, String description) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final data = {
        'admin_id': user.id,
        'action_type': action,
        'description': description,
        if (targetId != null) 'target_id': targetId,
      };

      await _client.from('admin_activity_log').insert(data);
    } catch (e) {
      // Fail silently for logging to avoid blocking main flow
      print('Failed to log activity: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    try {
      final response = await _client
          .from('admin_activity_log')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching activity log: $e');
      return [];
    }
  }

  // --- Dashboard Stats ---

  Future<Map<String, dynamic>> getDashboardStats() async {
    // Run parallel queries for efficiency
    try {
      final results = await Future.wait([
        _client.from('matches').count(CountOption.exact).eq('status', 'Live'), // Live Matches
        _client.from('matches').count(CountOption.exact).eq('status', 'Scheduled'), // Upcoming
        _client.from('products').count(CountOption.exact).eq('is_active', true), // Active Products
        _client.from('orders').count(CountOption.exact).eq('status', 'Pending'), // Pending Orders
      ]);

      return {
        'live_matches': results[0] ?? 0,
        'upcoming_matches': results[1] ?? 0,
        'active_products': results[2] ?? 0,
        'pending_orders': results[3] ?? 0,
      };
    } catch (e) {
      print('Stats fetch error: $e');
       return {
        'live_matches': 0,
        'upcoming_matches': 0,
        'active_products': 0,
        'pending_orders': 0,
      };
    }
  }
}
