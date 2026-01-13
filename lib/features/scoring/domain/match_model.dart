import 'team_model.dart';

class MatchModel {
  final String id;
  final String? tournamentId;
  final String? teamAId;
  final String? teamBId;
  final String? ground;
  final DateTime matchDate;
  final int oversCount;
  final String currentStatus;
  final String? winningTeamId;
  final String? tossWinnerId;
  final String? tossDecision;
  final String? resultDescription;
  
  final DateTime? scheduledDate;
  final String? matchType;
  final String? matchFormat;
  final String? venueName;
  final String? matchNotes;
  final DateTime? startedAt;
  final DateTime? endedAt;

  // Relational Objects (Nullable)
  final Team? teamA;
  final Team? teamB;

  MatchModel({
    required this.id,
    this.tournamentId,
    this.teamAId,
    this.teamBId,
    this.ground,
    required this.matchDate,
    this.oversCount = 20,
    required this.currentStatus,
    this.winningTeamId,
    this.tossWinnerId,
    this.tossDecision,
    this.resultDescription,
    this.scheduledDate,
    this.matchType,
    this.matchFormat,
    this.venueName,
    this.matchNotes,
    this.startedAt,
    this.endedAt,
    this.teamA,
    this.teamB,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'],
      tournamentId: json['tournament_id'],
      teamAId: json['team_a_id'],
      teamBId: json['team_b_id'],
      ground: json['ground'],
      matchDate: json['match_date'] != null 
          ? DateTime.tryParse(json['match_date']) ?? DateTime.now()
          : DateTime.now(),
      oversCount: json['overs_count'] ?? 20,
      currentStatus: json['status'] ?? 'Scheduled',
      winningTeamId: json['winning_team_id'],
      tossWinnerId: json['toss_winner_id'],
      tossDecision: json['toss_decision'],
      resultDescription: json['result_description'],
      scheduledDate: json['scheduled_date'] != null ? DateTime.tryParse(json['scheduled_date']) : null,
      matchType: json['match_type'],
      matchFormat: json['match_format'],
      venueName: json['venue_name'],
      matchNotes: json['match_notes'],
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at']) : null,
      teamA: json['team_a'] != null ? Team.fromJson(json['team_a']) : null,
      teamB: json['team_b'] != null ? Team.fromJson(json['team_b']) : null,
    );
  }
}
