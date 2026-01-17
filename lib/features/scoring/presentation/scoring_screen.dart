import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/supabase_service.dart';
import '../domain/ball_model.dart';
import '../data/scoring_queue_service.dart';
import 'widgets/advanced_scoring_widgets.dart';
import 'widgets/wagon_wheel_chart.dart';

class ScoringScreen extends StatefulWidget {
  final String matchId;
  const ScoringScreen({super.key, required this.matchId});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  // Data
  Map<String, dynamic>? _matchData;
  Map<String, dynamic>? _activeInning;
  List<Map<String, dynamic>> _battingSquad = [];
  List<Map<String, dynamic>> _bowlingSquad = [];

  // Match Settings
  int _matchOversLimit = 0;

  // State
  bool _isLoading = true;
  int _totalRuns = 0;
  int _wickets = 0;
  double _overs = 0.0;

  // Target (for 2nd innings)
  int? _targetRuns;

  // Active IDs
  String? _inningId;
  int _inningNumber = 1;
  String? _strikerId;
  String? _nonStrikerId;
  String? _bowlerId;

  // Processing Lock
  bool _isProcessingInningsEnd = false;

  // UI Helpers
  Map<String, dynamic>? get _striker => _getPlayer(_strikerId);
  Map<String, dynamic>? get _nonStriker => _getPlayer(_nonStrikerId);
  Map<String, dynamic>? get _bowler => _getPlayer(_bowlerId);

  Map<String, dynamic>? _getPlayer(String? id) {
    if (id == null) return null;
    return [..._battingSquad, ..._bowlingSquad].firstWhere(
      (p) => p['id'] == id,
      orElse: () => {
        'profile_json': {'name': 'Unknown'},
      },
    );
  }

  @override
  void initState() {
    super.initState();
    ScoringQueueService().init();
    _initMatch();
  }

  Future<void> _initMatch() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getMatchFullDetails(widget.matchId);
      if (data != null) {
        _matchData = data;
        _matchOversLimit = data['overs'] ?? 20;

        // Start Match if not started
        await SupabaseService.startMatch(
          widget.matchId,
          data['team_a_id'],
          data['team_b_id'],
        );

        // Refresh to get the created innings
        final refreshed = await SupabaseService.getMatchFullDetails(
          widget.matchId,
        );
        _matchData = refreshed;

        // Set Active Inning
        final innings = List<Map<String, dynamic>>.from(refreshed!['innings']);
        if (innings.isEmpty) throw "No innings found for this match.";

        // Sort by innings number
        innings.sort(
          (a, b) =>
              (a['innings_number'] ?? 0).compareTo(b['innings_number'] ?? 0),
        );

        // Find active inning (not completed)
        _activeInning = innings.firstWhere(
          (i) => i['is_completed'] == false,
          orElse: () => innings.last,
        );

        // Calculate Target if 2nd innings
        if (innings.length > 1) {
          final firstInnings = innings.firstWhere(
            (i) => i['innings_number'] == 1,
          );
          if (firstInnings['is_completed'] == true) {
            _targetRuns = (firstInnings['total_runs'] as int) + 1;
          }
        }

        if (_activeInning != null) {
          _inningId = _activeInning!['id'];
          _inningNumber = _activeInning!['innings_number'] ?? 1;
          _totalRuns = _activeInning!['total_runs'] ?? 0;
          _wickets = _activeInning!['wickets'] ?? 0;
          _overs = (_activeInning!['overs_played'] ?? 0).toDouble();

          _strikerId = _activeInning!['striker_id'];
          _nonStrikerId = _activeInning!['non_striker_id'];
          _bowlerId = _activeInning!['bowler_id'];

          // Fallback Team Logic
          var batTeamId = _activeInning!['batting_team_id'];
          var bowlTeamId = _activeInning!['bowling_team_id'];

          if (batTeamId == null) {
            final isInn1 = _inningNumber == 1;
            batTeamId = isInn1 ? data['team_a_id'] : data['team_b_id'];
          }
          if (bowlTeamId == null) {
            final isInn1 = _inningNumber == 1;
            bowlTeamId = isInn1 ? data['team_b_id'] : data['team_a_id'];
          }

          // Fetch Squads
          if (batTeamId != null) {
            _battingSquad = await SupabaseService.getTeamPlayers(batTeamId);
          }
          if (bowlTeamId != null) {
            _bowlingSquad = await SupabaseService.getTeamPlayers(bowlTeamId);
          }

          // Auto-Pick defaults if missing
          if (_strikerId == null && _battingSquad.isNotEmpty) {
            _strikerId = _battingSquad[0]['id'];
          }
          if (_nonStrikerId == null && _battingSquad.length > 1) {
            _nonStrikerId = _battingSquad[1]['id'];
          }
          if (_bowlerId == null && _bowlingSquad.isNotEmpty) {
            _bowlerId = _bowlingSquad[0]['id'];
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading match: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC ---

  Future<void> _handleBall(
    int runs, {
    bool isWide = false,
    bool isNoBall = false,
    bool isBye = false,
    bool isLegBye = false,
    bool isWicket = false,
    String? wicketType,
    String? fielderId,
    String? dismissType,
    String? zone,
  }) async {
    if (_inningId == null) return;

    // Prevent actions if innings is ending
    if (_isProcessingInningsEnd) return;

    if (_strikerId == null || _nonStrikerId == null || _bowlerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ensure Batsmen and Bowler are selected!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Wagon Wheel Trigger
    String? finalZone = zone;
    if (finalZone == null &&
        !isWide &&
        !isWicket &&
        (runs >= 3 || runs == 4 || runs == 6)) {
      finalZone = await showDialog<String>(
        context: context,
        builder: (ctx) => const WagonWheelSelector(),
      );
    }

    // 1. Calculate New State
    int extras = 0;
    if (isWide || isNoBall) extras = 1 + runs;
    if (isBye || isLegBye) extras = runs;

    int totalBallRuns = runs;
    if (isWide || isNoBall) totalBallRuns = 1 + runs;
    if (isBye || isLegBye) totalBallRuns = runs;

    int runsToAdd = totalBallRuns;

    int newTotalRuns = _totalRuns + runsToAdd;
    int newWickets = _wickets + (isWicket ? 1 : 0);

    // Overs Update checks
    double newOvers = _overs;
    int ballNum = 0;

    bool isLegal = !isWide && !isNoBall;

    if (isLegal) {
      int totalValidBalls =
          ((_overs.floor() * 6) + ((_overs % 1) * 10).round());
      totalValidBalls++;

      ballNum = totalValidBalls % 6;
      if (ballNum == 0) ballNum = 6;

      newOvers = (totalValidBalls ~/ 6) + (totalValidBalls % 6) / 10.0;
    } else {
      // Ball count doesn't increase for WD/NB
      int totalValidBalls =
          ((_overs.floor() * 6) + ((_overs % 1) * 10).round());
      ballNum =
          (totalValidBalls % 6) +
          1; // Used for ball_number in DB, not for over calculation
    }

    // 2. Optimistic UI Update
    setState(() {
      _totalRuns = newTotalRuns;
      _wickets = newWickets;
      _overs = newOvers;
    });

    // 3. Batting Swap Logic (Odd runs swap)
    if (runs % 2 != 0) {
      _swapBatsmen();
    }

    // 4. Record to Queue
    final ball = BallModel(
      matchId: widget.matchId,
      inningId: _inningId!,
      overNumber: newOvers.floor() + (ballNum == 6 ? 0 : 1),
      ballNumber: ballNum,
      runsScored: runs,
      extrasType: isWide
          ? 'wide'
          : (isNoBall
                ? 'noball'
                : (isBye ? 'bye' : (isLegBye ? 'legbye' : null))),
      extrasRuns: extras,
      isWicket: isWicket,
      wicketType: dismissType ?? wicketType,
      dismissedPlayerId: isWicket ? _strikerId : null,
      shotZone: finalZone,
      dismissalType: dismissType,
      dismissalFielderId: fielderId,
      strikerId: _strikerId ?? '',
      nonStrikerId: _nonStrikerId ?? '',
      bowlerId: _bowlerId ?? '',
      matchTotalRuns: newTotalRuns,
      matchWickets: newWickets,
      matchOvers: newOvers,
    );

    ScoringQueueService().enqueue(ball);

    // 5. Check Innings End
    bool inningsEnded = await _checkAndHandleInningsEnd(
      newTotalRuns,
      newWickets,
      newOvers,
    );

    // 6. Over Completion Checks (Only if innings NOT ended)
    if (!inningsEnded && isLegal && ballNum == 6) {
      _swapBatsmen();
      Future.delayed(const Duration(milliseconds: 500), _openNewBowlerModal);
    }
  }

  // --- INNINGS END LOGIC ---

  Future<bool> _checkAndHandleInningsEnd(
    int runs,
    int wickets,
    double overs,
  ) async {
    // 1. Overs Check
    // Convert overs to raw ball count for accurate comparison
    // 20.0 overs = 120 balls.
    int totalBallsBowled = ((overs.floor() * 6) + ((overs % 1) * 10).round());
    int matchTotalBalls = _matchOversLimit * 6;

    bool oversCompleted = totalBallsBowled >= matchTotalBalls;
    bool allOut = wickets >= 10; // Assuming 11 players per team, so 10 wickets.

    bool targetChased = false;
    if (_inningNumber == 2 && _targetRuns != null) {
      targetChased = runs >= _targetRuns!;
    }

    if (oversCompleted || allOut || targetChased) {
      String reason = oversCompleted
          ? 'Overs Completed'
          : (allOut ? 'All Out' : 'Target Chased');
      await _endCurrentInnings(reason);
      return true;
    }
    return false;
  }

  Future<void> _endCurrentInnings(String reason) async {
    if (_isProcessingInningsEnd) return;
    _isProcessingInningsEnd = true;

    try {
      // Update DB
      await Supabase.instance.client
          .from('innings')
          .update({
            'is_completed': true,
            'total_runs': _totalRuns,
            'wickets': _wickets,
            'overs_played': _overs,
            // 'end_reason': reason // Column usually doesn't exist, skipping
          })
          .eq('id', _inningId!);

      // Show Summary
      await _showInningsCompleteSummary(reason);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error ending innings: $e")));
      _isProcessingInningsEnd =
          false; // Release lock if error (so user can retry)
    }
    // Note: _isProcessingInningsEnd stays true on success until we navigate or reload
  }

  Future<void> _showInningsCompleteSummary(String reason) async {
    String title = _inningNumber == 1
        ? "First Innings Complete"
        : "Match Complete";

    // Determine team names safely
    String battingTeamName = "Batting Team";
    if (_activeInning != null && _matchData != null) {
      final batId = _activeInning!['batting_team_id'];
      if (batId == _matchData!['team_a_id']) {
        battingTeamName = _matchData!['team_a']['name'];
      } else {
        battingTeamName = _matchData!['team_b']['name'];
      }
    }

    String msg = _inningNumber == 1
        ? "$battingTeamName scored $_totalRuns/$_wickets in $_overs overs."
        : "Match Ended by $reason";

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              "Reason: $reason",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            if (_inningNumber == 1) ...[
              const Divider(),
              Text(
                "Target for 2nd Innings: ${_totalRuns + 1}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_inningNumber == 1)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _startSecondInnings();
              },
              child: const Text("Start 2nd Innings"),
            )
          else
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _calculateAndEndMatch();
              },
              child: const Text("View Result"),
            ),
        ],
      ),
    );
  }

  Future<void> _startSecondInnings() async {
    try {
      setState(() => _isLoading = true);

      // Swap Teams
      final prevBat = _activeInning?['batting_team_id'];
      final prevBowl = _activeInning?['bowling_team_id'];

      // Insert 2nd Innings
      final res = await Supabase.instance.client
          .from('innings')
          .insert({
            'match_id': widget.matchId,
            'innings_number': 2,
            'batting_team_id': prevBowl, // Swap
            'bowling_team_id': prevBat, // Swap
            'is_completed': false,
            'total_runs': 0,
            'wickets': 0,
            'overs_played': 0,
          })
          .select()
          .single();

      // Update Match Status
      await Supabase.instance.client
          .from('matches')
          .update({'current_innings': 2, 'status': 'second_innings'})
          .eq('id', widget.matchId);

      _isProcessingInningsEnd = false; // Unlock

      await _initMatch(); // Reload everything

      // Prompt for Openers
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Second Innings Started! Select Openers."),
          ),
        );
        await _openNewBatsmanModal(); // Select Striker
        // Note: Non-striker and bowler selection will follow naturally or can be forced
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error starting 2nd Innings: $e")),
        );
        setState(() => _isLoading = false);
        _isProcessingInningsEnd = false;
      }
    }
  }

  Future<void> _calculateAndEndMatch() async {
    // Logic mostly duplicate of _showEndMatchDialog but automated
    await _showEndMatchDialog();
  }

  void _swapBatsmen() {
    setState(() {
      final temp = _strikerId;
      _strikerId = _nonStrikerId;
      _nonStrikerId = temp;
    });
  }

  // --- ACTIONS ---

  Future<void> _handleWicketClick() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DismissalDialog(
        fieldingTeam: _bowlingSquad,
        battingTeam: _battingSquad
            .where((p) => p['id'] != _strikerId && p['id'] != _nonStrikerId)
            .toList(),
      ),
    );

    if (result != null) {
      final type = result['type'] as String;
      final fielderId = result['fielderId'] as String?;
      final newStrikerId = result['newStrikerId'] as String?;

      // 1. Record the Wicket Ball
      await _handleBall(
        0,
        isWicket: true,
        dismissType: type,
        fielderId: fielderId,
      );

      // 2. Set New Striker (Only if innings didn't end)
      // We check _isProcessingInningsEnd to avoid setting striker if match ended
      if (newStrikerId != null && !_isProcessingInningsEnd) {
        setState(() => _strikerId = newStrikerId);
        await Supabase.instance.client
            .from('innings')
            .update({'striker_id': _strikerId})
            .eq('id', _inningId!);
      }
    }
  }

  Future<void> _handleNoBallClick() async {
    final runs = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Runs off Bat (No Ball)'),
        children: [0, 1, 2, 3, 4, 6]
            .map(
              (r) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, r),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('$r Runs', style: const TextStyle(fontSize: 18)),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (runs != null) {
      _handleBall(runs, isNoBall: true);
    }
  }

  Future<void> _handleUndo() async {
    bool success = await ScoringQueueService().undoLastBall();
    if (!success) {
      // If local queue is empty, try Server Undo
      if (_inningId != null) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Undoing on server..."),
              duration: Duration(milliseconds: 500),
            ),
          );
          await SupabaseService.undoLastBall(_inningId!);
          success = true;
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Undo failed: $e")));
        }
      }
    }

    if (success) {
      // If we undo, we should ensure the UI reflects it.
      // And importantly, if we undid the "last ball" that caused innings end, the innings technically might need to "re-open".
      // But since we navigate away on match end, this button is usually only accessible active match.
      await _initMatch();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Last ball undone!")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Nothing to undo!")));
      }
    }
  }

  // --- MODALS ---

  Future<void> _openNewBatsmanModal() async {
    final newBatId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _PlayerSelectionList(
        players: _battingSquad,
        title: "Select New Batsman",
      ),
    );
    if (newBatId != null) {
      setState(() => _strikerId = newBatId);
      await Supabase.instance.client
          .from('innings')
          .update({'striker_id': _strikerId})
          .eq('id', _inningId!);
    }
  }

  Future<void> _openNewBowlerModal() async {
    final newBowlId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _PlayerSelectionList(
        players: _bowlingSquad,
        title: "Select Next Bowler",
      ),
    );
    if (newBowlId != null) {
      setState(() => _bowlerId = newBowlId);
      await Supabase.instance.client
          .from('innings')
          .update({'bowler_id': _bowlerId})
          .eq('id', _inningId!);
    }
  }

  Future<void> _showStatsModal() async {
    if (_inningId == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await Supabase.instance.client
          .from('balls')
          .select()
          .eq('inning_id', _inningId!);
      final balls = (response as List)
          .map((e) => BallModel.fromJson(e))
          .toList();

      if (mounted) {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Match Analytics",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(child: WagonWheelStatsWidget(balls: balls)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching stats: $e")));
    }
  }

  Future<void> _showEndMatchDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final fullData = await SupabaseService.getMatchFullDetails(
        widget.matchId,
      );
      if (!mounted) return;
      Navigator.pop(context);

      if (fullData == null) return;

      final innings = List<Map<String, dynamic>>.from(fullData['innings']);
      innings.sort(
        (a, b) =>
            (a['innings_number'] ?? 0).compareTo(b['innings_number'] ?? 0),
      );

      if (innings.isEmpty) return;

      final i1 = innings[0];
      final i2 = innings.length > 1 ? innings[1] : null;

      final i1Runs = i1['total_runs'] ?? 0;
      final i2Runs = i2?['total_runs'] ?? 0;
      final i2Wickets = i2?['wickets'] ?? 0;

      final teamA = fullData['team_a'];
      final teamB = fullData['team_b'];

      String? winningTeamId;
      String resultText = "Match Ended";

      final bat1Id = i1['batting_team_id'];
      final bat2Id = i2?['batting_team_id'];

      final teamBat1Name = bat1Id == teamA['id']
          ? teamA['name']
          : teamB['name'];
      final teamBat2Name = bat2Id == teamA['id']
          ? teamA['name']
          : teamB['name'];

      if (i1Runs > i2Runs) {
        winningTeamId = bat1Id;
        final margin = i1Runs - i2Runs;
        resultText = "$teamBat1Name won by $margin runs";
      } else if (i2Runs > i1Runs) {
        winningTeamId = bat2Id;
        final wicketsLeft = 10 - (i2Wickets as int);
        resultText = "$teamBat2Name won by $wicketsLeft wickets";
      } else {
        resultText = "Match Tied";
        winningTeamId = null;
      }

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("End Match?"),
          content: Text("Result: $resultText"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await SupabaseService.endMatch(
                  matchId: widget.matchId,
                  winningTeamId: winningTeamId ?? '', // Handle tie
                  resultDescription: resultText,
                );
                if (mounted) context.go('/home');
              },
              child: const Text("Confirm & End"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error ending match: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Calculate Runs Required (if 2nd Innings)
    String? statusMsg;
    if (_inningNumber == 2 && _targetRuns != null) {
      int needed = _targetRuns! - _totalRuns;
      int ballsLeft =
          (_matchOversLimit * 6) -
          ((_overs.floor() * 6) + ((_overs % 1) * 10).round());
      if (needed <= 0) needed = 0;
      statusMsg = "Target: $_targetRuns | Need $needed off $ballsLeft balls";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoring Console'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          // Pending Sync Indicator
          ListenableBuilder(
            listenable: ScoringQueueService(),
            builder: (context, _) {
              final queueLen = ScoringQueueService().queueLength;
              if (queueLen == 0) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 20,
                    color: Colors.orange,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showStatsModal,
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'End Match') _showEndMatchDialog();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'End Match', child: Text('End Match')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Scorecard Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _matchData?['team_a']?['name'] != null
                      ? '${_matchData!['team_a']['name']} vs ${_matchData!['team_b']['name']}'
                      : 'Match',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_totalRuns',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 4),
                      child: Text(
                        '/ $_wickets',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'OVERS: ${_overs.toStringAsFixed(1)} / $_matchOversLimit   CRR: ${(_totalRuns / (_overs == 0 ? 1 : _overs)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (statusMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      statusMsg,
                      style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Players
          Expanded(
            child: Container(
              color: const Color(0xFFFAFAFA),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildPlayerCard(_striker, isStriker: true),
                      const SizedBox(width: 12),
                      _buildPlayerCard(_nonStriker, isStriker: false),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBowlerCard(_bowler),
                ],
              ),
            ),
          ),

          // 3. Keypad
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SizedBox(
                height: 280,
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _keypadBtn('0', () => _handleBall(0)),
                    _keypadBtn('1', () => _handleBall(1)),
                    _keypadBtn('2', () => _handleBall(2)),
                    _keypadBtn(
                      'WD',
                      () => _handleBall(0, isWide: true),
                      isAccent: true,
                      label: "Wide",
                    ),

                    _keypadBtn('3', () => _handleBall(3)),
                    _keypadBtn('4', () => _handleBall(4), isHighlight: true),
                    _keypadBtn('6', () => _handleBall(6), isHighlight: true),
                    _keypadBtn(
                      'NB',
                      _handleNoBallClick,
                      isAccent: true,
                      label: "No Ball",
                    ),

                    _keypadBtn(
                      'B',
                      () => _handleBall(1, isBye: true),
                      label: "Bye",
                      isAccent: true,
                    ),
                    _keypadBtn(
                      'LB',
                      () => _handleBall(1, isLegBye: true),
                      label: "Leg Bye",
                      isAccent: true,
                    ),
                    _keypadBtn(
                      'W',
                      _handleWicketClick,
                      isWicket: true,
                      label: "WICKET",
                    ),
                    _keypadBtn(
                      'UNDO',
                      _handleUndo,
                      label: "",
                      isAccent: false,
                      isUndo: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildPlayerCard(
    Map<String, dynamic>? player, {
    bool isStriker = false,
  }) {
    final name =
        player?['user_metadata']?['name'] ??
        player?['profile_json']?['name'] ??
        'Select';
    final isSelected = player != null;
    return Expanded(
      child: InkWell(
        onTap: () => _openNewBatsmanModal(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isStriker
                ? AppColors.primary.withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isStriker
                  ? AppColors.primary.withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (!isStriker)
                BoxShadow(
                  color: Colors.grey.shade100,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 18,
                    color: isStriker ? AppColors.primary : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isStriker ? "Striker" : "Non-Striker",
                    style: TextStyle(
                      fontSize: 10,
                      color: isStriker ? AppColors.primary : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? Colors.black87 : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBowlerCard(Map<String, dynamic>? player) {
    final name = player?['profile_json']?['name'] ?? 'Select Bowler';
    return InkWell(
      onTap: () => _openNewBowlerModal(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sports_baseball, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Current Bowler",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.swap_horiz, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _keypadBtn(
    String text,
    VoidCallback onTap, {
    bool isHighlight = false,
    bool isAccent = false,
    bool isWicket = false,
    bool isUndo = false,
    String? label,
  }) {
    Color bg = Colors.white;
    Color fg = Colors.black87;

    if (isHighlight) {
      bg = AppColors.secondary;
      fg = Colors.white;
    }
    if (isAccent) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    }
    if (isWicket) {
      bg = AppColors.error;
      fg = Colors.white;
    }
    if (isUndo) {
      bg = Colors.grey.shade200;
      fg = Colors.black54;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isAccent || isUndo ? Border.all(color: Colors.black12) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
            if (label != null)
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: fg.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSafeName(dynamic val) => val?.toString() ?? 'Team';
}

class _PlayerSelectionList extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final String title;
  const _PlayerSelectionList({required this.players, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final p = players[index];
                final name = p['profile_json']?['name'] ?? 'Unknown';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      name[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(context, p['id']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
