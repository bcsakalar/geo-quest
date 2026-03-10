const { Router } = require('express');
const User = require('../../models/User');
const { comparePassword } = require('../../utils/helpers');

const router = Router();

// GET /admin/login
router.get('/login', (req, res) => {
  if (req.session.adminUser) return res.redirect('/admin/dashboard');
  res.render('auth/login', { title: 'Admin Giriş', layout: false, error: null });
});

// POST /admin/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findByEmail(email);

    if (!user || user.role !== 'admin') {
      return res.render('auth/login', { title: 'Admin Giriş', layout: false, error: 'Geçersiz email veya şifre' });
    }

    const valid = await comparePassword(password, user.password_hash);
    if (!valid) {
      return res.render('auth/login', { title: 'Admin Giriş', layout: false, error: 'Geçersiz email veya şifre' });
    }

    req.session.adminUser = { id: user.id, email: user.email, name: user.name, role: user.role };
    res.redirect('/admin/dashboard');
  } catch (err) {
    res.render('auth/login', { title: 'Admin Giriş', layout: false, error: 'Bir hata oluştu' });
  }
});

// GET /admin/logout
router.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/admin/login');
});

module.exports = router;
