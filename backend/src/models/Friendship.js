const db = require('../config/db');

const Friendship = {
  // Arkadaşlık isteği gönder
  async sendRequest(requesterId, addresseeId) {
    // Zaten bir ilişki var mı kontrol et
    const existing = await db.query(
      `SELECT * FROM friendships
       WHERE (requester_id = $1 AND addressee_id = $2)
          OR (requester_id = $2 AND addressee_id = $1)`,
      [requesterId, addresseeId]
    );
    if (existing.rows.length > 0) {
      const f = existing.rows[0];
      if (f.status === 'accepted') return { error: 'Zaten arkadaşsınız' };
      if (f.status === 'pending') return { error: 'Zaten bekleyen istek var' };
      if (f.status === 'blocked') return { error: 'Bu kullanıcı engellenmiş' };
      if (f.status === 'rejected') {
        // Reddedilmişse yeniden gönder
        await db.query(
          `UPDATE friendships SET status = 'pending', requester_id = $1, addressee_id = $2, updated_at = NOW()
           WHERE id = $3`,
          [requesterId, addresseeId, f.id]
        );
        return { success: true, status: 'pending' };
      }
    }

    const { rows } = await db.query(
      `INSERT INTO friendships (requester_id, addressee_id)
       VALUES ($1, $2) RETURNING *`,
      [requesterId, addresseeId]
    );
    return { success: true, friendship: rows[0] };
  },

  // İsteği kabul et
  async acceptRequest(friendshipId, userId) {
    const { rows } = await db.query(
      `UPDATE friendships SET status = 'accepted', updated_at = NOW()
       WHERE id = $1 AND addressee_id = $2 AND status = 'pending'
       RETURNING *`,
      [friendshipId, userId]
    );
    return rows[0] || null;
  },

  // İsteği reddet
  async rejectRequest(friendshipId, userId) {
    const { rows } = await db.query(
      `UPDATE friendships SET status = 'rejected', updated_at = NOW()
       WHERE id = $1 AND addressee_id = $2 AND status = 'pending'
       RETURNING *`,
      [friendshipId, userId]
    );
    return rows[0] || null;
  },

  // Arkadaşlığı kaldır
  async removeFriend(friendshipId, userId) {
    const { rows } = await db.query(
      `DELETE FROM friendships
       WHERE id = $1 AND (requester_id = $2 OR addressee_id = $2) AND status = 'accepted'
       RETURNING *`,
      [friendshipId, userId]
    );
    return rows[0] || null;
  },

  // Arkadaş listesi
  async getFriends(userId) {
    const { rows } = await db.query(
      `SELECT f.id AS friendship_id, f.created_at AS friends_since,
              u.id, u.name, u.email, u.total_points, u.current_streak, u.avatar_color, u.last_active_at
       FROM friendships f
       JOIN users u ON (u.id = CASE WHEN f.requester_id = $1 THEN f.addressee_id ELSE f.requester_id END)
       WHERE (f.requester_id = $1 OR f.addressee_id = $1) AND f.status = 'accepted'
       ORDER BY u.name`,
      [userId]
    );
    return rows;
  },

  // Gelen bekleyen istekler
  async getPendingRequests(userId) {
    const { rows } = await db.query(
      `SELECT f.id AS friendship_id, f.created_at AS requested_at,
              u.id, u.name, u.total_points, u.avatar_color
       FROM friendships f
       JOIN users u ON u.id = f.requester_id
       WHERE f.addressee_id = $1 AND f.status = 'pending'
       ORDER BY f.created_at DESC`,
      [userId]
    );
    return rows;
  },

  // Gönderilen bekleyen istekler
  async getSentRequests(userId) {
    const { rows } = await db.query(
      `SELECT f.id AS friendship_id, f.created_at AS requested_at,
              u.id, u.name, u.total_points, u.avatar_color
       FROM friendships f
       JOIN users u ON u.id = f.addressee_id
       WHERE f.requester_id = $1 AND f.status = 'pending'
       ORDER BY f.created_at DESC`,
      [userId]
    );
    return rows;
  },

  // İki kullanıcı arkadaş mı?
  async areFriends(userId1, userId2) {
    const { rows } = await db.query(
      `SELECT id FROM friendships
       WHERE ((requester_id = $1 AND addressee_id = $2) OR (requester_id = $2 AND addressee_id = $1))
         AND status = 'accepted'`,
      [userId1, userId2]
    );
    return rows.length > 0;
  },

  // Kullanıcı ara (arkadaş eklemek için)
  async searchUsers(query, currentUserId) {
    const search = `%${query}%`;
    const { rows } = await db.query(
      `SELECT u.id, u.name, u.total_points, u.avatar_color,
              f.status AS friendship_status, f.id AS friendship_id
       FROM users u
       LEFT JOIN friendships f ON (
         (f.requester_id = $2 AND f.addressee_id = u.id)
         OR (f.requester_id = u.id AND f.addressee_id = $2)
       )
       WHERE u.id != $2 AND u.role = 'user'
         AND (u.name ILIKE $1 OR u.email ILIKE $1)
       ORDER BY u.name
       LIMIT 20`,
      [search, currentUserId]
    );
    return rows;
  },
};

module.exports = Friendship;
