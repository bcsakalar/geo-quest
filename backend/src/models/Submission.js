const db = require('../config/db');

const Submission = {
  async create({ userId, questId, photoUrl, answerText, qrScannedData, aiEvaluation, aiScore }) {
    const { rows } = await db.query(
      `INSERT INTO submissions (user_id, quest_id, photo_url, answer_text, qr_scanned_data, ai_evaluation, ai_score)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [userId, questId, photoUrl || null, answerText || null, qrScannedData || null, aiEvaluation || null, aiScore || null]
    );
    return rows[0];
  },

  async findByUser(userId) {
    const { rows } = await db.query(
      `SELECT s.*, q.title AS quest_title, q.type AS quest_type, q.points AS quest_points
       FROM submissions s
       JOIN quests q ON s.quest_id = q.id
       WHERE s.user_id = $1
       ORDER BY s.submitted_at DESC`,
      [userId]
    );
    return rows;
  },

  async findAll() {
    const { rows } = await db.query(
      `SELECT s.*, u.name AS user_name, u.email AS user_email,
              q.title AS quest_title, q.type AS quest_type, q.points AS quest_points
       FROM submissions s
       JOIN users u ON s.user_id = u.id
       JOIN quests q ON s.quest_id = q.id
       ORDER BY s.submitted_at DESC`
    );
    return rows;
  },

  async findById(id) {
    const { rows } = await db.query(
      `SELECT s.*, u.name AS user_name, u.email AS user_email,
              q.title AS quest_title, q.type AS quest_type, q.points AS quest_points
       FROM submissions s
       JOIN users u ON s.user_id = u.id
       JOIN quests q ON s.quest_id = q.id
       WHERE s.id = $1`,
      [id]
    );
    return rows[0] || null;
  },

  async updateStatus(id, status, reviewedBy) {
    const { rows } = await db.query(
      `UPDATE submissions SET status = $1, reviewed_at = NOW(), reviewed_by = $2
       WHERE id = $3
       RETURNING *`,
      [status, reviewedBy, id]
    );
    return rows[0];
  },

  async existsForUser(userId, questId) {
    const { rows } = await db.query(
      'SELECT id FROM submissions WHERE user_id = $1 AND quest_id = $2',
      [userId, questId]
    );
    return rows.length > 0;
  },

  async count() {
    const { rows } = await db.query('SELECT COUNT(*)::int AS count FROM submissions');
    return rows[0].count;
  },

  async countByStatus(status) {
    const { rows } = await db.query(
      'SELECT COUNT(*)::int AS count FROM submissions WHERE status = $1',
      [status]
    );
    return rows[0].count;
  },
};

module.exports = Submission;
