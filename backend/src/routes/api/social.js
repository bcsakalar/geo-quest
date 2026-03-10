const { Router } = require('express');
const Notification = require('../../models/Notification');
const Activity = require('../../models/Activity');
const { requireAuth } = require('../../middleware/auth');
const db = require('../../config/db');

const router = Router();

// GET /api/social/notifications — Bildirimler
router.get('/notifications', requireAuth, async (req, res, next) => {
  try {
    const notifications = await Notification.getByUser(req.user.id);
    const unread = await Notification.getUnreadCount(req.user.id);
    res.json({ notifications, unread_count: unread });
  } catch (err) {
    next(err);
  }
});

// POST /api/social/notifications/read — Hepsini okundu yap
router.post('/notifications/read', requireAuth, async (req, res, next) => {
  try {
    await Notification.markAllRead(req.user.id);
    res.json({ message: 'Tüm bildirimler okundu' });
  } catch (err) {
    next(err);
  }
});

// POST /api/social/notifications/:id/read — Tekini okundu yap
router.post('/notifications/:id/read', requireAuth, async (req, res, next) => {
  try {
    await Notification.markRead(parseInt(req.params.id), req.user.id);
    res.json({ message: 'Bildirim okundu' });
  } catch (err) {
    next(err);
  }
});

// GET /api/social/feed — Arkadaş aktivite feed'i
router.get('/feed', requireAuth, async (req, res, next) => {
  try {
    const { offset = 0, limit = 30 } = req.query;
    const feed = await Activity.getFriendFeed(req.user.id, parseInt(limit), parseInt(offset));
    res.json({ feed });
  } catch (err) {
    next(err);
  }
});

// GET /api/social/unread — Okunmamış sayıları (bildirim + mesaj)
router.get('/unread', requireAuth, async (req, res, next) => {
  try {
    const [notifResult, msgResult] = await Promise.all([
      Notification.getUnreadCount(req.user.id),
      db.query(`SELECT COUNT(*)::int AS count FROM messages WHERE receiver_id = $1 AND is_read = false`, [req.user.id]),
    ]);
    res.json({
      notifications: notifResult,
      messages: msgResult.rows[0].count,
      total: notifResult + msgResult.rows[0].count,
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/social/push-token — Push token kaydet
router.post('/push-token', requireAuth, async (req, res, next) => {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ error: 'Token gerekli' });
    }
    await db.query(
      `UPDATE users SET push_token = $1, last_active_at = NOW() WHERE id = $2`,
      [token, req.user.id]
    );
    res.json({ message: 'Push token kaydedildi' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
