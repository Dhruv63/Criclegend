class FixtureGenerator {
  /// Generates Round Robin fixtures for a list of teams.
  /// Uses a Cyclic Algorithm to pair teams.
  /// Handles odd number of teams by adding a dummy "Bye" team.
  static List<Map<String, dynamic>> generateRoundRobin({
    required List<String> teamIds,
    required DateTime startDate,
    required String tournamentId,
  }) {
    List<String> teams = List.from(teamIds);
    
    // Handle Odd number of teams: Add a dummy 'Bye' team
    if (teams.length % 2 != 0) {
      teams.add('BYE'); // Placeholder for "Bye"
    }

    int numTeams = teams.length;
    int numRounds = numTeams - 1;
    int matchesPerRound = numTeams ~/ 2;

    List<Map<String, dynamic>> fixtures = [];
    DateTime currentDate = startDate;
    
    // Scheduling Config
    // Match 1: 10:00 AM
    // Match 2: 02:00 PM
    // If only 1 match/day -> 10:00 AM
    // Days increment every 2 matches.
    
    int totalMatchesScheduled = 0;

    for (int round = 0; round < numRounds; round++) {
      for (int i = 0; i < matchesPerRound; i++) {
        String teamA = teams[i];
        String teamB = teams[numTeams - 1 - i];

        // Skip "Bye" matches
        if (teamA == 'BYE' || teamB == 'BYE') continue;

        // Determine Schedule Time
        // Slot 1: 10:00 AM
        // Slot 2: 02:00 PM
        DateTime matchTime = DateTime(
          currentDate.year, 
          currentDate.month, 
          currentDate.day, 
          (totalMatchesScheduled % 2 == 0) ? 10 : 14, // 10 AM or 2 PM
          0
        );

        fixtures.add({
          'tournament_id': tournamentId,
          'team_a_id': teamA,
          'team_b_id': teamB,
          'status': 'Scheduled',
          'match_date': matchTime.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'is_mock': false, // Real generated match
        });
        
        totalMatchesScheduled++;
        
         // Increment Day if we filled the slots (2 per day)
         if (totalMatchesScheduled % 2 == 0) {
           currentDate = currentDate.add(const Duration(days: 1));
         }
      }

      // Rotate Team List (Cyclic Algorithm)
      // Keep first team fixed, rotate rest clockwise
      // [0, 1, 2, 3] -> [0, 3, 1, 2]
      if (teams.length > 1) {
         String lastTeam = teams.removeLast();
         teams.insert(1, lastTeam);
      }
    }
    
    // If finished on an odd match (1 match on last day), ensure next day starts fresh (not needed here but good logic)
    
    return fixtures;
  }
}
