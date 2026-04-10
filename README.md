<div align="center">

# 🗺️ Geo-Quest

**Location-Based Quest & Adventure Platform**

[![Node.js](https://img.shields.io/badge/Node.js-20-339933?logo=node.js&logoColor=white)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-4-000000?logo=express&logoColor=white)](https://expressjs.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)](https://postgresql.org/)
[![PostGIS](https://img.shields.io/badge/PostGIS-3.4-5CAE58)](https://postgis.net/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://docker.com/)
[![Gemini AI](https://img.shields.io/badge/Gemini-AI-8E75B2?logo=google&logoColor=white)](https://ai.google.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Discover real-world quests on a map, complete them by taking photos, answering questions, or scanning QR codes — all powered by **Google Gemini AI** for dynamic quest generation and smart photo evaluation.

[Features](#-features) · [Architecture](#-architecture) · [Getting Started](#-getting-started) · [API Reference](#-api-reference) · [Database](#-database-schema) · [License](#-license)

</div>

---

## 📌 About

Geo-Quest is a full-stack, location-based adventure platform that turns the real world into a playground. Users explore an interactive map to find quests nearby, then complete them by snapping photos, answering trivia, or scanning QR codes. The platform leverages **Google Gemini AI** to automatically generate quests tailored to the user's location and to evaluate photo submissions with a 0–100 scoring system.

The project ships with a **Node.js/Express REST API**, a **Flutter mobile app** (Android), a **PostgreSQL + PostGIS** spatial database, and a **web-based admin panel** for content management — all orchestrated via **Docker Compose**.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🗺️ **Map-Based Quests** | Photo, question, and QR-code quests placed at real-world GPS coordinates |
| 🤖 **AI Quest Generation** | Gemini AI creates 3 unique quests near the user's current location on demand |
| 📸 **AI Photo Evaluation** | Submitted photos are scored 0–100 by Gemini; scores ≥ 70 are auto-approved |
| 💡 **AI Hints & Recommendations** | Context-aware hints (costs 2 points) and personalized quest suggestions |
| 👥 **Social System** | Friend requests, direct messaging, challenge friends with quests, activity feed |
| 🏆 **Achievements** | 14 unlockable achievements triggered automatically on quest completion |
| 🔥 **Streak & Multiplier** | Consecutive-day tracking with point multipliers (up to 2× at 30-day streaks) |
| 📅 **Daily Challenges** | One randomly assigned quest per day with bonus points |
| 📊 **Leaderboard** | Global top-50 ranking by total points |
| 🔔 **Notifications** | In-app notifications for friend events, achievements, challenges, and more |
| 🛡️ **Admin Panel** | Bootstrap 5.3 web panel with Leaflet maps — manage quests, review submissions, view users |
| 📍 **PostGIS Spatial Queries** | `ST_DWithin` proximity filtering with GIST-indexed `GEOGRAPHY` columns |

---

## 🏗️ Architecture

```
┌───────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                     │
│  Provider · Dio · flutter_map · Geolocator · SecureStorage │
└─────────────────────┬─────────────────────────────────────┘
                      │  REST API (JSON + JWT Bearer Auth)
                      │  http://<host>:4001/api
┌─────────────────────▼─────────────────────────────────────┐
│               Node.js 20 + Express 4 Backend               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  API Routes (/api/*)        │  Web Routes (/admin/*) │  │
│  │  JWT Authentication         │  Session Authentication│  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  Models (Static Method Pattern)                      │  │
│  │  User · Quest · Submission · Achievement             │  │
│  │  DailyChallenge · Friendship · Message               │  │
│  │  Notification · Activity                             │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  Services                                            │  │
│  │  Gemini AI — quest generation, photo eval, hints     │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  Middleware                                          │  │
│  │  auth (JWT + session) · upload (Multer) · errors     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────┬─────────────────────────────────────┘
                      │  pg Pool (max 20 connections)
┌─────────────────────▼─────────────────────────────────────┐
│            PostgreSQL 16 + PostGIS 3.4                      │
│  10 tables · GIST spatial index · triggers · GEOGRAPHY     │
└───────────────────────────────────────────────────────────┘
```

### Data Flow

```
User Interaction → Screen (Widget) → Provider (ChangeNotifier)
  → Service (Dio HTTP) → REST API → Model (SQL) → PostgreSQL
  → Response → Provider state update → UI rebuild
```

### Gemini AI Integration

```
Mobile App                   Backend                       Gemini API
    │                           │                              │
    ├─ POST /quests/generate ──▶│ gemini.generateQuests() ────▶│ → 3 structured quests
    │                           │◀──── quest JSON ─────────────┤
    │                           │                              │
    ├─ POST /quests/:id/submit ▶│ gemini.evaluatePhoto() ─────▶│ → score 0-100
    │                           │◀──── ai_evaluation + score ──┤
    │                           │                              │
    ├─ GET /quests/:id/hint ───▶│ gemini.generateHint() ──────▶│ → contextual hint
    │                           │◀──── hint text ──────────────┤
    │                           │                              │
    ├─ GET /quests/recommend ──▶│ gemini.getRecommendations() ▶│ → top 3 suggestions
    │                           │◀──── recommendations ────────┤
```

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Backend** | Node.js 20, Express 4 | REST API + admin panel server |
| **Database** | PostgreSQL 16, PostGIS 3.4 | Relational data + spatial queries |
| **AI** | Google Gemini API (`@google/genai`) | Quest generation, photo scoring, hints |
| **Mobile** | Flutter 3.x, Dart 3 | Cross-platform mobile app |
| **Maps** | flutter_map 7, OpenStreetMap | Interactive quest map display |
| **Location** | Geolocator 13 | GPS permissions + distance calculation |
| **Camera** | image_picker 1.1 | Photo capture for quest submissions |
| **QR Scanner** | mobile_scanner 6 | QR code quest scanning |
| **Token Storage** | flutter_secure_storage 9.2 | Encrypted JWT storage on device |
| **State** | Provider 6 (`ChangeNotifier`) | App state management |
| **HTTP Client** | Dio 5.7 (singleton) | API communication with JWT interceptor |
| **Auth** | JWT (API), express-session (Admin) | Dual authentication strategy |
| **File Upload** | Multer | Multipart file handling (JPEG/PNG/WebP, max 10 MB) |
| **Admin UI** | EJS, Bootstrap 5.3, Leaflet | Server-rendered admin panel with maps |
| **Containers** | Docker, Docker Compose | One-command deployment |
| **Password** | bcrypt (10 salt rounds) | Secure password hashing |

---

## 📂 Project Structure

```
geo-quest/
├── docker-compose.yml              # Orchestrates PostgreSQL + Backend containers
├── .env                            # Environment variables (not committed)
│
├── backend/
│   ├── Dockerfile                  # node:20-alpine production image
│   ├── package.json
│   └── src/
│       ├── server.js               # Entry point — DB check, admin seed, listen :4001
│       ├── app.js                  # Express config, middleware stack, route mounting
│       ├── config/
│       │   ├── db.js               # PostgreSQL Pool (max 20, 30s idle, 5s connect)
│       │   └── env.js              # Loads .env, exports config object
│       ├── db/
│       │   ├── init.sql            # Core tables: users, quests, submissions + PostGIS
│       │   ├── seed.sql            # Seed data placeholder
│       │   ├── migrate-ai.sql      # AI columns: source, generated_for, ai_score
│       │   ├── migrate-achievements.sql  # achievements, user_achievements, daily_challenges
│       │   └── migrate-social.sql  # friendships, messages, notifications, activities
│       ├── middleware/
│       │   ├── auth.js             # requireAuth (JWT verify) + requireAdmin (session)
│       │   ├── upload.js           # Multer: JPEG/PNG/WebP, max 10 MB, random filenames
│       │   └── errorHandler.js     # Centralized error handler (API → JSON, Web → EJS)
│       ├── models/                 # Static method pattern — each model owns its SQL
│       │   ├── User.js             # Auth, points, streak, leaderboard
│       │   ├── Quest.js            # CRUD, PostGIS proximity (ST_DWithin), active filter
│       │   ├── Submission.js       # Create, list, status update, AI evaluation storage
│       │   ├── Achievement.js      # 14 achievement definitions, auto-unlock logic
│       │   ├── DailyChallenge.js   # Daily assignment, completion, bonus points
│       │   ├── Friendship.js       # Request/accept/reject/block, bidirectional check
│       │   ├── Message.js          # Text/challenge/system messages, read tracking
│       │   ├── Notification.js     # 8 notification types, unread counter, bulk read
│       │   └── Activity.js         # Social feed: quest_completed, achievement, streak
│       ├── services/
│       │   └── gemini.js           # Gemini AI: generate quests, evaluate photos, hints
│       ├── routes/
│       │   ├── api/                # REST API endpoints (JWT auth)
│       │   │   ├── auth.js         # POST /register, /login
│       │   │   ├── quests.js       # GET list + nearby, POST submit + generate, GET hint
│       │   │   ├── submissions.js  # GET /mine
│       │   │   ├── users.js        # GET /me, /leaderboard
│       │   │   ├── achievements.js # GET all, /check, /daily, /streak
│       │   │   ├── friends.js      # GET list/requests/sent/search, POST/DELETE actions
│       │   │   ├── messages.js     # GET conversations + history, POST send + challenge
│       │   │   └── social.js       # GET notifications/feed/unread, POST read + push-token
│       │   └── web/                # Admin panel routes (session auth)
│       │       ├── auth.js         # GET/POST /admin/login, /logout
│       │       ├── dashboard.js    # GET /admin/dashboard (stats overview)
│       │       ├── quests.js       # CRUD /admin/quests/*
│       │       ├── submissions.js  # GET list, POST approve/reject
│       │       └── users.js        # GET /admin/users
│       ├── views/                  # EJS templates for admin panel
│       │   ├── layouts/main.ejs    # Bootstrap 5.3 + Leaflet base layout
│       │   ├── partials/           # header.ejs, sidebar.ejs
│       │   ├── dashboard.ejs       # 4 stat cards + recent submissions
│       │   ├── quests/             # index, create, edit (with Leaflet map picker)
│       │   ├── submissions/        # Filterable table with approve/reject actions
│       │   └── users/              # User list table
│       ├── public/
│       │   ├── css/style.css       # Admin panel styles
│       │   └── uploads/            # Uploaded quest photos (Multer target)
│       └── utils/
│           └── helpers.js          # hashPassword, comparePassword, signToken, verifyToken
│
└── mobile/
    └── geo_quest/
        ├── pubspec.yaml            # Flutter dependencies
        └── lib/
            ├── main.dart           # App entry: MultiProvider, MaterialApp, named routes
            ├── config/
            │   └── api_config.dart # API base URL + timeout configuration
            ├── models/             # Data classes with fromJson factories
            │   ├── user.dart
            │   ├── quest.dart
            │   ├── submission.dart
            │   └── achievement.dart
            ├── services/           # API communication layer
            │   ├── api_service.dart     # Singleton Dio instance + JWT interceptor
            │   ├── auth_service.dart    # Login, register, profile, logout
            │   └── location_service.dart# GPS permissions, distance calculation
            ├── providers/          # State management (ChangeNotifier)
            │   ├── auth_provider.dart   # Authentication state + auto-login
            │   ├── quest_provider.dart  # Quests, submissions, leaderboard, achievements
            │   └── social_provider.dart # Friends, messages, notifications, feed
            ├── screens/            # 15 app screens
            │   ├── splash_screen.dart       # Auto-login token check
            │   ├── login_screen.dart        # Email + password login form
            │   ├── register_screen.dart     # Registration form
            │   ├── home_screen.dart         # BottomNav hub (5 tabs) + notification badge
            │   ├── map_screen.dart          # Quest markers, user location, AI generate FAB
            │   ├── quest_detail_screen.dart # Photo/question/QR submission + hints
            │   ├── qr_scanner_screen.dart   # QR code scanning
            │   ├── profile_screen.dart      # Stats, points, streak display
            │   ├── achievements_screen.dart # Achievement grid + daily challenge + streak
            │   ├── leaderboard_screen.dart  # Top 50 rankings
            │   ├── social_hub_screen.dart   # Tabbed: Feed, Messages, Friends
            │   ├── friends_screen.dart      # Friend list, requests, user search
            │   ├── chat_screen.dart         # Messaging (5s polling) + challenge sending
            │   ├── notifications_screen.dart# Notification center
            │   └── feed_screen.dart         # Friend activity timeline
            └── widgets/            # Reusable UI components
                ├── quest_card.dart      # Quest list card (type icon, distance, status)
                └── loading_widget.dart  # Centered loading indicator
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version | Required For |
|------|---------|-------------|
| [Docker](https://docker.com/) + Docker Compose | 20+ | Backend + Database |
| [Flutter SDK](https://flutter.dev/) | 3.x | Mobile app |
| [Git](https://git-scm.com/) | any | Cloning the repo |
| [Gemini API Key](https://aistudio.google.com/apikey) | — | AI features (optional) |

### 1. Clone the Repository

```bash
git clone https://github.com/bcsakalar/geo-quest.git
cd geo-quest
```

### 2. Configure Environment Variables

Create a `.env` file in the project root:

```env
# ──── General ────
NODE_ENV=development
PORT=4001

# ──── PostgreSQL ────
POSTGRES_USER=geoquest
POSTGRES_PASSWORD=your_strong_password_here
POSTGRES_DB=geoquest
POSTGRES_HOST=db
POSTGRES_PORT=5432

# ──── Authentication ────
JWT_SECRET=your_random_jwt_secret_here
SESSION_SECRET=your_random_session_secret_here

# ──── AI (optional) ────
GEMINI_API_KEY=your_gemini_api_key_here
```

> **Note:** Never commit `.env` to version control. A `.env.example` template is provided.

### 3. Start the Backend

```bash
docker-compose up --build -d
```

Verify everything is running:

```bash
docker-compose ps                  # Check container status
docker logs geoquest-app           # Should show:
# ✓ Database connected
# ✓ Admin user created (admin@geoquest.com / admin123)
# ✓ Geo-Quest server running on http://localhost:4001
```

### 4. Run Database Migrations

The base tables are created automatically. Additional features require manual migrations:

```bash
# AI quest generation & photo evaluation columns
docker exec -i geoquest-db psql -U geoquest -d geoquest < backend/src/db/migrate-ai.sql

# Achievement system, daily challenges, streak tracking
docker exec -i geoquest-db psql -U geoquest -d geoquest < backend/src/db/migrate-achievements.sql

# Social features: friendships, messaging, notifications, activity feed
docker exec -i geoquest-db psql -U geoquest -d geoquest < backend/src/db/migrate-social.sql
```

### 5. Set Up the Flutter App

```bash
cd mobile/geo_quest
flutter pub get
```

**Run on emulator:**

```bash
flutter run
```

**Run on physical device:**

1. Find your computer's local IP: `ipconfig` (Windows) or `ifconfig` (macOS/Linux)
2. Update `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_LOCAL_IP:4001/api';
   ```
3. Ensure your phone and computer are on the same WiFi network
4. Run: `flutter run` or build APK: `flutter build apk --debug`

### 6. Access the Admin Panel

| | |
|-|-|
| **URL** | http://localhost:4001/admin |
| **Email** | `admin@geoquest.com` |
| **Password** | `admin123` (change in production!) |

---

## 📡 API Reference

All endpoints (except auth) require a valid JWT token in the `Authorization: Bearer <token>` header.

### Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|:----:|-------------|
| `POST` | `/api/auth/register` | — | Register a new user (name, email, password) |
| `POST` | `/api/auth/login` | — | Login, returns JWT token (7-day expiry) |

### Quests

| Method | Endpoint | Auth | Description |
|--------|----------|:----:|-------------|
| `GET` | `/api/quests` | ✅ | List all active quests |
| `GET` | `/api/quests?lat=X&lng=Y&radius=Z` | ✅ | Find nearby quests using PostGIS `ST_DWithin` |
| `GET` | `/api/quests/:id` | ✅ | Quest details (answers & QR data are hidden) |
| `POST` | `/api/quests/:id/submit` | ✅ | Submit completion (multipart for photos) |
| `POST` | `/api/quests/generate` | ✅ | AI-generate 3 quests at location (rate limit: 1/min, max 50) |
| `GET` | `/api/quests/:id/hint` | ✅ | Get AI-generated hint (costs 2 points) |
| `GET` | `/api/quests/recommendations` | ✅ | AI-powered personalized quest suggestions |

### Submissions

| Method | Endpoint | Auth | Description |
|--------|----------|:----:|-------------|
| `GET` | `/api/submissions/mine` | ✅ | Get current user's submissions |

### Users

| Method | Endpoint | Auth | Description |
|--------|----------|:----:|-------------|
| `GET` | `/api/users/me` | ✅ | Get current user profile |
| `GET` | `/api/users/leaderboard` | ✅ | Top 50 leaderboard |

### Achievements

| Method | Endpoint | Auth | Description |
|--------|----------|:----:|-------------|
| `GET` | `/api/achievements` | ✅ | All achievements with user unlock status |
| `GET` | `/api/achievements/check` | ✅ | Trigger achievement condition check |
| `GET` | `/api/achievements/daily` | ✅ | Today's daily challenge (auto-assigned) |
| `GET` | `/api/achievements/streak` | ✅ | Streak info (current, max, multiplier) |

### Friends

| Method | Endpoint | Auth | Description |
|--------|----------|:----:|-------------|
| `GET` | `/api/friends` | ✅ | List accepted friends |
| `GET` | `/api/friends/requests` | ✅ | Incoming pending requests |
| `GET` | `/api/friends/sent` | ✅ | Outgoing pending requests |
| `GET` | `/api/friends/search?q=name` | ✅ | Search users by name (min 2 chars) |
| `POST` | `/api/friends/request` | ✅ | Send friend request |
| `POST` | `/api/friends/:id/accept` | ✅ | Accept friend request |
| `POST` | `/api/friends/:id/reject` | ✅ | Reject friend request |
| `DELETE` | `/api/friends/:id` | ✅ | Remove friend |

### Messages

| Method | Endpoint | Auth | Description |
|--------|----------|:----:|-------------|
| `GET` | `/api/messages` | ✅ | List all conversations with unread counts |
| `GET` | `/api/messages/:userId` | ✅ | Message history with a friend (paginated) |
| `POST` | `/api/messages/:userId` | ✅ | Send text message (friends only, max 1000 chars) |
| `POST` | `/api/messages/:userId/challenge` | ✅ | Send quest challenge to a friend |

### Social & Notifications

| Method | Endpoint | Auth | Description |
|--------|----------|:----:|-------------|
| `GET` | `/api/social/notifications` | ✅ | Get notifications + unread count |
| `POST` | `/api/social/notifications/read` | ✅ | Mark all notifications as read |
| `POST` | `/api/social/notifications/:id/read` | ✅ | Mark specific notification as read |
| `GET` | `/api/social/feed` | ✅ | Friend activity feed (paginated) |
| `GET` | `/api/social/unread` | ✅ | Combined unread count (notifications + messages) |
| `POST` | `/api/social/push-token` | ✅ | Save FCM push notification token |

---

## 🗄️ Database Schema

PostgreSQL 16 with PostGIS 3.4 extension. 10 tables with spatial indexing.

| Table | Description | Key Constraints |
|-------|-------------|-----------------|
| `users` | User accounts, points, streak tracking, push tokens | `UNIQUE(email)` |
| `quests` | Quest definitions with GPS coordinates and PostGIS geography | GIST index on `location`, trigger auto-computes geography from lat/lng |
| `submissions` | User quest submissions with AI evaluation | `UNIQUE(user_id, quest_id)` — one attempt per quest |
| `achievements` | 14 achievement definitions (first_quest, streak_7, etc.) | `UNIQUE(key)` |
| `user_achievements` | Unlocked achievement records | `UNIQUE(user_id, achievement_id)` |
| `daily_challenges` | Daily quest assignments with bonus points | `UNIQUE(user_id, challenge_date)` — one per day |
| `friendships` | Bidirectional friend relationships | `UNIQUE(requester_id, addressee_id)`, `CHECK(requester ≠ addressee)` |
| `messages` | Direct messages (text, challenge, system types) | `CHECK(sender ≠ receiver)` |
| `notifications` | In-app notifications (8 types) with JSONB data | — |
| `activities` | Social activity feed entries | — |

### Quest Types & Verification

| Type | Completion Method | Verification |
|------|-------------------|-------------|
| `photo` | Take a photo | AI scores 0–100; ≥ 70 = auto-approved, < 70 = pending admin review |
| `question` | Text answer | Case-insensitive exact match |
| `qr_code` | Scan QR code | Exact string match against stored `qr_data` |

### Streak Multiplier System

| Streak Days | Multiplier | Bonus |
|-------------|-----------|-------|
| 0 – 2 | 1.0× | — |
| 3 – 6 | 1.25× | +25% |
| 7 – 29 | 1.5× | +50% |
| 30+ | 2.0× | +100% |

### Achievement List (14 Total)

| Key | Requirement | Reward |
|-----|------------|--------|
| `first_quest` | Complete 1 quest | 10 pts |
| `quest_5` / `quest_10` / `quest_25` | Complete 5 / 10 / 25 quests | 25 / 50 / 100 pts |
| `photo_5` | Complete 5 photo quests | 30 pts |
| `question_5` | Complete 5 question quests | 30 pts |
| `ai_explorer` | Complete 1 AI-generated quest | 15 pts |
| `ai_master` | Complete 10 AI-generated quests | 50 pts |
| `streak_3` / `streak_7` / `streak_30` | Reach 3 / 7 / 30-day streak | 20 / 50 / 150 pts |
| `daily_5` | Complete 5 daily challenges | 30 pts |
| `points_100` / `points_500` | Accumulate 100 / 500 points | 10 / 50 pts |

---

## 🐳 Docker Services

| Service | Image | Ports | Description |
|---------|-------|-------|-------------|
| `db` | `postgis/postgis:16-3.4` | `5434:5432` | PostgreSQL + PostGIS with health checks |
| `app` | `node:20-alpine` (custom build) | `4001:4001` | Express backend, depends on healthy `db` |

**Volumes:**
- `pgdata` — persistent database storage
- `upload_data` — uploaded quest photos
- `./backend/src` → `/app/src` — hot-reload in development

### Common Docker Commands

```bash
docker-compose up -d                 # Start all services
docker-compose down                  # Stop all services
docker-compose down -v               # Stop and delete volumes (WARNING: data loss)
docker-compose logs -f app           # Follow backend logs
docker-compose logs -f db            # Follow database logs
docker-compose up -d --build app     # Rebuild and restart backend
docker-compose restart app           # Restart backend only

# Connect to database
docker exec -it geoquest-db psql -U geoquest -d geoquest

# Verify PostGIS
docker exec -it geoquest-db psql -U geoquest -d geoquest -c "SELECT PostGIS_Version();"
```

---

## 🔧 Troubleshooting

### Backend won't start

```bash
docker logs geoquest-app             # Check for error messages
docker-compose ps                    # Ensure 'db' is healthy before 'app' starts
docker-compose down && docker-compose up --build -d   # Full rebuild
```

### Flutter can't connect to API

- **Emulator:** Android emulator maps `10.0.2.2` to host `localhost`
- **Physical device:** Use your computer's LAN IP (`ipconfig` on Windows, `ifconfig` on macOS/Linux)
- Ensure port `4001` is not blocked by your firewall
- Phone and computer must be on the **same WiFi network**

### Migrations fail

- Make sure the `db` container is running and healthy: `docker-compose ps`
- Check that the database name in the migration command matches your `POSTGRES_DB` env var

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**bcsakalar** — [@bcsakalar](https://github.com/bcsakalar)

---

<div align="center">

**Built with ❤️ using Node.js, Flutter, PostgreSQL & Gemini AI**

</div>
