import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/scoring/domain/match_model.dart';
import '../../features/scoring/domain/ball_model.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  // --- Matches ---
  static Future<List<Map<String, dynamic>>> getLiveMatches() async {
    try {
      final response = await client
          .from('matches')
          .select('*, team_a:teams!team_a_id(*), team_b:teams!team_b_id(*)')
          .eq('status', 'Live')
          .order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching live matches: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAdminMatches() async {
    try {
      final response = await client
          .from('matches')
          .select('*, team_a:teams!team_a_id(*), team_b:teams!team_b_id(*)')
          .or('status.eq.Live,status.eq.Upcoming')
          .order('date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching admin matches: $e');
      return [];
    }
  }

  // --- Products ---
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await client
          .from('products')
          .select('*')
          .order('id', ascending: true); // or created_at
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // --- Auth (Mock/Demo) ---
  static Future<Map<String, dynamic>?> loginAsDemoUser() async {
    try {
      // Fetch Dudu Sharma by phone (known from seed)
      final response = await client
          .from('users')
          .select()
          .eq('phone', '8551069057')
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error logging in demo user: $e');
      return null;
    }
  }

  // --- Players ---
  static Future<List<Map<String, dynamic>>> getPopularCricketers() async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('is_mock', true)
          // .order('total_runs', ascending: false) // Column doesn't exist on top level
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching popular cricketers: $e');
      return [];
    }
  }
  // --- Community / Marketplace ---
  static Future<List<Map<String, dynamic>>> getServicesByCategory(String category) async {
    try {
      final response = await client
          .from('services')
          .select('*, users!provider_id(*)') // Embed provider profile
          .eq('title', category) // e.g., 'Scorer', 'Umpire'
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching services for $category: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getBusinessesByCategory(String category) async {
    try {
      final response = await client
          .from('business_listings')
          .select('*')
          .eq('type', category) // e.g., 'Academy', 'Shop'
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching businesses for $category: $e');
      return [];
    }
  }
    // --- Posts / Looking For ---
  static Future<List<Map<String, dynamic>>> getCommunityPosts(String? type) async {
    try {
      var query = client
          .from('posts')
          .select('*, users(*)');
      
      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }
  // --- My Cricket ---
  static Future<List<Map<String, dynamic>>> getUserTeams(String userId) async {
    try {
      final response = await client
          .from('teams')
          .select()
          .eq('captain_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user teams: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTeamPlayers(String teamId) async {
    try {
      // 1. Try Fetching Linked Players
      final response = await client
          .from('users')
          .select()
          .eq('team_id', teamId);
      
      final players = List<Map<String, dynamic>>.from(response);
      
      // 2. SELF-HEALING: If no players, assign some "Free Agents" to this team
      if (players.isEmpty) {
        print("Scoring: No players found for Team $teamId. Auto-assigning Free Agents...");
        
        // Fetch 11 users who have NO team_id
        final freeAgents = await client
            .from('users')
            .select()
            .isFilter('team_id', null) 
            .limit(11);
            
        final agents = List<Map<String, dynamic>>.from(freeAgents);
        
        if (agents.isNotEmpty) {
           // Update them to belong to this team
           for (var agent in agents) {
             await client.from('users').update({'team_id': teamId}).eq('id', agent['id']);
             agent['team_id'] = teamId; // Update local
           }
           return agents;
        } else {
           // Fallback: If no free agents (all taken?), just return ANY 11 users (Shared players?)
           // This prevents empty screen in worst case
           final anyUsers = await client.from('users').select().limit(11);
           return List<Map<String, dynamic>>.from(anyUsers);
        }
      }
      
      return players;
    } catch (e) {
      print('Error fetching team players: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCompletedMatches() async {
    try {
      final response = await client
          .from('matches')
          .select('*, team_a:teams!team_a_id(*), team_b:teams!team_b_id(*)')
          .eq('status', 'Completed')
          .order('date', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching completed matches: $e');
      return [];
    }
  }

  // --- Scorecard / Admin ---
  // --- Scorecard / Admin Engine ---

  /// Fetch full context: Match, Team names, current Innings, and recent Balls
  static Future<Map<String, dynamic>?> getMatchFullDetails(String matchId) async {
    try {
      final response = await client
          .from('matches')
          .select('*, team_a:teams!team_a_id(*), team_b:teams!team_b_id(*), innings(*)')
          .eq('id', matchId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching match details: $e');
      return null;
    }
  }

  /// Initialize a match with 2 innings if not exists
  static Future<void> startMatch(String matchId, String teamAId, String teamBId) async {
      // Check if innings exist
      final distinct = await client.from('innings').select().eq('match_id', matchId);
      if (distinct.isEmpty) {
        // Create Innings 1
        await client.from('innings').insert({
          'match_id': matchId,
          'innings_number': 1,
          'batting_team_id': teamAId,
          'bowling_team_id': teamBId,
        });
        // Create Innings 2 
        await client.from('innings').insert({
          'match_id': matchId,
          'innings_number': 2,
          'batting_team_id': teamBId,
          'bowling_team_id': teamAId,
        });
        
        await client.from('matches').update({'status': 'Live', 'current_innings': 1}).eq('id', matchId);
      }
  }

  // --- Stats Helpers ---
  static Future<Map<String, dynamic>> getActivePlayerStats(String matchId, String inningId, String strikerId, String nonStrikerId, String bowlerId) async {
    try {
      if (inningId.isEmpty || strikerId.isEmpty || nonStrikerId.isEmpty || bowlerId.isEmpty) {
        return {};
      }
      // 1. Fetch Runs/Balls for Batters
      final strikerData = await client.from('balls')
          .select('runs_scored, extras_type')
          .eq('inning_id', inningId)
          .eq('striker_id', strikerId); // using striker_id now
          
      final nonStrikerData = await client.from('balls')
          .select('runs_scored, extras_type')
          .eq('inning_id', inningId)
          .eq('striker_id', nonStrikerId);
          
      int sRuns = 0;
      int sBalls = 0;
      for (var b in strikerData) {
        // Runs off bat = total runs if not wide/noball? 
        // Logic: runs_scored counts. Wide is extra.
        // If Wide, ball doesn't count for batter. Runs go to extra. 
        // But our simpler model: runs_scored = bat runs. 
        final isWide = b['extras_type'] == 'wide';
        final runs = (b['runs_scored'] as int?) ?? 0;
        
        sRuns += runs;
        if (!isWide) sBalls++;
      }
      
      int nsRuns = 0;
      int nsBalls = 0;
      for (var b in nonStrikerData) {
        final isWide = b['extras_type'] == 'wide';
        final runs = (b['runs_scored'] as int?) ?? 0;
        nsRuns += runs;
        if (!isWide) nsBalls++;
      }
      
      // 2. Fetch Figures for Bowler
      final bowlerData = await client.from('balls')
          .select('runs_scored, extras_type, is_wicket, extras_runs')
          .eq('inning_id', inningId)
          .eq('bowler_id', bowlerId);
          
      int bRuns = 0; 
      int bWickets = 0;
      int legalBalls = 0;
      
      for (var b in bowlerData) {
        // Bowler runs: runs_scored + (wide/nb extras). 
        // Byes/Legbyes don't count for bowler.
        final type = b['extras_type'];
        final isWide = type == 'wide';
        final isNb = type == 'noball';
        final isBye = type == 'bye' || type == 'legbye'; // assuming these strings
        
        // Batter runs count against bowler (unless bye/lb)
        final runs = (b['runs_scored'] as int?) ?? 0;
        
        if (!isBye) {
           bRuns += runs; 
           // Add wide/nb extra runs? Usually +1. 
           // Our model: extras_runs stores the penalty.
           final eRuns = (b['extras_runs'] as int?) ?? 0;
           bRuns += eRuns;
        }
        
        if (b['is_wicket'] == true && type != 'runout') {
           bWickets++;
        }
        
        if (!isWide && !isNb) legalBalls++;
      }
      
      final bOvers = (legalBalls ~/ 6) + (legalBalls % 6) / 10.0;

      return {
        'striker': {'runs': sRuns, 'balls': sBalls},
        'nonStriker': {'runs': nsRuns, 'balls': nsBalls},
        'bowler': {'overs': bOvers, 'runs': bRuns, 'wickets': bWickets},
      };
      
    } catch (e) {
      print("Error Stats: $e");
      return {};
    }
  }

  /// The Core Engine Write Function
  static Future<void> recordBallEvent({
    required BallModel ball, // Refactored to use Model
    required int newTotalRuns,
    required double newOvers,
    required int newWickets,
    required String? currentStrikerId,
    required String? currentNonStrikerId,
    required String? currentBowlerId,
  }) async {
    try {
      // 1. Insert Ball Record
      await client.from('balls').insert(ball.toJson());

      // 2. Update Innings State (Score & Active Players)
      await client.from('innings').update({
        'total_runs': newTotalRuns,
        'wickets': newWickets,
        'overs_played': newOvers,
        'striker_id': currentStrikerId,
        'non_striker_id': currentNonStrikerId,
        'bowler_id': currentBowlerId,
      }).eq('id', ball.inningId);

    } catch (e) {
      print('Error recording ball event: $e');
      throw e; 
    }
  }

  /// End Match and Update Result
  static Future<void> endMatch({
    required String matchId,
    required String winningTeamId,
    required String resultDescription,
  }) async {
    try {
      await client.from('matches').update({
        'status': 'Completed',
        'current_status': 'Completed',
        'winning_team_id': winningTeamId,
        'result_description': resultDescription,
      }).eq('id', matchId);
    } catch (e) {
      print('Error ending match: $e');
      throw e;
    }
  }
}
