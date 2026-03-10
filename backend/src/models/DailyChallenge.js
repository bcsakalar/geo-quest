const db = require('../config/db');

const DailyChallenge = {
  async getToday(userId) {
    const { rows } = await db.query(
      `SELECT dc.*, q.title, q.description, q.type, q.points, q.latitude, q.longitude
       FROM daily_challenges dc
       JOIN quests q ON q.id = dc.quest_id
       WHERE dc.user_id = $1 AND dc.challenge_date = CURRENT_DATE`,
      [userId]
    );
    return rows[0] || null;
  },

  async assign(userId, questId, bonusPoints = 25) {
    const { rows } = await db.query(
      `INSERT INTO daily_challenges (user_id, quest_id, challenge_date, bonus_points)
       VALUES ($1, $2, CURRENT_DATE, $3)
       ON CONFLICT (user_id, challenge_date) DO NOTHING
       RETURNING *`,
      [userId, questId, bonusPoints]
    );
    return rows[0] || null;
  },

  async complete(userId) {
    const { rows } = await db.query(
      `UPDATE daily_challenges SET completed = true
       WHERE user_id = $1 AND challenge_date = CURRENT_DATE AND completed = false
       RETURNING *`,
      [userId]
    );
    return rows[0] || null;
  },

  async assignRandomDaily(userId) {
    // Kullanıcının henüz tamamlamadığı görevlerden rastgele birini seç
    const { rows } = await db.query(
      `SELECT q.id FROM quests q
       WHERE q.is_active = true
       AND q.id NOT IN (
         SELECT s.quest_id FROM submissions s WHERE s.user_id = $1 AND s.status = 'approved'
       )
       ORDER BY RANDOM() LIMIT 1`,
      [userId]
    );
    if (rows.length === 0) return null;
    return this.assign(userId, rows[0].id, 25);
  },
};

module.exports = DailyChallenge;
