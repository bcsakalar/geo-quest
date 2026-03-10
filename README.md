<div align="center">

# 🗺️ Geo-Quest

**Konum Tabanlı Görev & Macera Platformu**
**Location-Based Quest & Adventure Platform**

[![Node.js](https://img.shields.io/badge/Node.js-20-339933?logo=node.js&logoColor=white)](https://nodejs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)](https://postgresql.org/)
[![PostGIS](https://img.shields.io/badge/PostGIS-3.4-green)](https://postgis.net/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://docker.com/)
[![Gemini AI](https://img.shields.io/badge/Gemini-AI-8E75B2?logo=google&logoColor=white)](https://ai.google.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<br />

[Türkçe](#-türkçe) · [English](#-english)

</div>

---

# 🇹🇷 Türkçe

## 📌 Proje Hakkında

Geo-Quest, kullanıcıların harita üzerinde görevleri keşfettiği, fotoğraf çektiği, soruları cevapladığı ve QR kodları taradığı konum tabanlı bir macera platformudur. **Gemini AI** ile otomatik görev üretimi, sosyal özellikler, başarım sistemi ve gerçek zamanlı mesajlaşma sunar.

### Temel Özellikler

| Özellik | Açıklama |
|---------|----------|
| 🗺️ Harita Tabanlı Görevler | Gerçek dünya konumlarında fotoğraf, soru ve QR görevleri |
| 🤖 AI Görev Üretimi | Gemini AI ile konumunuza özel otomatik görev oluşturma |
| 📸 Fotoğraf Değerlendirme | AI destekli fotoğraf analizi ve otomatik onay |
| 👥 Sosyal Sistem | Arkadaşlık, mesajlaşma, aktivite feed'i |
| 🏆 Başarım & Seri | 14 farklı başarım, günlük görevler, streak takibi |
| 💬 Gerçek Zamanlı Mesajlaşma | Arkadaşlara meydan okuma gönderme |
| 📊 Sıralama Tablosu | Puan bazlı liderboard |
| 🛡️ Admin Paneli | Web tabanlı görev ve kullanıcı yönetimi |
| 📍 PostGIS | Konum bazlı yakınlık sorguları |

## 🏗️ Mimari

```
┌──────────────────────────────────────────────────────┐
│                    Flutter Mobile App                  │
│  (Harita · Görevler · Sosyal · Başarımlar · Profil)   │
└──────────────────┬───────────────────────────────────┘
                   │ REST API (JWT Auth)
┌──────────────────▼───────────────────────────────────┐
│              Node.js + Express Backend                │
│  (API Routes · Admin Panel · Gemini AI Service)       │
└──────────────────┬───────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────┐
│          PostgreSQL 16 + PostGIS 3.4                  │
│  (Users · Quests · Submissions · Social · Achieve.)   │
└──────────────────────────────────────────────────────┘
```

## 🛠️ Teknoloji Stack

| Katman | Teknoloji |
|--------|-----------|
| Backend | Node.js 20 + Express 4 |
| Veritabanı | PostgreSQL 16 + PostGIS 3.4 |
| AI | Google Gemini API (@google/genai) |
| Mobil | Flutter 3.x (Dart) |
| Harita | flutter_map + OpenStreetMap |
| Auth | JWT (API) + express-session (Admin) |
| Admin Panel | EJS + Bootstrap 5.3 |
| Container | Docker + Docker Compose |

## 📂 Proje Yapısı

```
geo-quest/
├── docker-compose.yml          # Container orchestration
├── .env.example                # Ortam değişkenleri şablonu
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   └── src/
│       ├── server.js           # Giriş noktası
│       ├── app.js              # Express yapılandırması
│       ├── config/
│       │   ├── db.js           # PostgreSQL bağlantısı
│       │   └── env.js          # Ortam değişkenleri
│       ├── middleware/
│       │   ├── auth.js         # JWT & session doğrulama
│       │   ├── upload.js       # Multer dosya yükleme
│       │   └── errorHandler.js
│       ├── models/
│       │   ├── User.js         # Kullanıcı (kayıt, login, streak)
│       │   ├── Quest.js        # Görev (CRUD, PostGIS sorguları)
│       │   ├── Submission.js   # Görev gönderimi
│       │   ├── Achievement.js  # 14 başarım tipi + otomatik kilit açma
│       │   ├── DailyChallenge.js # Günlük görev sistemi
│       │   ├── Friendship.js   # Arkadaşlık (istek, kabul, arama)
│       │   ├── Message.js      # Mesajlaşma + meydan okuma
│       │   ├── Notification.js # Bildirim sistemi
│       │   └── Activity.js     # Aktivite feed
│       ├── services/
│       │   └── gemini.js       # Gemini AI entegrasyonu
│       ├── routes/
│       │   ├── api/            # REST API endpoints
│       │   │   ├── auth.js     # POST /register, /login
│       │   │   ├── quests.js   # CRUD + AI üretim + ipucu
│       │   │   ├── submissions.js
│       │   │   ├── users.js    # Profil + leaderboard
│       │   │   ├── achievements.js
│       │   │   ├── friends.js  # Arkadaşlık yönetimi
│       │   │   ├── messages.js # Mesajlaşma
│       │   │   └── social.js   # Bildirimler + feed
│       │   └── web/            # Admin panel routes
│       ├── views/              # EJS şablonları (admin panel)
│       ├── public/             # CSS, uploads
│       └── db/
│           ├── init.sql        # Tablo oluşturma + PostGIS
│           ├── migrate-ai.sql  # AI kolonları
│           ├── migrate-achievements.sql
│           └── migrate-social.sql
└── mobile/
    └── geo_quest/
        └── lib/
            ├── main.dart
            ├── config/
            │   └── api_config.dart
            ├── models/
            │   ├── user.dart
            │   ├── quest.dart
            │   ├── submission.dart
            │   └── achievement.dart
            ├── providers/
            │   ├── auth_provider.dart
            │   ├── quest_provider.dart
            │   └── social_provider.dart
            ├── screens/          # 15 ekran
            │   ├── map_screen.dart
            │   ├── quest_detail_screen.dart
            │   ├── social_hub_screen.dart
            │   ├── chat_screen.dart
            │   ├── friends_screen.dart
            │   ├── achievements_screen.dart
            │   ├── leaderboard_screen.dart
            │   └── ...
            ├── services/
            │   ├── api_service.dart
            │   ├── auth_service.dart
            │   └── location_service.dart
            └── widgets/
                ├── quest_card.dart
                └── loading_widget.dart
```

## 🚀 Kurulum

### Gereksinimler

- [Docker](https://docker.com/) & Docker Compose
- [Flutter SDK](https://flutter.dev/) 3.x
- [Gemini API Key](https://aistudio.google.com/apikey) (opsiyonel — AI özellikleri için)

### 1. Repo'yu Klonlayın

```bash
git clone https://github.com/bcsakalar/geo-quest.git
cd geo-quest
```

### 2. Ortam Değişkenlerini Ayarlayın

```bash
cp .env.example .env
```

`.env` dosyasını düzenleyerek kendi değerlerinizi girin:

```env
POSTGRES_PASSWORD=guclu_bir_sifre
JWT_SECRET=rastgele_uzun_bir_string
SESSION_SECRET=baska_rastgele_bir_string
GEMINI_API_KEY=AIza...   # Google AI Studio'dan alın (opsiyonel)
```

### 3. Backend'i Başlatın

```bash
docker-compose up --build -d
```

Doğrulama:
```bash
docker logs geoquest-app
# ✓ Database connected
# ✓ Geo-Quest server running on http://localhost:4001
```

### 4. Veritabanı Migration'larını Çalıştırın

```bash
docker exec -i geoquest-db psql -U geoquest -d geoquest_db < backend/src/db/migrate-ai.sql
docker exec -i geoquest-db psql -U geoquest -d geoquest_db < backend/src/db/migrate-achievements.sql
docker exec -i geoquest-db psql -U geoquest -d geoquest_db < backend/src/db/migrate-social.sql
```

### 5. Flutter Uygulamasını Kurun

```bash
cd mobile/geo_quest
flutter pub get
```

**Emülatör için:**
```bash
flutter run
```

**Fiziksel cihaz için:**
1. `lib/config/api_config.dart` dosyasında IP'nizi güncelleyin:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:4001/api';
   ```
2. Telefon ve bilgisayar aynı WiFi ağında olmalı
3. `flutter build apk --debug` ile APK oluşturun

### 6. Admin Paneli

- **URL:** http://localhost:4001/admin
- **E-posta:** `admin@geoquest.com`
- **Şifre:** İlk kurulumda otomatik oluşturulur, loglardan kontrol edin

## 📡 API Endpoints

### Kimlik Doğrulama
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| POST | `/api/auth/register` | Kayıt ol |
| POST | `/api/auth/login` | Giriş yap |

### Görevler (JWT gerekli)
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/api/quests` | Tüm görevleri listele |
| GET | `/api/quests?lat=X&lng=Y&radius=Z` | Yakındaki görevler (PostGIS) |
| GET | `/api/quests/:id` | Görev detayı |
| POST | `/api/quests/:id/submit` | Görev gönderimi (multipart) |
| POST | `/api/quests/generate` | AI ile görev üret |
| GET | `/api/quests/:id/hint` | AI ipucu al |
| GET | `/api/quests/recommendations` | AI önerileri |

### Sosyal (JWT gerekli)
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/api/friends` | Arkadaş listesi |
| POST | `/api/friends/request` | Arkadaşlık isteği |
| GET | `/api/messages/:userId` | Mesaj geçmişi |
| POST | `/api/messages/:userId` | Mesaj gönder |
| GET | `/api/social/feed` | Aktivite feed |
| GET | `/api/social/notifications` | Bildirimler |

### Kullanıcı (JWT gerekli)
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/api/users/me` | Profil |
| GET | `/api/users/leaderboard` | Sıralama tablosu |
| GET | `/api/achievements` | Başarımlar |
| GET | `/api/achievements/daily` | Günlük görev |

## 📸 Ekran Görüntüleri

> Ekran görüntüleri eklenecek

---

# 🇬🇧 English

## 📌 About

Geo-Quest is a location-based adventure platform where users discover quests on a real-world map, take photos, answer questions, and scan QR codes. It features **Gemini AI** powered quest generation, social features, an achievement system, and real-time messaging.

### Key Features

| Feature | Description |
|---------|-------------|
| 🗺️ Map-Based Quests | Photo, question, and QR quests at real-world locations |
| 🤖 AI Quest Generation | Auto-generate quests near your location using Gemini AI |
| 📸 Photo Evaluation | AI-powered photo analysis and auto-approval |
| 👥 Social System | Friendships, messaging, activity feed |
| 🏆 Achievements & Streaks | 14 achievement types, daily challenges, streak tracking |
| 💬 Real-Time Messaging | Send challenges to friends |
| 📊 Leaderboard | Points-based ranking system |
| 🛡️ Admin Panel | Web-based quest and user management |
| 📍 PostGIS | Location-based proximity queries |

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│                    Flutter Mobile App                  │
│   (Map · Quests · Social · Achievements · Profile)    │
└──────────────────┬───────────────────────────────────┘
                   │ REST API (JWT Auth)
┌──────────────────▼───────────────────────────────────┐
│              Node.js + Express Backend                │
│   (API Routes · Admin Panel · Gemini AI Service)      │
└──────────────────┬───────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────┐
│          PostgreSQL 16 + PostGIS 3.4                  │
│   (Users · Quests · Submissions · Social · Achieve.)  │
└──────────────────────────────────────────────────────┘
```

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Node.js 20 + Express 4 |
| Database | PostgreSQL 16 + PostGIS 3.4 |
| AI | Google Gemini API (@google/genai) |
| Mobile | Flutter 3.x (Dart) |
| Maps | flutter_map + OpenStreetMap |
| Auth | JWT (API) + express-session (Admin) |
| Admin Panel | EJS + Bootstrap 5.3 |
| Containers | Docker + Docker Compose |

## 🚀 Getting Started

### Prerequisites

- [Docker](https://docker.com/) & Docker Compose
- [Flutter SDK](https://flutter.dev/) 3.x
- [Gemini API Key](https://aistudio.google.com/apikey) (optional — for AI features)

### 1. Clone the Repository

```bash
git clone https://github.com/bcsakalar/geo-quest.git
cd geo-quest
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
POSTGRES_PASSWORD=a_strong_password
JWT_SECRET=a_random_long_string
SESSION_SECRET=another_random_string
GEMINI_API_KEY=AIza...   # Get from Google AI Studio (optional)
```

### 3. Start the Backend

```bash
docker-compose up --build -d
```

Verify:
```bash
docker logs geoquest-app
# ✓ Database connected
# ✓ Geo-Quest server running on http://localhost:4001
```

### 4. Run Database Migrations

```bash
docker exec -i geoquest-db psql -U geoquest -d geoquest_db < backend/src/db/migrate-ai.sql
docker exec -i geoquest-db psql -U geoquest -d geoquest_db < backend/src/db/migrate-achievements.sql
docker exec -i geoquest-db psql -U geoquest -d geoquest_db < backend/src/db/migrate-social.sql
```

### 5. Set Up Flutter App

```bash
cd mobile/geo_quest
flutter pub get
```

**For emulator:**
```bash
flutter run
```

**For physical device:**
1. Update your IP in `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:4001/api';
   ```
2. Phone and computer must be on the same WiFi network
3. Build APK: `flutter build apk --debug`

### 6. Admin Panel

- **URL:** http://localhost:4001/admin
- **Email:** `admin@geoquest.com`
- **Password:** Auto-created on first run, check logs

## 📡 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login |

### Quests (JWT required)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/quests` | List all quests |
| GET | `/api/quests?lat=X&lng=Y&radius=Z` | Nearby quests (PostGIS) |
| GET | `/api/quests/:id` | Quest details |
| POST | `/api/quests/:id/submit` | Submit quest (multipart) |
| POST | `/api/quests/generate` | AI quest generation |
| GET | `/api/quests/:id/hint` | Get AI hint |
| GET | `/api/quests/recommendations` | AI recommendations |

### Social (JWT required)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/friends` | Friend list |
| POST | `/api/friends/request` | Send friend request |
| GET | `/api/messages/:userId` | Message history |
| POST | `/api/messages/:userId` | Send message |
| GET | `/api/social/feed` | Activity feed |
| GET | `/api/social/notifications` | Notifications |

### Users (JWT required)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/me` | Profile |
| GET | `/api/users/leaderboard` | Leaderboard |
| GET | `/api/achievements` | Achievements |
| GET | `/api/achievements/daily` | Daily challenge |

## 🗄️ Database Schema

### Core Tables

| Table | Description (TR) | Description (EN) |
|-------|-------------------|-------------------|
| `users` | Kullanıcılar, puanlar, streak | User accounts, points, streaks |
| `quests` | PostGIS konumlu görevler | Quest definitions with PostGIS locations |
| `submissions` | Görev gönderimleri | User quest submissions |
| `achievements` | Başarım tanımları | Achievement definitions |
| `user_achievements` | Açılan başarımlar | Unlocked achievements |
| `daily_challenges` | Günlük görev atamaları | Daily quest assignments |
| `friendships` | Arkadaşlık ilişkileri | Friend relationships |
| `messages` | Direkt mesajlar | Direct messages and challenges |
| `notifications` | Bildirimler | Notification records |
| `activities` | Sosyal aktivite feed | Social activity feed |

## 🔧 Troubleshooting / Sorun Giderme

### Docker
```bash
# Check running containers / Çalışan konteynerler
docker ps

# View logs / Logları görüntüle
docker logs geoquest-app -f
docker logs geoquest-db -f

# Restart / Yeniden başlat
docker-compose down
docker-compose up --build -d
```

### Flutter Connection / Bağlantı
- **Emulator:** Uses `10.0.2.2:4001` (Android emulator localhost)
- **Physical device:** Use computer's WiFi IP (`ipconfig` on Windows)
- Ensure port 4001 is not blocked by firewall
- Phone and computer must be on the same network

### PostGIS
```bash
docker exec -it geoquest-db psql -U geoquest -d geoquest_db -c "SELECT PostGIS_Version();"
```

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

**Built with ❤️ using Node.js, Flutter, PostgreSQL & Gemini AI**

</div>
