import '../domain/match_model.dart';

class ScoringState {
  final MatchModel? match;
  final int totalRuns;
  final int wickets;
  final int oversBowled; // Complete overs
  final int currentBallInOver; // 1-6

  // IDs of current players
  final String? strikerId;
  final String? nonStrikerId;
  final String? bowlerId;

  final bool isLoading;
  final String? error;

  ScoringState({
    this.match,
    this.totalRuns = 0,
    this.wickets = 0,
    this.oversBowled = 0,
    this.currentBallInOver = 0,
    this.strikerId,
    this.nonStrikerId,
    this.bowlerId,
    this.isLoading = false,
    this.error,
  });

  ScoringState copyWith({
    MatchModel? match,
    int? totalRuns,
    int? wickets,
    int? oversBowled,
    int? currentBallInOver,
    String? strikerId,
    String? nonStrikerId,
    String? bowlerId,
    bool? isLoading,
    String? error,
  }) {
    return ScoringState(
      match: match ?? this.match,
      totalRuns: totalRuns ?? this.totalRuns,
      wickets: wickets ?? this.wickets,
      oversBowled: oversBowled ?? this.oversBowled,
      currentBallInOver: currentBallInOver ?? this.currentBallInOver,
      strikerId: strikerId ?? this.strikerId,
      nonStrikerId: nonStrikerId ?? this.nonStrikerId,
      bowlerId: bowlerId ?? this.bowlerId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
