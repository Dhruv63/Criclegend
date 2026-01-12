import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class MainLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    print('DEBUG: MainLayout Build');
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) => widget.navigationShell.goBranch(index),
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent, // No indicator pill usually in this style
        elevation: 8,
        height: 65,
        destinations: [
          _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
          _buildNavItem(Icons.search, Icons.search, 'Looking', 1),
          _buildNavItem(Icons.sports_cricket_outlined, Icons.sports_cricket, 'My Cricket', 2, isMain: true),
          _buildNavItem(Icons.people_outlined, Icons.people, 'Community', 3),
          _buildNavItem(Icons.shopping_bag_outlined, Icons.shopping_bag, 'Store', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index, {bool isMain = false}) {
    final isSelected = widget.navigationShell.currentIndex == index;
    final color = isSelected ? AppColors.primary : Colors.grey.shade600;
    
    // "My Cricket" often has a distinct icon or center prominence
    // For now we treat them equally but with color highlighting
    
    return NavigationDestination(
      icon: Icon(icon, color: color),
      selectedIcon: Icon(activeIcon, color: AppColors.primary),
      label: label,
    );
  }
}
