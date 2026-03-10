const { Router } = require('express');
const Message = require('../../models/Message');
const Friendship = require('../../models/Friendship');
const Notification = require('../../models/Notification');
const User = require('../../models/User');
const Quest = require('../../models/Quest');
const { requireAuth } = require('../../middleware/auth');

const router = Router();

// GET /api/messages — Konuşma listesi
router.get('/', requireAuth, async (req, res, next) => {
  try {
    const conversations = await Message.getConversations(req.user.id);
    const unreadTotal = await Message.getUnreadCount(req.user.id);
    res.json({ conversations, unread_total: unreadTotal });
  } catch (err) {
    next(err);
  }
});

// GET /api/messages/:userId — Belirli kullanıcıyla mesajlar
router.get('/:userId', requireAuth, async (req, res, next) => {
  try {
    const partnerId = parseInt(req.params.userId);
    const { before, limit } = req.query;

    // Arkadaş mı kontrol et
    const friends = await Friendship.areFriends(req.user.id, partnerId);
    if (!friends) {
      return res.status(403).json({ error: 'Sadece arkadaşlarınıza mesaj gönderebilirsiniz' });
    }

    const messages = await Message.getConversation(req.user.id, partnerId, parseInt(limit) || 50, before || null);

    // Mesajları okundu olarak işaretle
    await Message.markAsRead(req.user.id, partnerId);

    res.json({ messages });
  } catch (err) {
    next(err);
  }
});

// POST /api/messages/:userId — Mesaj gönder
router.post('/:userId', requireAuth, async (req, res, next) => {
  try {
    const partnerId = parseInt(req.params.userId);
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ error: 'Mesaj boş olamaz' });
    }

    if (content.length > 1000) {
      return res.status(400).json({ error: 'Mesaj çok uzun (max 1000 karakter)' });
    }

    // Arkadaş mı kontrol et
    const friends = await Friendship.areFriends(req.user.id, partnerId);
    if (!friends) {
      return res.status(403).json({ error: 'Sadece arkadaşlarınıza mesaj gönderebilirsiniz' });
    }

    const message = await Message.send(req.user.id, partnerId, content.trim());

    // Bildirim gönder
    const sender = await User.findById(req.user.id);
    await Notification.notifyNewMessage(partnerId, sender.name);

    res.status(201).json({ message });
  } catch (err) {
    next(err);
  }
});

// POST /api/messages/:userId/challenge — Meydan okuma gönder
router.post('/:userId/challenge', requireAuth, async (req, res, next) => {
  try {
    const partnerId = parseInt(req.params.userId);
    const { quest_id } = req.body;

    if (!quest_id) {
      return res.status(400).json({ error: 'Görev ID gerekli' });
    }

    // Arkadaş mı kontrol et
    const friends = await Friendship.areFriends(req.user.id, partnerId);
    if (!friends) {
      return res.status(403).json({ error: 'Sadece arkadaşlarınıza meydan okuyabilirsiniz' });
    }

    const quest = await Quest.findById(quest_id);
    if (!quest) {
      return res.status(404).json({ error: 'Görev bulunamadı' });
    }

    const sender = await User.findById(req.user.id);
    const challengeMsg = `🎯 Meydan okuma: "${quest.title}" — Hadi sen de bu görevi tamamla!`;
    const message = await Message.send(req.user.id, partnerId, challengeMsg, 'challenge', quest_id);

    // Bildirim
    await Notification.notifyChallenge(partnerId, sender.name, quest.title, quest_id);

    res.status(201).json({ message, quest_title: quest.title });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
