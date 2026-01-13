import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_dashboard_screen.dart';
import 'admin_match_console.dart'; 
import 'store/product_management_screen.dart';
import 'store/order_management_screen.dart';
import 'store/store_analytics_screen.dart';
import 'store/store_settings_screen.dart';

// We'll keep AdminMatchConsole as the "Match" tab content for now, 
// but this screen replaces the outer shell.

class AdminConsoleScreen extends ConsumerStatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  ConsumerState<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends ConsumerState<AdminConsoleScreen> {
  String _selectedSection = 'Dashboard';
  
  // Map selection to Widget
  Widget _buildContent() {
    switch (_selectedSection) {
      case 'Dashboard':
        return const AdminDashboardScreen();
      case 'Matches':
        return const MatchListContent();
      case 'Products':
        return const ProductManagementScreen();
      case 'Orders':
        return const OrderManagementScreen();
      case 'Analytics':
        return const StoreAnalyticsScreen();
      case 'Settings':
        return const StoreSettingsScreen();
      default:
        return const AdminDashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: const Text('🏏 CricLegend Admin', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), 
            onPressed: () => context.go('/home'),
            tooltip: 'Exit to App',
          ),
        ],
      ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      body: Row(
        children: [
          if (isDesktop) 
            SizedBox(width: 260, child: _buildSidebar()),
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _NavItem(
            icon: Icons.dashboard, 
            label: 'Dashboard', 
            isSelected: _selectedSection == 'Dashboard',
            onTap: () => setState(() => _selectedSection = 'Dashboard'),
          ),
          const Divider(),
          _NavItem(
            icon: Icons.sports_cricket, 
            label: 'Match Management', 
            isSelected: _selectedSection == 'Matches',
            onTap: () {
               // Special case: Retrieve the old full console if needed
               // context.push('/admin/console/matches'); // If we had sub-routes
               setState(() => _selectedSection = 'Matches');
            },
          ),
          const Divider(),
          ExpansionTile(
            initiallyExpanded: true,
            leading: const Icon(Icons.store),
            title: const Text("Store Management"),
            children: [
               _NavItem(
                icon: Icons.shopping_bag, 
                label: 'Products', 
                indent: true,
                isSelected: _selectedSection == 'Products',
                onTap: () => setState(() => _selectedSection = 'Products'),
              ),
              _NavItem(
                icon: Icons.list_alt, 
                label: 'Orders', 
                indent: true,
                isSelected: _selectedSection == 'Orders',
                onTap: () => setState(() => _selectedSection = 'Orders'),
              ),
              _NavItem(
                icon: Icons.analytics, 
                label: 'Analytics', 
                indent: true,
                isSelected: _selectedSection == 'Analytics',
                onTap: () => setState(() => _selectedSection = 'Analytics'),
              ),
               _NavItem(
                icon: Icons.settings, 
                label: 'Store Settings', 
                indent: true,
                isSelected: _selectedSection == 'Settings',
                onTap: () => setState(() => _selectedSection = 'Settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool indent;

  const _NavItem({
    required this.icon, 
    required this.label, 
    required this.isSelected, 
    required this.onTap,
    this.indent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.only(left: indent ? 32 : 16, right: 16),
        leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade700, size: 20),
        title: Text(
          label, 
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}
