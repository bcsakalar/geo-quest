# 🏗️ Geo-Quest — Mimari ve Veri Akışı

## Genel Bakış

Geo-Quest, **üç katmanlı** bir mimari kullanır:

```
┌──────────────────────────────────────────────────────┐
│                    Flutter Mobile App                  │
│  (Provider State · Dio HTTP · flutter_map · Geolocator)│
└──────────────────┬───────────────────────────────────┘
                   │ REST API (JSON / JWT Auth)
                   │ Base URL: http://<IP>:4001/api
┌──────────────────▼───────────────────────────────────┐
│              Node.js 20 + Express 4 Backend           │
│  ┌─────────────────────────────────────────────────┐  │
│  │ API Routes (/api/*)    │ Web Routes (/admin/*)  │  │
│  │ JWT Authentication     │ Session Authentication │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ Models (Static Pattern)                         │  │
│  │ User · Quest · Submission · Achievement         │  │
│  │ DailyChallenge · Friendship · Message           │  │
│  │ Notification · Activity                         │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ Services                                        │  │
│  │ Gemini AI (görev üretimi, fotoğraf analizi)     │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ Middleware                                      │  │
│  │ auth · upload · errorHandler                    │  │
│  └─────────────────────────────────────────────────┘  │
└──────────────────┬───────────────────────────────────┘
                   │ pg Pool (max 20 conn)
┌──────────────────▼───────────────────────────────────┐
│          PostgreSQL 16 + PostGIS 3.4                  │
│  Tables: users, quests, submissions, achievements,    │
│  user_achievements, daily_challenges, friendships,    │
│  messages, notifications, activities                  │
│  Extension: postgis (GEOGRAPHY, ST_DWithin, GIST)    │
└──────────────────────────────────────────────────────┘
```

## Katmanlar

### 1. Mobil Uygulama (Flutter)

| Bileşen | Teknoloji | Açıklama |
|---------|-----------|----------|
| State Management | Provider (ChangeNotifier) | `AuthProvider`, `QuestProvider`, `SocialProvider` |
| HTTP Client | Dio 5.7 (Singleton) | `ApiService` ile JWT interceptor |
| Harita | flutter_map 7 + OpenStreetMap | Görev markerları, kullanıcı konumu |
| Konum | Geolocator 13 | GPS izin yönetimi, mesafe hesaplama |
| Kamera | image_picker 1.1 | Fotoğraf görevi çekimi |
| QR | mobile_scanner 6 | QR kod tarama |
| Token Saklama | flutter_secure_storage 9.2 | JWT token güvenli depolama |

**Veri Akışı (Mobil):**
```
Kullanıcı Etkileşimi
    → Screen (Widget)
        → Provider (ChangeNotifier + notifyListeners)
            → Service (Dio HTTP → REST API)
                → Response → Provider state güncelleme
                    → UI rebuild
```

### 2. Backend (Node.js + Express)

**İki ayrı arayüz sunar:**

#### a) REST API (`/api/*`) — Mobil Uygulama İçin
- **Auth**: JWT Bearer token (7 gün süreli)
- **Format**: JSON request/response
- **Middleware**: `requireAuth` (JWT doğrulama)
- **Dosya Yükleme**: Multer (multipart/form-data)

#### b) Web Admin Panel (`/admin/*`) — Yönetim İçin
- **Auth**: express-session (24 saat, httpOnly cookie)
- **View Engine**: EJS + express-ejs-layouts
- **UI**: Bootstrap 5.3 + Leaflet haritalar
- **Middleware**: `requireAdmin` (session kontrolü)

**Request Yaşam Döngüsü (API):**
```
HTTP İsteği
    → Express Middleware (JSON parse, cookie, session)
        → Route Handler
            → requireAuth middleware (JWT doğrulama)
                → Controller Lojik
                    → Model (SQL Query → PostgreSQL)
                        → Response (JSON)
```

**Model Pattern — Statik Metodlar:**
```javascript
// Her model kendi SQL sorgularını yönetir
const user = await User.findByEmail('user@example.com');
const quests = await Quest.findNearby(lat, lng, radius);
const submission = await Submission.create({ userId, questId, ... });
```

### 3. Veritabanı (PostgreSQL + PostGIS)

- **Bağlantı**: `pg` Pool (max 20 bağlantı, 30s idle timeout)
- **Spatial**: PostGIS GEOGRAPHY tipi, ST_DWithin ile yakınlık sorgusu
- **Index**: GIST spatial index, B-tree standart indexler
- **Trigger**: `trg_quest_location` — lat/lng'den otomatik GEOGRAPHY hesaplama

## Entegrasyonlar

### Google Gemini AI

```
Mobil App                Backend                      Gemini API
   │                        │                            │
   ├─ POST /quests/generate─▶ gemini.generateQuests() ──▶ Yapılandırılmış JSON
   │                        │◀──────────── 3 adet görev ─┤
   │                        ├─ Quest.create() x3         │
   │◀── quests[] response ──┤                            │
   │                        │                            │
   ├─ POST /quests/:id/submit (photo) ──────────────────▶│
   │                        ├─ gemini.evaluatePhoto() ──▶ score (0-100)
   │                        │◀──── ai_evaluation + score─┤
   │◀── submission response─┤                            │
```

**Gemini Kullanım Alanları:**
1. **Görev Üretimi**: Kullanıcının konumuna yakın 3 görev üretir (photo/question tipi)
2. **Fotoğraf Değerlendirme**: Gönderilen fotoğrafı göreve uygunluk açısından puanlar (0-100, ≥60 = onay)
3. **İpucu Üretimi**: Görev için cevabı açık etmeden yardımcı ipucu
4. **Kişisel Öneriler**: Tamamlanan görevlere göre yeni görev önerileri

### Docker Compose Akışı

```
docker-compose up -d
    │
    ├─ db (postgis/postgis:16-3.4)
    │   ├─ 01-init.sql       → Temel tablolar (users, quests, submissions)
    │   ├─ 02-seed.sql       → Boş (admin server.js'de seed edilir)
    │   └─ healthcheck       → pg_isready
    │
    └─ app (node:20-alpine)  ← depends_on: db (healthy)
        ├─ npm install --omit=dev
        ├─ server.js → DB bağlantısı doğrula → Admin seed → Listen :4001
        └─ Volume: ./backend/src → /app/src (dev hot-reload)
```

**Not**: Migration dosyaları (`migrate-achievements.sql`, `migrate-ai.sql`, `migrate-social.sql`) docker-entrypoint'e ekli **değildir**. Bu dosyalar manuel çalıştırılmalıdır:
```bash
docker exec -i geoquest-db psql -U $POSTGRES_USER -d $POSTGRES_DB < backend/src/db/migrate-achievements.sql
docker exec -i geoquest-db psql -U $POSTGRES_USER -d $POSTGRES_DB < backend/src/db/migrate-ai.sql
docker exec -i geoquest-db psql -U $POSTGRES_USER -d $POSTGRES_DB < backend/src/db/migrate-social.sql
```

## Portlar ve Erişim

| Servis | İç Port | Dış Port | URL |
|--------|---------|----------|-----|
| PostgreSQL | 5432 | 5434 | `localhost:5434` |
| Backend API | 4001 | 4001 | `http://localhost:4001/api` |
| Admin Panel | 4001 | 4001 | `http://localhost:4001/admin` |
| Mobil → Backend | — | 4001 | `http://<LAN_IP>:4001/api` |

## Güvenlik Mimarisi

```
Mobile App                          Backend
   │                                   │
   ├─ POST /api/auth/login ──────────▶ bcrypt.compare() → JWT sign (7d)
   │◀─────────── { token, user } ─────┤
   │                                   │
   ├─ GET /api/quests ────────────────▶ requireAuth → jwt.verify()
   │  Authorization: Bearer <token>    │    ├─ 200 + data (geçerli)
   │◀──────────────────────────────────┤    └─ 401 (geçersiz)
   │                                   │
   │         Admin Browser             │
   │              │                    │
   │              ├─ POST /admin/login ▶ bcrypt.compare() → session set
   │              │◀─── redirect ──────┤
   │              ├─ GET /admin/* ─────▶ requireAdmin → session check
   │              │◀─── EJS render ────┤
```
