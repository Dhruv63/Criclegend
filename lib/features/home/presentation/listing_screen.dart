import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/supabase_service.dart';

enum ListingType { service, business }

class ListingScreen extends StatelessWidget {
  final String title;
  final String categoryKey; // 'Scorer', 'Academy', etc. matching DB
  final ListingType type;

  const ListingScreen({
    super.key, 
    required this.title, 
    required this.categoryKey,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: type == ListingType.service 
            ? SupabaseService.getServicesByCategory(categoryKey)
            : SupabaseService.getBusinessesByCategory(categoryKey),
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
                  Text('No $title found.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return type == ListingType.service 
                  ? _buildServiceCard(item) 
                  : _buildBusinessCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> item) {
    final user = item['users'] ?? {};
    final profile = user['profile_json'] ?? {};
    final name = profile['name'] ?? 'Unknown User';
    final location = item['city'] ?? user['location'] ?? 'Mumbai';
    final rate = item['hourly_rate'];
    final imageUrl = 'https://ui-avatars.com/api/?background=random&name=${name.replaceAll(' ', '+')}';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(imageUrl),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['description'] ?? 'No description', maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (rate != null) Text('₹$rate/match', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
              child: const Text('VERIFIED', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Business';
    final address = item['address'] ?? 'Mumbai';
    final images = item['images'];
    String? imageUrl;
    if (images != null && (images is List) && images.isNotEmpty) {
      imageUrl = images[0];
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.amber),
                          SizedBox(width: 2),
                          Text('4.5', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(address, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
