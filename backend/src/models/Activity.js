const db = require('../config/db');

const Activity = {
  async log(userId, type, description, data = {}) {
    const { rows } = await db.query(
      `INSERT INTO activities (user_id, type, description, data)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [userId, type, description, JSON.stringify(data)]
    );
    return rows[0];
  },

  // Arkadaş feed'i — arkadaşların aktivitelerini getir
  async getFriendFeed(userId, limit = 30, offset = 0) {
    const { rows } = await db.query(
      `SELECT a.*, u.name AS user_name, u.avatar_color
       FROM activities a
       JOIN users u ON u.id = a.user_id
       WHERE a.user_id IN (
         SELECT CASE WHEN f.requester_id = $1 THEN f.addressee_id ELSE f.requester_id END
         FROM friendships f
         WHERE (f.requester_id = $1 OR f.addressee_id = $1) AND f.status = 'accepted'
       )
       OR a.user_id = $1
       ORDER BY a.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );
    return rows;
  },

  // ──── Aktivite kayıt yardımcıları ────

  async logQuestCompleted(userId, userName, questTitle, points) {
    return this.log(userId, 'quest_completed',
      `${userName} "${questTitle}" görevini tamamladı! (+${points} puan)`,
      { quest_title: questTitle, points });
  },

  async logAchievementUnlocked(userId, userName, achievementTitle) {
    return this.log(userId, 'achievement',
      `${userName} "${achievementTitle}" başarımını kazandı! 🏆`,
      { achievement_title: achievementTitle });
  },

  async logStreakMilestone(userId, userName, streak) {
    return this.log(userId, 'streak',
      `${userName} ${streak} günlük streak'e ulaştı! 🔥`,
      { streak });
  },

  async logNewFriendship(userId, userName, friendName) {
    return this.log(userId, 'friendship',
      `${userName} ve ${friendName} artık arkadaş!`,
      { friend_name: friendName });
  },
};

module.exports = Activity;
