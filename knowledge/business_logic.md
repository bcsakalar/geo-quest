# 📋 Geo-Quest — İş Kuralları ve Kısıtlamalar

## Projenin Ana Amacı

Geo-Quest, kullanıcıların **gerçek dünya konumlarındaki görevleri** keşfedip tamamladığı konum tabanlı bir macera platformudur. Kullanıcılar harita üzerinde görevleri bulur, fotoğraf çeker, soruları cevaplar veya QR kodlarını tarar. Platform, **Gemini AI** ile otomatik görev üretimi ve fotoğraf değerlendirmesi sunar.

---

## Görev Sistemi (Quests)

### Görev Tipleri

| Tip | Tamamlama Yöntemi | Doğrulama |
|-----|-------------------|-----------|
| `photo` | Fotoğraf çekim | AI değerlendirme (≥60 puan = onay) veya admin onayı |
| `question` | Metin cevabı | Otomatik (case-insensitive, trimmed exact match) |
| `qr_code` | QR kod tarama | Otomatik (exact match: taranan veri === qr_data) |

### Görev Kuralları

- Her görevin bir **konumu** (lat/lng) ve **yarıçapı** (varsayılan 100m) vardır
- Kullanıcı görev yarıçapı içinde olmalıdır (mesafe kontrolü mobilde yapılır, uyarı gösterilir)
- Her kullanıcı her görevi **sadece bir kez** gönderebilir (`UNIQUE(user_id, quest_id)`)
- Görevler `is_active = true` olmalıdır
- Görevin `answer` ve `qr_data` alanları API yanıtlarında **gizlenir** (client'a gönderilmez)

### AI Görev Üretimi

- Kullanıcının mevcut konumuna yakın **3 görev** üretilir
- Rate limit: kullanıcı başına **dakikada 1** istek
- Kullanıcı başına toplam **50 AI görev** limiti
- `source = 'ai'`, `generated_for = userId` olarak işaretlenir
- Kullanıcının aktif AI görev sayısı **5'in altına düşerse**, görev tamamlandığında otomatik olarak yeni AI görevleri üretilir
- AI görevleri yalnızca `photo` ve `question` tipindedir (QR üretilmez)

### AI Fotoğraf Değerlendirmesi

- Gemini API fotoğrafı analiz eder
- **0-100 arası puan** verir
- `ai_score ≥ 60` → otomatik `approved`
- `ai_score < 60` → `pending` (admin incelemesi beklenir)
- `ai_evaluation` metin olarak kaydedilir

---

## Puan ve Streak Sistemi

### Puan Kazanma

| Eylem | Puan |
|-------|------|
| Görev tamamlama | Görevin `points` değeri × streak çarpanı |
| Başarım kilidi açma | Başarımın `points_reward` değeri |
| Günlük görev bonusu | `25` puan (DailyChallenge.bonus_points) |
| İpucu alma | **-2 puan** (hint kullanım maliyeti) |

### Streak (Seri) Sistemi

Ardışık günlerde görev tamamlamayı takip eder.

**Güncelleme kuralı** (`User.updateStreak()`):
```
bugün = CURRENT_DATE
fark = bugün - last_quest_date

fark = 1 gün → seri devam: current_streak++
fark = 0 gün → aynı gün: değişiklik yok
fark > 1 gün → seri kırıldı: current_streak = 1

max_streak = MAX(current_streak, max_streak)
last_quest_date = bugün
```

### Streak Çarpanı

| Streak | Çarpan | Etki |
|--------|--------|------|
| 0-2 gün | 1.0x | Normal |
| 3-6 gün | 1.25x | %25 bonus |
| 7-29 gün | 1.5x | %50 bonus |
| 30+ gün | 2.0x | %100 bonus |

Çarpan, kazanılan puanla çarpılır: `finalPoints = basePoints * multiplier`

---

## Başarım Sistemi (Achievements)

### Otomatik Kilit Açma Mekanizması

`Achievement.checkAndUnlock(userId)` her görev tamamlamada çağrılır:

1. Kullanıcının mevcut istatistikleri **paralel olarak** sorgulanır:
   - Toplam onaylı görev sayısı
   - Fotoğraf görevi sayısı
   - Soru görevi sayısı
   - AI görevi sayısı
   - Toplam puan
   - Mevcut streak
   - Tamamlanan günlük görev sayısı

2. Her başarım tanımı kontrol edilir
3. Koşul sağlanıyorsa ve daha önce açılmamışsa → kilit açılır + puan ödülü verilir

### Günlük Görev (Daily Challenge)

- Her kullanıcıya günde **bir görev** atanır (`UNIQUE(user_id, challenge_date)`)
- Atanan görev: kullanıcının **henüz tamamlamadığı** aktif bir görev
- Tamamlandığında **25 bonus puan** kazandırılır
- Görev yoksa veya tümü tamamlanmışsa → atama yapılmaz

---

## Sosyal Sistem

### Arkadaşlık Kuralları

- Kendine arkadaşlık isteği gönderilemez (`CHECK(requester_id != addressee_id)`)
- Mevcut bir ilişki varsa (herhangi bir durumda) yeni istek gönderilemez
- Her iki yön kontrol edilir (A→B veya B→A)
- **Status akışı**: `pending` → `accepted` / `rejected`
- `blocked` durumu mevcut ama aktif kullanılmıyor
- Arkadaş silme: kayıt tamamen `DELETE` edilir

### Mesajlaşma Kuralları

- Sadece **arkadaş** olan kullanıcılar mesajlaşabilir
- Mesaj tipleri: `text`, `challenge`, `system`
- Challenge mesajı: `quest_id` ile birlikte gönderilir
- Mesajlar **her iki tarafa da** sender → receiver
- **Okundu takibi**: alıcı tarafa ait `is_read` flag'i
- Konuşma alındığında mesajlar otomatik okundu olarak işaretlenir
- **Pagination**: `before` cursor ile (created_at < before, LIMIT 50)
- Mobilde **5 saniye polling** ile yeni mesaj kontrolü

### Bildirim Sistemi

| Event | Bildirim Tipi | Alıcı |
|-------|--------------|-------|
| Arkadaşlık isteği | `friend_request` | Addressee |
| İstek kabul | `friend_accepted` | Requester |
| Challenge mesajı | `challenge` | Receiver |
| Yeni mesaj | `message` | Receiver |
| Streak uyarısı | `streak_warning` | (Planlı) |
| Günlük görev | `daily_challenge` | (Planlı) |
| Başarım açıldı | `achievement` | User |
| Yakın görev | `nearby_quest` | (Planlı) |

- Bildirimler `is_read` flag'i ile takip edilir
- Toplu "hepsini okundu yap" özelliği var
- `data` JSONB alanında ek bilgi saklanır

### Aktivite Feed

- Arkadaşların aktiviteleri kronolojik sırada gösterilir
- **Pagination**: `before` cursor + LIMIT 20
- Feed tipleri: `quest_completed`, `achievement`, `streak`, `friendship`

---

## Kimlik Doğrulama (Auth)

### API Auth (Mobil Uygulama)

| Özellik | Değer |
|---------|-------|
| Yöntem | JWT (Bearer token) |
| Süre | 7 gün |
| Header | `Authorization: Bearer <token>` |
| Şifre hash | bcrypt (10 salt rounds) |
| Min şifre uzunluğu | 6 karakter |
| Token saklama | FlutterSecureStorage (mobil) |

**Kayıt/Giriş akışı**:
1. `POST /api/auth/register` veya `/login`
2. Şifre bcrypt ile doğrulanır
3. JWT token üretilir ve döner
4. Mobil uygulama token'ı SecureStorage'da saklar
5. Her istekte `Authorization: Bearer <token>` header'ı eklenir

### Admin Auth (Web Panel)

| Özellik | Değer |
|---------|-------|
| Yöntem | express-session |
| Süre | 24 saat (httpOnly cookie) |
| Rol kontrolü | `role = 'admin'` |
| Varsayılan admin | `admin@geoquest.com` / `admin123` |

---

## Admin Panel Yetkileri

| İşlem | Yetki | Route |
|-------|-------|-------|
| Görev oluştur | Admin | `POST /admin/quests/create` |
| Görev düzenle | Admin | `POST /admin/quests/:id/edit` |
| Görev sil | Admin | `POST /admin/quests/:id/delete` |
| Gönderi onayla | Admin | `POST /admin/submissions/:id/approve` |
| Gönderi reddet | Admin | `POST /admin/submissions/:id/reject` |
| Kullanıcıları gör | Admin | `GET /admin/users` |
| Dashboard istatistikleri | Admin | `GET /admin/dashboard` |

**Onay akışı**:
- Photo görevi AI tarafından `approved` edilebilir (`ai_score ≥ 60`)
- Photo görevi AI puanı düşükse `pending` kalır → admin incelemesi
- Question/QR görevleri otomatik doğrulanır
- Admin onayında → kullanıcıya puan eklenir (`User.addPoints`)

---

## Dosya Yükleme Kuralları

| Kural | Değer |
|-------|-------|
| İzin verilen MIME | `image/jpeg`, `image/png`, `image/webp` |
| Max boyut | 10 MB |
| Depolama | `backend/src/public/uploads/` |
| Dosya adı | `{random-hex}-{timestamp}.{ext}` (güvenlik) |
| Multer field adı | `photo` |

---

## Rate Limiting ve Kısıtlamalar

| Kısıt | Değer | Kontrol |
|-------|-------|---------|
| AI görev üretimi | 1 istek / dakika / kullanıcı | Son üretim zamanı kontrolü |
| Toplam AI görev | Max 50 / kullanıcı | DB count sorgusu |
| Hint (İpucu) | 2 puan maliyeti | `total_points >= 2` kontrolü |
| Günlük görev | 1 / gün / kullanıcı | `UNIQUE(user_id, challenge_date)` |
| Görev gönderimi | 1 / görev / kullanıcı | `UNIQUE(user_id, quest_id)` |
| Kullanıcı araması | Min 2 karakter | Query length kontrolü |
| Mesaj | Max 1000 karakter | (Mobilde kontrol) |

---

## Leaderboard

- Top 50 kullanıcı `total_points DESC` sırasıyla
- Sıralama `RANK() OVER (ORDER BY total_points DESC)` ile hesaplanır
- `GET /api/users/leaderboard` endpoint'i ile erişilir
