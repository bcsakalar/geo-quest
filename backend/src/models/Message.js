const db = require('../config/db');

const Message = {
  // Mesaj gönder
  async send(senderId, receiverId, content, messageType = 'text', questId = null) {
    const { rows } = await db.query(
      `INSERT INTO messages (sender_id, receiver_id, content, message_type, quest_id)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [senderId, receiverId, content, messageType, questId]
    );
    return rows[0];
  },

  // İki kullanıcı arasındaki mesajları getir (sayfalama)
  async getConversation(userId1, userId2, limit = 50, before = null) {
    let query = `
      SELECT m.*, 
             s.name AS sender_name, s.avatar_color AS sender_color,
             r.name AS receiver_name
      FROM messages m
      JOIN users s ON s.id = m.sender_id
      JOIN users r ON r.id = m.receiver_id
      WHERE ((m.sender_id = $1 AND m.receiver_id = $2)
          OR (m.sender_id = $2 AND m.receiver_id = $1))
    `;
    const params = [userId1, userId2];

    if (before) {
      query += ` AND m.created_at < $3`;
      params.push(before);
    }

    query += ` ORDER BY m.created_at DESC LIMIT $${params.length + 1}`;
    params.push(limit);

    const { rows } = await db.query(query, params);
    return rows.reverse(); // kronolojik sıra
  },

  // Konuşma listesi (son mesajla birlikte)
  async getConversations(userId) {
    const { rows } = await db.query(
      `SELECT DISTINCT ON (partner_id)
              partner_id, partner_name, partner_color,
              content AS last_message, message_type, created_at AS last_message_at,
              unread_count
       FROM (
         SELECT
           CASE WHEN m.sender_id = $1 THEN m.receiver_id ELSE m.sender_id END AS partner_id,
           CASE WHEN m.sender_id = $1 THEN r.name ELSE s.name END AS partner_name,
           CASE WHEN m.sender_id = $1 THEN r.avatar_color ELSE s.avatar_color END AS partner_color,
           m.content, m.message_type, m.created_at,
           (SELECT COUNT(*)::int FROM messages m2
            WHERE m2.sender_id = CASE WHEN m.sender_id = $1 THEN m.receiver_id ELSE m.sender_id END
              AND m2.receiver_id = $1 AND m2.is_read = false) AS unread_count
         FROM messages m
         JOIN users s ON s.id = m.sender_id
         JOIN users r ON r.id = m.receiver_id
         WHERE m.sender_id = $1 OR m.receiver_id = $1
         ORDER BY m.created_at DESC
       ) sub
       ORDER BY partner_id, last_message_at DESC`,
      [userId]
    );
    // Son mesaja göre sırala
    return rows.sort((a, b) => new Date(b.last_message_at) - new Date(a.last_message_at));
  },

  // Mesajları okundu olarak işaretle
  async markAsRead(receiverId, senderId) {
    await db.query(
      `UPDATE messages SET is_read = true
       WHERE receiver_id = $1 AND sender_id = $2 AND is_read = false`,
      [receiverId, senderId]
    );
  },

  // Toplam okunmamış mesaj sayısı
  async getUnreadCount(userId) {
    const { rows } = await db.query(
      `SELECT COUNT(*)::int AS count FROM messages WHERE receiver_id = $1 AND is_read = false`,
      [userId]
    );
    return rows[0].count;
  },
};

module.exports = Message;
