const { Router } = require('express');
const User = require('../../models/User');
const { requireAuth } = require('../../middleware/auth');

const router = Router();

// GET /api/users/me — Profilim
router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }
    res.json({ user });
  } catch (err) {
    next(err);
  }
});

// GET /api/leaderboard — Sıralama listesi
router.get('/leaderboard', requireAuth, async (req, res, next) => {
  try {
    const leaderboard = await User.getLeaderboard(50);
    res.json({ leaderboard });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
