const { Router } = require('express');
const { requireAdmin } = require('../../middleware/auth');
const Submission = require('../../models/Submission');
const User = require('../../models/User');
const Quest = require('../../models/Quest');

const router = Router();

// GET /admin/submissions
router.get('/', requireAdmin, async (req, res, next) => {
  try {
    const { status } = req.query;
    let submissions = await Submission.findAll();
    if (status) {
      submissions = submissions.filter(s => s.status === status);
    }
    res.render('submissions/index', { title: 'Gönderimler', submissions, filterStatus: status || 'all' });
  } catch (err) {
    next(err);
  }
});

// POST /admin/submissions/:id/approve
router.post('/:id/approve', requireAdmin, async (req, res, next) => {
  try {
    const submission = await Submission.findById(req.params.id);
    if (!submission) return res.redirect('/admin/submissions');

    await Submission.updateStatus(submission.id, 'approved', req.session.adminUser.id);
    await User.addPoints(submission.user_id, submission.quest_points);

    res.redirect('/admin/submissions');
  } catch (err) {
    next(err);
  }
});

// POST /admin/submissions/:id/reject
router.post('/:id/reject', requireAdmin, async (req, res, next) => {
  try {
    const submission = await Submission.findById(req.params.id);
    if (!submission) return res.redirect('/admin/submissions');

    await Submission.updateStatus(submission.id, 'rejected', req.session.adminUser.id);
    res.redirect('/admin/submissions');
  } catch (err) {
    next(err);
  }
});

module.exports = router;
