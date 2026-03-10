const { Router } = require('express');
const { requireAdmin } = require('../../middleware/auth');
const Quest = require('../../models/Quest');

const router = Router();

// GET /admin/quests
router.get('/', requireAdmin, async (req, res, next) => {
  try {
    const quests = await Quest.findAll();
    res.render('quests/index', { title: 'Görevler', quests });
  } catch (err) {
    next(err);
  }
});

// GET /admin/quests/create
router.get('/create', requireAdmin, (req, res) => {
  res.render('quests/create', { title: 'Yeni Görev', error: null });
});

// POST /admin/quests/create
router.post('/create', requireAdmin, async (req, res, next) => {
  try {
    const { title, description, type, latitude, longitude, radius_meters, points, question, answer, qr_data } = req.body;

    if (!title || !type || !latitude || !longitude) {
      return res.render('quests/create', {
        title: 'Yeni Görev',
        error: 'Başlık, tip ve konum zorunludur',
      });
    }

    await Quest.create({
      title,
      description,
      type,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      radiusMeter: parseInt(radius_meters, 10) || 100,
      points: parseInt(points, 10) || 10,
      question: question || null,
      answer: answer || null,
      qrData: qr_data || null,
      createdBy: req.session.adminUser.id,
    });

    res.redirect('/admin/quests');
  } catch (err) {
    next(err);
  }
});

// GET /admin/quests/:id/edit
router.get('/:id/edit', requireAdmin, async (req, res, next) => {
  try {
    const quest = await Quest.findById(req.params.id);
    if (!quest) return res.redirect('/admin/quests');
    res.render('quests/edit', { title: 'Görev Düzenle', quest, error: null });
  } catch (err) {
    next(err);
  }
});

// POST /admin/quests/:id/edit
router.post('/:id/edit', requireAdmin, async (req, res, next) => {
  try {
    const { title, description, type, latitude, longitude, radius_meters, points, question, answer, qr_data, is_active } = req.body;

    await Quest.update(req.params.id, {
      title,
      description,
      type,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      radiusMeter: parseInt(radius_meters, 10) || 100,
      points: parseInt(points, 10) || 10,
      question: question || null,
      answer: answer || null,
      qrData: qr_data || null,
      isActive: is_active === 'on',
    });

    res.redirect('/admin/quests');
  } catch (err) {
    next(err);
  }
});

// POST /admin/quests/:id/delete
router.post('/:id/delete', requireAdmin, async (req, res, next) => {
  try {
    await Quest.delete(req.params.id);
    res.redirect('/admin/quests');
  } catch (err) {
    next(err);
  }
});

module.exports = router;
