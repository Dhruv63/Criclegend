
class BallModel {
  final String matchId;
  final String inningId;
  final int overNumber;
  final int ballNumber;
  final int runsScored;
  final String? extrasType; // 'wide', 'noball', 'bye', 'legbye'
  final int extrasRuns;
  final bool isWicket;
  final String? wicketType; // 'bowled', 'caught', etc.
  final String? dismissedPlayerId;
  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;
  
  final String? shotZone;
  final String? dismissalType;
  final String? dismissalFielderId;
  
  // Snapshot State (Post-Ball)
  final int matchTotalRuns;
  final int matchWickets;
  final double matchOvers;

  final DateTime? createdAt;

  const BallModel({
    required this.matchId,
    required this.inningId,
    required this.overNumber,
    required this.ballNumber,
    this.runsScored = 0,
    this.extrasType,
    this.extrasRuns = 0,
    this.isWicket = false,
    this.wicketType,
    this.dismissedPlayerId,
    this.shotZone,
    this.dismissalType,
    this.dismissalFielderId,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
    required this.matchTotalRuns,
    required this.matchWickets,
    required this.matchOvers,
    this.createdAt,
  });

  // Convert to Map for Supabase Insert
  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'inning_id': inningId,
      'over_number': overNumber,
      'ball_number': ballNumber,
      'runs_scored': runsScored,
      'extras_type': extrasType,
      'extras_runs': extrasRuns,
      'is_wicket': isWicket,
      'wicket_type': wicketType,
      'dismissed_player_id': dismissedPlayerId,
      'shot_zone': shotZone,
      'dismissal_type': dismissalType,
      'dismissal_fielder_id': dismissalFielderId,
      'striker_id': strikerId, 
      'non_striker_id': nonStrikerId,
      'bowler_id': bowlerId,
    };
  }

  // Create from Map (for reading from Queue Persistence)
  factory BallModel.fromJson(Map<String, dynamic> json) {
    return BallModel(
      matchId: json['match_id'],
      inningId: json['inning_id'],
      overNumber: json['over_number'],
      ballNumber: json['ball_number'],
      runsScored: json['runs_scored'] ?? 0,
      extrasType: json['extras_type'],
      extrasRuns: json['extras_runs'] ?? 0,
      isWicket: json['is_wicket'] ?? false,
      wicketType: json['wicket_type'],
      dismissedPlayerId: json['dismissed_player_id'],
      shotZone: json['shot_zone'],
      dismissalType: json['dismissal_type'],
      dismissalFielderId: json['dismissal_fielder_id'],
      strikerId: json['striker_id'],
      nonStrikerId: json['non_striker_id'],
      bowlerId: json['bowler_id'],
      matchTotalRuns: json['snapshot_total_runs'] ?? 0,
      matchWickets: json['snapshot_wickets'] ?? 0,
      matchOvers: json['snapshot_overs'] ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
  
  // Custom 'toQueueJson' to include snapshots
  Map<String, dynamic> toQueueJson() {
    final m = toJson();
    m['snapshot_total_runs'] = matchTotalRuns;
    m['snapshot_wickets'] = matchWickets;
    m['snapshot_overs'] = matchOvers;
    return m;
  }
}
