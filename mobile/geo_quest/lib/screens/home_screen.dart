import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/social_provider.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'achievements_screen.dart';
import 'social_hub_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    MapScreen(),
    SocialHubScreen(),
    AchievementsScreen(),
    ProfileScreen(),
    LeaderboardScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Unread sayılarını yükle
    context.read<SocialProvider>().loadUnreadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sp = context.watch<SocialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo-Quest'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: sp.unreadNotifications > 0,
              label: Text('${sp.unreadNotifications}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.map), label: 'Harita'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: sp.totalUnread > 0,
              label: Text('${sp.totalUnread}'),
              child: const Icon(Icons.people),
            ),
            label: 'Sosyal',
          ),
          const NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Başarım'),
          const NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
          const NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Sıralama'),
        ],
      ),
    );
  }
}
