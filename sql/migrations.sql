-- ═══════════════════════════════════════════════════════════
-- kt_idcard_ui v3 — Migrations SQL
-- À exécuter une seule fois sur votre base de données
-- ═══════════════════════════════════════════════════════════

-- 1. Permis de conduire (si pas déjà existant)
CREATE TABLE IF NOT EXISTS user_licenses (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(60)  NOT NULL,
  unique_id  VARCHAR(60)  NOT NULL,
  type       VARCHAR(30)  NOT NULL,
  UNIQUE KEY uq_license (unique_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Numéros de permis persistants (FIX)
-- Évite la génération aléatoire à chaque affichage
CREATE TABLE IF NOT EXISTS user_licenses_meta (
  unique_id      VARCHAR(60)  NOT NULL PRIMARY KEY,
  license_number VARCHAR(30)  NOT NULL,
  created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Log des contrôles policiers (NEW)
-- Traçabilité anti-abus RP
CREATE TABLE IF NOT EXISTS police_checks_log (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  officer_uid VARCHAR(60)  NOT NULL,
  target_uid  VARCHAR(60)  NOT NULL,
  check_type  VARCHAR(20)  NOT NULL COMMENT 'identity | license | badge',
  checked_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_officer  (officer_uid),
  INDEX idx_target   (target_uid),
  INDEX idx_date     (checked_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Photo de profil sur user_character (si pas déjà existant)
ALTER TABLE user_character
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL;

-- ═══════════════════════════════════════════════════════════
-- Index utiles pour les performances
-- ═══════════════════════════════════════════════════════════
ALTER TABLE user_licenses
  ADD INDEX IF NOT EXISTS idx_unique_id (unique_id);
