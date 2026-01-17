class PointsTableService {
  static List<Map<String, dynamic>> calculateStandings(
    List<Map<String, dynamic>> matches,
    List<Map<String, dynamic>> teams,
    String tournamentId,
  ) {
    // 1. Initialize Stats Map
    Map<String, _TeamStats> stats = {};
    for (var t in teams) {
      stats[t['id']] = _TeamStats(
        teamId: t['id'],
        name: t['name'],
        logoUrl: t['logo_url'],
      );
    }

    // 2. Process Matches
    for (var m in matches) {
      // Only processed completed matches or "No Result"
      if (m['status'] != 'Completed' && m['status'] != 'Abandoned') continue;

      String aId = m['team_a_id'];
      String bId = m['team_b_id'];
      String? winnerId = m['winner_team_id'];
      String? resultDesc = m['result_description']; // "Team A won by..."

      // Update Matches Played
      stats[aId]?.played++;
      stats[bId]?.played++;

      // Handle Abandoned
      if (m['status'] == 'Abandoned' || resultDesc == 'No Result') {
        stats[aId]?.noResult++;
        stats[bId]?.noResult++;
        stats[aId]?.points += 1;
        stats[bId]?.points += 1;
        continue;
      }

      // Handle Result
      if (winnerId == null) {
        // Tie
        stats[aId]?.tied++;
        stats[bId]?.tied++;
        stats[aId]?.points += 1;
        stats[bId]?.points += 1;
      } else if (winnerId == aId) {
        stats[aId]?.won++;
        stats[aId]?.points += 2;
        stats[bId]?.lost++;
      } else {
        stats[bId]?.won++;
        stats[bId]?.points += 2;
        stats[aId]?.lost++;
      }

      // 3. NRR Calculation Data
      // Need innings data
      List<dynamic> innings = m['innings'] ?? [];
      if (innings.isEmpty) continue; // Should not happen for Completed

      // Check format overs (default 20 if not set, or parse from match)
      double matchOvers = (m['overs'] as num?)?.toDouble() ?? 20.0;

      for (var inn in innings) {
        String battingTeamId = inn['batting_team_id'];
        String bowlingTeamId = inn['bowling_team_id'];
        int runs = inn['total_runs'] ?? 0;
        double overs = (inn['overs'] as num?)?.toDouble() ?? 0.0; // e.g. 19.3
        int wickets = inn['wickets'] ?? 0;

        // NRR Logic:
        // If All Out (10 wickets), use Match Overs
        // Else use actual overs faced

        double effectiveOversFaced = overs;
        if (wickets >= 10) {
          effectiveOversFaced = matchOvers;
        }

        // Batting Stats
        if (stats.containsKey(battingTeamId)) {
          stats[battingTeamId]!.runsScored += runs;
          stats[battingTeamId]!.oversFaced += _convertOversToBalls(
            effectiveOversFaced,
          );
        }

        // Bowling Stats
        if (stats.containsKey(bowlingTeamId)) {
          stats[bowlingTeamId]!.runsConceded += runs;
          // For bowling team, do we use effective overs of opponent? YES.
          // "The team is deemed to have batted for its full quota of overs"
          // So bowler is charged for full quota effectively in denominator?
          // Standard NRR: Yes.
          stats[bowlingTeamId]!.oversBowled += _convertOversToBalls(
            effectiveOversFaced,
          );
        }
      }
    }

    // 4. Compute NRR & Sort
    List<Map<String, dynamic>> standings = [];

    for (var s in stats.values) {
      double ballsFaced = s.oversFaced;
      double ballsBowled = s.oversBowled;

      double battingRate = ballsFaced > 0
          ? (s.runsScored / _ballsToOvers(ballsFaced))
          : 0.0;
      double bowlingRate = ballsBowled > 0
          ? (s.runsConceded / _ballsToOvers(ballsBowled))
          : 0.0;

      s.nrr = battingRate - bowlingRate;

      standings.add(s.toMap());
    }

    // Sort: Points (Desc), then NRR (Desc)
    standings.sort((a, b) {
      int pCmp = (b['points'] as int).compareTo(a['points'] as int);
      if (pCmp != 0) return pCmp;
      return (b['net_run_rate'] as double).compareTo(
        a['net_run_rate'] as double,
      );
    });

    return standings;
  }

  // Helper: 15.3 overs -> 15*6 + 3 = 93 balls
  static double _convertOversToBalls(double overs) {
    int whole = overs.truncate();
    int decimals = ((overs - whole) * 10).round(); // .3 -> 3
    return (whole * 6 + decimals).toDouble();
  }

  // Helper: 93 balls -> 15.5 (decimal overs for division)
  // Wait, standard NRR uses "Overs" as denominator?
  // 15.3 overs = 15.5 actual overs mathematically for division?
  // Yes. 93 balls / 6 = 15.5
  static double _ballsToOvers(double balls) {
    return balls / 6.0;
  }
}

class _TeamStats {
  final String teamId;
  final String name;
  final String? logoUrl;

  int played = 0;
  int won = 0;
  int lost = 0;
  int tied = 0;
  int noResult = 0;
  int points = 0;

  int runsScored = 0;
  double oversFaced = 0; // stored as balls

  int runsConceded = 0;
  double oversBowled = 0; // stored as balls

  double nrr = 0.0;

  _TeamStats({required this.teamId, required this.name, this.logoUrl});

  Map<String, dynamic> toMap() {
    return {
      'team': {'id': teamId, 'name': name, 'logo_url': logoUrl},
      'matches_played': played,
      'won': won,
      'lost': lost,
      'tied': tied,
      'points': points,
      'net_run_rate': nrr,
    };
  }
}
