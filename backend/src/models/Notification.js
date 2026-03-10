const db = require('../config/db');

const Notification = {
  // Bildirim oluştur
  async create(userId, type, title, body, data = {}) {
    const { rows } = await db.query(
      `INSERT INTO notifications (user_id, type, title, body, data)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [userId, type, title, body, JSON.stringify(data)]
    );
    return rows[0];
  },

  // Kullanıcının bildirimlerini getir
  async getByUser(userId, limit = 30, offset = 0) {
    const { rows } = await db.query(
      `SELECT * FROM notifications
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );
    return rows;
  },

  // Okunmamış sayısı
  async getUnreadCount(userId) {
    const { rows } = await db.query(
      `SELECT COUNT(*)::int AS count FROM notifications
       WHERE user_id = $1 AND is_read = false`,
      [userId]
    );
    return rows[0].count;
  },

  // Hepsini okundu yap
  async markAllRead(userId) {
    await db.query(
      `UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false`,
      [userId]
    );
  },

  // Tekini okundu yap
  async markRead(notificationId, userId) {
    await db.query(
      `UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2`,
      [notificationId, userId]
    );
  },

  // ──── Otomatik Bildirimler ────

  async notifyFriendRequest(toUserId, fromUserName) {
    return this.create(toUserId, 'friend_request', 'Arkadaşlık İsteği',
      `${fromUserName} sana arkadaşlık isteği gönderdi!`,
      { type: 'friend_request' });
  },

  async notifyFriendAccepted(toUserId, friendName) {
    return this.create(toUserId, 'friend_accepted', 'Arkadaşlık Kabul Edildi',
      `${friendName} arkadaşlık isteğini kabul etti!`,
      { type: 'friend_accepted' });
  },

  async notifyChallenge(toUserId, fromUserName, questTitle, questId) {
    return this.create(toUserId, 'challenge', 'Meydan Okuma!',
      `${fromUserName} seni "${questTitle}" görevine davet ediyor!`,
      { type: 'challenge', quest_id: questId });
  },

  async notifyNewMessage(toUserId, fromUserName) {
    return this.create(toUserId, 'message', 'Yeni Mesaj',
      `${fromUserName} sana mesaj gönderdi.`,
      { type: 'message' });
  },

  async notifyStreakWarning(userId) {
    return this.create(userId, 'streak_warning', 'Streak Uyarısı! 🔥',
      'Streak\'in kırılmak üzere! Bugün bir görev tamamla.',
      { type: 'streak_warning' });
  },

  async notifyDailyChallenge(userId) {
    return this.create(userId, 'daily_challenge', 'Günlük Meydan Okuma',
      'Bugünkü günlük görevin hazır! Bonus puan kazanmak için tamamla.',
      { type: 'daily_challenge' });
  },

  async notifyAchievement(userId, achievementTitle) {
    return this.create(userId, 'achievement', 'Başarım Açıldı! 🏆',
      `"${achievementTitle}" başarımını kazandın!`,
      { type: 'achievement' });
  },

  async notifyNearbyQuest(userId, questTitle) {
    return this.create(userId, 'nearby_quest', 'Yakınında Görev Var!',
      `"${questTitle}" görevi yakınında bekliyor.`,
      { type: 'nearby_quest' });
  },
};

module.exports = Notification;
