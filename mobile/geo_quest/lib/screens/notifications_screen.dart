import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/social_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SocialProvider>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SocialProvider>();
    final notifications = sp.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (sp.unreadNotifications > 0)
            TextButton(
              onPressed: () => sp.markNotificationsRead(),
              child: const Text('Hepsini Oku'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => sp.loadNotifications(),
        child: notifications.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Bildirim yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  final isRead = n['is_read'] == true;

                  return Card(
                    color: isRead ? null : Colors.blue.shade50,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTypeColor(n['type']).withAlpha(30),
                        child: Icon(_getTypeIcon(n['type']), color: _getTypeColor(n['type'])),
                      ),
                      title: Text(
                        n['title'] ?? '',
                        style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['body'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(n['created_at']),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'friend_accepted':
        return Icons.people;
      case 'challenge':
        return Icons.sports_martial_arts;
      case 'message':
        return Icons.chat_bubble;
      case 'streak_warning':
        return Icons.local_fire_department;
      case 'daily_challenge':
        return Icons.today;
      case 'achievement':
        return Icons.emoji_events;
      case 'nearby_quest':
        return Icons.location_on;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'friend_request':
      case 'friend_accepted':
        return Colors.blue;
      case 'challenge':
        return Colors.orange;
      case 'message':
        return Colors.green;
      case 'streak_warning':
        return Colors.red;
      case 'daily_challenge':
        return Colors.purple;
      case 'achievement':
        return Colors.amber;
      case 'nearby_quest':
        return Colors.teal;
      default:
        return Colors.grey;
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
