import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/looking_providers.dart';
import 'widgets/looking_card.dart';

class LookingScreen extends ConsumerWidget {
  const LookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final lookingAsync = ref.watch(lookingRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // App Bar with Search
      appBar: AppBar(
        title: Text('Looking For...', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.notifications_outlined, color: Colors.black)
              ),
            )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
               onChanged: (val) => ref.read(searchCityProvider.notifier).set(val),
               decoration: InputDecoration(
                 hintText: 'Search by city (e.g. Mumbai)',
                 prefixIcon: const Icon(Icons.search, color: Colors.grey),
                 filled: true,
                 fillColor: Colors.grey.shade100,
                 contentPadding: const EdgeInsets.symmetric(vertical: 0),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
               ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
             color: Colors.white,
             height: 50,
             child: ListView(
               scrollDirection: Axis.horizontal,
               padding: const EdgeInsets.symmetric(horizontal: 16),
               children: [
                 _FilterChip(label: 'All', isSelected: selectedCategory == null, onTap: () => ref.read(selectedCategoryProvider.notifier).set(null)),
                 _FilterChip(label: '🏏 Player', isSelected: selectedCategory == 'Player', onTap: () => ref.read(selectedCategoryProvider.notifier).set('Player')),
                 _FilterChip(label: '⚔️ Opponent', isSelected: selectedCategory == 'Opponent', onTap: () => ref.read(selectedCategoryProvider.notifier).set('Opponent')),
                 _FilterChip(label: '👔 Umpire', isSelected: selectedCategory == 'Umpire', onTap: () => ref.read(selectedCategoryProvider.notifier).set('Umpire')),
                 _FilterChip(label: '🏟️ Ground', isSelected: selectedCategory == 'Ground', onTap: () => ref.read(selectedCategoryProvider.notifier).set('Ground')),
                 _FilterChip(label: '🎓 Academy', isSelected: selectedCategory == 'Academy', onTap: () => ref.read(selectedCategoryProvider.notifier).set('Academy')),
               ],
             ),
          ),
          
          Expanded(
            child: lookingAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No requests found', style: GoogleFonts.inter(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(lookingRequestsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) => LookingCard(request: requests[index]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-looking'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Post Request'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )
        ),
      ),
    );
  }
}
