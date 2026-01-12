import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _userCount = 0;
  int _activeMatches = 0;
  int _verifiedTeams = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final client = Supabase.instance.client;
    try {
      final users = await client.from('users').count(CountOption.exact);
      final matches = await client.from('matches').count(CountOption.exact).eq('status', 'Live');
      final teams = await client.from('teams').count(CountOption.exact).eq('is_verified', true);
      
      if (mounted) {
        setState(() {
          _userCount = users;
          _activeMatches = matches;
          _verifiedTeams = teams;
          _loading = false;
        });
      }
    } catch (e) {
      // Handle error (tables might not have policies yet)
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Platform Overview", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _StatCard(title: 'Total Users', count: _userCount.toString(), icon: Icons.people, color: Colors.blue),
              _StatCard(title: 'Live Matches', count: _activeMatches.toString(), icon: Icons.sports_cricket, color: Colors.red),
              _StatCard(title: 'Verified Teams', count: _verifiedTeams.toString(), icon: Icons.verified, color: Colors.green),
              _StatCard(title: 'Pending Reports', count: '0', icon: Icons.warning, color: Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
