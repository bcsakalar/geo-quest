import 'package:flutter/material.dart';
import '../models/quest.dart';

class QuestCard extends StatelessWidget {
  final Quest quest;
  final bool completed;
  final VoidCallback onTap;

  const QuestCard({
    super.key,
    required this.quest,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: completed ? Colors.grey.shade200 : _typeColor(quest.type).withValues(alpha: 0.15),
          child: Icon(
            _typeIcon(quest.type),
            color: completed ? Colors.grey : _typeColor(quest.type),
          ),
        ),
        title: Text(
          quest.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${quest.typeLabel} • ${quest.points} puan'
          '${quest.distanceMeters != null ? ' • ${quest.distanceMeters!.toInt()}m' : ''}',
        ),
        trailing: completed
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.chevron_right),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'photo':
        return Icons.camera_alt;
      case 'question':
        return Icons.quiz;
      case 'qr_code':
        return Icons.qr_code;
      default:
        return Icons.flag;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'photo':
        return Colors.orange;
      case 'question':
        return Colors.blue;
      case 'qr_code':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }
}
