const { Router } = require('express');
const Quest = require('../../models/Quest');
const Submission = require('../../models/Submission');
const User = require('../../models/User');
const { requireAuth } = require('../../middleware/auth');
const upload = require('../../middleware/upload');
const db = require('../../config/db');
const geminiService = require('../../services/gemini');
const Achievement = require('../../models/Achievement');
const DailyChallenge = require('../../models/DailyChallenge');
const Activity = require('../../models/Activity');
const NotificationModel = require('../../models/Notification');

const router = Router();

// GET /api/quests — Aktif görevleri listele (opsiyonel: lat, lng, radius ile yakınlık filtresi)
router.get('/', requireAuth, async (req, res, next) => {
  try {
    const { lat, lng, radius } = req.query;

    let quests;
    if (lat && lng) {
      const r = parseInt(radius, 10) || 5000;
      quests = await Quest.findNearby(parseFloat(lat), parseFloat(lng), r);
    } else {
      quests = await Quest.findActive();
    }

    res.json({ quests });
  } catch (err) {
    next(err);
  }
});

// POST /api/quests/generate — AI ile görev üret
router.post('/generate', requireAuth, async (req, res, next) => {
  try {
    if (!geminiService.isAvailable()) {
      return res.status(503).json({ error: 'AI servisi şu anda kullanılamıyor' });
    }

    const { lat, lng } = req.body;
    if (!lat || !lng) {
      return res.status(400).json({ error: 'Konum bilgisi (lat, lng) gerekli' });
    }

    const userId = req.user.id;

    // Rate limit: 1 dakikada 1 üretim
    const { rows: recentAI } = await db.query(
      `SELECT created_at FROM quests
       WHERE source = 'ai' AND generated_for = $1
       ORDER BY created_at DESC LIMIT 1`,
      [userId]
    );

    if (recentAI.length > 0) {
      const lastGen = new Date(recentAI[0].created_at);
      const oneMinAgo = new Date(Date.now() - 60 * 1000);
      if (lastGen > oneMinAgo) {
        const waitSec = Math.ceil((lastGen.getTime() + 60 * 1000 - Date.now()) / 1000);
        return res.status(429).json({
          error: `Çok sık görev üretimi. ${waitSec} saniye sonra tekrar deneyin.`,
        });
      }
    }

    // Max 50 aktif AI görevi
    const { rows: activeAI } = await db.query(
      `SELECT COUNT(*)::int AS count FROM quests
       WHERE source = 'ai' AND generated_for = $1 AND is_active = true`,
      [userId]
    );

    if (activeAI[0].count >= 50) {
      return res.status(400).json({
        error: 'Maksimum 50 aktif AI görevi olabilir. Mevcut görevleri tamamlayın.',
      });
    }

    // Mevcut başlıkları al
    const existingQuests = await Quest.findActive();
    const existingTitles = existingQuests.map((q) => q.title);

    // Gemini ile üret
    const generated = await geminiService.generateQuests(
      parseFloat(lat),
      parseFloat(lng),
      existingTitles
    );

    // Veritabanına kaydet
    const savedQuests = [];
    for (const q of generated.quests) {
      const quest = await Quest.create({
        title: q.title,
        description: q.description,
        type: q.type === 'question' ? 'question' : 'photo',
        latitude: q.latitude,
        longitude: q.longitude,
        radiusMeter: q.radius_meters || 150,
        points: q.points || 15,
        question: q.question || null,
        answer: q.answer || null,
        qrData: null,
        createdBy: userId,
        source: 'ai',
        generatedFor: userId,
      });
      savedQuests.push(quest);
    }

    res.status(201).json({
      message: `${savedQuests.length} yeni AI görevi oluşturuldu!`,
      quests: savedQuests,
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/quests/recommendations — AI öneriler
router.get('/recommendations', requireAuth, async (req, res, next) => {
  try {
    if (!geminiService.isAvailable()) {
      return res.status(503).json({ error: 'AI servisi şu anda kullanılamıyor' });
    }

    const userId = req.user.id;
    const user = await User.findById(userId);
    const completedQuests = await Submission.findByUser(userId);
    const allQuests = await Quest.findActive();

    // Tamamlananları filtrele
    const completedIds = new Set(completedQuests.map((s) => s.quest_id));
    const availableQuests = allQuests.filter((q) => !completedIds.has(q.id));

    if (availableQuests.length === 0) {
      return res.json({ recommendations: [], message: 'Tüm görevler tamamlandı!' });
    }

    const result = await geminiService.getRecommendations(
      completedQuests,
      availableQuests,
      user.name
    );

    // Görev verileriyle zenginleştir
    const enriched = result.recommendations
      .map((r) => {
        const quest = availableQuests.find((q) => q.id === r.quest_id);
        if (!quest) return null;
        return { ...r, quest };
      })
      .filter(Boolean);

    res.json({ recommendations: enriched });
  } catch (err) {
    next(err);
  }
});

// GET /api/quests/:id — Görev detayı
router.get('/:id', requireAuth, async (req, res, next) => {
  try {
    const quest = await Quest.findById(req.params.id);
    if (!quest) {
      return res.status(404).json({ error: 'Görev bulunamadı' });
    }

    // Cevabı ve QR datasını mobil kullanıcıya gösterme
    const { answer, qr_data, ...safeQuest } = quest;
    res.json({ quest: safeQuest });
  } catch (err) {
    next(err);
  }
});

// GET /api/quests/:id/hint — AI ipucu
router.get('/:id/hint', requireAuth, async (req, res, next) => {
  try {
    if (!geminiService.isAvailable()) {
      return res.status(503).json({ error: 'AI servisi şu anda kullanılamıyor' });
    }

    const quest = await Quest.findById(req.params.id);
    if (!quest) {
      return res.status(404).json({ error: 'Görev bulunamadı' });
    }

    // İpucu maliyeti: 2 puan
    const userId = req.user.id;
    const user = await User.findById(userId);
    if (user.total_points < 2) {
      return res.status(400).json({ error: 'Yeterli puanınız yok (2 puan gerekli)' });
    }

    await User.addPoints(userId, -2);

    const result = await geminiService.generateHint(quest);
    res.json({ hint: result.hint, pointsDeducted: 2 });
  } catch (err) {
    next(err);
  }
});

// POST /api/quests/:id/submit — Görevi tamamla
router.post('/:id/submit', requireAuth, upload.single('photo'), async (req, res, next) => {
  try {
    const questId = parseInt(req.params.id, 10);
    const userId = req.user.id;

    const quest = await Quest.findById(questId);
    if (!quest) {
      return res.status(404).json({ error: 'Görev bulunamadı' });
    }

    if (!quest.is_active) {
      return res.status(400).json({ error: 'Bu görev artık aktif değil' });
    }

    // Daha önce tamamlanmış mı?
    const alreadySubmitted = await Submission.existsForUser(userId, questId);
    if (alreadySubmitted) {
      return res.status(409).json({ error: 'Bu görevi zaten tamamladınız' });
    }

    const photoUrl = req.file ? `/uploads/${req.file.filename}` : null;
    const { answer_text, qr_scanned_data } = req.body;

    // Görev tipine göre validasyon
    let status = 'pending';
    let aiEvaluation = null;
    let aiScore = null;

    if (quest.type === 'photo' && !photoUrl) {
      return res.status(400).json({ error: 'Fotoğraf yüklemeniz gerekiyor' });
    }

    // Fotoğraf görevlerinde AI değerlendirme
    if (quest.type === 'photo' && photoUrl && geminiService.isAvailable()) {
      try {
        const evalResult = await geminiService.evaluatePhoto(
          photoUrl,
          quest.title,
          quest.description
        );
        aiScore = evalResult.score;
        aiEvaluation = evalResult.evaluation;
        if (aiScore >= 70) {
          status = 'approved';
        }
      } catch (evalErr) {
        console.error('AI photo evaluation failed:', evalErr.message);
        // AI başarısız olursa pending olarak bırak
      }
    }

    if (quest.type === 'question') {
      if (!answer_text) {
        return res.status(400).json({ error: 'Cevap gerekli' });
      }
      // Otomatik doğrulama
      if (answer_text.trim().toLowerCase() === quest.answer.trim().toLowerCase()) {
        status = 'approved';
      } else {
        status = 'rejected';
      }
    }

    if (quest.type === 'qr_code') {
      if (!qr_scanned_data) {
        return res.status(400).json({ error: 'QR kod verisi gerekli' });
      }
      // Otomatik doğrulama
      if (qr_scanned_data.trim() === quest.qr_data.trim()) {
        status = 'approved';
      } else {
        status = 'rejected';
      }
    }

    const submission = await Submission.create({
      userId,
      questId,
      photoUrl,
      answerText: answer_text,
      qrScannedData: qr_scanned_data,
      aiEvaluation,
      aiScore,
    });

    // Eğer otomatik onaylandıysa, statusunu güncelle ve puan ver
    let streakInfo = null;
    let newAchievements = [];
    if (status !== 'pending') {
      await Submission.updateStatus(submission.id, status, null);
      if (status === 'approved') {
        // Streak güncelle ve çarpan uygula
        streakInfo = await User.updateStreak(userId);
        const multiplier = streakInfo ? streakInfo.multiplier : 1.0;
        const earnedPoints = Math.round(quest.points * multiplier);
        await User.addPoints(userId, earnedPoints);
        quest._earnedPoints = earnedPoints;

        // Günlük meydan okuma kontrolü
        const daily = await DailyChallenge.getToday(userId);
        if (daily && daily.quest_id === questId && !daily.completed) {
          await DailyChallenge.complete(userId);
          await User.addPoints(userId, daily.bonus_points);
        }

        // Başarım kontrolü
        newAchievements = await Achievement.checkAndUnlock(userId);

        // Aktivite ve bildirim kaydet
        const currentUser = await User.findById(userId);
        await Activity.logQuestCompleted(userId, currentUser.name, quest.title, quest._earnedPoints || quest.points);
        for (const a of newAchievements) {
          await Activity.logAchievementUnlocked(userId, currentUser.name, a.title);
          await NotificationModel.notifyAchievement(userId, a.title);
        }
        if (streakInfo && streakInfo.current_streak >= 3 && [3, 7, 14, 30].includes(streakInfo.current_streak)) {
          await Activity.logStreakMilestone(userId, currentUser.name, streakInfo.current_streak);
        }
      }
      submission.status = status;
    }

    // AI görevi tamamlandıysa arka planda yeni görev üret
    if (quest.source === 'ai' && status === 'approved' && geminiService.isAvailable()) {
      setImmediate(async () => {
        try {
          const activeAI = await db.query(
            `SELECT COUNT(*)::int AS count FROM quests
             WHERE source = 'ai' AND generated_for = $1 AND is_active = true`,
            [userId]
          );
          if (activeAI.rows[0].count < 5) {
            const existingQuests = await Quest.findActive();
            const titles = existingQuests.map((q) => q.title);
            const generated = await geminiService.generateQuests(quest.latitude, quest.longitude, titles);
            for (const q of generated.quests.slice(0, 1)) {
              await Quest.create({
                title: q.title,
                description: q.description,
                type: q.type === 'question' ? 'question' : 'photo',
                latitude: q.latitude,
                longitude: q.longitude,
                radiusMeter: q.radius_meters || 150,
                points: q.points || 15,
                question: q.question || null,
                answer: q.answer || null,
                qrData: null,
                createdBy: userId,
                source: 'ai',
                generatedFor: userId,
              });
            }
            console.log('✓ AI quest regenerated for user', userId);
          }
        } catch (err) {
          console.error('AI regeneration failed:', err.message);
        }
      });
    }

    const earnedPoints = quest._earnedPoints || quest.points;
    const responseData = {
      submission,
      message:
        status === 'approved'
          ? `Tebrikler! ${earnedPoints} puan kazandınız!`
          : status === 'rejected'
          ? 'Yanlış cevap. Tekrar deneyin!'
          : 'Gönderiminiz incelemeye alındı.',
    };

    // Streak bilgisi
    if (streakInfo) {
      responseData.streak = streakInfo;
    }

    // Yeni açılan başarımlar
    if (newAchievements.length > 0) {
      responseData.new_achievements = newAchievements;
    }

    // AI değerlendirme varsa ekle
    if (aiEvaluation) {
      responseData.ai_evaluation = aiEvaluation;
      responseData.ai_score = aiScore;
    }

    res.status(201).json(responseData);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
