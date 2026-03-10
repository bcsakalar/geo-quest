-- ═══════════════════════════════════════════════════
-- Geo-Quest: Veritabanı Şeması
-- ═══════════════════════════════════════════════════

-- PostGIS eklentisini etkinleştir
CREATE EXTENSION IF NOT EXISTS postgis;

-- ──── Users ────
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    name            VARCHAR(100) NOT NULL,
    role            VARCHAR(20)  NOT NULL DEFAULT 'user',
    total_points    INT          NOT NULL DEFAULT 0,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ──── Quests ────
CREATE TABLE IF NOT EXISTS quests (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    type            VARCHAR(50)  NOT NULL CHECK (type IN ('photo', 'qr_code', 'question')),
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    location        GEOGRAPHY(POINT, 4326),
    radius_meters   INT          NOT NULL DEFAULT 100,
    points          INT          NOT NULL DEFAULT 10,
    question        TEXT,
    answer          TEXT,
    qr_data         TEXT,
    is_active       BOOLEAN      NOT NULL DEFAULT true,
    source          VARCHAR(20)  NOT NULL DEFAULT 'manual',
    generated_for   INT          REFERENCES users(id) ON DELETE SET NULL,
    created_by      INT          REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Spatial index for fast proximity queries
CREATE INDEX IF NOT EXISTS idx_quests_location ON quests USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_quests_active   ON quests (is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_quests_source   ON quests (source);
CREATE INDEX IF NOT EXISTS idx_quests_generated_for ON quests (generated_for);

-- Trigger: otomatik olarak lat/lng'den geography kolonunu doldur
CREATE OR REPLACE FUNCTION update_quest_location()
RETURNS TRIGGER AS $$
BEGIN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_quest_location ON quests;
CREATE TRIGGER trg_quest_location
    BEFORE INSERT OR UPDATE OF latitude, longitude ON quests
    FOR EACH ROW
    EXECUTE FUNCTION update_quest_location();

-- ──── Submissions ────
CREATE TABLE IF NOT EXISTS submissions (
    id                SERIAL PRIMARY KEY,
    user_id           INT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quest_id          INT          NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
    status            VARCHAR(20)  NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    photo_url         TEXT,
    answer_text       TEXT,
    qr_scanned_data   TEXT,
    ai_evaluation     TEXT,
    ai_score          INT,
    submitted_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    reviewed_at       TIMESTAMP,
    reviewed_by       INT          REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE(user_id, quest_id)
);

CREATE INDEX IF NOT EXISTS idx_submissions_user    ON submissions (user_id);
CREATE INDEX IF NOT EXISTS idx_submissions_quest   ON submissions (quest_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status  ON submissions (status);
