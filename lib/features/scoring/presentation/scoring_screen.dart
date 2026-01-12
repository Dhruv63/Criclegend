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
  
  // State
  bool _isLoading = true;
  int _totalRuns = 0;
  int _wickets = 0;
  double _overs = 0.0;
  
  // Active IDs
  String? _inningId;
  String? _strikerId;
  String? _nonStrikerId;
  String? _bowlerId;
  
  // UI Helpers
  Map<String, dynamic>? get _striker => _getPlayer(_strikerId);
  Map<String, dynamic>? get _nonStriker => _getPlayer(_nonStrikerId);
  Map<String, dynamic>? get _bowler => _getPlayer(_bowlerId);
  
  Map<String, dynamic>? _getPlayer(String? id) {
    if (id == null) return null;
    return [..._battingSquad, ..._bowlingSquad].firstWhere(
      (p) => p['id'] == id, 
      orElse: () => {'profile_json': {'name': 'Unknown'}}
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
        // Start Match if not started (create innings)
        await SupabaseService.startMatch(widget.matchId, data['team_a_id'], data['team_b_id']);
        
        // Refresh to get the created innings
        final refreshed = await SupabaseService.getMatchFullDetails(widget.matchId);
        _matchData = refreshed;
        
        // Set Active Inning
        final innings = List<Map<String, dynamic>>.from(refreshed!['innings']);
        if (innings.isEmpty) throw "No innings found for this match.";
        
        // Sort by innings number to ensure Inning 1 comes before Inning 2
        innings.sort((a, b) => (a['innings_number'] ?? 0).compareTo(b['innings_number'] ?? 0));
        
        _activeInning = innings.firstWhere((i) => i['is_completed'] == false, orElse: () => innings.last);
        
        if (_activeInning != null) {
          _inningId = _activeInning!['id'];
          _totalRuns = _activeInning!['total_runs'] ?? 0;
          _wickets = _activeInning!['wickets'] ?? 0;
          _overs = (_activeInning!['overs_played'] ?? 0).toDouble();
          
          _strikerId = _activeInning!['striker_id'];
          _nonStrikerId = _activeInning!['non_striker_id'];
          _bowlerId = _activeInning!['bowler_id'];
          
          // Fallback Team Logic for Legacy Data
          var batTeamId = _activeInning!['batting_team_id'];
          var bowlTeamId = _activeInning!['bowling_team_id'];
          
          if (batTeamId == null) {
             // Derive from Match. If Inning 1, Bat = Team A
             final isInn1 = _activeInning!['innings_number'] == 1;
             batTeamId = isInn1 ? data['team_a_id'] : data['team_b_id'];
          }
           if (bowlTeamId == null) {
             // Derive from Match. If Inning 1, Bowl = Team B
             final isInn1 = _activeInning!['innings_number'] == 1;
             bowlTeamId = isInn1 ? data['team_b_id'] : data['team_a_id'];
          }

          // Fetch Squads
          if (batTeamId != null) {
             _battingSquad = await SupabaseService.getTeamPlayers(batTeamId);
          }
          if (bowlTeamId != null) {
             _bowlingSquad = await SupabaseService.getTeamPlayers(bowlTeamId);
          }
          
          // Auto-Pick if missing keys but squad exists
          if (_strikerId == null && _battingSquad.isNotEmpty) _strikerId = _battingSquad[0]['id'];
          if (_nonStrikerId == null && _battingSquad.length > 1) _nonStrikerId = _battingSquad[1]['id'];
          if (_bowlerId == null && _bowlingSquad.isNotEmpty) _bowlerId = _bowlingSquad[0]['id'];
        }
      }
    } catch (e) {
      print("ERROR INIT MATCH: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading match: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC ---

  Future<void> _handleBall(int runs, {bool isWide = false, bool isNoBall = false, bool isWicket = false, String? wicketType, String? fielderId, String? dismissType, String? zone}) async {
    if (_inningId == null) return;
    
    if (_strikerId == null || _nonStrikerId == null || _bowlerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please ensure Batsmen and Bowler are selected!"), backgroundColor: Colors.orange)
      );
      return;
    }

    // --- PHASE 3: WAGON WHEEL ---
    // If runs >= 3 or Boundary (4, 6), ask for Shot Zone if not provided
    // (And if it's a legal ball off the bat)
    String? finalZone = zone;
    if (finalZone == null && !isWide && !isWicket && (runs >= 3 || runs == 4 || runs == 6)) {
       finalZone = await showDialog<String>(
         context: context,
         builder: (ctx) => const WagonWheelSelector(),
       );
    }

    // 1. Calculate New State
    int runsToAdd = runs + (isWide || isNoBall ? 1 : 0);
    int newTotalRuns = _totalRuns + runsToAdd;
    int newWickets = _wickets + (isWicket ? 1 : 0);
    
    // Overs Logic
    double newOvers = _overs;
    int ballNum = 0;
    
    bool isLegal = !isWide && !isNoBall;
    if (isLegal) {
       int totalBalls = ((_overs.floor() * 6) + ((_overs % 1) * 10).round());
       totalBalls++;
       ballNum = totalBalls % 6; 
       if (ballNum == 0) ballNum = 6; 
       
       newOvers = (totalBalls ~/ 6) + (totalBalls % 6) / 10.0;
    } else {
       int totalBalls = ((_overs.floor() * 6) + ((_overs % 1) * 10).round());
       ballNum = (totalBalls % 6) + 1; 
    }

    // 2. Optimistic UI Update
    setState(() {
      _totalRuns = newTotalRuns;
      _wickets = newWickets;
      _overs = newOvers;
    });

    // 3. Batting Swap Logic
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
      extrasType: isWide ? 'wide' : (isNoBall ? 'noball' : null),
      extrasRuns: (isWide || isNoBall) ? 1 : 0,
      isWicket: isWicket,
      wicketType: dismissType ?? wicketType, // Prefer explicit type
      dismissedPlayerId: isWicket ? _strikerId : null, // Default to striker
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

    // 5. Post-Ball Checks
    if (isWicket) {
        // If the Modal gave us a new striker, apply it.
       // Note: The DismissalDialog handled the "Who is next" selection, but _handleWicketClick needs to pass it here?
       // Actually, _handleWicketClick calls _handleBall. 
       // We should handle the "New Striker" logic AFTER _handleBall updates the partial state.
       // But _handleWicketClick logic is below.
    }
    
    if (isLegal && ballNum == 6) {
       _swapBatsmen(); 
       await _openNewBowlerModal();
    }
  }
  
  void _swapBatsmen() {
    setState(() {
      final temp = _strikerId;
      _strikerId = _nonStrikerId;
      _nonStrikerId = temp;
    });
  }
  
  // --- MODALS ---
  
  Future<void> _openNewBatsmanModal() async {
    final newBatId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _PlayerSelectionList(players: _battingSquad, title: "Select New Batsman"),
    );
    if (newBatId != null) {
      setState(() => _strikerId = newBatId);
      await Supabase.instance.client.from('innings').update({'striker_id': _strikerId}).eq('id', _inningId!);
    }
  }

  Future<void> _openNewBowlerModal() async {
    final newBowlId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _PlayerSelectionList(players: _bowlingSquad, title: "Select Next Bowler"),
    );
    if (newBowlId != null) {
      setState(() => _bowlerId = newBowlId);
       await Supabase.instance.client.from('innings').update({'bowler_id': _bowlerId}).eq('id', _inningId!);
    }
  }
  
  Future<void> _handleWicketClick() async {
    // --- PHASE 3: ADVANCED WICKET MODAL ---
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true, // Allow full height
      builder: (ctx) => DismissalDialog(
        fieldingTeam: _bowlingSquad,
        battingTeam: _battingSquad.where((p) => p['id'] != _strikerId && p['id'] != _nonStrikerId).toList(),
      ),
    );

    if (result != null) {
      final type = result['type'] as String;
      final fielderId = result['fielderId'] as String?;
      final newStrikerId = result['newStrikerId'] as String?;

      // 1. Record the Ball (Wicket)
      await _handleBall(0, isWicket: true, dismissType: type, fielderId: fielderId);
      
      // 2. Set New Striker (Immediate Update)
      if (newStrikerId != null) {
        setState(() => _strikerId = newStrikerId);
        await Supabase.instance.client.from('innings').update({'striker_id': _strikerId}).eq('id', _inningId!);
      }
    }
  }
  
  Future<void> _handleNoBallClick() async {
     final runs = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Runs off Bat (No Ball)'),
        children: [0, 1, 2, 3, 4, 6].map((r) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, r),
          child: Padding(padding: const EdgeInsets.all(8.0), child: Text('$r Runs', style: const TextStyle(fontSize: 18))),
        )).toList(),
      ),
    );
    if (runs != null) {
      _handleBall(runs, isNoBall: true);
    }
  }

  Future<void> _showStatsModal() async {
    // 1. Fetch Balls for the current innings
    if (_inningId == null) return;
    
    // Show Loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final response = await Supabase.instance.client
          .from('balls')
          .select()
          .eq('inning_id', _inningId!);
      
      final balls = (response as List).map((e) => BallModel.fromJson(e)).toList();
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        
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
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text("Match Analytics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        WagonWheelStatsWidget(balls: balls),
                        const SizedBox(height: 24),
                        // Add more stats here (e.g. Run Rate Chart)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching stats: $e")));
    }
  }

  Future<void> _showEndMatchDialog() async {
    // 1. Fetch Latest Data
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final fullData = await SupabaseService.getMatchFullDetails(widget.matchId);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (fullData == null) return;
      
      // 2. Calculate Result
      // Assuming Inning 1 and 2 exist
      final innings = List<Map<String, dynamic>>.from(fullData['innings']);
      innings.sort((a, b) => (a['innings_number'] ?? 0).compareTo(b['innings_number'] ?? 0));
      
      if (innings.isEmpty) return;
      
      final i1 = innings[0];
      final i2 = innings.length > 1 ? innings[1] : null;
      
      final i1Runs = i1['total_runs'] ?? 0;
      final i2Runs = i2?['total_runs'] ?? 0;
      final i2Wickets = i2?['wickets'] ?? 0;
      
      // Determine Teams
      final teamA = fullData['team_a']; // Batting 1st (Assuming)
      final teamB = fullData['team_b']; // Batting 2nd (Assuming)
      
      // Note: We need to know WHO batted first. 
      // i1['batting_team_id'] should tell us.
      String? winningTeamId;
      String resultText = "Match Ended";
      
      final bat1Id = i1['batting_team_id'];
      final bat2Id = i2?['batting_team_id'];
      
      final teamBat1Name = bat1Id == teamA['id'] ? teamA['name'] : teamB['name'];
      final teamBat2Name = bat2Id == teamA['id'] ? teamA['name'] : teamB['name'];

      if (i1Runs > i2Runs) {
        // Team Batting 1st Wins
        winningTeamId = bat1Id;
        final margin = i1Runs - i2Runs;
        resultText = "$teamBat1Name won by $margin runs";
      } else if (i2Runs > i1Runs) {
        // Team Batting 2nd Wins
        winningTeamId = bat2Id;
        final wicketsLeft = 10 - (i2Wickets as int);
        resultText = "$teamBat2Name won by $wicketsLeft wickets";
      } else {
         resultText = "Match Tied";
         winningTeamId = null; 
      }
      
      // 3. Show Confirmation
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("End Match?"),
          content: Text("Are you sure you want to end this match?\n\nResult: $resultText"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                // 4. Commit to DB
                await SupabaseService.endMatch(
                  matchId: widget.matchId,
                  winningTeamId: winningTeamId ?? '',
                  resultDescription: resultText,
                );
                if (mounted) context.go('/'); // Back to Home
              },
              child: const Text("Confirm & End"),
            )
          ],
        ),
      );

    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading if error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error ending match: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoring Console'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          // SYNC STATUS
          ListenableBuilder(
            listenable: ScoringQueueService(),
            builder: (context, child) {
              final queueLen = ScoringQueueService().queueLength;
              final syncing = ScoringQueueService().isSyncing;
              if (queueLen == 0 && !syncing) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Row(
                    children: [
                      if(syncing) const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      if(!syncing) const Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text('$queueLen Pending', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showStatsModal,
            tooltip: 'Match Stats',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'End Match') _showEndMatchDialog();
            },
            itemBuilder: (BuildContext context) {
              return {'End Match'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Scorecard Header (Modern Dark Theme)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                 Text(_getSafeName(_matchData?['team_a']?['name']), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                 const SizedBox(height: 8),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_totalRuns', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 4),
                      child: Text('/ $_wickets', style: const TextStyle(fontSize: 32, color: Colors.white70)),
                    ),
                  ],
                 ),
                 const SizedBox(height: 16),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text('OVERS: ${_overs.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       const SizedBox(width: 16),
                       Container(width: 1, height: 14, color: Colors.white30),
                       const SizedBox(width: 16),
                       Text('CRR: ${(_totalRuns / (_overs == 0 ? 1 : _overs)).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                     ],
                   ),
                 )
              ],
            ),
          ),
          
          // 2. Players Area
          Expanded(
            child: Container(
              color: const Color(0xFFFAFAFA),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Batsmen
                  Row(
                    children: [
                      _buildPlayerCard(_striker, isStriker: true),
                      const SizedBox(width: 12),
                      _buildPlayerCard(_nonStriker, isStriker: false),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bowler
                  _buildBowlerCard(_bowler),
                ],
              ),
            ),
          ),
          
          // 3. Control Pad
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Wrap content
                children: [
                   Container(
                     width: 40, height: 4, 
                     margin: const EdgeInsets.only(bottom: 12),
                     decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                   ),
                   SizedBox(
                     height: 280, // Reduced from 320
                     child: GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8, // Tighter spacing
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.3, // Wider buttons (shorter height)
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _btn('0', () => _handleBall(0)),
                        _btn('1', () => _handleBall(1)),
                        _btn('2', () => _handleBall(2)),
                        _btn('WD', () => _handleBall(0, isWide: true), color: AppColors.warning, label: "Wide"),
                        _btn('3', () => _handleBall(3)),
                        _btn('4', () => _handleBall(4), color: AppColors.secondary),
                        _btn('6', () => _handleBall(6), color: AppColors.secondary),
                        _btn('NB', _handleNoBallClick, color: AppColors.warning, label: "No Ball"),
                        _btn('W', _handleWicketClick, color: AppColors.error, label: "WICKET", fontSize: 14, isSolid: true),
                        _btn('Undo', () {/* TODO */}, color: Colors.grey, label: "Undo", fontSize: 14),
                        // Fillers / Custom
                        _btn('1b', () => _handleBall(1), color: Colors.blueGrey.shade100, label: "Bye"),
                        _btn('1lb', () => _handleBall(1), color: Colors.blueGrey.shade100, label: "Leg B"),
                      ],
                                     ),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerCard(Map<String, dynamic>? player, {bool isStriker = false}) {
    final name = player?['user_metadata']?['name'] ?? player?['profile_json']?['name'] ?? 'Select Player';
    return Expanded(
      child: InkWell(
        onTap: () => _openNewBatsmanModal(), // Allow changing player on tap
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isStriker ? AppColors.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isStriker ? AppColors.primary : Colors.transparent, width: 2),
            boxShadow: [if(!isStriker) BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: isStriker ? AppColors.primary : Colors.grey),
                  const SizedBox(width: 8),
                  if (isStriker) const Icon(Icons.circle, size: 8, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 12),
              Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isStriker ? Colors.black : Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Text('Tap to Change', style: TextStyle(fontSize: 10, color: Colors.grey)), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBowlerCard(Map<String, dynamic>? player) {
    final name = player?['profile_json']?['name'] ?? 'Select Bowler';
    return InkWell(
      onTap: () => _openNewBowlerModal(), // Allow changing bowler
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                 child: const Icon(Icons.sports_baseball, size: 20, color: Colors.black87)
               ), 
               const SizedBox(width: 12), 
               Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            ]),
            const Text('Tap to Change', style: TextStyle(fontSize: 12, color: Colors.grey)), 
          ],
        ),
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap, {Color color = Colors.transparent, String? label, double fontSize = 28, bool isSolid = false}) {
    // Default style (Run buttons)
    Color bgColor = Colors.white;
    Color fgColor = Colors.black;
    BorderSide border = BorderSide(color: Colors.grey.shade200);
    
    // Custom Styles
    if (color != Colors.transparent && !isSolid) {
      bgColor = color.withOpacity(0.08); // Light tint
      fgColor = color; // Colored text
      border = BorderSide(color: color.withOpacity(0.3));
    } else if (isSolid) {
      bgColor = color;
      fgColor = Colors.white;
      border = BorderSide.none;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: fgColor, fontFamily: 'Outfit')),
             if (label != null) Text(label, style: TextStyle(fontSize: 10, color: fgColor.withOpacity(0.8), fontWeight: FontWeight.bold)),
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
          Padding(padding: const EdgeInsets.all(20), child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final p = players[index];
                final name = p['profile_json']?['name'] ?? 'Unknown';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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
