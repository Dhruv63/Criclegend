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
    final data = await _supabase.from('teams').insert({
      'name': name,
      'captain_id': userId,
      'players_array': [],
    }).select().single();
    return Team.fromJson(data);
  }

  Future<MatchModel> createMatch({
    required String teamAId,
    required String teamBId,
    required int overs,
    required String ground,
    required String tossWinnerId,
    required String tossDecision,
  }) async {
    final data = await _supabase.from('matches').insert({
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'overs_count': overs,
      'ground': ground,
      'toss_winner_id': tossWinnerId,
      'toss_decision': tossDecision,
      'current_status': 'Live', // Start immediately
      'match_date': DateTime.now().toIso8601String(),
    }).select().single();

    // Create Initial Innings
    // If toss winner bats, they are batting team. Else other team.
    final battingTeamId = (tossDecision == 'Bat') 
      ? tossWinnerId 
      : (tossWinnerId == teamAId ? teamBId : teamAId);

    await _supabase.from('innings').insert({
      'match_id': data['id'],
      'batting_team_id': battingTeamId,
      'inning_number': 1,
    });

    return MatchModel.fromJson(data);
  }
}
