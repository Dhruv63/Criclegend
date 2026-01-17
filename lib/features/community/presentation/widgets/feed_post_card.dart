import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final VoidCallback? onComment;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.onLike,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final user = post['users'] ?? {};
    final profile = user['profile_json'] ?? {};
    final name = profile['name'] ?? 'Unknown User';
    final content = post['content'] ?? '';
    final createdAt = DateTime.parse(post['created_at']);
    final media = List<String>.from(post['media_urls'] ?? []);
    final likesCount = post['likes_count'] ?? 0;
    final isLiked = post['is_liked_by_me'] ?? false;

    // Avatar
    final avatarUrl =
        'https://ui-avatars.com/api/?background=random&name=${name.replaceAll(' ', '+')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      timeago.format(createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            if (content.isNotEmpty)
              Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),

            const SizedBox(height: 12),

            // Media (Simple Image for now)
            if (media.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  media.first,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),

            if (media.isNotEmpty) const SizedBox(height: 12),

            // Footer (Actions)
            Row(
              children: [
                _ActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey,
                  label: '$likesCount',
                  onTap: onLike,
                ),
                const SizedBox(width: 24),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: Colors.grey,
                  label: '${post['comments_count'] ?? 0}',
                  onTap: onComment ?? () {},
                ),
                const Spacer(),
                const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
