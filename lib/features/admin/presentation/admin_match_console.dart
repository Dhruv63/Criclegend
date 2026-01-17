import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/supabase_service.dart';
import '../data/admin_repository.dart';

class AdminMatchConsole extends StatefulWidget {
  const AdminMatchConsole({super.key});

  @override
  State<AdminMatchConsole> createState() => _AdminMatchConsoleState();
}

class _AdminMatchConsoleState extends State<AdminMatchConsole>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Management"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Live"),
            Tab(text: "Upcoming"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"), // Added Cancelled tab
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/new-match'),
        label: const Text("Schedule Match"),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MatchList(status: 'Live'),
          _MatchList(status: 'Upcoming'), // Maps to 'Scheduled' or 'Upcoming'
          _MatchList(status: 'Completed'),
          _MatchList(status: 'Cancelled'), // Ensure you handle case-sensitivity if needed
        ],
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  final String status;
  const _MatchList({required this.status});

  @override
  Widget build(BuildContext context) {
    // Handling "Upcoming" to match DB "Scheduled" or "Upcoming" if mixed
    // ideally helper handles this, but here we pass distinct status
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getMatchesByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  "No $status matches found",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final matches = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final match = matches[index];
            return _AdminMatchCard(match: match, status: status);
          },
        );
      },
    );
  }
}

class _AdminMatchCard extends ConsumerWidget {
  final Map<String, dynamic> match;
  final String status;

  const _AdminMatchCard({required this.match, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamA = match['team_a']['name'];
    final teamB = match['team_b']['name'];
    final venue = match['venue_name'] ?? match['ground'] ?? 'Unknown Venue';
    // Format date properly
    final dateStr = match['date'] != null
        ? DateTime.parse(match['date']).toLocal().toString().split('.')[0]
        : 'TB A';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$teamA vs $teamB",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              venue,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            if (status != 'Completed' && status != 'Cancelled') ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   if (status == 'Upcoming' || status == 'Scheduled') ...[
                      IconButton(
                        onPressed: () => _deleteMatch(context, ref, match['id']),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete Match',
                      ),
                      TextButton.icon(
                        onPressed: () => _cancelMatch(context, ref, match['id']),
                        icon: const Icon(Icons.cancel_outlined, color: Colors.orange),
                        label: const Text("Cancel", style: TextStyle(color: Colors.orange)),
                      ),
                      TextButton.icon(
                        onPressed: () => _editMatch(context, ref, match),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        label: const Text("Edit", style: TextStyle(color: Colors.blue)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/match-setup/${match['id']}'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Start Toss"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                   ],
                  if (status == 'Live') ...[
                     TextButton.icon(
                        onPressed: () => _forceEndMatch(context, ref, match['id']),
                        icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                        label: const Text("Force End", style: TextStyle(color: Colors.red)),
                     ),
                     const SizedBox(width: 8),
                     ElevatedButton.icon(
                      onPressed: () => context.push('/scoring/${match['id']}'),
                      icon: const Icon(Icons.sports_cricket),
                      label: const Text("Score Console"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editMatch(BuildContext context, WidgetRef ref, Map<String, dynamic> match) async {
      final venueController = TextEditingController(text: match['venue_name'] ?? match['ground']);
      DateTime selectedDate = match['date'] != null ? DateTime.parse(match['date']) : DateTime.now();

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Match Details"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: venueController,
                    decoration: const InputDecoration(labelText: "Venue / Ground"),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text("Date & Time"),
                    subtitle: Text(selectedDate.toString().split('.')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                       final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                       );
                       if(date != null && context.mounted) {
                          final time = await showTimePicker(
                             context: context,
                             initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if(time != null) {
                             setState(() {
                                selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                             });
                          }
                       }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                TextButton(
                  onPressed: () async {
                    await Supabase.instance.client
                        .from('matches')
                        .update({
                           'venue_name': venueController.text,
                           'ground': venueController.text,
                           'date': selectedDate.toIso8601String(),
                           'scheduled_date': selectedDate.toIso8601String(),
                        })
                        .eq('id', match['id']);
                    
                    // Log
                    await ref.read(adminRepositoryProvider).logActivity(
                      'edit_match', 
                      match['id'], 
                      'Updated match details (Venue: ${venueController.text})'
                    );

                    if(context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          }
        ),
      );
      // Refresh handled parent logic
  }

  Future<void> _cancelMatch(BuildContext context, WidgetRef ref, String matchId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Match?"),
        content: const Text("This cannot be undone. Notifications will be sent to teams."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes, Cancel")),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client
          .from('matches')
          .update({'status': 'Cancelled'})
          .eq('id', matchId);
      
      await ref.read(adminRepositoryProvider).logActivity('cancel_match', matchId, 'Match cancelled by admin');

       if(context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match Cancelled")));
       }
    }
  }

  Future<void> _deleteMatch(BuildContext context, WidgetRef ref, String matchId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Match?"),
        content: const Text("Are you sure? This will remove the match record permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes, Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.from('matches').delete().eq('id', matchId);
      await ref.read(adminRepositoryProvider).logActivity('delete_match', matchId, 'Match deleted permanently');
      
      if(context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match Deleted")));
      }
    }
  }

  Future<void> _forceEndMatch(BuildContext context, WidgetRef ref, String matchId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Force End Match?"),
        content: const Text("This will mark the match as Completed immediately. Ensure scores are final."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes, End Match")),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client
          .from('matches')
          .update({'status': 'Completed'})
          .eq('id', matchId);
      
      await ref.read(adminRepositoryProvider).logActivity('force_end_match', matchId, 'Match force ended by admin');
      
      if(context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match Ended")));
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Live': color = Colors.red; break;
      case 'Upcoming': color = Colors.blue; break;
      case 'Completed': color = Colors.green; break;
      case 'Cancelled': color = Colors.grey; break;
      default: color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
