import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/team_controller.dart';
import '../../auth/presentation/providers/auth_providers.dart';

class TeamDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamId = team['id'] as String;
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final currentUser = ref.watch(userProvider);
    final isCaptain = currentUser?.id == team['captain_id'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(team['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepTeal,
        foregroundColor: Colors.white,
        actions: [
          if (isCaptain)
            IconButton(icon: const Icon(Icons.edit), onPressed: () {}), // TODO: Edit Team
        ],
      ),
      floatingActionButton: isCaptain ? FloatingActionButton(
        onPressed: () => _showAddPlayerSheet(context, ref, teamId),
        backgroundColor: AppColors.premiumRed,
        child: const Icon(Icons.person_add),
      ) : null,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.deepTeal.withOpacity(0.05)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: team['logo_url'] != null ? NetworkImage(team['logo_url']) : null,
                  child: team['logo_url'] == null ? const Icon(Icons.security, size: 40, color: Colors.grey) : null,
                ),
                const SizedBox(height: 16),
                Text(team['name'], style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(team['city'] ?? 'Unknown location', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          
          // Squad List
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (members) {
                 if (members.isEmpty) {
                   return const Center(child: Text('No players in this team yet.'));
                 }
                 
                 return ListView.separated(
                   padding: const EdgeInsets.all(16),
                   itemCount: members.length,
                   separatorBuilder: (_, __) => const Divider(),
                   itemBuilder: (context, index) {
                     final member = members[index];
                     final profile = member['profile_json'] ?? {};
                     final name = profile['name'] ?? 'Unknown Player';
                     final isCap = member['id'] == team['captain_id'];
                     
                     return ListTile(
                       leading: CircleAvatar(
                         backgroundColor: Colors.grey.shade200,
                         backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${name.replaceAll(' ', '+')}'),
                       ),
                       title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                       subtitle: Text(isCap ? 'Captain' : (profile['role'] ?? 'Player')),
                       trailing: isCap ? const Icon(Icons.star, color: Colors.amber) : null,
                     );
                   },
                 );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerSheet(BuildContext context, WidgetRef ref, String teamId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PlayerSearchSheet(teamId: teamId),
    );
  }
}

class PlayerSearchSheet extends ConsumerStatefulWidget {
  final String teamId;
  const PlayerSearchSheet({super.key, required this.teamId});

  @override
  ConsumerState<PlayerSearchSheet> createState() => _PlayerSearchSheetState();
}

class _PlayerSearchSheetState extends ConsumerState<PlayerSearchSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  void _onSearch(String query) async {
    if (query.length < 2) return;
    setState(() => _isSearching = true);
    
    // In MVP, we search on submit or debounce. Assuming manual search button or debounce later.
    // For now, let's just trigger immediately for simplicity if short, but better to wait.
    // I will call repo directly here as it's ephemeral local state.
    final repo = ref.read(teamRepositoryProvider);
    final results = await repo.searchPlayers(query);
    
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _addPlayer(String userId) async {
    try {
      await ref.read(teamControllerProvider.notifier).addPlayer(teamId: widget.teamId, userId: userId);
      if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Player added!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              Text('Add Player', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or phone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                 icon: const Icon(Icons.arrow_forward),
                 onPressed: () => _onSearch(_searchController.text),
              ),
            ),
            onSubmitted: _onSearch,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    final profile = user['profile_json'] ?? {};
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(profile['name'] ?? 'Unknown'),
                      subtitle: Text(user['phone'] ?? ''),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepTeal, foregroundColor: Colors.white),
                        onPressed: () => _addPlayer(user['id']),
                        child: const Text('Add'),
                      ),
                    );
                  },
              ),
          ),
        ],
      ),
    );
  }
}
