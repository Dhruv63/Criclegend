import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/tournament_repository.dart';
import 'generate_fixtures_screen.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tournament Center"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
             Tab(text: "Points Table"),
             Tab(text: "Fixtures"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: POINTS TABLE (Extracted Logic)
          _PointsTableView(tournamentId: widget.tournamentId),
          
          // TAB 2: FIXTURES
          _FixturesView(tournamentId: widget.tournamentId),
        ],
      ),
    );
  }
}

class _PointsTableView extends ConsumerWidget {
  final String tournamentId;
  const _PointsTableView({required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsFuture = ref.watch(tournamentRepositoryProvider).getPointsTable(tournamentId);

    return FutureBuilder<List<Map<String, dynamic>>>(
        future: pointsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          final teams = snapshot.data ?? [];

          if (teams.isEmpty) {
            return const Center(child: Text("No teams found in this tournament."));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('W', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('L', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('NRR', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: teams.asMap().entries.map((entry) {
                  final index = entry.key;
                  final team = entry.value;
                  final teamDetails = team['teams'] as Map<String, dynamic>; 
                  final isTop4 = index < 4;

                  return DataRow(
                    color: isTop4 ? MaterialStateProperty.all(Colors.green.shade50) : null,
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: teamDetails['logo_url'] != null ? NetworkImage(teamDetails['logo_url']) : null,
                              child: teamDetails['logo_url'] == null ? const Icon(Icons.shield, size: 14, color: Colors.grey) : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              teamDetails['name'] ?? 'Unknown',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      ),
                      DataCell(Text(team['matches_played'].toString())),
                      DataCell(Text(team['won'].toString())),
                      DataCell(Text(team['lost'].toString())),
                      DataCell(Text(team['points'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(
                        (team['net_run_rate'] as num).toStringAsFixed(3),
                        style: TextStyle(
                            color: (team['net_run_rate'] as num) >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
  }
}

class _FixturesView extends ConsumerWidget {
  final String tournamentId;
  const _FixturesView({required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: const Text("Generate Schedule"),
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => GenerateFixturesScreen(tournamentId: tournamentId)));
              },
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: ref.watch(tournamentRepositoryProvider).getFixtures(tournamentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              
              final fixtures = snapshot.data ?? [];
              if (fixtures.isEmpty) return const Center(child: Text("No fixtures scheduled yet."));
              
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: fixtures.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final match = fixtures[i];
                  final date = DateTime.parse(match['match_date']).toLocal();
                  final fmtDate = DateFormat('EEE, d MMM').format(date);
                  final fmtTime = DateFormat('jm').format(date);
                  
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               Text(fmtDate, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                               Text(fmtTime, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                               // Team A
                               Column(
                                 children: [
                                   CircleAvatar(
                                     backgroundImage: match['team_a']['logo_url'] != null ? NetworkImage(match['team_a']['logo_url']) : null,
                                     child: match['team_a']['logo_url'] == null ? const Icon(Icons.shield) : null,
                                   ),
                                   const SizedBox(height: 4),
                                   Text(match['team_a']['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                 ],
                               ),
                               const Text("VS", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.premiumRed)),
                               // Team B
                               Column(
                                 children: [
                                   CircleAvatar(
                                     backgroundImage: match['team_b']['logo_url'] != null ? NetworkImage(match['team_b']['logo_url']) : null,
                                     child: match['team_b']['logo_url'] == null ? const Icon(Icons.shield) : null,
                                   ),
                                   const SizedBox(height: 4),
                                   Text(match['team_b']['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                 ],
                               ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text("Scheduled", style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ),
      ],
    );
  }
}
