const db = require('../config/db');

const User = {
  async findByEmail(email) {
    const { rows } = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    return rows[0] || null;
  },

  async findById(id) {
    const { rows } = await db.query(
      'SELECT id, email, name, role, total_points, current_streak, max_streak, last_quest_date, created_at FROM users WHERE id = $1',
      [id]
    );
    return rows[0] || null;
  },

  async create({ email, passwordHash, name }) {
    const { rows } = await db.query(
      `INSERT INTO users (email, password_hash, name)
       VALUES ($1, $2, $3)
       RETURNING id, email, name, role, total_points, created_at`,
      [email, passwordHash, name]
    );
    return rows[0];
  },

  async addPoints(userId, points) {
    const { rows } = await db.query(
      `UPDATE users SET total_points = total_points + $1 WHERE id = $2
       RETURNING id, total_points`,
      [points, userId]
    );
    return rows[0];
  },

  async getLeaderboard(limit = 20) {
    const { rows } = await db.query(
      `SELECT id, name, total_points, current_streak, max_streak, created_at
       FROM users WHERE role = 'user'
       ORDER BY total_points DESC
       LIMIT $1`,
      [limit]
    );
    return rows;
  },

  async count() {
    const { rows } = await db.query("SELECT COUNT(*)::int AS count FROM users WHERE role = 'user'");
    return rows[0].count;
  },

  async updateStreak(userId) {
    const user = await this.findById(userId);
    if (!user) return null;

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const lastDate = user.last_quest_date ? new Date(user.last_quest_date) : null;
    if (lastDate) lastDate.setHours(0, 0, 0, 0);

    let newStreak = 1;
    if (lastDate) {
      const diffDays = Math.floor((today - lastDate) / (1000 * 60 * 60 * 24));
      if (diffDays === 0) {
        // Aynı gün, streak değişmez
        return { current_streak: user.current_streak, max_streak: user.max_streak, multiplier: this.getStreakMultiplier(user.current_streak) };
      } else if (diffDays === 1) {
        newStreak = (user.current_streak || 0) + 1;
      }
      // diffDays > 1 → streak sıfırlanır (newStreak = 1)
    }

    const newMax = Math.max(newStreak, user.max_streak || 0);
    const { rows } = await db.query(
      `UPDATE users SET current_streak = $1, max_streak = $2, last_quest_date = CURRENT_DATE
       WHERE id = $3 RETURNING current_streak, max_streak`,
      [newStreak, newMax, userId]
    );
    return { ...rows[0], multiplier: this.getStreakMultiplier(newStreak) };
  },

  getStreakMultiplier(streak) {
    if (streak >= 30) return 2.0;
    if (streak >= 7) return 1.5;
    if (streak >= 3) return 1.25;
    return 1.0;
  },

  async findAll() {
    const { rows } = await db.query(
      'SELECT id, email, name, role, total_points, created_at FROM users ORDER BY created_at DESC'
    );
    return rows;
  },
};

module.exports = User;
