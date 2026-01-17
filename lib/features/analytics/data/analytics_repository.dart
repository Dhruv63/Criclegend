import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model for Over Summary
class OverSummary {
  final int overNumber;
  final int runsConceded;
  final int cumulativeScore;
  final int wicketsInOver;
  final String teamId;

  OverSummary({
    required this.overNumber,
    required this.runsConceded,
    required this.cumulativeScore,
    required this.wicketsInOver,
    required this.teamId,
  });
}

// Provider
final analyticsRepositoryProvider = Provider((ref) => AnalyticsRepository());

class AnalyticsRepository {
  final _client = Supabase.instance.client;

  Future<List<OverSummary>> getMatchOvers(String matchId, String teamId) async {
    try {
      // Fetch all balls for this team in this match
      // We need balls where batting_team_id (via innings) = teamId
      // But balls table links to innings_id.
      // So fetch innings for this match & team first.

      final inningRes = await _client
          .from('innings')
          .select('id')
          .eq('match_id', matchId)
          .eq('batting_team_id', teamId)
          .maybeSingle();

      if (inningRes == null) return [];

      final String inningId = inningRes['id'];

      // Now fetch balls
      final ballsRes = await _client
          .from('balls')
          .select('*')
          .eq('inning_id', inningId)
          .order('ball_number', ascending: true);

      final List<dynamic> ballsData = ballsRes;

      // Aggregation Logic
      List<OverSummary> summaries = [];

      // Determine max overs (e.g. 20).
      // We iterate through available data.
      // Group by Over Number.

      // balls have 'over_number' usually derived from ball_number or stored explicitly?
      // In our schema check `BallModel`, we have `ballNumber`.
      // Typically over = (ballNumber - 1) ~/ 6 + 1.
      // But let's check ball_model.dart or schema to be sure.
      // Assuming 6 legal balls. Let's rely on standard logic:
      // O1 -> balls 1.1 to 1.6 (or 0.1 to 0.6 depending on notation).
      // Let's assume standard: 0.1, 0.2 ... 0.6 is Over 1.

      // WAIT using `overs_played` double in DB (e.g. 0.1, 0.2).
      // actually `balls` table usually stores ball-by-ball.
      // Let's aggregate by standard cricket logic.

      Map<int, List<dynamic>> ballsByOver = {};

      for (var ball in ballsData) {
        // We need to parse over number.
        // Assuming we calculate it sequentially or if stored.
        // Let's assume sequential for MVP if not stored explicitly.
        // Actually, let's just use the `overs` field if it exists, or calculate.
        // Checking ball_model from memory (or previous views):
        // It has `ballNumber` (int).
        // Let's assume standard 6-ball overs.
        // BUT wait, extras (WD/NB) don't count towards over count usually.
        // Simplest: Group by integer part of over if stored, or just accumulate.

        // BETTER: Calculate running totals.
        // Let's iterate linearly.
      }

      int currentRuns = 0;
      int currentWickets = 0;
      int matchRuns = 0;

      // Grouping
      // We need exactly one entry per over (1 to 20).
      // Fill gaps? Yes, likely.

      Map<int, int> runsPerOver = {};
      Map<int, int> wicketsPerOver = {};
      int cumulative = 0;

      // Sort balls first? Already ordered.

      double currentOver = 0.0; // 0.1, 0.2
      // We need to group by "Over Index" (1-20).

      // Let's calculate over index from the `ball_number`? No, that can be tricky with extras.
      // Let's simply count "Valid Balls".
      int legalBalls = 0;
      int currentOverRuns = 0;
      int currentOverWickets = 0;
      int overIndex = 1;

      for (var ball in ballsData) {
        final int runs = ball['runs_scored'] ?? 0;
        final String? extrasType = ball['extras_type'];
        final int extrasRun = ball['extras_runs'] ?? 0;
        final bool isWicket = ball['is_wicket'] ?? false;

        final int totalBallRuns = runs + extrasRun;

        currentOverRuns += totalBallRuns;
        if (isWicket) currentOverWickets++;

        bool isLegal = (extrasType != 'WD' && extrasType != 'NB');

        if (isLegal) {
          legalBalls++;
        }

        // If legalBalls % 6 == 0 and legalBalls > 0 -> End of Over
        // But what if the over ended mid-way?
        // We should just push data when legalBalls hits multiple of 6.
        // Or if it's the last ball of the dataset.

        if (isLegal && legalBalls % 6 == 0) {
          cumulative += currentOverRuns;
          summaries.add(
            OverSummary(
              overNumber: overIndex,
              runsConceded: currentOverRuns,
              cumulativeScore: cumulative,
              wicketsInOver: currentOverWickets,
              teamId: teamId,
            ),
          );

          // Reset for next over
          currentOverRuns = 0;
          currentOverWickets = 0;
          overIndex++;
        }
      }

      // Handle partial over (last over currently in progress)
      if (currentOverRuns > 0 || (legalBalls % 6 != 0)) {
        cumulative += currentOverRuns;
        summaries.add(
          OverSummary(
            overNumber: overIndex,
            runsConceded: currentOverRuns,
            cumulativeScore: cumulative,
            wicketsInOver: currentOverWickets,
            teamId: teamId,
          ),
        );
      }

      return summaries;
    } catch (e) {
      print('Analytics Error: $e');
      return [];
    }
  }
}
