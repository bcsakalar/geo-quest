const db = require('../config/db');

const Quest = {
  async findAll() {
    const { rows } = await db.query(
      `SELECT q.*, u.name AS creator_name
       FROM quests q
       LEFT JOIN users u ON q.created_by = u.id
       ORDER BY q.created_at DESC`
    );
    return rows;
  },

  async findActive() {
    const { rows } = await db.query(
      `SELECT id, title, description, type, latitude, longitude,
              radius_meters, points, question, is_active, source, generated_for, created_at
       FROM quests
       WHERE is_active = true
       ORDER BY created_at DESC`
    );
    return rows;
  },

  async findById(id) {
    const { rows } = await db.query('SELECT * FROM quests WHERE id = $1', [id]);
    return rows[0] || null;
  },

  // PostGIS: belirli bir konuma yakın aktif görevleri getir
  async findNearby(lat, lng, radiusMeters = 5000) {
    const { rows } = await db.query(
      `SELECT id, title, description, type, latitude, longitude,
              radius_meters, points, question, is_active, source, generated_for, created_at,
              ST_Distance(location, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography) AS distance_meters
       FROM quests
       WHERE is_active = true
         AND ST_DWithin(location, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
       ORDER BY distance_meters ASC`,
      [lat, lng, radiusMeters]
    );
    return rows;
  },

  async create({ title, description, type, latitude, longitude, radiusMeter, points, question, answer, qrData, createdBy, source, generatedFor }) {
    const { rows } = await db.query(
      `INSERT INTO quests (title, description, type, latitude, longitude, radius_meters, points, question, answer, qr_data, created_by, source, generated_for)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
       RETURNING *`,
      [title, description, type, latitude, longitude, radiusMeter || 100, points || 10, question, answer, qrData, createdBy, source || 'manual', generatedFor || null]
    );
    return rows[0];
  },

  async update(id, { title, description, type, latitude, longitude, radiusMeter, points, question, answer, qrData, isActive }) {
    const { rows } = await db.query(
      `UPDATE quests SET
         title = $1, description = $2, type = $3, latitude = $4, longitude = $5,
         radius_meters = $6, points = $7, question = $8, answer = $9, qr_data = $10, is_active = $11
       WHERE id = $12
       RETURNING *`,
      [title, description, type, latitude, longitude, radiusMeter, points, question, answer, qrData, isActive, id]
    );
    return rows[0];
  },

  async delete(id) {
    await db.query('DELETE FROM quests WHERE id = $1', [id]);
  },

  async count() {
    const { rows } = await db.query('SELECT COUNT(*)::int AS count FROM quests');
    return rows[0].count;
  },

  async countActive() {
    const { rows } = await db.query('SELECT COUNT(*)::int AS count FROM quests WHERE is_active = true');
    return rows[0].count;
  },
};

module.exports = Quest;
