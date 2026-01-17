import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../analytics/presentation/match_analysis_screen.dart';
import '../../../core/data/supabase_service.dart';

class LiveMatchScreen extends ConsumerStatefulWidget {
  final String matchId;
  const LiveMatchScreen({super.key, required this.matchId});

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  final _supabase = Supabase.instance.client;

  // Data State
  Map<String, dynamic>? _matchData;
  Map<String, dynamic>? _activeInning;
  List<Map<String, dynamic>> _recentBalls = [];
  final Map<String, String> _playerNames = {};

  // Stats State
  Map<String, dynamic> _playerStats = {};

  bool _isLoading = true;
  Timer? _pollingTimer;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _initLiveFeed();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initLiveFeed() async {
    // 1. Initial Load
    await _fetchFullData();

    // 2. Setup Realtime Subscription (Manual Channel for granular control)
    _channel = _supabase
        .channel('public:match_${widget.matchId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'balls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: widget.matchId,
          ),
          callback: (payload) {
            print("REALTIME: New Ball! ${payload.newRecord}");
            _handleNewBall(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'innings',
          // Note: Inning updates might not have match_id in payload if not changed,
          // so we rely on NEW ball events to trigger score refresh mostly,
          // but listen here just in case of non-ball updates.
          callback: (payload) {
            print("REALTIME: Inning Update! $payload");
            _fetchScoreOnly();
          },
        )
        .subscribe();

    // 3. Setup Fallback Polling (Every 10s)
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchScoreOnly();
    });
  }

  Future<void> _fetchFullData() async {
    try {
      final match = await SupabaseService.getMatchFullDetails(widget.matchId);
      if (match != null) {
        _matchData = match;
        // Players
        final p1 = await SupabaseService.getTeamPlayers(match['team_a_id']);
        final p2 = await SupabaseService.getTeamPlayers(match['team_b_id']);
        for (var p in [...p1, ...p2]) {
          _playerNames[p['id']] = p['profile_json']?['name'] ?? 'Player';
        }

        // Innings & Balls
        final innings = match['innings'] as List;
        if (innings.isNotEmpty) {
          _activeInning = innings.firstWhere(
            (i) => i['is_completed'] == false,
            orElse: () => innings.last,
          );
        }

        // Fetch recent balls
        final balls = await _supabase
            .from('balls')
            .select()
            .eq('match_id', widget.matchId)
            .order('created_at', ascending: false)
            .limit(20);
        _recentBalls = List<Map<String, dynamic>>.from(balls);

        // Initial Stats Fetch
        if (_activeInning != null) await _fetchPlayerStats();
      }
    } catch (e) {
      print("Error fetching full data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchScoreOnly() async {
    // Lightweight fetch for scorecard
    try {
      final innings = await _supabase
          .from('innings')
          .select()
          .eq('match_id', widget.matchId);
      if (innings.isNotEmpty) {
        final active = innings.firstWhere(
          (i) => i['is_completed'] == false,
          orElse: () => innings.last,
        );
        if (mounted) {
          setState(() => _activeInning = active);
          _fetchPlayerStats(); // Fetch stats when score updates
        }
      }
    } catch (e) {
      print("Poll Error: $e");
    }
  }

  Future<void> _fetchPlayerStats() async {
    if (_activeInning == null) return;
    final stats = await SupabaseService.getActivePlayerStats(
      widget.matchId,
      _activeInning!['id'],
      _activeInning!['striker_id'] ?? '',
      _activeInning!['non_striker_id'] ?? '',
      _activeInning!['bowler_id'] ?? '',
    );
    if (mounted) {
      setState(() => _playerStats = stats);
    }
  }

  void _handleNewBall(Map<String, dynamic> ball) {
    if (!mounted) return;

    // 1. Optimistic UI Update (Insert at Top)
    setState(() {
      _recentBalls.insert(0, ball);
      // Enforce Sort Order (Newest First) to prevent anomalies
      _recentBalls.sort((a, b) {
        final tA = a['created_at'] ?? '';
        final tB = b['created_at'] ?? '';
        return tB.compareTo(tA); // Descending
      });
    });

    // 2. Delayed Fetch to allow DB triggers/updates to propagate
    Future.delayed(const Duration(milliseconds: 500), () {
      _fetchScoreOnly();
    });
  }

  String _getName(String? id) => _playerNames[id] ?? 'Player';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_matchData == null) {
      return const Scaffold(body: Center(child: Text('Match not found')));
    }

    final teamA = _matchData!['team_a']['name'];
    final teamB = _matchData!['team_b']['name'];

    final totalRuns = _activeInning?['total_runs'] ?? 0;
    final wickets = _activeInning?['wickets'] ?? 0;
    final overs = _activeInning?['overs_played'] ?? 0;

    final striker = _getName(_activeInning?['striker_id']);
    final nonStriker = _getName(_activeInning?['non_striker_id']);
    final bowler = _getName(_activeInning?['bowler_id']);

    // Stats for UI
    final sStats = _playerStats['striker'];
    final nsStats = _playerStats['nonStriker'];
    final bStats = _playerStats['bowler'];

    final sLabel = sStats != null
        ? '${sStats['runs']} (${sStats['balls']}) *'
        : 'Batting *';
    final nsLabel = nsStats != null
        ? '${nsStats['runs']} (${nsStats['balls']})'
        : 'Batting';
    final bLabel = bStats != null
        ? '${bStats['wickets']}-${bStats['runs']} (${bStats['overs']})'
        : 'Bowling';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Match Center'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Match Analytics',
            onPressed: () {
              // Get team IDs from match data if available
              final match = _matchData;
              if (match != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchAnalysisScreen(
                      matchId: widget.matchId,
                      teamAId: match['team_a_id'],
                      teamBId: match['team_b_id'],
                      teamAName: match['team_a']['name'],
                      teamBName: match['team_b']['name'],
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // 1. Sticky Scorecard Header (Consistent with Admin)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$totalRuns',
                      style: GoogleFonts.outfit(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/$wickets',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Text(
                  'OVERS: $overs',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Active Players
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _playerStat(striker, sLabel, true, Icons.sports_cricket),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _playerStat(
                        nonStriker,
                        nsLabel,
                        false,
                        Icons.sports_cricket_outlined,
                      ),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _playerStat(bowler, bLabel, false, Icons.sports_baseball),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Ball Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              itemCount: _recentBalls.length,
              itemBuilder: (context, index) {
                final ball = _recentBalls[index];
                final isWicket = ball['is_wicket'] == true;
                final runs = ball['runs_scored'] ?? 0;
                final isBoundary = runs == 4 || runs == 6;
                // Highlight color logic
                Color highlightColor = Colors.grey.shade100;
                if (isWicket) {
                  highlightColor = AppColors.error;
                } else if (isBoundary)
                  highlightColor = AppColors.secondary;
                else if (runs > 0)
                  highlightColor = AppColors.primary.withOpacity(0.1);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Ball Indicator
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: highlightColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          isWicket ? 'W' : '$runs',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: (isWicket || isBoundary)
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Over ${ball['over_number']}.${ball['ball_number']}',
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isWicket
                                  ? 'WICKET! ${_getName(ball['batsman_id'])} out.'
                                  : '${_getName(ball['batsman_id'])} to ${_getName(ball['bowler_id'])}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Extras Tag
                      if (ball['extras_type'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Text(
                            ball['extras_type'].toString().toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerStat(
    String name,
    String label,
    bool isHighlight,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          children: [
            if (isHighlight)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.star, size: 10, color: AppColors.secondary),
              ),
            Text(
              name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 10, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
