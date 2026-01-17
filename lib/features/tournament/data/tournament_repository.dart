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
          .select(
            '*, team_a:team_a_id(name, logo_url), team_b:team_b_id(name, logo_url)',
          )
          .eq('tournament_id', tournamentId)
          .eq('status', 'Scheduled')
          .order('match_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching fixtures: $e');
      return [];
    }
  }

  Future<String?> createTournament({
    required String name,
    required String venue,
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> teamIds,
  }) async {
    try {
      // 1. Check for duplicates (Simple version)
      // Real prod: Use database function or select count

      // 2. Insert Tournament
      final res = await _client
          .from('tournaments')
          .insert({
            'name': name,
            'venue': venue,
            'format': format,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'status': 'Upcoming',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final tournamentId = res['id'] as String;

      // 3. Link Teams (tournament_teams)
      if (teamIds.isNotEmpty) {
        final teamLinks = teamIds
            .map((tid) => {'tournament_id': tournamentId, 'team_id': tid})
            .toList();

        await _client.from('tournament_teams').insert(teamLinks);
      }

      return tournamentId;
    } catch (e) {
      print('Error creating tournament: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTeams() async {
    try {
      final res = await _client
          .from('teams')
          .select('id, name, logo_url')
          .order('name');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print("Error fetching all teams: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCompletedMatches(
    String tournamentId,
  ) async {
    try {
      final response = await _client
          .from('matches')
          .select(
            '*, team_a:team_a_id(name, logo_url), team_b:team_b_id(name, logo_url), innings(*)',
          )
          .eq('tournament_id', tournamentId)
          .eq('status', 'Completed');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching completed matches: $e');
      return [];
    }
  }
}
