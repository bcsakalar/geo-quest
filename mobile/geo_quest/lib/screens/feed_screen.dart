import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/social_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SocialProvider>().loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SocialProvider>();
    final feed = sp.feed;

    return RefreshIndicator(
      onRefresh: () => sp.loadFeed(),
      child: feed.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dynamic_feed, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aktivite yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Arkadaş ekle ve aktivitelerini gör!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: feed.length,
              itemBuilder: (context, index) {
                final item = feed[index];
                final color = _parseColor(item['avatar_color']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withAlpha(50),
                          child: Text(
                            (item['user_name'] ?? '?')[0].toUpperCase(),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_getActivityIcon(item['type']), size: 16, color: _getActivityColor(item['type'])),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['user_name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(item['description'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(item['created_at']),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'quest_completed':
        return Icons.check_circle;
      case 'achievement':
        return Icons.emoji_events;
      case 'streak':
        return Icons.local_fire_department;
      case 'friendship':
        return Icons.people;
      default:
        return Icons.circle;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'quest_completed':
        return Colors.green;
      case 'achievement':
        return Colors.amber;
      case 'streak':
        return Colors.orange;
      case 'friendship':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.green;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.green;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Az önce';
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
      if (diff.inHours < 24) return '${diff.inHours} saat önce';
      if (diff.inDays < 7) return '${diff.inDays} gün önce';
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
