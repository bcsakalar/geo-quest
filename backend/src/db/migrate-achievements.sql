-- ═══════════════════════════════════════════════════
-- Geo-Quest: Başarım, Streak, Günlük Görev Migrasyonu
-- ═══════════════════════════════════════════════════

-- ──── Başarımlar (Achievements) ────
CREATE TABLE IF NOT EXISTS achievements (
    id              SERIAL PRIMARY KEY,
    key             VARCHAR(50)  UNIQUE NOT NULL,
    title           VARCHAR(100) NOT NULL,
    description     TEXT         NOT NULL,
    icon            VARCHAR(50)  NOT NULL DEFAULT 'emoji_events',
    color           VARCHAR(20)  NOT NULL DEFAULT '#FFD700',
    required_count  INT          NOT NULL DEFAULT 1,
    points_reward   INT          NOT NULL DEFAULT 5
);

-- ──── Kullanıcı Başarımları ────
CREATE TABLE IF NOT EXISTS user_achievements (
    id              SERIAL PRIMARY KEY,
    user_id         INT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id  INT          NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at     TIMESTAMP    NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements (user_id);

-- ──── Streak Tablosu ────
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_streak INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS max_streak INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_quest_date DATE;

-- ──── Günlük Görev ────
CREATE TABLE IF NOT EXISTS daily_challenges (
    id              SERIAL PRIMARY KEY,
    user_id         INT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quest_id        INT          NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
    challenge_date  DATE         NOT NULL DEFAULT CURRENT_DATE,
    completed       BOOLEAN      NOT NULL DEFAULT false,
    bonus_points    INT          NOT NULL DEFAULT 10,
    UNIQUE(user_id, challenge_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_user_date ON daily_challenges (user_id, challenge_date);

-- ──── Başarım Tanımları ────
INSERT INTO achievements (key, title, description, icon, color, required_count, points_reward) VALUES
    ('first_quest',     'İlk Adım',          'İlk görevini tamamla!',                 'flag',           '#4CAF50', 1,  10),
    ('quest_5',         'Kaşif',              '5 görev tamamla',                       'explore',        '#2196F3', 5,  25),
    ('quest_10',        'Maceraperest',        '10 görev tamamla',                      'hiking',         '#FF9800', 10, 50),
    ('quest_25',        'Efsane',              '25 görev tamamla',                      'military_tech',  '#9C27B0', 25, 100),
    ('photo_5',         'Fotoğrafçı',          '5 fotoğraf görevi tamamla',             'camera_alt',     '#E91E63', 5,  30),
    ('question_5',      'Bilge',              '5 soru görevi tamamla',                 'school',         '#00BCD4', 5,  30),
    ('ai_explorer',     'AI Kaşifi',          'İlk AI görevini tamamla',               'auto_awesome',   '#7C4DFF', 1,  15),
    ('ai_master',       'AI Ustası',          '10 AI görevini tamamla',                'psychology',     '#651FFF', 10, 50),
    ('streak_3',        'Kararlı',            '3 günlük seri',                         'local_fire_department', '#FF5722', 3, 20),
    ('streak_7',        'Durdurulamaz',        '7 günlük seri',                         'whatshot',       '#FF1744', 7,  50),
    ('streak_30',       'Efsanevi Seri',      '30 günlük seri',                        'bolt',           '#FFD600', 30, 150),
    ('daily_5',         'Disiplinli',          '5 günlük meydan okuma tamamla',         'event_available','#8BC34A', 5,  30),
    ('points_100',      'Yüzlük',             '100 puan topla',                        'stars',          '#FFC107', 100, 10),
    ('points_500',      'Beş Yüzlük',        '500 puan topla',                        'workspace_premium','#FF6F00', 500, 50)
ON CONFLICT (key) DO NOTHING;
