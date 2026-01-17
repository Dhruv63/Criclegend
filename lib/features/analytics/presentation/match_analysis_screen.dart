import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/analytics_repository.dart';
import 'widgets/manhattan_chart.dart';
import 'widgets/worm_chart.dart';

class MatchAnalysisScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String teamAName;
  final String teamBName;
  final String teamAId;
  final String teamBId;

  const MatchAnalysisScreen({
    super.key,
    required this.matchId,
    required this.teamAId,
    required this.teamBId,
    this.teamAName = 'Team A',
    this.teamBName = 'Team B',
  });

  @override
  ConsumerState<MatchAnalysisScreen> createState() =>
      _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends ConsumerState<MatchAnalysisScreen> {
  // We fetch data for both teams
  late Future<List<OverSummary>> _teamAFuture;
  late Future<List<OverSummary>> _teamBFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    final repo = ref.read(analyticsRepositoryProvider);
    _teamAFuture = repo.getMatchOvers(widget.matchId, widget.teamAId);
    _teamBFuture = repo.getMatchOvers(widget.matchId, widget.teamBId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Match Center - Analytics",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: Future.wait([_teamAFuture, _teamBFuture]),
          builder: (context, AsyncSnapshot<List<List<OverSummary>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final teamAData = snapshot.data![0];
            final teamBData = snapshot.data![1];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. WORM CHART
                _SectionHeader(title: "Run Rate Comparison (Worm)"),
                const SizedBox(height: 16),
                WormChart(
                  teamAData: teamAData,
                  teamBData: teamBData,
                  teamAName: widget.teamAName,
                  teamBName: widget.teamBName,
                ),
                const SizedBox(height: 8),
                _Legend(
                  teamAName: widget.teamAName,
                  teamBName: widget.teamBName,
                ),

                const Divider(height: 48),

                // 2. MANHATTAN CHART (Tabbed or Column? Let's do Column for now)
                _SectionHeader(title: "Overs Comparison (Manhattan)"),
                const SizedBox(height: 16),

                // Toggle Button for Team A / Team B? Or just show both?
                // Visual crowding if we show both. Let's show separate blocks.
                Text(
                  widget.teamAName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ManhattanChart(data: teamAData, barColor: AppColors.primary),

                const SizedBox(height: 24),

                Text(
                  widget.teamBName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ManhattanChart(data: teamBData, barColor: AppColors.secondary),

                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: AppColors.premiumRed),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String teamAName;
  final String teamBName;

  const _Legend({required this.teamAName, required this.teamBName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: AppColors.primary, label: teamAName),
        const SizedBox(width: 24),
        _LegendItem(color: AppColors.secondary, label: teamBName),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
