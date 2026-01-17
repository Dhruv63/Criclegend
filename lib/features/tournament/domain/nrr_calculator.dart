class NRRCalculator {
  /// Calculates Points based on standard rules:
  /// Win = 2, Tie/NR = 1, Loss = 0
  static int calculatePoints(int won, int tied, int noResult) {
    return (won * 2) + (tied * 1) + (noResult * 1);
  }

  /// Calculates Net Run Rate (NRR)
  /// Formula: (Total Runs Scored / Total Overs Faced) - (Total Runs Conceded / Total Overs Bowled)
  ///
  /// Important:
  /// - Overs are typically stored as 10.4 (10 overs, 4 balls).
  /// - For calculation, 10.4 must be converted to 10 + (4/6) = 10.6666
  static double calculateNRR({
    required int runsScored,
    required double oversFaced,
    required int runsConceded,
    required double oversBowled,
  }) {
    if (oversFaced == 0 && oversBowled == 0) return 0.0;

    double oversFacedNormalized = _normalizeOvers(oversFaced);
    double oversBowledNormalized = _normalizeOvers(oversBowled);

    // Prevent Division by Zero
    if (oversFacedNormalized == 0) oversFacedNormalized = 1.0;
    // Technically if faced 0 overs but scored runs (impossible/penalty?), handle graceful.
    // If a team batted 0 overs, their run rate is 0.

    // Calculate Team Run Rate
    double teamRunRate = (oversFacedNormalized > 0)
        ? runsScored / oversFacedNormalized
        : 0.0;

    // Calculate Opponent Run Rate
    double opponentRunRate = (oversBowledNormalized > 0)
        ? runsConceded / oversBowledNormalized
        : 0.0;

    // NRR
    return teamRunRate - opponentRunRate;
  }

  /// Helper to convert cricket overs (e.g. 10.4) to decimal (e.g. 10.666)
  static double _normalizeOvers(double overs) {
    int wholeOvers = overs.toInt();
    int balls = ((overs - wholeOvers) * 10).round(); // 10.4 -> 0.4 * 10 = 4.0

    // Safety check for balls > 6 (should not happen in valid data, but defensive coding)
    if (balls >= 6) {
      wholeOvers += balls ~/ 6;
      balls = balls % 6;
    }

    return wholeOvers + (balls / 6.0);
  }
}
