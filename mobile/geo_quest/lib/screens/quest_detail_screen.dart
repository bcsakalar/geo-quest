import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/quest.dart';
import '../providers/quest_provider.dart';
import '../services/location_service.dart';
import 'qr_scanner_screen.dart';

class QuestDetailScreen extends StatefulWidget {
  final Quest quest;
  const QuestDetailScreen({super.key, required this.quest});

  @override
  State<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends State<QuestDetailScreen> {
  final LocationService _locationService = LocationService();
  final _answerController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingHint = false;
  File? _photo;
  String? _qrResult;
  double? _distanceToQuest;
  bool _isNearby = false;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _checkProximity();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _checkProximity() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      final distance = _locationService.distanceBetween(
        pos.latitude, pos.longitude,
        widget.quest.latitude, widget.quest.longitude,
      );
      setState(() {
        _distanceToQuest = distance;
        _isNearby = distance <= widget.quest.radiusMeters;
      });
    } catch (e) {
      // Can't determine distance, allow anyway for testing
      setState(() => _isNearby = true);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200);
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null) {
      setState(() => _qrResult = result);
    }
  }

  Future<void> _getHint() async {
    setState(() => _isLoadingHint = true);

    final provider = context.read<QuestProvider>();
    final result = await provider.getHint(widget.quest.id);

    if (!mounted) return;

    setState(() => _isLoadingHint = false);

    final error = result['error'];
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.red,
      ));
    } else {
      setState(() => _hint = result['hint']?.toString());
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final provider = context.read<QuestProvider>();
    final result = await provider.submitQuest(
      questId: widget.quest.id,
      photo: _photo,
      answerText: _answerController.text.isNotEmpty ? _answerController.text.trim() : null,
      qrScannedData: _qrResult,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    final error = result['error'];
    final message = result['message'] ?? (error != null ? null : 'Gönderildi!');
    final aiEvaluation = result['ai_evaluation'];
    final aiScore = result['ai_score'];
    final newAchievements = result['new_achievements'] as List?;
    final streak = result['streak'] as Map<String, dynamic>?;

    // Show AI evaluation dialog if available
    if (aiEvaluation != null && error == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text('AI Değerlendirme: $aiScore/100'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(aiEvaluation.toString()),
              if (streak != null && (streak['multiplier'] ?? 1.0) > 1.0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${streak['multiplier']}x streak çarpanı uygulandı!',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                _showNewAchievements(newAchievements);
                if (message != null && message.contains('Tebrikler')) {
                  Navigator.pop(context); // go back if approved
                }
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } else {
      // Show streak info in snackbar message
      String snackMessage = error ?? message ?? 'İşlem tamamlandı';
      if (streak != null && (streak['multiplier'] ?? 1.0) > 1.0 && error == null) {
        snackMessage += ' (${streak['multiplier']}x streak!)';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(snackMessage),
        backgroundColor: error != null ? Colors.red : Colors.green,
      ));

      if (error == null) {
        _showNewAchievements(newAchievements);
        Navigator.pop(context);
      }
    }
  }

  void _showNewAchievements(List? achievements) {
    if (achievements == null || achievements.isEmpty || !mounted) return;
    for (final a in achievements) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Başarım Açıldı: ${a['title']}! (+${a['points_reward']} puan)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final completed = context.read<QuestProvider>().isQuestCompleted(quest.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(quest.title),
        actions: [
          if (quest.isAI)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('AI', style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quest info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _typeBadge(quest.type),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${quest.points} puan',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(quest.description, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    if (_distanceToQuest != null) ...[
                      Row(
                        children: [
                          Icon(_isNearby ? Icons.check_circle : Icons.warning,
                              color: _isNearby ? Colors.green : Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isNearby
                                ? 'Görev alanındasınız! (${_distanceToQuest!.toInt()}m)'
                                : '${_distanceToQuest!.toInt()}m uzaklıkta (${quest.radiusMeters}m yakınına gelin)',
                            style: TextStyle(color: _isNearby ? Colors.green : Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Hint section
            if (!completed) ...[
              Card(
                color: Colors.deepPurple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_hint != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            const Text('İpucu',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_hint!, style: const TextStyle(fontSize: 14)),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: _isLoadingHint
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : TextButton.icon(
                                  onPressed: _getHint,
                                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                                  label: const Text('AI İpucu Al (2 puan)'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.deepPurple,
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            if (completed) ...[
              const Card(
                color: Color(0xFFE8F5E9),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Bu görevi zaten tamamladınız!',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Quest action area
              _buildActionArea(quest),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(Quest quest) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Görevi Tamamla',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Photo quest
            if (quest.type == 'photo') ...[
              if (_photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_photo!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_photo == null ? 'Fotoğraf Çek' : 'Tekrar Çek'),
                ),
              ),
            ],

            // Question quest
            if (quest.type == 'question') ...[
              Text(quest.question ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              TextField(
                controller: _answerController,
                decoration: InputDecoration(
                  hintText: 'Cevabınızı yazın...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],

            // QR quest
            if (quest.type == 'qr_code') ...[
              if (_qrResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text('QR Okundu: $_qrResult')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _scanQR,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(_qrResult == null ? 'QR Kod Tara' : 'Tekrar Tara'),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canSubmit() && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Gönder', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    switch (widget.quest.type) {
      case 'photo':
        return _photo != null;
      case 'question':
        return _answerController.text.trim().isNotEmpty;
      case 'qr_code':
        return _qrResult != null;
      default:
        return false;
    }
  }

  Widget _typeBadge(String type) {
    IconData icon;
    Color color;
    String label;
    switch (type) {
      case 'photo':
        icon = Icons.camera_alt;
        color = Colors.orange;
        label = 'Fotoğraf';
        break;
      case 'question':
        icon = Icons.quiz;
        color = Colors.blue;
        label = 'Soru';
        break;
      case 'qr_code':
        icon = Icons.qr_code;
        color = Colors.purple;
        label = 'QR Kod';
        break;
      default:
        icon = Icons.flag;
        color = Colors.green;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
