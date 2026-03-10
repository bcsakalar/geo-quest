const { Router } = require('express');
const Friendship = require('../../models/Friendship');
const Notification = require('../../models/Notification');
const Activity = require('../../models/Activity');
const User = require('../../models/User');
const { requireAuth } = require('../../middleware/auth');

const router = Router();

// GET /api/friends — Arkadaş listesi
router.get('/', requireAuth, async (req, res, next) => {
  try {
    const friends = await Friendship.getFriends(req.user.id);
    res.json({ friends });
  } catch (err) {
    next(err);
  }
});

// GET /api/friends/requests — Gelen bekleyen istekler
router.get('/requests', requireAuth, async (req, res, next) => {
  try {
    const requests = await Friendship.getPendingRequests(req.user.id);
    res.json({ requests });
  } catch (err) {
    next(err);
  }
});

// GET /api/friends/sent — Gönderilen istekler
router.get('/sent', requireAuth, async (req, res, next) => {
  try {
    const requests = await Friendship.getSentRequests(req.user.id);
    res.json({ requests });
  } catch (err) {
    next(err);
  }
});

// GET /api/friends/search?q=isim — Kullanıcı ara
router.get('/search', requireAuth, async (req, res, next) => {
  try {
    const q = (req.query.q || '').trim();
    if (q.length < 2) {
      return res.json({ users: [] });
    }
    const users = await Friendship.searchUsers(q, req.user.id);
    res.json({ users });
  } catch (err) {
    next(err);
  }
});

// POST /api/friends/request — Arkadaşlık isteği gönder
router.post('/request', requireAuth, async (req, res, next) => {
  try {
    const { user_id } = req.body;
    if (!user_id || user_id === req.user.id) {
      return res.status(400).json({ error: 'Geçersiz kullanıcı' });
    }

    const target = await User.findById(user_id);
    if (!target) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }

    const result = await Friendship.sendRequest(req.user.id, user_id);
    if (result.error) {
      return res.status(400).json({ error: result.error });
    }

    // Bildirim gönder
    const sender = await User.findById(req.user.id);
    await Notification.notifyFriendRequest(user_id, sender.name);

    res.json({ message: 'Arkadaşlık isteği gönderildi', ...result });
  } catch (err) {
    next(err);
  }
});

// POST /api/friends/:id/accept — İsteği kabul et
router.post('/:id/accept', requireAuth, async (req, res, next) => {
  try {
    const friendship = await Friendship.acceptRequest(parseInt(req.params.id), req.user.id);
    if (!friendship) {
      return res.status(404).json({ error: 'İstek bulunamadı' });
    }

    // Bildirim ve aktivite
    const me = await User.findById(req.user.id);
    const friend = await User.findById(friendship.requester_id);
    await Notification.notifyFriendAccepted(friendship.requester_id, me.name);
    await Activity.logNewFriendship(req.user.id, me.name, friend.name);
    await Activity.logNewFriendship(friendship.requester_id, friend.name, me.name);

    res.json({ message: 'Arkadaşlık kabul edildi', friendship });
  } catch (err) {
    next(err);
  }
});

// POST /api/friends/:id/reject — İsteği reddet
router.post('/:id/reject', requireAuth, async (req, res, next) => {
  try {
    const friendship = await Friendship.rejectRequest(parseInt(req.params.id), req.user.id);
    if (!friendship) {
      return res.status(404).json({ error: 'İstek bulunamadı' });
    }
    res.json({ message: 'İstek reddedildi' });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/friends/:id — Arkadaşlığı kaldır
router.delete('/:id', requireAuth, async (req, res, next) => {
  try {
    const result = await Friendship.removeFriend(parseInt(req.params.id), req.user.id);
    if (!result) {
      return res.status(404).json({ error: 'Arkadaşlık bulunamadı' });
    }
    res.json({ message: 'Arkadaşlık kaldırıldı' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
