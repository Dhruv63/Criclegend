class PlayerStats {
  final String id;
  final String userId;

  // Batting
  final int totalMatches;
  final int inningsBatted;
  final int totalRuns;
  final int ballsFaced;
  final int totalFours;
  final int totalSixes;
  final int highestScore;
  final int timesNotOut;
  final int fifties;
  final int centuries;
  final int ducks;
  final double battingAverage;
  final double battingStrikeRate;

  // Bowling
  final int inningsBowled;
  final double totalOversBowled;
  final int totalBallsBowled;
  final int totalRunsConceded;
  final int totalWickets;
  final String? bestBowlingFigures;
  final int fiveWicketHauls;
  final double bowlingAverage;
  final double bowlingEconomy;
  final double bowlingStrikeRate;

  // Fielding
  final int totalCatches;
  final int totalStumpings;
  final int totalRunOuts;

  PlayerStats({
    required this.id,
    required this.userId,
    this.totalMatches = 0,
    this.inningsBatted = 0,
    this.totalRuns = 0,
    this.ballsFaced = 0,
    this.totalFours = 0,
    this.totalSixes = 0,
    this.highestScore = 0,
    this.timesNotOut = 0,
    this.fifties = 0,
    this.centuries = 0,
    this.ducks = 0,
    this.battingAverage = 0.0,
    this.battingStrikeRate = 0.0,
    this.inningsBowled = 0,
    this.totalOversBowled = 0.0,
    this.totalBallsBowled = 0,
    this.totalRunsConceded = 0,
    this.totalWickets = 0,
    this.bestBowlingFigures,
    this.fiveWicketHauls = 0,
    this.bowlingAverage = 0.0,
    this.bowlingEconomy = 0.0,
    this.bowlingStrikeRate = 0.0,
    this.totalCatches = 0,
    this.totalStumpings = 0,
    this.totalRunOuts = 0,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      id: json['id'],
      userId: json['user_id'],
      totalMatches: json['total_matches'] ?? 0,
      inningsBatted: json['innings_batted'] ?? 0,
      totalRuns: json['total_runs'] ?? 0,
      ballsFaced: json['total_balls_faced'] ?? 0,
      totalFours: json['total_fours'] ?? 0,
      totalSixes: json['total_sixes'] ?? 0,
      highestScore: json['highest_score'] ?? 0,
      timesNotOut: json['times_not_out'] ?? 0,
      fifties: json['fifties'] ?? 0,
      centuries: json['centuries'] ?? 0,
      ducks: json['ducks'] ?? 0,
      battingAverage: (json['batting_average'] ?? 0).toDouble(),
      battingStrikeRate: (json['batting_strike_rate'] ?? 0).toDouble(),
      inningsBowled: json['innings_bowled'] ?? 0,
      totalOversBowled: (json['total_overs_bowled'] ?? 0).toDouble(),
      totalBallsBowled: json['total_balls_bowled'] ?? 0,
      totalRunsConceded: json['total_runs_conceded'] ?? 0,
      totalWickets: json['total_wickets'] ?? 0,
      bestBowlingFigures: json['best_bowling_figures'],
      fiveWicketHauls: json['five_wicket_hauls'] ?? 0,
      bowlingAverage: (json['bowling_average'] ?? 0).toDouble(),
      bowlingEconomy: (json['bowling_economy'] ?? 0).toDouble(),
      bowlingStrikeRate: (json['bowling_strike_rate'] ?? 0).toDouble(),
      totalCatches: json['total_catches'] ?? 0,
      totalStumpings: json['total_stumpings'] ?? 0,
      totalRunOuts: json['total_run_outs'] ?? 0,
    );
  }
}
