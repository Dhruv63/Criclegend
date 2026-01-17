import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/match_model.dart';
import '../domain/team_model.dart';

class ScoringRepository {
  final SupabaseClient _supabase;

  ScoringRepository(this._supabase);

  Future<List<Team>> getMyTeams() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Simple query: Teams where I am captain or just all teams for now
    // For specific user teams we need a many-to-many or check players_array
    // For this stage, let's just fetch ALL teams to pick from.
    final data = await _supabase.from('teams').select();
    return (data as List).map((e) => Team.fromJson(e)).toList();
  }

  Future<Team> createTeam(String name) async {
    final userId = _supabase.auth.currentUser?.id;
    final data = await _supabase
        .from('teams')
        .insert({'name': name, 'captain_id': userId, 'players_array': []})
        .select()
        .single();
    return Team.fromJson(data);
  }

  // 1. Schedule a Match (Phase 1)
  Future<MatchModel> createMatch({
    required String teamAId,
    required String teamBId,
    required int overs,
    required String ground,
    required DateTime scheduledDate,
    String matchType = 'Friendly',
    String matchFormat = 'T20',
    String? venueName, // Optional specific venue name
    String? notes,
  }) async {
    final data = await _supabase
        .from('matches')
        .insert({
          'team_a_id': teamAId,
          'team_b_id': teamBId,
          'overs_count': overs,
          'ground': ground, // Legacy/Display location
          'venue_name': venueName ?? ground,
          'status': 'scheduled',
          'current_status': 'scheduled', // Legacy field backup
          'match_date': scheduledDate.toIso8601String(), // Display date
          'scheduled_date': scheduledDate.toIso8601String(),
          'match_type': matchType,
          'match_format': matchFormat,
          'match_notes': notes,
          'toss_winner_id': null, // Set when starting
          'toss_decision': null, // Set when starting
        })
        .select()
        .single();

    return MatchModel.fromJson(data);
  }

  // 2. Start Scheduled Match (Phase 2 - Toss & Execution)
  Future<void> startMatch({
    required String matchId,
    required String tossWinnerId,
    required String tossDecision,
    required String teamAId,
    required String teamBId,
  }) async {
    // A. Update Match Status & Toss
    await _supabase
        .from('matches')
        .update({
          'toss_winner_id': tossWinnerId,
          'toss_decision': tossDecision,
          'status': 'live',
          'current_status': 'Live',
          'started_at': DateTime.now().toIso8601String(),
        })
        .eq('id', matchId);

    // B. Create Initial Innings
    final battingTeamId = (tossDecision == 'Bat')
        ? tossWinnerId
        : (tossWinnerId == teamAId ? teamBId : teamAId);

    final bowlingTeamId = (battingTeamId == teamAId) ? teamBId : teamAId;

    await _supabase.from('innings').insert({
      'match_id': matchId,
      'batting_team_id': battingTeamId,
      'bowling_team_id': bowlingTeamId,
      'innings_number': 1,
      'is_completed': false,
      'total_runs': 0,
      'wickets': 0,
      'overs_played': 0.0,
    });
  }
}
