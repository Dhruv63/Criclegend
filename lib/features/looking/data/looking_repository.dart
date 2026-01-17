import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/looking_request_model.dart';
// For user check if needed

class LookingRepository {
  final SupabaseClient _client;

  LookingRepository(this._client);

  Future<List<LookingRequest>> getRequests({
    String? category,
    String? city,
  }) async {
    try {
      var query = _client
          .from('looking_requests')
          .select('*, users!user_id(profile_json)') // Join with users table
          .eq('status', 'Open'); // Only open requests

      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }

      if (city != null && city.isNotEmpty) {
        query = query.ilike('location_city', '%$city%');
      }

      // Ordering: Urgent first, then Newest first
      final response = await query
          .order('urgency_level', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((e) => LookingRequest.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching looking requests: $e');
      return [];
    }
  }

  Future<void> createRequest(LookingRequest request) async {
    try {
      await _client.from('looking_requests').insert(request.toMap());
    } catch (e) {
      print('Error creating looking request: $e');
      rethrow;
    }
  }
}
