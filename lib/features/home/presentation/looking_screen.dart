import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/supabase_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class LookingScreen extends StatefulWidget {
  const LookingScreen({super.key});

  @override
  State<LookingScreen> createState() => _LookingScreenState();
}

class _LookingScreenState extends State<LookingScreen> {
  String? _selectedType; // null = All/Mumbai default, 'Opponent', 'Team', 'Player'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: AppColors.background,
       appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('PRO @ ₹199', style: TextStyle(fontSize: 14)), 
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_alt_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('Looking for ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    _selectedType == null ? 'Anything?' : '$_selectedType?', 
                    style: const TextStyle(fontSize: 16, color: AppColors.secondary, fontWeight: FontWeight.bold)
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: (){}, 
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                       foregroundColor: Colors.white,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                       visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
             // Sub Filter
             Container(
               height: 50,
               color: Colors.white,
               child: ListView(
                 scrollDirection: Axis.horizontal,
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 children: [
                   _buildTab('All', _selectedType == null, () => setState(() => _selectedType = null)),
                   _buildTab('Opponent', _selectedType == 'Opponent', () => setState(() => _selectedType = 'Opponent')),
                   _buildTab('Team', _selectedType == 'Team', () => setState(() => _selectedType = 'Team')),
                   _buildTab('Player', _selectedType == 'Player', () => setState(() => _selectedType = 'Player')),
                 ],
               ),
             ),
             
             Expanded(
               child: FutureBuilder<List<Map<String, dynamic>>>(
                 future: SupabaseService.getCommunityPosts(_selectedType),
                 builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) {
                     return const Center(child: CircularProgressIndicator());
                   }
                   
                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text('No posts found in this category.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                   }

                   return ListView.builder(
                     padding: const EdgeInsets.all(16),
                     itemCount: snapshot.data!.length,
                     itemBuilder: (context, index) => _buildLookingCard(snapshot.data![index]),
                   );
                 },
               ),
             )
        ],
      ),
    );
  }
  
  Widget _buildTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? AppColors.secondary : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? AppColors.secondary : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );
  }

  Widget _buildLookingCard(Map<String, dynamic> item) {
    final user = item['users'] ?? {};
    final profile = user['profile_json'] ?? {};
    final name = profile['name'] ?? 'Unknown User';
    final type = item['type'] ?? 'General';
    final description = item['description'] ?? '';
    final createdAt = DateTime.parse(item['created_at']);
    final imageUrl = 'https://ui-avatars.com/api/?background=random&name=${name.replaceAll(' ', '+')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200, 
                  backgroundImage: NetworkImage(imageUrl),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                          children: [
                            TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' is looking for '),
                            TextSpan(text: type, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            const TextSpan(text: '.'),
                          ]
                        ),
                      ),
                       if (description.isNotEmpty) ...[
                         const SizedBox(height: 8),
                         Text(description, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                       ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeago.format(createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                TextButton.icon(
                  onPressed: (){},
                  icon: const Icon(Icons.chat_bubble_outline, size: 14),
                  label: const Text('Contact'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

