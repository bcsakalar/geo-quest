const db = require('../config/db');

const Achievement = {
  async findAll() {
    const { rows } = await db.query('SELECT * FROM achievements ORDER BY required_count ASC');
    return rows;
  },

  async findByKey(key) {
    const { rows } = await db.query('SELECT * FROM achievements WHERE key = $1', [key]);
    return rows[0] || null;
  },

  async getUserAchievements(userId) {
    const { rows } = await db.query(
      `SELECT a.*, ua.unlocked_at
       FROM user_achievements ua
       JOIN achievements a ON ua.achievement_id = a.id
       WHERE ua.user_id = $1
       ORDER BY ua.unlocked_at DESC`,
      [userId]
    );
    return rows;
  },

  async unlock(userId, achievementId) {
    const { rows } = await db.query(
      `INSERT INTO user_achievements (user_id, achievement_id)
       VALUES ($1, $2) ON CONFLICT DO NOTHING
       RETURNING *`,
      [userId, achievementId]
    );
    return rows[0] || null;
  },

  async hasAchievement(userId, achievementKey) {
    const { rows } = await db.query(
      `SELECT 1 FROM user_achievements ua
       JOIN achievements a ON ua.achievement_id = a.id
       WHERE ua.user_id = $1 AND a.key = $2`,
      [userId, achievementKey]
    );
    return rows.length > 0;
  },

  /**
   * Görev tamamlama sonrası başarım kontrolü
   * Yeni açılan başarımları döndürür
   */
  async checkAndUnlock(userId) {
    const newlyUnlocked = [];

    // İstatistikleri topla
    const stats = await this._getUserStats(userId);
    const allAchievements = await this.findAll();

    for (const achievement of allAchievements) {
      const alreadyHas = await this.hasAchievement(userId, achievement.key);
      if (alreadyHas) continue;

      let earned = false;

      switch (achievement.key) {
        case 'first_quest':
          earned = stats.totalApproved >= 1;
          break;
        case 'quest_5':
          earned = stats.totalApproved >= 5;
          break;
        case 'quest_10':
          earned = stats.totalApproved >= 10;
          break;
        case 'quest_25':
          earned = stats.totalApproved >= 25;
          break;
        case 'photo_5':
          earned = stats.photoApproved >= 5;
          break;
        case 'question_5':
          earned = stats.questionApproved >= 5;
          break;
        case 'ai_explorer':
          earned = stats.aiApproved >= 1;
          break;
        case 'ai_master':
          earned = stats.aiApproved >= 10;
          break;
        case 'streak_3':
          earned = stats.currentStreak >= 3;
          break;
        case 'streak_7':
          earned = stats.currentStreak >= 7;
          break;
        case 'streak_30':
          earned = stats.currentStreak >= 30;
          break;
        case 'daily_5':
          earned = stats.dailyCompleted >= 5;
          break;
        case 'points_100':
          earned = stats.totalPoints >= 100;
          break;
        case 'points_500':
          earned = stats.totalPoints >= 500;
          break;
      }

      if (earned) {
        const result = await this.unlock(userId, achievement.id);
        if (result) {
          // Başarım ödül puanı ver
          await db.query(
            'UPDATE users SET total_points = total_points + $1 WHERE id = $2',
            [achievement.points_reward, userId]
          );
          newlyUnlocked.push(achievement);
        }
      }
    }

    return newlyUnlocked;
  },

  async _getUserStats(userId) {
    const [approvedRes, photoRes, questionRes, aiRes, userRes, dailyRes] = await Promise.all([
      db.query(
        `SELECT COUNT(*)::int AS count FROM submissions WHERE user_id = $1 AND status = 'approved'`,
        [userId]
      ),
      db.query(
        `SELECT COUNT(*)::int AS count FROM submissions s
         JOIN quests q ON s.quest_id = q.id
         WHERE s.user_id = $1 AND s.status = 'approved' AND q.type = 'photo'`,
        [userId]
      ),
      db.query(
        `SELECT COUNT(*)::int AS count FROM submissions s
         JOIN quests q ON s.quest_id = q.id
         WHERE s.user_id = $1 AND s.status = 'approved' AND q.type = 'question'`,
        [userId]
      ),
      db.query(
        `SELECT COUNT(*)::int AS count FROM submissions s
         JOIN quests q ON s.quest_id = q.id
         WHERE s.user_id = $1 AND s.status = 'approved' AND q.source = 'ai'`,
        [userId]
      ),
      db.query(
        'SELECT total_points, current_streak, max_streak FROM users WHERE id = $1',
        [userId]
      ),
      db.query(
        `SELECT COUNT(*)::int AS count FROM daily_challenges
         WHERE user_id = $1 AND completed = true`,
        [userId]
      ),
    ]);

    return {
      totalApproved: approvedRes.rows[0].count,
      photoApproved: photoRes.rows[0].count,
      questionApproved: questionRes.rows[0].count,
      aiApproved: aiRes.rows[0].count,
      totalPoints: userRes.rows[0]?.total_points || 0,
      currentStreak: userRes.rows[0]?.current_streak || 0,
      maxStreak: userRes.rows[0]?.max_streak || 0,
      dailyCompleted: dailyRes.rows[0].count,
    };
  },
};

module.exports = Achievement;
