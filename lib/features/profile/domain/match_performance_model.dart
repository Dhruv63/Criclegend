class MatchPerformance {
  final String id;
  final String matchId;
  final String teamId;
  final int? battingPosition;
  final int runsScored;
  final int ballsFaced;
  final int foursHit;
  final int sixesHit;
  final double strikeRate;
  final String? dismissalType;
  final bool isNotOut;
  final double oversBowled;
  final int runsConceded;
  final int wicketsTaken;
  final double bowlingEconomy;
  final int catchesTaken;
  final int stumpingsDone;
  final DateTime createdAt;

  MatchPerformance({
    required this.id,
    required this.matchId,
    required this.teamId,
    this.battingPosition,
    this.runsScored = 0,
    this.ballsFaced = 0,
    this.foursHit = 0,
    this.sixesHit = 0,
    this.strikeRate = 0.0,
    this.dismissalType,
    this.isNotOut = true,
    this.oversBowled = 0.0,
    this.runsConceded = 0,
    this.wicketsTaken = 0,
    this.bowlingEconomy = 0.0,
    this.catchesTaken = 0,
    this.stumpingsDone = 0,
    required this.createdAt,
  });

  factory MatchPerformance.fromJson(Map<String, dynamic> json) {
    return MatchPerformance(
      id: json['id'],
      matchId: json['match_id'],
      teamId: json['team_id'],
      battingPosition: json['batting_position'],
      runsScored: json['runs_scored'] ?? 0,
      ballsFaced: json['balls_faced'] ?? 0,
      foursHit: json['fours_hit'] ?? 0,
      sixesHit: json['sixes_hit'] ?? 0,
      strikeRate: (json['strike_rate'] ?? 0).toDouble(),
      dismissalType: json['dismissal_type'],
      isNotOut: json['is_not_out'] ?? true,
      oversBowled: (json['overs_bowled'] ?? 0).toDouble(),
      runsConceded: json['runs_conceded'] ?? 0,
      wicketsTaken: json['wickets_taken'] ?? 0,
      bowlingEconomy: (json['bowling_economy'] ?? 0).toDouble(),
      catchesTaken: json['catches_taken'] ?? 0,
      stumpingsDone: json['stumpings_done'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
