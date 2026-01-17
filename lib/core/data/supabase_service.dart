import 'package:supabase_flutter/supabase_flutter.dart';
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

  static Future<List<Map<String, dynamic>>> getScheduledMatches() async {
    try {
      final response = await client
          .from('matches')
          .select('*, team_a:teams!team_a_id(*), team_b:teams!team_b_id(*)')
          .or(
            'status.eq.scheduled,status.eq.Scheduled,status.eq.upcoming,status.eq.Upcoming',
          )
          .order('scheduled_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching scheduled matches: $e');
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
  static Future<List<Map<String, dynamic>>> getServicesByCategory(
    String category,
  ) async {
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

  static Future<List<Map<String, dynamic>>> getBusinessesByCategory(
    String category,
  ) async {
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
  static Future<List<Map<String, dynamic>>> getCommunityPosts(
    String? type,
  ) async {
    try {
      var query = client.from('posts').select('*, users(*)');

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

  static Future<List<Map<String, dynamic>>> getTeamPlayers(
    String teamId,
  ) async {
    try {
      // 1. Try Fetching Linked Players
      final response = await client
          .from('users')
          .select()
          .eq('team_id', teamId);

      final players = List<Map<String, dynamic>>.from(response);

      // 2. SELF-HEALING: If no players, assign some "Free Agents" to this team
      if (players.isEmpty) {
        print(
          "Scoring: No players found for Team $teamId. Auto-assigning Free Agents...",
        );

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
            await client
                .from('users')
                .update({'team_id': teamId})
                .eq('id', agent['id']);
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

  static Future<List<Map<String, dynamic>>> getMatchesByStatus(
    String status,
  ) async {
    try {
      var query = client
          .from('matches')
          .select('*, team_a:teams!team_a_id(*), team_b:teams!team_b_id(*)')
          // .eq('status', status) // Old simple check
          ; 

      // Enhanced filtering to handle commonly used variations matching DB values
      if (status == 'Upcoming' || status == 'Scheduled') {
         query = query.or('status.eq.Scheduled,status.eq.scheduled,status.eq.Upcoming,status.eq.upcoming');
      } else if (status == 'Live' || status == 'In Progress') {
         query = query.or('status.eq.Live,status.eq.live,status.eq.in_progress,status.eq.In Progress');
      } else if (status == 'Completed') {
         query = query.or('status.eq.Completed,status.eq.completed');
      } else if (status == 'Cancelled') {
         query = query.or('status.eq.Cancelled,status.eq.cancelled');
      } else {
         query = query.eq('status', status);
      }

      final response = await query.order(
            'date',
            ascending: status == 'Scheduled' || status == 'Upcoming',
          );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching matches for status $status: $e');
      return [];
    }
  }

  // --- Scorecard / Admin ---
  // --- Scorecard / Admin Engine ---

  /// Fetch full context: Match, Team names, current Innings, and recent Balls
  static Future<Map<String, dynamic>?> getMatchFullDetails(
    String matchId,
  ) async {
    try {
      final response = await client
          .from('matches')
          .select(
            '*, team_a:teams!team_a_id(*), team_b:teams!team_b_id(*), innings(*)',
          )
          .eq('id', matchId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching match details: $e');
      return null;
    }
  }

  /// Initialize a match with 2 innings if not exists
  static Future<void> startMatch(
    String matchId,
    String teamAId,
    String teamBId,
  ) async {
    // Check if innings exist
    final distinct = await client
        .from('innings')
        .select()
        .eq('match_id', matchId);
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

      await client
          .from('matches')
          .update({'status': 'Live', 'current_innings': 1})
          .eq('id', matchId);
    }
  }

  // --- Stats Helpers ---
  static Future<Map<String, dynamic>> getActivePlayerStats(
    String matchId,
    String inningId,
    String strikerId,
    String nonStrikerId,
    String bowlerId,
  ) async {
    try {
      if (inningId.isEmpty ||
          strikerId.isEmpty ||
          nonStrikerId.isEmpty ||
          bowlerId.isEmpty) {
        return {};
      }
      // 1. Fetch Runs/Balls for Batters
      final strikerData = await client
          .from('balls')
          .select('runs_scored, extras_type')
          .eq('inning_id', inningId)
          .eq('striker_id', strikerId); // using striker_id now

      final nonStrikerData = await client
          .from('balls')
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
      final bowlerData = await client
          .from('balls')
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
        final isBye =
            type == 'bye' || type == 'legbye'; // assuming these strings

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
      await client
          .from('innings')
          .update({
            'total_runs': newTotalRuns,
            'wickets': newWickets,
            'overs_played': newOvers,
            'striker_id': currentStrikerId,
            'non_striker_id': currentNonStrikerId,
            'bowler_id': currentBowlerId,
          })
          .eq('id', ball.inningId);
    } catch (e) {
      print('Error recording ball event: $e');
      rethrow;
    }
  }

  static Future<void> endMatch({
    required String matchId,
    String? winningTeamId, // Changed to nullable
    required String resultDescription,
  }) async {
    try {
      await client
          .from('matches')
          .update({
            'status': 'Completed',
            'current_status': 'Completed',
            'winning_team_id':
                (winningTeamId != null && winningTeamId.isNotEmpty)
                ? winningTeamId
                : null,
            'result_description': resultDescription,
          })
          .eq('id', matchId);
    } catch (e) {
      print('Error ending match: $e');
      rethrow;
    }
  }

  static Future<void> undoLastBall(String inningId) async {
    try {
      // 1. Fetch Last Ball
      final response = await client
          .from('balls')
          .select()
          .eq('inning_id', inningId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return;

      final ball = BallModel.fromJson(response);
      final isWide = ball.extrasType == 'wide';
      final isNoBall = ball.extrasType == 'noball';

      // 2. Revert Stats (Manual revert since DB trigger failed)
      // Striker Revert
      if (ball.strikerId.isNotEmpty) {
        final pData = await client
            .from('player_match_performances')
            .select()
            .eq('user_id', ball.strikerId)
            .eq('innings_id', inningId)
            .single();
        await client
            .from('player_match_performances')
            .update({
              'runs_scored': (pData['runs_scored'] ?? 0) - ball.runsScored,
              'balls_faced': (pData['balls_faced'] ?? 0) - (isWide ? 0 : 1),
              'fours_hit':
                  (pData['fours_hit'] ?? 0) - (ball.runsScored == 4 ? 1 : 0),
              'sixes_hit':
                  (pData['sixes_hit'] ?? 0) - (ball.runsScored == 6 ? 1 : 0),
            })
            .eq('id', pData['id']);
      }

      // Bowler Revert
      if (ball.bowlerId.isNotEmpty) {
        final bData = await client
            .from('player_match_performances')
            .select()
            .eq('user_id', ball.bowlerId)
            .eq('innings_id', inningId)
            .single();
        final ballRuns = ball.runsScored + ball.extrasRuns;

        await client
            .from('player_match_performances')
            .update({
              'balls_bowled':
                  (bData['balls_bowled'] ?? 0) - (isWide || isNoBall ? 0 : 1),
              'runs_conceded': (bData['runs_conceded'] ?? 0) - ballRuns,
              'wickets_taken':
                  (bData['wickets_taken'] ?? 0) -
                  ((ball.isWicket && ball.dismissalType != 'run_out') ? 1 : 0),
            })
            .eq('id', bData['id']);
      }

      // Wicket Revert
      if (ball.isWicket && ball.dismissedPlayerId != null) {
        await client
            .from('player_match_performances')
            .update({'is_not_out': true, 'dismissal_type': null})
            .eq('user_id', ball.dismissedPlayerId!)
            .eq('innings_id', inningId);

        final fielderId = ball.dismissalFielderId;
        if (fielderId != null) {
          final fData = await client
              .from('player_match_performances')
              .select()
              .eq('user_id', fielderId)
              .eq('innings_id', inningId)
              .single();
          await client
              .from('player_match_performances')
              .update({
                'catches_taken':
                    (fData['catches_taken'] ?? 0) -
                    (ball.dismissalType == 'caught' ? 1 : 0),
                'run_outs_involved':
                    (fData['run_outs_involved'] ?? 0) -
                    (ball.dismissalType == 'run_out' ? 1 : 0),
                'stumpings_done':
                    (fData['stumpings_done'] ?? 0) -
                    (ball.dismissalType == 'stumped' ? 1 : 0),
              })
              .eq('id', fData['id']);
        }
      }

      // 3. Delete Ball
      if (ball.id != null) {
        await client.from('balls').delete().eq('id', ball.id!);
      }

      // 4. Update Innings Totals
      final agg = await client
          .from('balls')
          .select('runs_scored, extras_runs, is_wicket, extras_type')
          .eq('inning_id', inningId);
      int totalR = 0;
      int totalW = 0;
      int validBalls = 0;

      for (var b in agg) {
        totalR += (b['runs_scored'] as int) + (b['extras_runs'] as int);
        if (b['is_wicket'] == true) totalW++;
        final type = b['extras_type'];
        if (type != 'wide' && type != 'noball') validBalls++;
      }

      final overs = (validBalls ~/ 6) + (validBalls % 6) / 10.0;

      await client
          .from('innings')
          .update({
            'total_runs': totalR,
            'wickets': totalW,
            'overs_played': overs,
          })
          .eq('id', inningId);
    } catch (e) {
      print('Error undoing last ball: $e');
      rethrow;
    }
  }
}
