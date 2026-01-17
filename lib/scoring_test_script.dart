// pure dart

/// A pure Dart simulation of the Scoring Logic to verify correctness.
/// Run this file to test the core math.
library;

void main() async {
  print("--- STARTING SCORING LOGIC TEST ---");

  // Initial State
  int totalRuns = 0;
  int wickets = 0;
  double overs = 0.0;
  String striker = "A";
  String nonStriker = "B";

  void printState() => print(
    "Overs: $overs | Score: $totalRuns/$wickets | Batting: $striker (Str) - $nonStriker (Non)",
  );

  void swap() {
    final temp = striker;
    striker = nonStriker;
    nonStriker = temp;
    print("  >> SWAP BATSMEN -> Now Striker: $striker");
  }

  void handleBall(
    int runs, {
    bool isWide = false,
    bool isNoBall = false,
    bool isWicket = false,
  }) {
    // 1. Calculate Score
    int extra = (isWide || isNoBall) ? 1 : 0;
    totalRuns += runs + extra;

    // 2. Calculate Overs
    bool isLegal = !isWide && !isNoBall;

    // Current ball in over (0-5)
    // Logic from App:
    int totalBalls = ((overs.floor() * 6) + ((overs % 1) * 10).round());
    if (isLegal) totalBalls++;

    int ballNum = totalBalls % 6;
    if (ballNum == 0 && isLegal) ballNum = 6;

    // Update Overs
    if (isLegal) {
      overs = (totalBalls ~/ 6) + (totalBalls % 6) / 10.0;
    }

    print("Ball Event: Runs=$runs, Wide=$isWide, NB=$isNoBall");

    // 3. Swap Logic (Run Swap)
    if (runs % 2 != 0) {
      swap();
    }

    // 4. End of Over Logic
    if (isLegal && ballNum == 6) {
      print("  >> END OF OVER");
      swap(); // End of over swap
    }

    printState();
  }

  // TEST CASES

  // 1. Single Run (Should Swap)
  print("\nTest 1: Single Run");
  handleBall(1);
  // Expected: A swaps to Non. B becomes Striker.
  assert(striker == "B", "FAIL: Striker should be B");

  // 2. Dot Ball (No Swap)
  print("\nTest 2: Dot Ball");
  handleBall(0);
  assert(striker == "B", "FAIL: Striker should be B");

  // 3. Three Runs (Should Swap)
  print("\nTest 3: Three Runs");
  handleBall(3);
  assert(striker == "A", "FAIL: Striker should be A");

  // 4. Wide Ball (1 Run, No Swap)
  print("\nTest 4: Wide Ball (Standard)");
  handleBall(0, isWide: true);
  // Total Runs should be 1 + 0 + 3 + 1 = 5
  assert(totalRuns == 5, "FAIL: Total runs should be 5");
  assert(striker == "A", "FAIL: Wide should not swap striker (0 runs)");

  // 5. End of Over (Ball 4, 5, 6)
  // Current Overs: 0.3. Need 3 more legal balls.
  print("\nTest 5: Finishing Over");
  handleBall(0); // 0.4
  handleBall(1); // 0.5. Swap -> Striker is B.
  // Last ball of over.
  // Striker is B. Non is A.
  // If B scores 1 run:
  //   Swap 1 (Run): Striker -> A.
  //   Swap 2 (End Over): Striker -> B.
  //   Next Over facing: B.
  print("  -- Last Ball (1 Run) --");
  handleBall(1); // 1.0.

  assert(overs == 1.0, "FAIL: Should be 1.0 overs");
  assert(
    striker == "B",
    "FAIL: After 1 run on last ball, B should be facing next over.",
  );

  print("\n--- ALL TESTS PASSED ---");
}
