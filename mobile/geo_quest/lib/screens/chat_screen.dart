import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/social_provider.dart';
import '../providers/quest_provider.dart';

class ChatScreen extends StatefulWidget {
  final int partnerId;
  final String partnerName;
  final String partnerColor;

  const ChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerColor,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Her 5 saniyede mesajları yenile (polling)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final sp = context.read<SocialProvider>();
    final messages = await sp.loadMessages(widget.partnerId);
    if (mounted) {
      final wasAtBottom = _scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 60;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      if (wasAtBottom || _isLoading) {
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final sp = context.read<SocialProvider>();
    await sp.sendMessage(widget.partnerId, text);
    await _loadMessages();
    _scrollToBottom();
  }

  Future<void> _sendChallenge() async {
    final qp = context.read<QuestProvider>();
    if (qp.quests.isEmpty) await qp.loadQuests();

    if (!mounted) return;
    final quests = qp.quests;
    if (quests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gönderilebilecek görev yok')),
      );
      return;
    }

    final quest = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Meydan Okuma Gönder'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: quests.length,
            itemBuilder: (_, i) {
              final q = quests[i];
              return ListTile(
                title: Text(q.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${q.points} puan • ${q.type}'),
                trailing: const Icon(Icons.sports_martial_arts, color: Colors.orange),
                onTap: () => Navigator.pop(ctx, q),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
        ],
      ),
    );

    if (quest != null && mounted) {
      final sp = context.read<SocialProvider>();
      final result = await sp.sendChallenge(widget.partnerId, quest.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] ?? 'Meydan okuma gönderildi!'),
          backgroundColor: result['error'] != null ? Colors.red : Colors.green,
        ));
      }
      await _loadMessages();
      _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final partnerColor = _parseColor(widget.partnerColor);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: partnerColor.withAlpha(50),
              child: Text(
                widget.partnerName[0].toUpperCase(),
                style: TextStyle(color: partnerColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.partnerName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_martial_arts, color: Colors.orange),
            tooltip: 'Meydan Oku',
            onPressed: _sendChallenge,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Henüz mesaj yok.\nBir mesaj gönder!',
                            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender_id'] != widget.partnerId;
                          final isChallenge = msg['message_type'] == 'challenge';

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isChallenge
                                    ? Colors.orange.shade50
                                    : isMe
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                                border: isChallenge ? Border.all(color: Colors.orange, width: 1) : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isChallenge)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.sports_martial_arts, size: 14, color: Colors.orange.shade700),
                                          const SizedBox(width: 4),
                                          Text('Meydan Okuma', style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  Text(msg['content'] ?? '', style: const TextStyle(fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime(msg['created_at']),
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Mesaj gönderme alanı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, -1))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLength: 1000,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}.${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
