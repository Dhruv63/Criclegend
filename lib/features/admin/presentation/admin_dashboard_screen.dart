import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../data/admin_repository.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // Stats are now handled by provider
  List<Map<String, dynamic>> _activityLog = [];
  bool _loadingActivity = true;

  @override
  void initState() {
    super.initState();
    _fetchActivityLog();
  }

  Future<void> _fetchActivityLog() async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      final logs = await repo.getRecentActivity();
      if (mounted) {
        setState(() {
          _activityLog = logs;
          _loadingActivity = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingActivity = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      backgroundColor: Colors.grey[50], // Light background
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(adminDashboardStatsProvider);
          _fetchActivityLog();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80), // Added bottom padding
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              const Text(
                "Dashboard Overview",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Welcome back, Admin. Here's what's happening today.",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Metrics Grid
              statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.4 : 1.05,
                  children: [
                     _StatCard(
                      title: 'Live Matches',
                      count: stats['live_matches'].toString(),
                      icon: Icons.sports_cricket,
                      color: Colors.red,
                      subtext: 'Matches in progress',
                    ),
                    _StatCard(
                      title: 'Upcoming',
                      count: stats['upcoming_matches'].toString(),
                      icon: Icons.calendar_today,
                      color: Colors.blue,
                      subtext: 'Scheduled matches',
                    ),
                    _StatCard(
                      title: 'Active Products',
                      count: stats['active_products'].toString(),
                      icon: Icons.inventory_2_outlined,
                      color: Colors.purple,
                      subtext: 'In store',
                    ),
                    _StatCard(
                      title: 'Pending Orders',
                      count: stats['pending_orders'].toString(),
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.orange,
                      subtext: 'Action required',
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading stats: $err'),
              ),
              const SizedBox(height: 32),

              // Quick Actions
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: isWide ? 6 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isWide ? 1.0 : 1.2, // Adjusted aspect ratio for mobile
                children: [
                   _ActionCard(
                    icon: Icons.sports_cricket,
                    label: "Matches",
                    color: AppColors.primary,
                    onTap: () => context.push('/admin/matches'),
                  ),
                  _ActionCard(
                    icon: Icons.store,
                    label: "Products", // Changed from Store to Products
                    color: Colors.blue,
                    onTap: () => context.push('/admin/products'),
                  ),
                  _ActionCard(
                    icon: Icons.receipt_long,
                    label: "Orders",
                    color: Colors.orange,
                    onTap: () => context.push('/admin/orders'),
                  ),
                  _ActionCard(
                    icon: Icons.add_circle_outline,
                    label: "New Match",
                    color: Colors.green,
                    onTap: () => context.push('/new-match'),
                  ),
                   _ActionCard(
                    icon: Icons.add_box_outlined,
                    label: "Add Product",
                    color: Colors.purple,
                    onTap: () => context.push('/admin/products/add'),
                  ),
                   _ActionCard(
                    icon: Icons.settings_outlined,
                    label: "Settings",
                    color: Colors.grey,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Settings coming soon")),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Activity (Real)
              const Text(
                "Recent Activity",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_activityLog.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No recent activity")))
              else
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activityLog.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final activity = _activityLog[i];
                      final date = DateTime.parse(activity['created_at']);
                      final action = activity['action_type'] ?? 'action';
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[100],
                          child: _getActivityIcon(action),
                        ),
                        title: Text(
                          activity['description'] ?? 'Unknown activity',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          timeago.format(date),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Icon _getActivityIcon(String action) {
    if (action.contains('product')) return const Icon(Icons.inventory, size: 18, color: Colors.blue);
    if (action.contains('order')) return const Icon(Icons.shopping_bag, size: 18, color: Colors.orange);
    if (action.contains('match')) return const Icon(Icons.sports_cricket, size: 18, color: AppColors.primary);
    return const Icon(Icons.info_outline, size: 18, color: Colors.grey);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final String subtext;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.subtext,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min, // Use min size
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20), // Reduced icon size
              ),
            ],
          ),
          const SizedBox(height: 8), // Gap
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    count,
                    style: const TextStyle(
                      fontSize: 24, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                 Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
