const { Router } = require('express');
const { requireAdmin } = require('../../middleware/auth');
const Quest = require('../../models/Quest');
const User = require('../../models/User');
const Submission = require('../../models/Submission');

const router = Router();

// GET /admin/dashboard
router.get('/dashboard', requireAdmin, async (req, res, next) => {
  try {
    const [totalQuests, activeQuests, totalUsers, totalSubmissions, pendingSubmissions] = await Promise.all([
      Quest.count(),
      Quest.countActive(),
      User.count(),
      Submission.count(),
      Submission.countByStatus('pending'),
    ]);

    const recentSubmissions = await Submission.findAll();

    res.render('dashboard', {
      title: 'Dashboard',
      stats: { totalQuests, activeQuests, totalUsers, totalSubmissions, pendingSubmissions },
      recentSubmissions: recentSubmissions.slice(0, 10),
    });
  } catch (err) {
    next(err);
  }
});

// Redirect /admin → /admin/dashboard
router.get('/', requireAdmin, (req, res) => {
  res.redirect('/admin/dashboard');
});

module.exports = router;
