const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const expressLayouts = require('express-ejs-layouts');
const env = require('./config/env');

const app = express();

// ──── Body Parsers ────
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// ──── Session (Web Admin) ────
app.use(session({
  secret: env.sessionSecret,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: false,
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000, // 1 gün
  },
}));

// ──── Static Files ────
app.use(express.static(path.join(__dirname, 'public')));

// ──── EJS View Engine ────
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(expressLayouts);
app.set('layout', 'layouts/main');

// ──── Make session user available in all views ────
app.use((req, res, next) => {
  res.locals.adminUser = req.session.adminUser || null;
  next();
});

// ──── Routes ────
const apiAuthRoutes = require('./routes/api/auth');
const apiQuestRoutes = require('./routes/api/quests');
const apiSubmissionRoutes = require('./routes/api/submissions');
const apiUserRoutes = require('./routes/api/users');
const apiAchievementRoutes = require('./routes/api/achievements');
const apiFriendRoutes = require('./routes/api/friends');
const apiMessageRoutes = require('./routes/api/messages');
const apiSocialRoutes = require('./routes/api/social');
const webAuthRoutes = require('./routes/web/auth');
const webDashboardRoutes = require('./routes/web/dashboard');
const webQuestRoutes = require('./routes/web/quests');
const webSubmissionRoutes = require('./routes/web/submissions');
const webUserRoutes = require('./routes/web/users');

// API routes
app.use('/api/auth', apiAuthRoutes);
app.use('/api/quests', apiQuestRoutes);
app.use('/api/submissions', apiSubmissionRoutes);
app.use('/api/users', apiUserRoutes);
app.use('/api/achievements', apiAchievementRoutes);
app.use('/api/friends', apiFriendRoutes);
app.use('/api/messages', apiMessageRoutes);
app.use('/api/social', apiSocialRoutes);

// Web admin routes
app.use('/admin', webAuthRoutes);
app.use('/admin', webDashboardRoutes);
app.use('/admin/quests', webQuestRoutes);
app.use('/admin/submissions', webSubmissionRoutes);
app.use('/admin/users', webUserRoutes);

// ──── Root redirect ────
app.get('/', (req, res) => res.redirect('/admin'));

// ──── Error Handler ────
const errorHandler = require('./middleware/errorHandler');
app.use(errorHandler);

module.exports = app;
