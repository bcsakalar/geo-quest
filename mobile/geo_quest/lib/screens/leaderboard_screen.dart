import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QuestProvider>().loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final questProvider = context.watch<QuestProvider>();
    final leaderboard = questProvider.leaderboard;

    return RefreshIndicator(
      onRefresh: () => questProvider.loadLeaderboard(),
      child: leaderboard.isEmpty
          ? const Center(child: Text('Henüz sıralama yok', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final user = leaderboard[index];
                final rank = index + 1;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rank <= 3 ? _medalColor(rank) : Colors.grey.shade200,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rank <= 3 ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: user.currentStreak > 0
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                              const SizedBox(width: 2),
                              Text('${user.currentStreak} gün', style: const TextStyle(fontSize: 12)),
                            ],
                          )
                        : null,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${user.totalPoints} puan',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _medalColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.grey;
    }
  }
}
