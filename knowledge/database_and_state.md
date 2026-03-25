# 🗄️ Geo-Quest — Veritabanı Şemaları ve State Management

## Veritabanı Genel Bilgi

| Özellik | Değer |
|---------|-------|
| Motor | PostgreSQL 16 |
| Extension | PostGIS 3.4 |
| Bağlantı | pg Pool (max 20, idle 30s, connect timeout 5s) |
| Docker Port | Dış: 5434, İç: 5432 |
| Spatial Index | GIST (`idx_quests_location`) |

---

## Tablolar ve Şemalar

### 1. `users` — Kullanıcılar

| Kolon | Tip | Kısıt | Varsayılan | Açıklama |
|-------|-----|-------|-----------|----------|
| `id` | SERIAL | PK | auto | |
| `email` | VARCHAR(255) | UNIQUE NOT NULL | — | |
| `password_hash` | VARCHAR(255) | NOT NULL | — | bcrypt hash |
| `name` | VARCHAR(100) | NOT NULL | — | |
| `role` | VARCHAR(20) | NOT NULL | `'user'` | `user` veya `admin` |
| `total_points` | INT | NOT NULL | `0` | Toplam puan |
| `current_streak` | INT | NOT NULL | `0` | Güncel ardışık gün serisi |
| `max_streak` | INT | NOT NULL | `0` | En yüksek seri |
| `last_quest_date` | DATE | — | NULL | Son görev tamamlama tarihi |
| `push_token` | TEXT | — | NULL | FCM push token |
| `last_active_at` | TIMESTAMP | — | `NOW()` | Son aktiflik |
| `avatar_color` | VARCHAR(7) | — | `'#4CAF50'` | Profil rengi |
| `created_at` | TIMESTAMP | NOT NULL | `NOW()` | |

**Kaynak SQL**: `init.sql` (temel), `migrate-achievements.sql` (streak), `migrate-social.sql` (push/avatar)

---

### 2. `quests` — Görevler

| Kolon | Tip | Kısıt | Varsayılan | Açıklama |
|-------|-----|-------|-----------|----------|
| `id` | SERIAL | PK | auto | |
| `title` | VARCHAR(255) | NOT NULL | — | |
| `description` | TEXT | — | — | |
| `type` | VARCHAR(50) | NOT NULL, CHECK | — | `photo`, `qr_code`, `question` |
| `latitude` | DOUBLE PRECISION | NOT NULL | — | |
| `longitude` | DOUBLE PRECISION | NOT NULL | — | |
| `location` | GEOGRAPHY(POINT,4326) | — | — | Trigger ile otomatik hesaplanır |
| `radius_meters` | INT | NOT NULL | `100` | Görev yarıçapı (metre) |
| `points` | INT | NOT NULL | `10` | Kazandırdığı puan |
| `question` | TEXT | — | — | Soru tipi görevler için |
| `answer` | TEXT | — | — | Doğru cevap |
| `qr_data` | TEXT | — | — | QR taranacak veri |
| `is_active` | BOOLEAN | NOT NULL | `true` | |
| `source` | VARCHAR(20) | NOT NULL | `'manual'` | `manual` veya `ai` |
| `generated_for` | INT | FK→users | NULL | AI görev hangi kullanıcı için üretildi |
| `created_by` | INT | FK→users | NULL | Oluşturan admin |
| `created_at` | TIMESTAMP | NOT NULL | `NOW()` | |

**Indexler**: `idx_quests_location` (GIST), `idx_quests_active`, `idx_quests_source`, `idx_quests_generated_for`

**Trigger**: `trg_quest_location` — INSERT/UPDATE'de lat+lng'den location geography otomatik hesaplanır:
```sql
NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
```

---

### 3. `submissions` — Görev Gönderimleri

| Kolon | Tip | Kısıt | Varsayılan | Açıklama |
|-------|-----|-------|-----------|----------|
| `id` | SERIAL | PK | auto | |
| `user_id` | INT | FK→users NOT NULL | — | |
| `quest_id` | INT | FK→quests NOT NULL | — | |
| `status` | VARCHAR(20) | NOT NULL, CHECK | `'pending'` | `pending`, `approved`, `rejected` |
| `photo_url` | TEXT | — | — | Fotoğraf yolu |
| `answer_text` | TEXT | — | — | Soru cevabı |
| `qr_scanned_data` | TEXT | — | — | Taranan QR verisi |
| `ai_evaluation` | TEXT | — | — | AI değerlendirme metni |
| `ai_score` | INT | — | — | AI puanı (0-100) |
| `submitted_at` | TIMESTAMP | NOT NULL | `NOW()` | |
| `reviewed_at` | TIMESTAMP | — | — | |
| `reviewed_by` | INT | FK→users | NULL | Onaylayan admin |

**Kısıt**: `UNIQUE(user_id, quest_id)` — Her kullanıcı her görev için tek gönderi

---

### 4. `achievements` — Başarım Tanımları

| Kolon | Tip | Kısıt | Varsayılan | Açıklama |
|-------|-----|-------|-----------|----------|
| `id` | SERIAL | PK | auto | |
| `key` | VARCHAR(50) | UNIQUE NOT NULL | — | Tanımlayıcı (first_quest, streak_7 vb.) |
| `title` | VARCHAR(100) | NOT NULL | — | Başarım adı |
| `description` | TEXT | NOT NULL | — | Açıklama |
| `icon` | VARCHAR(50) | NOT NULL | `'emoji_events'` | Material icon adı |
| `color` | VARCHAR(20) | NOT NULL | `'#FFD700'` | HEX renk kodu |
| `required_count` | INT | NOT NULL | `1` | Kilit açma eşiği |
| `points_reward` | INT | NOT NULL | `5` | Kazandırdığı bonus puan |

**Başarım listesi (14 adet)**:
| Key | Açıklama | Gerekli | Puan |
|-----|----------|---------|------|
| `first_quest` | İlk görev | 1 | 10 |
| `quest_5` | 5 görev | 5 | 25 |
| `quest_10` | 10 görev | 10 | 50 |
| `quest_25` | 25 görev | 25 | 100 |
| `photo_5` | 5 fotoğraf görevi | 5 | 30 |
| `question_5` | 5 soru görevi | 5 | 30 |
| `ai_explorer` | İlk AI görevi | 1 | 15 |
| `ai_master` | 10 AI görevi | 10 | 50 |
| `streak_3` | 3 günlük seri | 3 | 20 |
| `streak_7` | 7 günlük seri | 7 | 50 |
| `streak_30` | 30 günlük seri | 30 | 150 |
| `daily_5` | 5 günlük meydan okuma | 5 | 30 |
| `points_100` | 100 puan topla | 100 | 10 |
| `points_500` | 500 puan topla | 500 | 50 |

---

### 5. `user_achievements` — Kullanıcı Başarımları

| Kolon | Tip | Kısıt | Varsayılan |
|-------|-----|-------|-----------|
| `id` | SERIAL | PK | auto |
| `user_id` | INT | FK→users NOT NULL | — |
| `achievement_id` | INT | FK→achievements NOT NULL | — |
| `unlocked_at` | TIMESTAMP | NOT NULL | `NOW()` |

**Kısıt**: `UNIQUE(user_id, achievement_id)`

---

### 6. `daily_challenges` — Günlük Görevler

| Kolon | Tip | Kısıt | Varsayılan |
|-------|-----|-------|-----------|
| `id` | SERIAL | PK | auto |
| `user_id` | INT | FK→users NOT NULL | — |
| `quest_id` | INT | FK→quests NOT NULL | — |
| `challenge_date` | DATE | NOT NULL | `CURRENT_DATE` |
| `completed` | BOOLEAN | NOT NULL | `false` |
| `bonus_points` | INT | NOT NULL | `10` |

**Kısıt**: `UNIQUE(user_id, challenge_date)` — Günde bir görev

---

### 7. `friendships` — Arkadaşlıklar

| Kolon | Tip | Kısıt | Varsayılan |
|-------|-----|-------|-----------|
| `id` | SERIAL | PK | auto |
| `requester_id` | INT | FK→users NOT NULL | — |
| `addressee_id` | INT | FK→users NOT NULL | — |
| `status` | VARCHAR(20) | NOT NULL, CHECK | `'pending'` |
| `created_at` | TIMESTAMP | NOT NULL | `NOW()` |
| `updated_at` | TIMESTAMP | NOT NULL | `NOW()` |

**Kısıtlar**: `UNIQUE(requester_id, addressee_id)`, `CHECK(requester_id != addressee_id)`
**Status değerleri**: `pending`, `accepted`, `rejected`, `blocked`

---

### 8. `messages` — Mesajlar

| Kolon | Tip | Kısıt | Varsayılan |
|-------|-----|-------|-----------|
| `id` | SERIAL | PK | auto |
| `sender_id` | INT | FK→users NOT NULL | — |
| `receiver_id` | INT | FK→users NOT NULL | — |
| `content` | TEXT | NOT NULL | — |
| `is_read` | BOOLEAN | NOT NULL | `false` |
| `message_type` | VARCHAR(20) | NOT NULL, CHECK | `'text'` |
| `quest_id` | INT | FK→quests | NULL |
| `created_at` | TIMESTAMP | NOT NULL | `NOW()` |

**Kısıt**: `CHECK(sender_id != receiver_id)`
**Message tipleri**: `text`, `challenge`, `system`

---

### 9. `notifications` — Bildirimler

| Kolon | Tip | Kısıt | Varsayılan |
|-------|-----|-------|-----------|
| `id` | SERIAL | PK | auto |
| `user_id` | INT | FK→users NOT NULL | — |
| `type` | VARCHAR(50) | NOT NULL | — |
| `title` | TEXT | NOT NULL | — |
| `body` | TEXT | NOT NULL | — |
| `data` | JSONB | — | `'{}'` |
| `is_read` | BOOLEAN | NOT NULL | `false` |
| `created_at` | TIMESTAMP | NOT NULL | `NOW()` |

**Bildirim tipleri**: `friend_request`, `friend_accepted`, `challenge`, `message`, `streak_warning`, `daily_challenge`, `achievement`, `nearby_quest`

---

### 10. `activities` — Aktivite Feed

| Kolon | Tip | Kısıt | Varsayılan |
|-------|-----|-------|-----------|
| `id` | SERIAL | PK | auto |
| `user_id` | INT | FK→users NOT NULL | — |
| `type` | VARCHAR(50) | NOT NULL | — |
| `description` | TEXT | NOT NULL | — |
| `data` | JSONB | — | `'{}'` |
| `created_at` | TIMESTAMP | NOT NULL | `NOW()` |

**Aktivite tipleri**: `quest_completed`, `achievement`, `streak`, `friendship`

---

## ER Diyagramı (İlişkiler)

```
users ──────────┬──── submissions ──── quests
   │            │
   ├──── user_achievements ──── achievements
   │
   ├──── daily_challenges ──── quests
   │
   ├──── friendships (requester_id, addressee_id)
   │
   ├──── messages (sender_id, receiver_id)
   │         └──── quests (challenge mesajları)
   │
   ├──── notifications
   │
   └──── activities
```

---

## State Management (Flutter — Provider)

### Provider Hiyerarşisi

```dart
// main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),   // Auth state
    ChangeNotifierProvider(create: (_) => QuestProvider()),  // Quest/game state
    ChangeNotifierProvider(create: (_) => SocialProvider()), // Social state
  ],
  child: MaterialApp(...)
)
```

### AuthProvider State

| State | Tip | Açıklama |
|-------|-----|----------|
| `_user` | `User?` | Giriş yapan kullanıcı |
| `_isLoading` | `bool` | İşlem devam ediyor mu |
| `_error` | `String?` | Son hata mesajı |
| `isLoggedIn` | `bool` (getter) | `_user != null` |

**Metodlar**: `login()`, `register()`, `loadProfile()`, `logout()`, `tryAutoLogin()`

### QuestProvider State

| State | Tip | Açıklama |
|-------|-----|----------|
| `_quests` | `List<Quest>` | Aktif görevler |
| `_submissions` | `List<Submission>` | Kullanıcının gönderimleri |
| `_leaderboard` | `List<Map>` | Sıralama tablosu |
| `_achievements` | `List<Achievement>` | Tüm başarımlar |
| `_dailyChallenge` | `Map?` | Günlük görev |
| `_streakInfo` | `Map?` | Streak bilgisi |
| `_recommendations` | `List<Quest>` | AI önerileri |
| `_isLoading` | `bool` | İşlem devam ediyor mu |

**Metodlar**: `loadQuests()`, `submitQuest()`, `generateQuests()`, `getHint()`, `loadSubmissions()`, `loadLeaderboard()`, `loadAchievements()`, `loadDailyChallenge()`, `loadStreakInfo()`, `loadRecommendations()`

### SocialProvider State

| State | Tip | Açıklama |
|-------|-----|----------|
| `_friends` | `List<Map>` | Arkadaş listesi |
| `_pendingRequests` | `List<Map>` | Gelen istekler |
| `_conversations` | `List<Map>` | Sohbet listesi |
| `_messages` | `List<Map>` | Aktif sohbet mesajları |
| `_notifications` | `List<Map>` | Bildirimler |
| `_feed` | `List<Map>` | Aktivite feed |
| `_unreadNotifications` | `int` | Okunmamış bildirim sayısı |
| `_unreadMessages` | `int` | Okunmamış mesaj sayısı |

**Metodlar**: `loadFriends()`, `searchUsers()`, `sendFriendRequest()`, `acceptRequest()`, `rejectRequest()`, `removeFriend()`, `loadConversations()`, `loadMessages()`, `sendMessage()`, `sendChallenge()`, `loadNotifications()`, `markNotificationsRead()`, `loadFeed()`

---

## Veri Akışı: Görev Gönderimi Örneği

```
1. Kullanıcı görev detayına girer (QuestDetailScreen)
2. Fotoğraf çeker / cevap yazar / QR tarar
3. "Gönder" butonuna basar
4. QuestProvider.submitQuest() çağrılır
5. Dio → POST /api/quests/:id/submit (multipart FormData)
6. Backend:
   a. requireAuth → JWT doğrulaması
   b. Submission.existsForUser() → tekrar kontrol
   c. Tip kontrolü:
      - photo: Gemini AI fotoğraf değerlendirme (score ≥ 60 = approved)
      - question: answer_text === quest.answer (case-insensitive trim)
      - qr_code: qr_scanned_data === quest.qr_data
   d. Submission.create() → DB'ye kaydet
   e. Status approved ise:
      - User.updateStreak() → streak güncelle
      - User.addPoints(points * streakMultiplier)
      - Achievement.checkAndUnlock() → başarım kontrol
      - Activity.logQuestCompleted() → feed'e log
   f. JSON response döner
7. QuestProvider state güncellenir → notifyListeners()
8. UI rebuild → başarım/streak popup gösterilir
```
