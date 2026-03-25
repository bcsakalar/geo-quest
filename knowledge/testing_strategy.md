# 🧪 Geo-Quest — Test Stratejisi ve Kuralları

## ⚠️ Temel Kural

> **Yazılan veya değiştirilen her kod parçası (en küçük bir util fonksiyonu bile olsa) ilgili test senaryolarıyla birlikte teslim edilmeli ve mevcut testlerin bozulmadığından emin olunmalıdır.**

---

## Mevcut Durum

| Katman | Test Framework | Durum |
|--------|---------------|-------|
| Backend (Node.js) | — | **Henüz kurulmamış** — Aşağıdaki kurulum talimatlarına göre oluşturulmalıdır |
| Mobile (Flutter) | flutter_test | Varsayılan widget_test.dart mevcut, genişletilmeli |

---

## Backend Test Altyapısı (Kurulacak)

### Önerilen Yapı

```
backend/
├── package.json                 # test scriptleri eklenmeli
├── jest.config.js               # Jest yapılandırması
└── src/
    └── __tests__/               # Test dosyaları
        ├── unit/
        │   ├── models/
        │   │   ├── User.test.js
        │   │   ├── Quest.test.js
        │   │   ├── Submission.test.js
        │   │   ├── Achievement.test.js
        │   │   ├── DailyChallenge.test.js
        │   │   ├── Friendship.test.js
        │   │   ├── Message.test.js
        │   │   ├── Notification.test.js
        │   │   └── Activity.test.js
        │   ├── middleware/
        │   │   ├── auth.test.js
        │   │   ├── upload.test.js
        │   │   └── errorHandler.test.js
        │   ├── services/
        │   │   └── gemini.test.js
        │   └── utils/
        │       └── helpers.test.js
        ├── integration/
        │   ├── auth.test.js
        │   ├── quests.test.js
        │   ├── submissions.test.js
        │   ├── achievements.test.js
        │   ├── friends.test.js
        │   ├── messages.test.js
        │   └── social.test.js
        └── helpers/
            ├── setup.js          # Global test setup
            ├── teardown.js       # Global cleanup
            └── testDb.js         # Test veritabanı yardımcıları
```

### Kurulum Adımları

```bash
cd backend

# Test bağımlılıklarını yükle
npm install --save-dev jest supertest

# package.json'a test scriptlerini ekle
```

#### package.json — Eklenecek Scriptler

```json
{
  "scripts": {
    "start": "node src/server.js",
    "dev": "node --watch src/server.js",
    "test": "jest --forceExit --detectOpenHandles",
    "test:watch": "jest --watch --forceExit --detectOpenHandles",
    "test:coverage": "jest --coverage --forceExit --detectOpenHandles",
    "test:unit": "jest --testPathPattern=unit --forceExit",
    "test:integration": "jest --testPathPattern=integration --forceExit --detectOpenHandles"
  }
}
```

#### jest.config.js

```javascript
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.test.js'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/server.js',
    '!src/db/*.sql',
    '!src/views/**',
    '!src/public/**',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov'],
  setupFilesAfterSetup: ['./src/__tests__/helpers/setup.js'],
  globalTeardown: './src/__tests__/helpers/teardown.js',
  testTimeout: 10000,
};
```

---

## İsimlendirme Standartları

### Dosya İsimlendirme

| Kaynak Dosya | Test Dosyası | Konum |
|-------------|-------------|-------|
| `models/User.js` | `User.test.js` | `__tests__/unit/models/` |
| `models/Quest.js` | `Quest.test.js` | `__tests__/unit/models/` |
| `middleware/auth.js` | `auth.test.js` | `__tests__/unit/middleware/` |
| `services/gemini.js` | `gemini.test.js` | `__tests__/unit/services/` |
| `utils/helpers.js` | `helpers.test.js` | `__tests__/unit/utils/` |
| `routes/api/quests.js` | `quests.test.js` | `__tests__/integration/` |

**Kural**: Test dosyası adı `<kaynak-adı>.test.js` formatında olmalıdır.

### Test İsimlendirme (describe/it)

```javascript
describe('ModelAdı', () => {
  describe('metodAdı', () => {
    it('beklenen davranışı açıklar', () => {});
    it('hata durumunu açıklar', () => {});
  });
});
```

**Örnek**:
```javascript
describe('User', () => {
  describe('findByEmail', () => {
    it('should return user when email exists', async () => {});
    it('should return null when email does not exist', async () => {});
  });

  describe('updateStreak', () => {
    it('should increment streak for consecutive day', async () => {});
    it('should reset streak when gap is more than 1 day', async () => {});
    it('should not change streak for same day', async () => {});
  });
});
```

---

## Unit Test Şablonları

### Model Testi Şablonu

```javascript
// __tests__/unit/models/User.test.js
const db = require('../../../config/db');
const User = require('../../../models/User');

// DB modülünü mock'la
jest.mock('../../../config/db');

describe('User', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findByEmail', () => {
    it('should return user when email exists', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        total_points: 0,
      };

      db.query.mockResolvedValue({ rows: [mockUser] });

      const result = await User.findByEmail('test@example.com');

      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('SELECT'),
        ['test@example.com']
      );
      expect(result).toEqual(mockUser);
    });

    it('should return null when email does not exist', async () => {
      db.query.mockResolvedValue({ rows: [] });

      const result = await User.findByEmail('notfound@example.com');

      expect(result).toBeNull();
    });
  });

  describe('create', () => {
    it('should insert user and return created record', async () => {
      const newUser = {
        id: 1,
        email: 'new@example.com',
        name: 'New User',
        role: 'user',
      };

      db.query.mockResolvedValue({ rows: [newUser] });

      const result = await User.create({
        email: 'new@example.com',
        passwordHash: 'hashedpass',
        name: 'New User',
      });

      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT'),
        expect.arrayContaining(['new@example.com', 'hashedpass', 'New User'])
      );
      expect(result).toEqual(newUser);
    });
  });

  describe('addPoints', () => {
    it('should add points and return updated user', async () => {
      const updatedUser = { id: 1, total_points: 50 };
      db.query.mockResolvedValue({ rows: [updatedUser] });

      const result = await User.addPoints(1, 50);

      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('total_points'),
        [50, 1]
      );
      expect(result.total_points).toBe(50);
    });
  });
});
```

### Middleware Testi Şablonu

```javascript
// __tests__/unit/middleware/auth.test.js
const { requireAuth, requireAdmin } = require('../../../middleware/auth');
const { verifyToken } = require('../../../utils/helpers');

jest.mock('../../../utils/helpers');

describe('auth middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      headers: {},
      session: {},
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      redirect: jest.fn(),
    };
    next = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('requireAuth', () => {
    it('should call next() with valid JWT token', () => {
      req.headers.authorization = 'Bearer valid-token';
      verifyToken.mockReturnValue({ id: 1, email: 'test@test.com' });

      requireAuth(req, res, next);

      expect(verifyToken).toHaveBeenCalledWith('valid-token');
      expect(req.user).toEqual({ id: 1, email: 'test@test.com' });
      expect(next).toHaveBeenCalled();
    });

    it('should return 401 when no token provided', () => {
      requireAuth(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 when token is invalid', () => {
      req.headers.authorization = 'Bearer invalid-token';
      verifyToken.mockImplementation(() => { throw new Error('invalid'); });

      requireAuth(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('requireAdmin', () => {
    it('should call next() when admin session exists', () => {
      req.session.adminUser = { id: 1, role: 'admin' };

      requireAdmin(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should redirect to login when no admin session', () => {
      requireAdmin(req, res, next);

      expect(res.redirect).toHaveBeenCalledWith('/admin/login');
      expect(next).not.toHaveBeenCalled();
    });
  });
});
```

### Utils Testi Şablonu

```javascript
// __tests__/unit/utils/helpers.test.js
const { hashPassword, comparePassword, signToken, verifyToken } = require('../../../utils/helpers');

describe('helpers', () => {
  describe('hashPassword / comparePassword', () => {
    it('should hash and verify password correctly', async () => {
      const password = 'testpassword123';
      const hash = await hashPassword(password);

      expect(hash).not.toBe(password);
      expect(await comparePassword(password, hash)).toBe(true);
      expect(await comparePassword('wrongpassword', hash)).toBe(false);
    });
  });

  describe('signToken / verifyToken', () => {
    it('should sign and verify JWT token', () => {
      const payload = { id: 1, email: 'test@test.com' };
      const token = signToken(payload);

      const decoded = verifyToken(token);
      expect(decoded.id).toBe(1);
      expect(decoded.email).toBe('test@test.com');
    });

    it('should throw on invalid token', () => {
      expect(() => verifyToken('invalid-token')).toThrow();
    });
  });
});
```

### Service Testi Şablonu

```javascript
// __tests__/unit/services/gemini.test.js
const gemini = require('../../../services/gemini');

// Google GenAI SDK'yı mock'la
jest.mock('@google/genai');

describe('GeminiService', () => {
  describe('generateQuests', () => {
    it('should generate 3 quests for given location', async () => {
      // Mock implementation
      const mockQuests = [
        { title: 'Quest 1', type: 'photo', latitude: 41.0, longitude: 29.0 },
        { title: 'Quest 2', type: 'question', latitude: 41.001, longitude: 29.001 },
        { title: 'Quest 3', type: 'photo', latitude: 41.002, longitude: 29.002 },
      ];

      // Test implementation depends on actual mock setup
      // Verify quest count, types, and location proximity
    });
  });

  describe('evaluatePhoto', () => {
    it('should return score between 0-100', async () => {
      // Mock AI response
      // Verify score range and evaluation text
    });
  });
});
```

### Integration (API Route) Testi Şablonu

```javascript
// __tests__/integration/auth.test.js
const request = require('supertest');
const app = require('../../app');
const db = require('../../config/db');

describe('Auth API', () => {
  beforeAll(async () => {
    // Test veritabanı hazırlığı
  });

  afterAll(async () => {
    // Temizlik
    await db.pool.end();
  });

  describe('POST /api/auth/register', () => {
    it('should register new user successfully', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'newuser@test.com',
          password: 'password123',
          name: 'Test User',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('token');
      expect(res.body.user).toHaveProperty('email', 'newuser@test.com');
    });

    it('should return 400 for existing email', async () => {
      await request(app)
        .post('/api/auth/register')
        .send({ email: 'dup@test.com', password: 'pass123', name: 'Dup' });

      const res = await request(app)
        .post('/api/auth/register')
        .send({ email: 'dup@test.com', password: 'pass456', name: 'Dup2' });

      expect(res.statusCode).toBe(400);
    });

    it('should return 400 for short password', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ email: 'short@test.com', password: '123', name: 'Short' });

      expect(res.statusCode).toBe(400);
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login with correct credentials', async () => {
      // Önce kayıt ol
      await request(app)
        .post('/api/auth/register')
        .send({ email: 'login@test.com', password: 'password123', name: 'Login User' });

      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'login@test.com', password: 'password123' });

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('token');
    });

    it('should return 401 for wrong password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'login@test.com', password: 'wrongpassword' });

      expect(res.statusCode).toBe(401);
    });
  });
});
```

---

## Flutter Test Şablonları

### Widget Testi Şablonu

```dart
// test/widgets/quest_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_quest/widgets/quest_card.dart';
import 'package:geo_quest/models/quest.dart';

void main() {
  group('QuestCard', () {
    late Quest testQuest;

    setUp(() {
      testQuest = Quest(
        id: 1,
        title: 'Test Quest',
        description: 'A test quest',
        type: 'photo',
        latitude: 41.0,
        longitude: 29.0,
        points: 10,
        isActive: true,
        source: 'manual',
      );
    });

    testWidgets('should display quest title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuestCard(quest: testQuest)),
        ),
      );

      expect(find.text('Test Quest'), findsOneWidget);
    });

    testWidgets('should show photo icon for photo type quest', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuestCard(quest: testQuest)),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });
  });
}
```

### Provider Testi Şablonu

```dart
// test/providers/auth_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_quest/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('initial state should not be logged in', () {
      expect(provider.isLoggedIn, false);
      expect(provider.user, null);
      expect(provider.isLoading, false);
    });

    test('login should update user on success', () async {
      // Mock ApiService required
      // Verify state transitions: loading → loaded
    });
  });
}
```

### Flutter Test Yapısı

```
mobile/geo_quest/test/
├── widget_test.dart              # Varsayılan (genişletilmeli)
├── models/
│   ├── user_test.dart
│   ├── quest_test.dart
│   ├── submission_test.dart
│   └── achievement_test.dart
├── providers/
│   ├── auth_provider_test.dart
│   ├── quest_provider_test.dart
│   └── social_provider_test.dart
├── widgets/
│   ├── quest_card_test.dart
│   └── loading_widget_test.dart
└── screens/
    ├── login_screen_test.dart
    ├── register_screen_test.dart
    └── home_screen_test.dart
```

---

## Test Yazarken Uyulacak Kurallar

### 1. Her Değişiklik Test Edilmeli

| Değişiklik | Zorunlu Test |
|------------|-------------|
| Yeni model metodu | Unit test (mock DB) |
| Yeni API route | Integration test (supertest) |
| Middleware değişikliği | Unit test (mock req/res/next) |
| Yeni service metodu | Unit test (mock external deps) |
| Util fonksiyonu | Unit test (doğrudan) |
| Yeni widget | Widget test (pumpWidget) |
| Provider metodu | Unit test (mock service) |
| Business logic değişikliği | İlgili tüm testler güncellenmeli |

### 2. Mock Kuralları

- **DB sorguları**: `jest.mock('../../../config/db')` ile mock'lanır
- **Gemini API**: `jest.mock('@google/genai')` ile mock'lanır
- **File system**: `jest.mock('fs')` veya gerçek temp dosyalar
- **JWT**: Test ortamında gerçek JWT_SECRET kullanılabilir
- **HTTP istekleri**: `supertest` ile gerçek Express app'e istek atılır

### 3. Test Veritabanı (Integration Testler)

Integration testleri ayrı bir veritabanında çalıştırılmalıdır:

```
POSTGRES_DB_TEST=geoquest_test
```

Her test suite başında temizlik ve hazırlık:
```javascript
beforeAll(async () => {
  // Migration'ları çalıştır
  // Seed verilerini yükle
});

afterAll(async () => {
  // Verileri temizle
  // Pool'u kapat
});

afterEach(async () => {
  // Transaction rollback veya tablo temizliği
});
```

### 4. Coverage Hedefleri

| Metrik | Minimum Hedef |
|--------|--------------|
| Statements | %80 |
| Branches | %70 |
| Functions | %80 |
| Lines | %80 |

### 5. Test Çalıştırma Sırası

1. **Kod değişikliği yap**
2. **İlgili unit testleri çalıştır** → `npm test -- --testPathPattern=<dosya>`
3. **Etkilenen integration testleri çalıştır** → `npm run test:integration`
4. **Tüm testleri çalıştır** → `npm test`
5. **Coverage kontrol et** → `npm run test:coverage`
6. **Testler geçtiyse → MEMORY.md güncelle**

---

## CI/CD Entegrasyonu (Planlanan)

```yaml
# .github/workflows/test.yml (ileride oluşturulacak)
name: Tests
on: [push, pull_request]
jobs:
  backend-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgis/postgis:16-3.4
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: geoquest_test
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: cd backend && npm install
      - run: cd backend && npm test
      - run: cd backend && npm run test:coverage

  flutter-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.x' }
      - run: cd mobile/geo_quest && flutter pub get
      - run: cd mobile/geo_quest && flutter test
```
