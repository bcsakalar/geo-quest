const { Router } = require('express');
const Submission = require('../../models/Submission');
const { requireAuth } = require('../../middleware/auth');

const router = Router();

// GET /api/submissions/mine — Kendi gönderimlerim
router.get('/mine', requireAuth, async (req, res, next) => {
  try {
    const submissions = await Submission.findByUser(req.user.id);
    res.json({ submissions });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
