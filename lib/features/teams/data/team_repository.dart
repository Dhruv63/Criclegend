import 'package:supabase_flutter/supabase_flutter.dart';

class TeamRepository {
  final SupabaseClient _supabase;

  TeamRepository(this._supabase);

  // 1. Create Team
  Future<Map<String, dynamic>> createTeam(String name, String city) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      final response = await _supabase.from('teams').insert({
        'name': name,
        'location': city, // Mapped to DB column 'location'
        'captain_id': userId,
        // 'logo_url': ... optional
      }).select().single();
      return response;
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  // 2. Get My Teams (Owned)
  Future<List<Map<String, dynamic>>> getMyTeams() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('teams')
          .select()
          .eq('captain_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching my teams: $e');
      return [];
    }
  }

  // 3. Search Players
  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    if (query.length < 2) return [];

    try {
      final response = await _supabase
          .from('users')
          .select()
          .ilike('profile_json->>name', '%$query%') // Search inside JSON
          .limit(10);
          
      // Note: If you wanted to search by phone too:
      // .or('profile_json->>name.ilike.%$query%,phone.ilike.%$query%')
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching players: $e');
      return [];
    }
  }

  // 4. Add Player to Team
  Future<void> addPlayerToTeam(String userId, String teamId) async {
    try {
      // Security: RLS should check if I am captain of teamId
      // Logic: Update user's team_id
      await _supabase.from('users').update({
        'team_id': teamId
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to add player: $e');
    }
  }

  // 5. Get Team Members
  Future<List<Map<String, dynamic>>> getTeamMembers(String teamId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('team_id', teamId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching team members: $e');
      return [];
    }
  }
}
