import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final userMetadata = user?.userMetadata ?? {};
    final name = userMetadata['name'] ?? 'Guest User';
    final phone = user?.phone ?? user?.email ?? 'Not Signed In'; // Fallback
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    return Drawer(
      child: Column(
        children: [
          // 1. Dynamic Header
          Container(
            color: const Color(0xFF1D3557), // Deep Teal
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
            child: InkWell(
              onTap: () {
                // Navigate to Profile when implemented
                // context.push('/profile');
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: GoogleFonts.outfit(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: const Color(0xFF1D3557)
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            color: Colors.white, 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
            ),
          ),

          // 2. Essentials List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.sports_cricket, 
                  title: 'Start a Match',
                  onTap: () => context.push('/new-match'), // Updated Route
                  color: AppColors.primary,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.groups_outlined, 
                  title: 'My Teams',
                  onTap: () => {},//context.push('/my-teams'), // Coming soon
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.bar_chart_rounded, 
                  title: 'My Stats',
                  onTap: () => {}, //context.push('/profile/stats'),
                ),
                const Divider(),
                // Admin Panel Section
                ref.watch(userRoleProvider).when(
                  data: (role) => role == 'admin' 
                    ? _buildMenuItem(
                        context,
                        icon: Icons.admin_panel_settings,
                        title: 'Admin Panel',
                        color: Colors.red,
                        onTap: () => context.push('/admin/console'),
                      )
                    : const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                ),
                const Divider(),
                 _buildMenuItem(
                  context,
                  icon: Icons.logout, 
                  title: 'Logout',
                  color: Colors.red,
                  onTap: () async {
                    await ref.read(authControllerProvider).signOut();
                    // GoRouter redirect should handle moving back to Login
                  },
                ),
              ],
            ),
          ),

          // Footer version
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v0.2.0 (Alpha)', 
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon, 
    required String title, 
    required VoidCallback onTap,
    Color color = Colors.grey, // Default icon color
  }) {
    return ListTile(
      leading: Icon(icon, color: color == Colors.grey ? Colors.grey.shade700 : color, size: 24),
      title: Text(
        title, 
        style: GoogleFonts.inter(
          fontSize: 15, 
          fontWeight: FontWeight.w500,
          color: Colors.black87
        )
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer first
        onTap();
      },
      dense: true,
      minLeadingWidth: 20,
    );
  }
}
