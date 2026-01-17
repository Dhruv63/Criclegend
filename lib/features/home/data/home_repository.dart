import 'package:supabase_flutter/supabase_flutter.dart';
import '../../scoring/domain/match_model.dart';

class HomeRepository {
  final SupabaseClient _client;

  HomeRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Fetches Live and Upcoming matches.
  /// Joins with Teams table to get Team Names and Logos.
  Future<List<MatchModel>> getLiveMatches() async {
    try {
      final response = await _client
          .from('matches')
          .select('*, team_a:teams!team_a_id(*), team_b:teams!team_b_id(*)')
          .neq('status', 'Completed')
          .order('match_date', ascending: true); // Show soonest first

      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => MatchModel.fromJson(json)).toList();
    } catch (e) {
      print('HomeRepository Error: $e');
      return []; // Return empty on error to avoid breaking UI, or rethrow?
      // Provider will handle AsyncError if we rethrow. Let's rethrow for better UI handling.
      rethrow;
    }
  }
}
