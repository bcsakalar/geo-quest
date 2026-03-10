import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';
import '../providers/auth_provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    final qp = context.read<QuestProvider>();
    qp.loadAchievements();
    qp.loadStreakInfo();
    qp.loadDailyChallenge();
  }

  @override
  Widget build(BuildContext context) {
    final qp = context.watch<QuestProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final achievements = qp.achievements;
    final streak = qp.streakInfo;
    final daily = qp.dailyChallenge;

    return RefreshIndicator(
      onRefresh: () async {
        await qp.loadAchievements();
        await qp.loadStreakInfo();
        await qp.loadDailyChallenge();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ──── Streak Card ────
          _buildStreakCard(streak, user),
          const SizedBox(height: 16),

          // ──── Günlük Meydan Okuma ────
          _buildDailyCard(daily),
          const SizedBox(height: 16),

          // ──── Başarımlar ────
          const Text(
            'Başarımlar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (achievements.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Başarımlar yükleniyor...', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ),
          _buildAchievementGrid(achievements),
        ],
      ),
    );
  }

  Widget _buildStreakCard(Map<String, dynamic>? streak, dynamic user) {
    final currentStreak = streak?['current_streak'] ?? user?.currentStreak ?? 0;
    final maxStreak = streak?['max_streak'] ?? user?.maxStreak ?? 0;
    final multiplier = streak?['multiplier'] ?? 1.0;

    return Card(
      color: currentStreak >= 7
          ? Colors.orange.shade50
          : currentStreak >= 3
              ? Colors.amber.shade50
              : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentStreak >= 7
                    ? Colors.orange
                    : currentStreak >= 3
                        ? Colors.amber
                        : Colors.grey.shade400,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                  Text(
                    '$currentStreak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currentStreak Gün Streak!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'En yüksek: $maxStreak gün',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (multiplier > 1.0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${multiplier}x Puan Çarpanı!',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCard(Map<String, dynamic>? daily) {
    if (daily == null) {
      return Card(
        color: Colors.blue.shade50,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.today, color: Colors.blue, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Günlük meydan okuma hazırlanıyor...',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final completed = daily['completed'] == true;
    final bonus = daily['bonus_points'] ?? 25;

    return Card(
      color: completed ? Colors.green.shade50 : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.today,
              color: completed ? Colors.green : Colors.blue,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completed ? 'Günlük Görev Tamamlandı!' : 'Günlük Meydan Okuma',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: completed ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    daily['title'] ?? 'Görev',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!completed)
                    Text(
                      '+$bonus bonus puan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementGrid(List achievements) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final a = achievements[index];
        final unlocked = a.unlocked;

        return GestureDetector(
          onTap: () => _showAchievementDetail(a),
          child: Card(
            color: unlocked ? Colors.amber.shade50 : Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcon(a.icon),
                    size: 32,
                    color: unlocked
                        ? Color(int.parse(a.color.replaceFirst('#', '0xFF')))
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: unlocked ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (unlocked)
                    const Icon(Icons.check_circle, size: 14, color: Colors.green),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAchievementDetail(dynamic a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIcon(a.icon),
              color: a.unlocked
                  ? Color(int.parse(a.color.replaceFirst('#', '0xFF')))
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(a.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.description),
            const SizedBox(height: 8),
            Text('Ödül: ${a.pointsReward} puan',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (a.unlocked && a.unlockedAt != null)
              Text(
                'Kazanıldı: ${a.unlockedAt!.day}.${a.unlockedAt!.month}.${a.unlockedAt!.year}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'military_tech':
        return Icons.military_tech;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'quiz':
        return Icons.quiz;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'psychology':
        return Icons.psychology;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'whatshot':
        return Icons.whatshot;
      case 'diamond':
        return Icons.diamond;
      case 'today':
        return Icons.today;
      case 'monetization_on':
        return Icons.monetization_on;
      case 'account_balance':
        return Icons.account_balance;
      default:
        return Icons.emoji_events;
    }
  }
}
