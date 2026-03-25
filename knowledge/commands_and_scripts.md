# ⚙️ Geo-Quest — Komutlar ve Scriptler

## Ön Koşullar

| Araç | Minimum Versiyon | Kurulum |
|------|-----------------|---------|
| Docker Desktop | 20+ | [docker.com](https://docker.com) |
| Docker Compose | v2+ | Docker Desktop ile gelir |
| Node.js | 20+ | [nodejs.org](https://nodejs.org) (lokal geliştirme için) |
| Flutter SDK | 3.x | [flutter.dev](https://flutter.dev) (mobil geliştirme için) |
| Git | herhangi | [git-scm.com](https://git-scm.com) |

## Ortam Değişkenleri

Kök dizinde `.env` dosyası oluşturulmalıdır:

```env
# ──── Genel ────
NODE_ENV=development
PORT=4001

# ──── PostgreSQL ────
POSTGRES_USER=geoquest
POSTGRES_PASSWORD=geoquest_secret
POSTGRES_DB=geoquest
POSTGRES_HOST=db          # Docker içi: 'db', Lokal: 'localhost'
POSTGRES_PORT=5432         # Docker içi: 5432

# ──── Auth ────
JWT_SECRET=your-jwt-secret-here
SESSION_SECRET=your-session-secret-here

# ──── AI ────
GEMINI_API_KEY=your-gemini-api-key-here
```

> **ÖNEMLİ**: `.env` dosyası `.gitignore`'da olmalı, **asla commit edilmemelidir**.

---

## Docker ile Çalıştırma (Önerilen)

### Tüm Sistemi Başlatma

```bash
# Kök dizinde:
docker-compose up -d
```

Bu komut:
1. `postgis/postgis:16-3.4` PostgreSQL container'ı başlatır
2. `init.sql` ile temel tabloları oluşturur
3. Backend uygulamasını build eder ve başlatır
4. Admin kullanıcısı otomatik oluşturulur: `admin@geoquest.com` / `admin123`

### Migration Dosyalarını Çalıştırma

Migration dosyaları Docker entrypoint'e **otomatik olarak eklenmez**. İlk kurulumda veya yeni migration eklendiğinde manuel çalıştırılmalıdır:

```bash
# Başarım & streak sistemi
docker exec -i geoquest-db psql -U geoquest -d geoquest < backend/src/db/migrate-achievements.sql

# AI kolonları
docker exec -i geoquest-db psql -U geoquest -d geoquest < backend/src/db/migrate-ai.sql

# Sosyal sistem (arkadaşlık, mesajlaşma, bildirimler)
docker exec -i geoquest-db psql -U geoquest -d geoquest < backend/src/db/migrate-social.sql
```

### Container Yönetimi

```bash
# Durumu kontrol et
docker-compose ps

# Logları izle
docker-compose logs -f           # Tüm servisler
docker-compose logs -f app       # Sadece backend
docker-compose logs -f db        # Sadece veritabanı

# Yeniden başlat
docker-compose restart app       # Sadece backend
docker-compose restart            # Tüm servisler

# Durdur
docker-compose down              # Container'ları durdur
docker-compose down -v           # Container'ları ve verileri sil (DİKKAT!)

# Yeniden build et (kod değişikliği sonrası)
docker-compose up -d --build app
```

### Veritabanına Bağlanma

```bash
# psql ile interaktif bağlantı (Docker içinden)
docker exec -it geoquest-db psql -U geoquest -d geoquest

# Dışarıdan bağlantı (port 5434)
psql -h localhost -p 5434 -U geoquest -d geoquest
```

### Faydalı SQL Komutları

```sql
-- Tablo listesi
\dt

-- Tablo şeması
\d users
\d quests
\d submissions

-- Kullanıcı sayısı
SELECT COUNT(*) FROM users;

-- Aktif görev sayısı
SELECT COUNT(*) FROM quests WHERE is_active = true;

-- Bekleyen gönderimler
SELECT s.*, u.name, q.title
FROM submissions s
JOIN users u ON s.user_id = u.id
JOIN quests q ON s.quest_id = q.id
WHERE s.status = 'pending';

-- Yakınlık sorgusu örneği (500m içinde)
SELECT id, title, ST_Distance(location, ST_SetSRID(ST_MakePoint(29.0, 41.0), 4326)::geography) AS distance
FROM quests
WHERE is_active = true
AND ST_DWithin(location, ST_SetSRID(ST_MakePoint(29.0, 41.0), 4326)::geography, 500);
```

---

## Lokal Geliştirme (Docker'sız)

### Backend

```bash
cd backend

# Bağımlılıkları yükle
npm install

# Geliştirme modunda başlat (--watch ile hot-reload)
npm run dev

# Üretim modunda başlat
npm start
```

> **Not**: Lokal geliştirmede PostgreSQL ayrıca çalışıyor olmalıdır. `.env` dosyasında `POSTGRES_HOST=localhost`, `POSTGRES_PORT=5434` (Docker DB kullanıyorsanız) ayarlayın.

### Sadece Veritabanını Docker ile Çalıştırma

```bash
# Sadece DB container'ını başlat
docker-compose up -d db

# Ardından backend'i lokalde çalıştır
cd backend
npm run dev
```

Bu durumda `.env`'de:
```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5434
```

---

## Flutter Mobil Uygulama

### İlk Kurulum

```bash
cd mobile/geo_quest

# Bağımlılıkları yükle
flutter pub get

# Cihazları listele
flutter devices
```

### API URL Yapılandırması

`mobile/geo_quest/lib/config/api_config.dart` dosyasını **kendi LAN IP adresinize** göre düzenleyin:

```dart
static const String baseUrl = 'http://192.168.1.XXX:4001/api';
```

LAN IP'nizi bulmak için:
```bash
# Windows
ipconfig

# macOS/Linux
ifconfig | grep "inet "
```

### Çalıştırma

```bash
cd mobile/geo_quest

# Debug modda çalıştır
flutter run

# Belirli bir cihazda çalıştır
flutter run -d <device_id>

# Release build
flutter build apk             # Android APK
flutter build appbundle        # Android App Bundle
```

### Analiz ve Lint

```bash
cd mobile/geo_quest

# Dart analiz
flutter analyze

# Format kontrol
dart format lib/

# Testleri çalıştır
flutter test
```

---

## Test Komutları

### Backend Testleri

> **Not**: Proje henüz bir test framework'ü içermiyor. Test altyapısı kurulması gerekiyor. Önerilen kurulum için `knowledge/testing_strategy.md` dosyasına bakın.

Planlanan test komutları:
```bash
cd backend

# Tüm testleri çalıştır
npm test

# Watch modda
npm run test:watch

# Coverage raporu
npm run test:coverage
```

### Flutter Testleri

```bash
cd mobile/geo_quest

# Tüm testleri çalıştır
flutter test

# Belirli bir test dosyası
flutter test test/widget_test.dart

# Coverage
flutter test --coverage
```

---

## Proje Scriptleri (package.json)

```json
{
  "scripts": {
    "start": "node src/server.js",
    "dev": "node --watch src/server.js"
  }
}
```

| Script | Komut | Açıklama |
|--------|-------|----------|
| `npm start` | `node src/server.js` | Üretim modu |
| `npm run dev` | `node --watch src/server.js` | Geliştirme modu (dosya değişikliğinde restart) |

---

## Erişim Bilgileri

| Servis | URL | Kullanıcı |
|--------|-----|-----------|
| Admin Panel | `http://localhost:4001/admin` | `admin@geoquest.com` / `admin123` |
| API Base | `http://localhost:4001/api` | JWT token gerekli |
| PostgreSQL | `localhost:5434` | `.env` dosyasındaki bilgilerle |
| Mobil → API | `http://<LAN_IP>:4001/api` | JWT token gerekli |

---

## Sık Karşılaşılan Sorunlar

### Container başlamıyor
```bash
# Container loglarını kontrol et
docker-compose logs app

# DB sağlık kontrolü
docker exec geoquest-db pg_isready -U geoquest

# Container'ları yeniden oluştur
docker-compose down
docker-compose up -d --build
```

### Mobil uygulama API'ye bağlanamıyor
1. Backend'in çalıştığını doğrula: `curl http://localhost:4001/api/quests`
2. `api_config.dart`'taki IP adresini kontrol et
3. Mobil cihaz ve bilgisayarın aynı ağda olduğundan emin ol
4. Firewall portunu kontrol et (4001)

### Veritabanı bağlantı hatası
```bash
# DB container durumunu kontrol et
docker-compose ps db

# Manuel bağlantı testi
docker exec -it geoquest-db psql -U geoquest -d geoquest -c "SELECT 1"
```
