-- ═══════════════════════════════════════════════════
-- Geo-Quest: AI Migration
-- Run against existing database to add AI columns
-- ═══════════════════════════════════════════════════

-- Quests: AI source tracking
ALTER TABLE quests ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'manual';
ALTER TABLE quests ADD COLUMN IF NOT EXISTS generated_for INT REFERENCES users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_quests_source ON quests (source);
CREATE INDEX IF NOT EXISTS idx_quests_generated_for ON quests (generated_for);

-- Submissions: AI evaluation
ALTER TABLE submissions ADD COLUMN IF NOT EXISTS ai_evaluation TEXT;
ALTER TABLE submissions ADD COLUMN IF NOT EXISTS ai_score INT;
