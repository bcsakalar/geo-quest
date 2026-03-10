const { Router } = require('express');
const { requireAdmin } = require('../../middleware/auth');
const User = require('../../models/User');

const router = Router();

// GET /admin/users — app.js'de /admin/users olarak mount edilecek
router.get('/', requireAdmin, async (req, res, next) => {
  try {
    const users = await User.findAll();
    res.render('users/index', { title: 'Kullanıcılar', users });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
