# 📂 Geo-Quest — Klasör ve Dosya Rehberi

## Kök Dizin

```
geo-quest/
├── .cursorrules                    # Cursor AI agent kuralları
├── .env                            # Ortam değişkenleri (git'e eklenMEZ)
├── .github/
│   └── copilot-instructions.md     # GitHub Copilot talimatları
├── AGENTS.md                       # Tüm AI ajanları için ana giriş noktası
├── MEMORY.md                       # Dinamik proje hafızası (TODO, hatalar, durum)
├── README.md                       # Proje tanıtım dokümanı
├── docker-compose.yml              # Docker servis tanımları (db + app)
├── knowledge/                      # Projeye özel bilgi bankası (AI için)
│   ├── architecture.md
│   ├── directory_structure.md      # (Bu dosya)
│   ├── database_and_state.md
│   ├── business_logic.md
│   ├── commands_and_scripts.md
│   └── testing_strategy.md
├── .agents/
│   └── skills/                     # Genel yazılım becerileri (framework-agnostik)
├── backend/                        # Node.js + Express backend
└── mobile/                         # Flutter mobil uygulama
```

---

## Backend (`backend/`)

```
backend/
├── Dockerfile                      # Production image (node:20-alpine)
├── package.json                    # Bağımlılıklar ve scriptler
└── src/
    ├── server.js                   # Entry point: DB bağlantı, admin seed, listen
    ├── app.js                      # Express yapılandırması, middleware, route mount
    │
    ├── config/
    │   ├── db.js                   # PostgreSQL Pool bağlantısı (max 20)
    │   └── env.js                  # .env yükleme, ortam değişkenleri export
    │
    ├── db/                         # SQL dosyaları (şema ve migration)
    │   ├── init.sql                # Temel tablolar: users, quests, submissions + PostGIS
    │   ├── seed.sql                # Seed verileri (şu an boş, admin server.js'de oluşturulur)
    │   ├── migrate-achievements.sql # achievements, user_achievements, daily_challenges + streak
    │   ├── migrate-ai.sql          # AI kolonları: source, generated_for, ai_evaluation, ai_score
    │   └── migrate-social.sql      # friendships, messages, notifications, activities + push_token
    │
    ├── middleware/
    │   ├── auth.js                 # requireAuth (JWT), requireAdmin (session)
    │   ├── errorHandler.js         # Merkezi hata yönetimi (API: JSON, Web: EJS)
    │   └── upload.js               # Multer: JPEG/PNG/WebP, max 10MB, rastgele dosya adı
    │
    ├── models/                     # Veri modelleri (statik metod pattern)
    │   ├── User.js                 # Kullanıcı: auth, puan, streak, leaderboard
    │   ├── Quest.js                # Görev: CRUD, PostGIS yakınlık, aktif filtreleme
    │   ├── Submission.js           # Gönderi: oluştur, listele, durum güncelle
    │   ├── Achievement.js          # Başarım: 14 tip, otomatik kilit açma, puan ödülü
    │   ├── DailyChallenge.js       # Günlük görev: atama, tamamlama, bonus puan
    │   ├── Friendship.js           # Arkadaşlık: istek gönder/kabul/ret, arama
    │   ├── Message.js              # Mesaj: metin/challenge/sistem, okundu takibi
    │   ├── Notification.js         # Bildirim: 8 tip, okunmamış sayacı
    │   └── Activity.js             # Aktivite feed: görev/başarım/streak/arkadaşlık
    │
    ├── routes/
    │   ├── api/                    # REST API (Mobil uygulama → JWT auth)
    │   │   ├── auth.js             # POST /api/auth/register, /login
    │   │   ├── quests.js           # GET/POST /api/quests, /:id/submit, /generate, /:id/hint
    │   │   ├── submissions.js      # GET /api/submissions/mine
    │   │   ├── users.js            # GET /api/users/me, /leaderboard
    │   │   ├── achievements.js     # GET /api/achievements, /check, /daily, /streak
    │   │   ├── friends.js          # GET/POST/DELETE /api/friends/*
    │   │   ├── messages.js         # GET/POST /api/messages/*
    │   │   └── social.js           # GET/POST /api/social/notifications, /feed, /unread
    │   │
    │   └── web/                    # Admin Web Panel (Session auth)
    │       ├── auth.js             # GET/POST /admin/login, /logout
    │       ├── dashboard.js        # GET /admin/dashboard (istatistikler)
    │       ├── quests.js           # CRUD /admin/quests/*
    │       ├── submissions.js      # GET /admin/submissions, POST approve/reject
    │       └── users.js            # GET /admin/users
    │
    ├── services/
    │   └── gemini.js               # Google Gemini AI: görev üretimi, fotoğraf analizi, ipucu
    │
    ├── utils/
    │   └── helpers.js              # hashPassword, comparePassword, signToken, verifyToken
    │
    ├── public/
    │   ├── css/
    │   │   └── style.css           # Admin panel stil dosyası
    │   ├── js/                     # (Boş — frontend JS varsa buraya)
    │   └── uploads/                # Yüklenen fotoğraflar (multer hedef dizini)
    │
    └── views/                      # EJS şablonları (Admin panel)
        ├── layouts/
        │   └── main.ejs            # Ana layout (Bootstrap 5.3, Leaflet, sidebar, header)
        ├── partials/
        │   ├── header.ejs          # Sayfa başlığı + sistem durumu badge
        │   └── sidebar.ejs         # Sol menü: Dashboard, Görevler, Gönderiler, Kullanıcılar
        ├── auth/
        │   └── login.ejs           # Admin giriş formu
        ├── dashboard.ejs           # Dashboard: 4 istatistik kartı + son gönderiler
        ├── error.ejs               # Hata sayfası
        ├── quests/
        │   ├── index.ejs           # Görev listesi tablosu
        │   ├── create.ejs          # Görev oluşturma (harita + form)
        │   └── edit.ejs            # Görev düzenleme (harita + form)
        ├── submissions/
        │   └── index.ejs           # Gönderiler: filtreli tablo + onay/ret
        └── users/
            └── index.ejs           # Kullanıcı listesi tablosu
```

---

## Mobile (`mobile/geo_quest/`)

```
mobile/geo_quest/
├── pubspec.yaml                    # Flutter bağımlılıkları ve proje yapılandırması
├── analysis_options.yaml           # Dart lint kuralları
├── android/                        # Android native yapılandırma
│   ├── app/build.gradle.kts
│   ├── build.gradle.kts
│   └── ...
│
├── lib/                            # Dart kaynak kodu
│   ├── main.dart                   # Uygulama giriş noktası (MultiProvider, MaterialApp, routes)
│   │
│   ├── config/
│   │   └── api_config.dart         # API base URL ve timeout ayarları
│   │
│   ├── models/                     # Veri modelleri (fromJson factory)
│   │   ├── user.dart               # User: id, email, name, role, totalPoints, streak
│   │   ├── quest.dart              # Quest: id, title, type, lat/lng, points, distance
│   │   ├── submission.dart         # Submission: id, status, photoUrl, aiScore
│   │   └── achievement.dart        # Achievement: key, title, icon, isUnlocked, pointsReward
│   │
│   ├── services/                   # API iletişim katmanı
│   │   ├── api_service.dart        # Singleton Dio instance + JWT interceptor
│   │   ├── auth_service.dart       # login, register, getProfile, logout
│   │   └── location_service.dart   # Konum izinleri, GPS, mesafe hesaplama
│   │
│   ├── providers/                  # State management (ChangeNotifier)
│   │   ├── auth_provider.dart      # Login, register, autoLogin, user state
│   │   ├── quest_provider.dart     # Görevler, gönderiler, leaderboard, başarımlar
│   │   └── social_provider.dart    # Arkadaşlar, mesajlar, bildirimler, feed
│   │
│   ├── screens/                    # Sayfa widgets
│   │   ├── splash_screen.dart      # Açılış ekranı (auto-login dener)
│   │   ├── login_screen.dart       # E-posta + şifre giriş formu
│   │   ├── register_screen.dart    # Kayıt formu (isim + e-posta + şifre)
│   │   ├── home_screen.dart        # Ana ekran: BottomNav (5 tab) + bildirim badge
│   │   ├── map_screen.dart         # Harita: quest marker, konum, AI üretim FAB
│   │   ├── quest_detail_screen.dart# Görev detay: fotoğraf/soru/QR gönderimi, ipucu
│   │   ├── profile_screen.dart     # Profil: puan, streak, gönderi istatistikleri
│   │   ├── achievements_screen.dart# Başarımlar: streak, günlük görev, grid
│   │   ├── social_hub_screen.dart  # Sosyal merkez: Feed, Mesajlar, Arkadaşlar tabs
│   │   ├── friends_screen.dart     # Arkadaş listesi, istekler, kullanıcı arama
│   │   └── chat_screen.dart        # Mesajlaşma (5s polling, challenge gönderme)
│   │
│   └── widgets/                    # Tekrar kullanılan UI bileşenleri
│       ├── loading_widget.dart     # Merkezi yükleniyor göstergesi
│       └── quest_card.dart         # Görev listesi kartı (tip ikonu, mesafe, tamamlanmış)
│
├── test/
│   └── widget_test.dart            # Varsayılan Flutter test dosyası
│
└── build/                          # Build çıktıları (git'e eklenMEZ)
```

---

## Önemli Dosya Yolu Referansları

### Backend'de Yeni Bir Bileşen Eklerken

| Bileşen | Oluşturulacak Dosya | Bağlanacağı Yer |
|---------|---------------------|-----------------|
| Yeni Model | `backend/src/models/YeniModel.js` | İlgili route dosyasında `require` |
| Yeni API Route | `backend/src/routes/api/yeni.js` | `backend/src/app.js` → `app.use('/api/yeni', ...)` |
| Yeni Web Route | `backend/src/routes/web/yeni.js` | `backend/src/app.js` → `app.use('/admin/yeni', ...)` |
| Yeni Middleware | `backend/src/middleware/yeni.js` | İlgili route'da `require` ve `app.use` |
| Yeni View | `backend/src/views/yeni/index.ejs` | İlgili web route'da `res.render('yeni/index')` |
| Yeni Service | `backend/src/services/yeni.js` | İlgili route/model'de `require` |

### Mobile'da Yeni Bir Bileşen Eklerken

| Bileşen | Oluşturulacak Dosya | Bağlanacağı Yer |
|---------|---------------------|-----------------|
| Yeni Model | `lib/models/yeni_model.dart` | Provider veya service'de import |
| Yeni Screen | `lib/screens/yeni_screen.dart` | `main.dart` routes veya `Navigator.push` |
| Yeni Provider | `lib/providers/yeni_provider.dart` | `main.dart` → `MultiProvider` |
| Yeni Widget | `lib/widgets/yeni_widget.dart` | İlgili screen'de import |
| Yeni Service | `lib/services/yeni_service.dart` | İlgili provider'da import |
