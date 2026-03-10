const { Router } = require('express');
const Achievement = require('../../models/Achievement');
const DailyChallenge = require('../../models/DailyChallenge');
const User = require('../../models/User');
const { requireAuth } = require('../../middleware/auth');

const router = Router();

// ──── Başarımlar ────

// GET /api/achievements — Tüm başarımlar + kullanıcının kazandıkları
router.get('/', requireAuth, async (req, res, next) => {
  try {
    const [all, mine] = await Promise.all([
      Achievement.findAll(),
      Achievement.getUserAchievements(req.user.id),
    ]);
    const unlockedIds = new Set(mine.map((a) => a.achievement_id));
    const achievements = all.map((a) => ({
      ...a,
      unlocked: unlockedIds.has(a.id),
      unlocked_at: mine.find((m) => m.achievement_id === a.id)?.unlocked_at || null,
    }));
    res.json({ achievements });
  } catch (err) {
    next(err);
  }
});

// GET /api/achievements/check — Başarımları kontrol et ve yenilerini aç
router.get('/check', requireAuth, async (req, res, next) => {
  try {
    const newlyUnlocked = await Achievement.checkAndUnlock(req.user.id);
    res.json({ newly_unlocked: newlyUnlocked });
  } catch (err) {
    next(err);
  }
});

// ──── Günlük Meydan Okuma ────

// GET /api/achievements/daily — Bugünkü günlük görev
router.get('/daily', requireAuth, async (req, res, next) => {
  try {
    let daily = await DailyChallenge.getToday(req.user.id);
    if (!daily) {
      // Henüz atanmamış, otomatik ata
      await DailyChallenge.assignRandomDaily(req.user.id);
      daily = await DailyChallenge.getToday(req.user.id);
    }
    res.json({ daily_challenge: daily || null });
  } catch (err) {
    next(err);
  }
});

// ──── Streak Bilgisi ────

// GET /api/achievements/streak — Kullanıcının streak bilgisi
router.get('/streak', requireAuth, async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    res.json({
      current_streak: user.current_streak || 0,
      max_streak: user.max_streak || 0,
      multiplier: User.getStreakMultiplier(user.current_streak || 0),
      last_quest_date: user.last_quest_date,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
