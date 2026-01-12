import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final tournamentRepositoryProvider = Provider((ref) => TournamentRepository());

class TournamentRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPointsTable(String tournamentId) async {
    try {
      final response = await _client
          .from('tournament_teams')
          .select('*, teams(name, logo_url)')
          .eq('tournament_id', tournamentId)
          .order('points', ascending: false)
          .order('net_run_rate', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching points table: $e');
      return [];
    }
  }

  Future<void> bulkCreateMatches(List<Map<String, dynamic>> matches) async {
    try {
      await _client.from('matches').insert(matches);
    } catch (e) {
      print('Error Creating Fixtures: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFixtures(String tournamentId) async {
    try {
      final response = await _client
          .from('matches')
          .select('*, team_a:team_a_id(name, logo_url), team_b:team_b_id(name, logo_url)')
          .eq('tournament_id', tournamentId)
          .eq('status', 'Scheduled')
          .order('match_date', ascending: true);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching fixtures: $e');
      return [];
    }
  }
}
