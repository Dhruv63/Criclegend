import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scoring_state.dart';

// The Notifier (Riverpod 2.0 Style)
class ScoringNotifier extends Notifier<ScoringState> {
  @override
  ScoringState build() {
    return ScoringState();
  }

  Future<void> loadMatch(String matchId) async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: Fetch match from repository
      // final repo = ref.read(scoringRepositoryProvider);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> recordBall({
    required int runs,
    required bool isWide,
    required bool isNoBall,
    required bool isWicket,
    String? wicketType,
  }) async {
    // Current State
    int currentRuns = state.totalRuns;
    int currentWickets = state.wickets;
    int balls = state.currentBallInOver;
    int overs = state.oversBowled;

    // Logic
    int ballRuns = runs;
    int extraRuns = 0;

    if (isWide || isNoBall) {
      extraRuns += 1;
      // Wide/NB doesn't count as a legal ball
    } else {
      balls += 1;
    }

    // Total for this event
    currentRuns += ballRuns + extraRuns;

    if (isWicket) {
      currentWickets += 1;
    }

    // Over Completion
    if (balls >= 6) {
      overs += 1;
      balls = 0;
    }

    // Update State Optimistically
    state = state.copyWith(
      totalRuns: currentRuns,
      wickets: currentWickets,
      oversBowled: overs,
      currentBallInOver: balls,
    );

    // Persist via ref.read(scoringRepositoryProvider).recordBall(...)
  }
}

// The Provider
final scoringProvider = NotifierProvider<ScoringNotifier, ScoringState>(
  ScoringNotifier.new,
);
