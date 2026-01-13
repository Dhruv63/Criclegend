import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../scoring/data/scoring_provider.dart';
import '../../scoring/domain/match_model.dart';
import '../../scoring/domain/team_model.dart';
import '../../../core/data/supabase_service.dart';

class PreMatchSetupScreen extends ConsumerStatefulWidget {
  final String matchId;
  const PreMatchSetupScreen({super.key, required this.matchId});

  @override
  ConsumerState<PreMatchSetupScreen> createState() => _PreMatchSetupScreenState();
}

class _PreMatchSetupScreenState extends ConsumerState<PreMatchSetupScreen> {
  MatchModel? _match;
  bool _isLoading = true;

  // Toss Logic
  Team? _tossWinner;
  String? _tossDecision; // 'Bat' or 'Bowl'
  
  @override
  void initState() {
    super.initState();
    _loadMatchDetails();
  }

  Future<void> _loadMatchDetails() async {
    try {
      final fullData = await SupabaseService.getMatchFullDetails(widget.matchId);
      if (fullData != null) {
        setState(() {
          _match = MatchModel.fromJson(fullData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading match: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startMatch() async {
    if (_tossWinner == null || _tossDecision == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Toss Winner and Decision!')));
      return;
    }
    
    // Check if scheduled time is far in future (e.g. > 30 mins)
    // Optional: Add warning dialog here
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(scoringRepositoryProvider).startMatch(
        matchId: widget.matchId,
        tossWinnerId: _tossWinner!.id,
        tossDecision: _tossDecision!,
        teamAId: _match!.teamAId!,
        teamBId: _match!.teamBId!,
      );
      
      if (mounted) {
        context.go('/scoring/${widget.matchId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting match: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_match == null) return const Scaffold(body: Center(child: Text("Match not found")));

    final teamA = _match!.teamA!;
    final teamB = _match!.teamB!;
    final dateStr = DateFormat('EEE, d MMM • h:mm a').format(_match!.scheduledDate ?? _match!.matchDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Toss & Teams')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Match Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(_match!.matchType ?? 'Friendly', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTeamHeader(teamA),
                        const Text('VS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        _buildTeamHeader(teamB),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 2. Toss Section
            const Text('TOSS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Who won the toss?', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTossChoice(teamA, _tossWinner?.id == teamA.id, () => setState(() => _tossWinner = teamA))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTossChoice(teamB, _tossWinner?.id == teamB.id, () => setState(() => _tossWinner = teamB))),
                      ],
                    ),
                    
                    if (_tossWinner != null) ...[
                      const SizedBox(height: 24),
                      Text('${_tossWinner!.name} elected to:', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDecisionChoice('Bat', Icons.sports_cricket, _tossDecision == 'Bat'),
                          const SizedBox(width: 16),
                          _buildDecisionChoice('Bowl', Icons.sports_baseball, _tossDecision == 'Bowl'),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 3. Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _tossWinner != null && _tossDecision != null ? _startMatch : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: const Text('START SCORING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader(Team team) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
          backgroundColor: Colors.white24,
          child: team.logoUrl == null ? Text(team.name[0], style: const TextStyle(color: Colors.white, fontSize: 20)) : null,
        ),
        const SizedBox(height: 8),
        Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTossChoice(Team team, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
              backgroundColor: Colors.grey.shade200,
              child: team.logoUrl == null ? Text(team.name[0]) : null,
            ),
            const SizedBox(height: 8),
            Text(team.name, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.black87), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionChoice(String label, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _tossDecision = label),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
