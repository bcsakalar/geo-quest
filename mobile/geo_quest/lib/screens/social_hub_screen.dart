import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/social_provider.dart';
import 'friends_screen.dart';
import 'chat_screen.dart';
import 'feed_screen.dart';

class SocialHubScreen extends StatefulWidget {
  const SocialHubScreen({super.key});

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen> {
  @override
  void initState() {
    super.initState();
    final sp = context.read<SocialProvider>();
    sp.loadConversations();
    sp.loadFeed();
    sp.loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SocialProvider>();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              const Tab(text: 'Feed'),
              Tab(
                child: Badge(
                  isLabelVisible: sp.unreadMessages > 0,
                  label: Text('${sp.unreadMessages}'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Mesajlar'),
                  ),
                ),
              ),
              const Tab(text: 'Arkadaşlar'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const FeedScreen(),
                _buildMessagesTab(sp),
                _buildFriendsQuickView(sp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab(SocialProvider sp) {
    final conversations = sp.conversations;

    return RefreshIndicator(
      onRefresh: () => sp.loadConversations(),
      child: conversations.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz mesaj yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Arkadaşlarınla sohbet başlat!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final unread = conv['unread_count'] ?? 0;
                final color = _parseColor(conv['partner_color']);

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withAlpha(50),
                      child: Text(
                        (conv['partner_name'] ?? '?')[0].toUpperCase(),
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv['partner_name'] ?? '',
                            style: TextStyle(fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w500),
                          ),
                        ),
                        Text(
                          _formatTime(conv['last_message_at']),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        if (conv['message_type'] == 'challenge')
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.sports_martial_arts, size: 14, color: Colors.orange.shade600),
                          ),
                        Expanded(
                          child: Text(
                            conv['last_message'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: unread > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.green,
                            child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            partnerId: conv['partner_id'],
                            partnerName: conv['partner_name'] ?? 'Arkadaş',
                            partnerColor: conv['partner_color'] ?? '#4CAF50',
                          ),
                        ),
                      ).then((_) => sp.loadConversations());
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFriendsQuickView(SocialProvider sp) {
    final friends = sp.friends;
    final pending = sp.pendingRequests;

    return RefreshIndicator(
      onRefresh: () async {
        await sp.loadFriends();
        await sp.loadPendingRequests();
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Bekleyen istekler
          if (pending.isNotEmpty) ...[
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: Badge(
                  label: Text('${pending.length}'),
                  child: const Icon(Icons.person_add, color: Colors.blue),
                ),
                title: Text('${pending.length} bekleyen arkadaşlık isteği'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen())),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Arkadaş ekle butonu
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen())),
            icon: const Icon(Icons.person_add),
            label: const Text('Arkadaş Ekle / Yönet'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),

          Text('Arkadaşlarım (${friends.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (friends.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Henüz arkadaşın yok', style: TextStyle(color: Colors.grey))),
              ),
            ),

          ...friends.map((f) {
            final color = _parseColor(f['avatar_color']);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withAlpha(50),
                  child: Text(
                    (f['name'] ?? '?')[0].toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(f['name'] ?? ''),
                subtitle: Text('${f['total_points'] ?? 0} puan'),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          partnerId: f['id'],
                          partnerName: f['name'] ?? 'Arkadaş',
                          partnerColor: f['avatar_color'] ?? '#4CAF50',
                        ),
                      ),
                    ).then((_) => sp.loadConversations());
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
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

      if (diff.inMinutes < 1) return 'Şimdi';
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
      if (diff.inHours < 24) return '${diff.inHours} sa';
      if (diff.inDays < 7) return '${diff.inDays} gün';
      return '${dt.day}.${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
