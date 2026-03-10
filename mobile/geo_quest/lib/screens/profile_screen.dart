import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/quest_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().loadProfile();
    context.read<QuestProvider>().loadSubmissions();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final questProvider = context.watch<QuestProvider>();
    final user = auth.user;
    final submissions = questProvider.submissions;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final approved = submissions.where((s) => s.status == 'approved').length;
    final pending = submissions.where((s) => s.status == 'pending').length;
    final rejected = submissions.where((s) => s.status == 'rejected').length;

    return RefreshIndicator(
      onRefresh: () async {
        await auth.loadProfile();
        await questProvider.loadSubmissions();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 32, color: Colors.green.shade700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(user.email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          '${user.totalPoints} Puan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user.currentStreak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${user.currentStreak} gün streak',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _statCard('Onaylanan', approved, Colors.green),
              const SizedBox(width: 8),
              _statCard('Bekleyen', pending, Colors.orange),
              const SizedBox(width: 8),
              _statCard('Reddedilen', rejected, Colors.red),
            ],
          ),
          const SizedBox(height: 16),

          // Submissions list
          const Text('Gönderimlerim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (submissions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Henüz gönderiminiz yok', style: TextStyle(color: Colors.grey))),
              ),
            ),

          ...submissions.map((s) => Card(
            child: ListTile(
              leading: _statusIcon(s.status),
              title: Text(s.questTitle),
              subtitle: Text('${s.questPoints} puan • ${s.statusLabel}'),
              trailing: Text(
                '${s.submittedAt.day}.${s.submittedAt.month}.${s.submittedAt.year}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('$count',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return const CircleAvatar(
            backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.check, color: Colors.green));
      case 'pending':
        return const CircleAvatar(
            backgroundColor: Color(0xFFFFF3E0), child: Icon(Icons.hourglass_bottom, color: Colors.orange));
      case 'rejected':
        return const CircleAvatar(
            backgroundColor: Color(0xFFFFEBEE), child: Icon(Icons.close, color: Colors.red));
      default:
        return const CircleAvatar(child: Icon(Icons.help));
    }
  }
}
