import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/supabase_service.dart';
import '../../auth/presentation/providers/auth_providers.dart';

class MyCricketScreen extends ConsumerStatefulWidget {
  const MyCricketScreen({super.key});

  @override
  ConsumerState<MyCricketScreen> createState() => _MyCricketScreenState();
}

class _MyCricketScreenState extends ConsumerState<MyCricketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); 
    // Data loading triggered in build via ref.listen or just checking state
    // But we need async fetch for matches/teams.
    // Better to use ref.listen(userProvider) or just fetch in didChangeDependencies?
    // Let's use didChangeDependencies or just fetch once if user is present.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = ref.read(userProvider);
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Fetch Profile Data (from public.users)
      // We can get this from SupabaseService using user.id
      final userData = await SupabaseService.getUserProfile(user.id);
      
      // 2. Fetch Dependent Data
      final matches = await SupabaseService.getCompletedMatches(); // Showing history
      final teams = await SupabaseService.getUserTeams(user.id);
      
      if (mounted) {
        setState(() {
          _profile = userData;
          _matches = matches;
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('MyCricket Load Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    // If not loaded and no user, show login prompt or empty state (should ideally not happen due to AuthGuard)
    if (_profile == null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Profile not loaded'),
                TextButton(onPressed: _loadData, child: const Text('Retry'))
              ],
            ),
          )
        );
    }

    final profile = _profile!['profile_json'] ?? {};
    final name = profile['name'] ?? 'Player';
    final role = profile['role'] ?? 'Cricketer';
    final location = profile['location'] ?? 'Mumbai';
    final imageUrl = 'https://ui-avatars.com/api/?background=random&name=${name.replaceAll(' ', '+')}';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('My Cricket', style: TextStyle(fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                 Row(
                   children: [
                     CircleAvatar(radius: 30, backgroundImage: NetworkImage(imageUrl)),
                     const SizedBox(width: 16),
                     Expanded( // Wrap text column in Expanded to prevent overflow
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(name, 
                             style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                             maxLines: 1, 
                             overflow: TextOverflow.ellipsis, // Handle text overflow
                           ),
                           Text('$role • $location', 
                             style: const TextStyle(color: Colors.white70, fontSize: 12),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ],
                       ),
                     ),
                     // const Spacer(), // Spacer not needed if using Expanded, or use Spacer AFTER Expanded if we want gaps?
                     // Actually, if we use Expanded on Column, it takes ALL space.
                     // If we want the PRO badge to be right-aligned, Expanded pushes it there.
                     // But if we want it *pushed* to the end, Expanded does that.
                     // However, "Spacer()" is essentially Expanded(flex: 1).
                     // If we have Expanded(Column) and Spacer(), they share space.
                     // We probably want Column to take "needed" space up to limit?
                     // No, "My Cricket" header usually has name on left, badge on right.
                     // Expanded(Column) ensures Column uses available space.
                     const SizedBox(width: 16),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                       child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                     )
                   ],
                 ),
                 const SizedBox(height: 16),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                     _buildStatItem('Matches', '${profile['matches_played'] ?? 0}'),
                     _buildStatItem('Runs', '${profile['total_runs'] ?? 0}'),
                     _buildStatItem('Wickets', '${profile['total_wickets'] ?? 0}'),
                   ],
                 )
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Matches'),
                Tab(text: 'Teams'),
                Tab(text: 'Stats'),
                Tab(text: 'Awards'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMatchesTab(),
                _buildTeamsTab(),
                const Center(child: Text('Detailed Stats Coming Soon')),
                const Center(child: Text('No Awards Yet')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildMatchesTab() {
    if (_matches.isEmpty) {
      return const Center(child: Text('No matches played yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        final teamA = match['team_a']['name'];
        final teamB = match['team_b']['name'];
        final ground = match['ground'] ?? 'Unknown Ground';
        final result = match['result'] ?? 'Match Completed';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(teamA, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('VS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(teamB, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(ground, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Manage My Teams'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                foregroundColor: Colors.white,
              ),
              onPressed: () => context.push('/my-teams'),
            ),
          ),
        ),
        Expanded(
          child: _teams.isEmpty
              ? const Center(child: Text('No teams joined yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final team = _teams[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.group)),
                        title: Text(team['name']),
                        subtitle: Text(team['location'] ?? (team['city'] ?? 'Unknown')),
                        // trailing: const Icon(Icons.star, color: Colors.amber),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

