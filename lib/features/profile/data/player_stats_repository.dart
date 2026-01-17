import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/player_stats_model.dart';
import '../domain/match_performance_model.dart';

class PlayerStatsRepository {
  final SupabaseClient _supabase;

  PlayerStatsRepository(this._supabase);

  // Get Career Stats for a User
  Future<PlayerStats?> getPlayerStats(String userId) async {
    try {
      final data = await _supabase
          .from('player_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) {
        // Attempt to create if missing (failsafe, though trigger handles it)
        try {
          final newData = await _supabase
              .from('player_stats')
              .insert({'user_id': userId})
              .select()
              .single();
          return PlayerStats.fromJson(newData);
        } catch (e) {
          return null; // Race condition or error
        }
      }
      return PlayerStats.fromJson(data);
    } catch (e) {
      print('Error fetching player stats: $e');
      return null;
    }
  }

  // Get Match History (Performance List)
  Future<List<MatchPerformance>> getMatchHistory(String userId) async {
    try {
      final data = await _supabase
          .from('player_match_performances')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => MatchPerformance.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching match history: $e');
      return [];
    }
  }

  // Get Specific Match Details (For drill down)
  // Can reuse MatchRepository or create enhanced query here if needed
}
