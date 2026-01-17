class FixtureGenerator {
  /// Generates Round Robin fixtures for a list of teams.
  /// Uses a Cyclic Algorithm to pair teams.
  /// Handles odd number of teams by adding a dummy "BYE" team.
  static List<Map<String, dynamic>> generateRoundRobin({
    required List<String> teamIds,
    required DateTime startDate,
    required String tournamentId,
    int matchesPerDay = 2,
    bool allowBackToBack = false, // If false, team needs min 1 day rest
  }) {
    List<String> teams = List.from(teamIds);

    // Handle Odd number of teams: Add a dummy 'BYE' team
    // For odd teams, N teams means N rounds.
    // For even teams, N teams means N-1 rounds.
    // Cyclic method requires even number of slots, so add dummy if odd.
    if (teams.length % 2 != 0) {
      teams.add('BYE');
    }

    int numTeams = teams.length;
    int numRounds = numTeams - 1;
    int matchesPerRound = numTeams ~/ 2;

    List<Map<String, dynamic>> fixtures = [];
    DateTime currentDate = startDate;

    // Track team schedules to enforce rest days
    // Map<TeamID, LastMatchDate>
    Map<String, DateTime> teamLastMatchDate = {};

    // Generate Rounds (Pairings only first)
    List<List<Map<String, String>>> rounds = [];

    for (int round = 0; round < numRounds; round++) {
      List<Map<String, String>> roundMatches = [];
      for (int i = 0; i < matchesPerRound; i++) {
        String teamA = teams[i];
        String teamB = teams[numTeams - 1 - i];

        // Skip "Bye" matches for now (or store them if needed for points table display)
        // If we want to show "BYE" in UI, we should keep it.
        // But for "Matches" table, we usually only store playable matches.
        if (teamA != 'BYE' && teamB != 'BYE') {
          roundMatches.add({'team_a': teamA, 'team_b': teamB});
        }
      }
      rounds.add(roundMatches);

      // Rotate Team List (Cyclic Algorithm)
      // Keep first team fixed, rotate rest clockwise
      // [0, 1, 2, 3] -> [0, 3, 1, 2]
      if (teams.length > 1) {
        String lastTeam = teams.removeLast();
        teams.insert(1, lastTeam);
      }
    }

    // Scheduling Logic: Assign Dates & Times to Rounds
    // We treat rounds sequentially ideally, but allow overlap if needed.
    // Strict Round Robin = Finish Round 1 before Round 2 usually.

    int matchesScheduledToday = 0;

    for (var roundMatches in rounds) {
      for (var match in roundMatches) {
        String teamA = match['team_a']!;
        String teamB = match['team_b']!;

        // Find a valid slot for this match
        // Check 1: Teams must not have played "recently" if rest enforced
        // Check 2: Max matches per day limit

        bool scheduled = false;
        DateTime attemptDate = currentDate;
        int attemptMatchesToday = matchesScheduledToday;

        // Simple greedy scheduler: try to fit in current day, else move next
        // Refinement: If strictly 2 matches/day, we just adhere to that.

        // Loop until valid slot found (rarely strictly needed if we just push dates)
        while (!scheduled) {
          // Check Rest Period
          if (!allowBackToBack) {
            DateTime? lastA = teamLastMatchDate[teamA];
            DateTime? lastB = teamLastMatchDate[teamB];

            bool conflict = false;
            // If played today, definitely conflict
            if (lastA != null && _isSameDay(lastA, attemptDate)) {
              conflict = true;
            }
            if (lastB != null && _isSameDay(lastB, attemptDate)) {
              conflict = true;
            }

            // If played yesterday (Back-to-back check which we want to prevent)
            // If allowBackToBack is FALSE, we want >0 days diff.
            // Actually logic: Min 1 day gap means if played on 20th, next is 22nd? Or 21st?
            // Usually "No back to back" means cannot play consecutive days.

            if (lastA != null && attemptDate.difference(lastA).inDays < 2) {
              conflict = true; // <2 means 0 or 1 day diff
            }
            if (lastB != null && attemptDate.difference(lastB).inDays < 2) {
              conflict = true;
            }

            // Logic fix: difference().inDays is tricky. Use Day values.
            // easier: if (lastA != null && attemptDate.day == lastA.add(Duration(days:1)).day)...

            // Let's simplify: Just ensure they haven't played on attemptDate.
            // And if strictly no consecutive, check attemptDate-1.

            if (conflict) {
              // Move to next day
              attemptDate = attemptDate.add(const Duration(days: 1));
              attemptMatchesToday = 0;
              continue;
            }
          }

          // Check Slot Capacity
          if (attemptMatchesToday >= matchesPerDay) {
            attemptDate = attemptDate.add(const Duration(days: 1));
            attemptMatchesToday = 0;
            continue;
          }

          // Found Slot!
          scheduled = true;

          // Assign Time: 10 AM or 2 PM
          int hour = (attemptMatchesToday % 2 == 0) ? 10 : 14;
          DateTime finalTime = DateTime(
            attemptDate.year,
            attemptDate.month,
            attemptDate.day,
            hour,
            0,
          );

          fixtures.add({
            'tournament_id': tournamentId,
            'team_a_id': teamA,
            'team_b_id': teamB,
            'status': 'Scheduled',
            'match_date': finalTime.toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'is_mock': false,
          });

          // Update Tracking
          teamLastMatchDate[teamA] = finalTime;
          teamLastMatchDate[teamB] = finalTime;

          // Update Global Date Pointer if we moved days
          if (attemptDate.isAfter(currentDate)) {
            currentDate = attemptDate;
            matchesScheduledToday = attemptMatchesToday + 1;
          } else {
            matchesScheduledToday++;
          }
        }
      }
    }

    return fixtures;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
