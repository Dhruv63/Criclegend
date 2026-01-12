import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../community/data/community_repository.dart';
import '../../community/presentation/widgets/feed_post_card.dart';
import '../../community/presentation/create_post_screen.dart';
import '../../tournament/presentation/points_table_screen.dart'; // Added this import
import 'listing_screen.dart';
import 'store_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added this import

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityRepository _repo = CommunityRepository();

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Community & Services', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Social Feed'),
            Tab(text: 'Services'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.store, color: AppColors.secondary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: SOCIAL FEED
          RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _repo.getFeedPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final posts = snapshot.data ?? [];
                
                if (posts.isEmpty) {
                  return const Center(child: Text("No posts yet. Be the first!"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return FeedPostCard(
                      post: post,
                      onLike: () async {
                        // Optimistic UI could be here, but for now we just call API and refresh
                        // Ideally we setState local posts list.
                        await _repo.toggleLike(post['id']);
                        setState(() {}); // Refresh to show new count/status
                      },
                    );
                  },
                );
              },
            ),
          ),

          // TAB 2: SERVICES GRID (Existing Code Refactored)
          Column(
            children: [
               Container(
                 color: Colors.white,
                 padding: const EdgeInsets.all(16.0),
                 child: Row(
                   children: [
                     const Text('Cricket community in ', style: TextStyle(fontSize: 16)),
                     const Text('Mumbai', style: TextStyle(fontSize: 16, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                     const SizedBox(width: 4),
                     Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
                   ],
                 ),
               ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _ServiceCard(icon: Icons.emoji_events, label: 'Tournaments', onTap: () async {
                       // Demo: Fetch the CPL 2026 ID
                       try {
                         final res = await Supabase.instance.client
                           .from('tournaments')
                           .select('id')
                           .eq('name', 'CricLegend Premier League 2026')
                           .maybeSingle();
                         
                         if (res != null && mounted) {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: res['id'])));
                         } else if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active tournament found!')));
                         }
                       } catch (e) {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                       }
                    }),
                    _ServiceCard(icon: Icons.sports_cricket, label: 'Scorers', onTap: () => _nav(context, 'Scorers')),
                    _ServiceCard(icon: Icons.sports, label: 'Umpires', onTap: () => _nav(context, 'Umpires')),
                    _buildGridItem(context, Icons.mic, 'Commentators', 'Commentator', ListingType.service),
                    _buildGridItem(context, Icons.live_tv, 'Streamers', 'Streamer', ListingType.service),
                    _buildGridItem(context, Icons.star_border, 'Organisers', 'Organiser', ListingType.service),
                    _buildGridItem(context, Icons.school, 'Academies', 'Academy', ListingType.business),
                    _buildGridItem(context, Icons.grass, 'Grounds', 'Ground', ListingType.business),
                    _buildGridItem(context, Icons.store, 'Shops', 'Shop', ListingType.business),
                    _buildGridItem(context, Icons.fitness_center, 'Physio', 'Physio', ListingType.service),
                    _buildGridItem(context, Icons.person, 'Coaching', 'Coach', ListingType.service), 
                    _buildGridItem(context, Icons.sports_tennis, 'Box Cricket', 'Box Cricket', ListingType.business),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
        },
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  void _nav(BuildContext context, String title) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to $title')));
  }

  Widget _buildGridItem(BuildContext context, IconData icon, String label, String dbKey, ListingType type) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingScreen(title: label, categoryKey: dbKey, type: type),
          ),
        );
      },
      child: _GridItemUI(icon: icon, label: label),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: _GridItemUI(icon: icon, label: label),
    );
  }
}

class _GridItemUI extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GridItemUI({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
     return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.black87),
            const SizedBox(height: 12),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
            ),
          ],
        ),
      );
  }
}
