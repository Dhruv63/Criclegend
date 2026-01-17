import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../data/player_stats_repository.dart';
import '../domain/player_stats_model.dart';
import '../domain/match_performance_model.dart';

final playerStatsRepoProvider = Provider(
  (ref) => PlayerStatsRepository(Supabase.instance.client),
);

final playerStatsProvider = FutureProvider.family<PlayerStats?, String>((
  ref,
  userId,
) async {
  return ref.read(playerStatsRepoProvider).getPlayerStats(userId);
});

final matchHistoryProvider =
    FutureProvider.family<List<MatchPerformance>, String>((ref, userId) async {
      return ref.read(playerStatsRepoProvider).getMatchHistory(userId);
    });

class PlayerProfileScreen extends ConsumerWidget {
  final String userId;

  const PlayerProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatsProvider(userId));
    final historyAsync = ref.watch(matchHistoryProvider(userId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Player Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Statistics Header
            statsAsync.when(
              data: (stats) => stats == null
                  ? const Center(child: Text("No stats available"))
                  : _buildCareerStatsCard(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text("Error: $e"),
            ),
            const SizedBox(height: 24),

            // 2. Recent Performances List
            Text(
              "Match History",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (history) => _buildRecentMatchesList(history),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text("Error loading history: $e"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerStatsCard(PlayerStats stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Player Stats",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${stats.totalMatches} Matches Played",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Runs", "${stats.totalRuns}"),
                _buildStatItem("Wickets", "${stats.totalWickets}"),
                _buildStatItem("Avg", stats.battingAverage.toStringAsFixed(1)),
                _buildStatItem("High Score", "${stats.highestScore}"),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  "50s/100s",
                  "${stats.fifties} / ${stats.centuries}",
                ),
                _buildStatItem("5W Hauls", "${stats.fiveWicketHauls}"),
                _buildStatItem("Best Bowl", stats.bestBowlingFigures ?? "-"),
                _buildStatItem("Catches", "${stats.totalCatches}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRecentMatchesList(List<MatchPerformance> history) {
    if (history.isEmpty) return const Text("No matches played yet.");

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final match = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_cricket, size: 20, color: Colors.grey),
                Text(
                  match.createdAt.day.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            title: Text(
              match.runsScored > 0
                  ? "${match.runsScored} (${match.ballsFaced})"
                  : "Did not bat",
            ),
            subtitle: Text(
              match.wicketsTaken > 0
                  ? "${match.wicketsTaken} wkts / ${match.runsConceded} runs"
                  : "No wickets",
            ),
            trailing: match.isNotOut && match.ballsFaced > 0
                ? const Chip(label: Text("NO", style: TextStyle(fontSize: 10)))
                : null,
          ),
        );
      },
    );
  }
}
