import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/supabase_service.dart';

class AdminMatchConsole extends StatefulWidget {
  const AdminMatchConsole({super.key});

  @override
  State<AdminMatchConsole> createState() => _AdminMatchConsoleState();
}

class _AdminMatchConsoleState extends State<AdminMatchConsole> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: const Text('🏏 CricLegend Admin Console'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState((){})),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => context.go('/admin')),
        ],
      ),
      drawer: isDesktop ? null : Drawer(child: _Sidebar(context: context)),
      body: Row(
        children: [
          // Sidebar (Desktop Only)
          if (isDesktop) 
            SizedBox(width: 250, child: _Sidebar(context: context)),

          // Main Content
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Responsive Header
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Column(
                           crossAxisAlignment: CrossAxisAlignment.stretch,
                           children: [
                             const Text('Live / Upcoming Matches', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                             const SizedBox(height: 16),
                             ElevatedButton.icon(
                                onPressed: () => context.push('/new-match'), 
                                icon: const Icon(Icons.add),
                                label: const Text('Create New Match'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                           ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Live / Upcoming Matches', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/new-match'), 
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Match'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 32),
                  // Match List
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: SupabaseService.getAdminMatches(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_cricket, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('No active matches found.', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                              ],
                            ),
                          );
                        }

                        final matches = snapshot.data!;
                        return ListView.builder(
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final match = matches[index];
                            final teamA = match['team_a']['name'];
                            final teamB = match['team_b']['name'];
                            final status = match['status'];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: status == 'Live' ? Colors.red : Colors.blue,
                                  child: const Icon(Icons.sports_cricket, color: Colors.white),
                                ),
                                title: Text('$teamA vs $teamB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                subtitle: Text('Status: $status • Overs: ${match['overs_count'] ?? 20}'),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    context.push('/scoring/${match['id']}');
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                                  child: const Text('Score Match'),
                                ),
                              ),
                            );
                          },
                        );
                      },
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
}

class _Sidebar extends StatelessWidget {
  final BuildContext context;
  const _Sidebar({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: ListView(
        children: [
          _buildNavItem(Icons.dashboard, 'Dashboard', true),
          _buildNavItem(Icons.sports_cricket, 'Matches', false),
          _buildNavItem(Icons.people, 'Players', false),
          _buildNavItem(Icons.emoji_events, 'Tournaments', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Container(
      color: isSelected ? Colors.white : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.black87),
        title: Text(label, style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
        onTap: () {
           if (label != 'Dashboard') {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label Management Coming Soon!")));
           }
        },
      ),
    );
  }
}
