const app = require('./app');
const env = require('./config/env');
const db = require('./config/db');
const User = require('./models/User');
const { hashPassword } = require('./utils/helpers');

async function seedAdmin() {
  const existing = await User.findByEmail('admin@geoquest.com');
  if (!existing) {
    const passwordHash = await hashPassword('admin123');
    await db.query(
      `INSERT INTO users (email, password_hash, name, role) VALUES ($1, $2, $3, $4)`,
      ['admin@geoquest.com', passwordHash, 'Admin', 'admin']
    );
    console.log('✓ Admin user created (admin@geoquest.com / admin123)');
  }
}

async function start() {
  // Verify DB connection
  try {
    const result = await db.query('SELECT NOW() AS now');
    console.log(`✓ Database connected: ${result.rows[0].now}`);
  } catch (err) {
    console.error('✗ Database connection failed:', err.message);
    process.exit(1);
  }

  // Seed admin user
  await seedAdmin();

  app.listen(env.port, '0.0.0.0', () => {
    console.log(`✓ Geo-Quest server running on http://localhost:${env.port}`);
    console.log(`  Admin panel: http://localhost:${env.port}/admin`);
    console.log(`  API base:    http://localhost:${env.port}/api`);
  });
}

start();
