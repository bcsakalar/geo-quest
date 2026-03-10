import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/social_provider.dart';
import 'chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final sp = context.read<SocialProvider>();
    sp.loadFriends();
    sp.loadPendingRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arkadaşlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.people),
              text: 'Arkadaşlar',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: context.watch<SocialProvider>().pendingRequests.isNotEmpty,
                label: Text('${context.watch<SocialProvider>().pendingRequests.length}'),
                child: const Icon(Icons.person_add),
              ),
              text: 'İstekler',
            ),
            const Tab(icon: Icon(Icons.search), text: 'Ara'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildRequestsList(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    final sp = context.watch<SocialProvider>();
    final friends = sp.friends;

    if (friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Henüz arkadaşın yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('"Ara" sekmesinden arkadaş ekle!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => sp.loadFriends(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          final color = _parseColor(friend['avatar_color']);

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withAlpha(50),
                child: Text(
                  (friend['name'] ?? '?')[0].toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(friend['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  Text('${friend['total_points'] ?? 0} puan'),
                  if ((friend['current_streak'] ?? 0) > 0) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.local_fire_department, size: 14, color: Colors.orange.shade600),
                    Text('${friend['current_streak']}', style: TextStyle(color: Colors.orange.shade600)),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(
                        partnerId: friend['id'],
                        partnerName: friend['name'] ?? 'Arkadaş',
                        partnerColor: friend['avatar_color'] ?? '#4CAF50',
                      )),
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'remove', child: Text('Arkadaşlıktan Çıkar')),
                    ],
                    onSelected: (value) async {
                      if (value == 'remove') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Arkadaşlıktan Çıkar'),
                            content: Text('${friend['name']} arkadaşlıktan çıkarılsın mı?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıkar', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await sp.removeFriend(friend['friendship_id']);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList() {
    final sp = context.watch<SocialProvider>();
    final requests = sp.pendingRequests;

    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Bekleyen istek yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (req['name'] ?? '?')[0].toUpperCase(),
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(req['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${req['total_points'] ?? 0} puan'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () async {
                    await sp.acceptRequest(req['friendship_id']);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${req['name']} artık arkadaşın!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => sp.rejectRequest(req['friendship_id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    final sp = context.watch<SocialProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'İsim veya e-posta ile ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        sp.searchUsers('');
                      },
                    )
                  : null,
            ),
            onChanged: (q) => sp.searchUsers(q),
          ),
        ),
        Expanded(
          child: sp.searchResults.isEmpty
              ? const Center(child: Text('Aramak için yukarıya yaz', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: sp.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = sp.searchResults[index];
                    final status = user['friendship_status'];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _parseColor(user['avatar_color']).withAlpha(50),
                        child: Text(
                          (user['name'] ?? '?')[0].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: _parseColor(user['avatar_color'])),
                        ),
                      ),
                      title: Text(user['name'] ?? ''),
                      subtitle: Text('${user['total_points'] ?? 0} puan'),
                      trailing: _buildFriendActionButton(user, status, sp),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFriendActionButton(Map<String, dynamic> user, String? status, SocialProvider sp) {
    if (status == 'accepted') {
      return const Chip(
        label: Text('Arkadaş', style: TextStyle(fontSize: 12)),
        backgroundColor: Color(0xFFE8F5E9),
      );
    }
    if (status == 'pending') {
      return const Chip(
        label: Text('Bekliyor', style: TextStyle(fontSize: 12)),
        backgroundColor: Color(0xFFFFF3E0),
      );
    }
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await sp.sendFriendRequest(user['id']);
        if (mounted) {
          final error = result['error'];
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error ?? 'İstek gönderildi!'),
            backgroundColor: error != null ? Colors.red : Colors.green,
          ));
        }
        sp.searchUsers(_searchController.text);
      },
      icon: const Icon(Icons.person_add, size: 16),
      label: const Text('Ekle', style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
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
}
