-- ═══════════════════════════════════════════════════════════
-- kt_idcard_ui v3 — Migrations SQL
-- Compatible MySQL 5.7+ et MariaDB 10.1+
-- À exécuter une seule fois sur votre base de données
-- ═══════════════════════════════════════════════════════════

-- 1. Permis de conduire
CREATE TABLE IF NOT EXISTS user_licenses (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(60)  NOT NULL,
  unique_id  VARCHAR(60)  NOT NULL,
  type       VARCHAR(30)  NOT NULL,
  UNIQUE KEY uq_license (unique_id, type),
  INDEX idx_unique_id (unique_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Numéros persistants (badge, permis arme, EMS)
-- Évite la génération aléatoire à chaque affichage [FIX-7]
CREATE TABLE IF NOT EXISTS user_licenses_meta (
  unique_id      VARCHAR(60)  NOT NULL PRIMARY KEY,
  license_number VARCHAR(30)  NOT NULL,
  created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Log des contrôles policiers
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

-- 4. Photo de profil sur user_character
ALTER TABLE user_character
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL;

-- ═══════════════════════════════════════════════════════════
-- Purge automatique des logs de contrôles > 90 jours
-- [FIX] Évite la croissance infinie de police_checks_log
-- NOTE : nécessite que l'event_scheduler soit activé sur votre MySQL.
-- Vérifiez avec : SHOW VARIABLES LIKE 'event_scheduler';
-- Activez avec  : SET GLOBAL event_scheduler = ON;
-- ═══════════════════════════════════════════════════════════

DROP EVENT IF EXISTS purge_police_checks_log;

CREATE EVENT purge_police_checks_log
  ON SCHEDULE EVERY 1 DAY
  STARTS CURRENT_TIMESTAMP
  DO
    DELETE FROM police_checks_log
    WHERE checked_at < DATE_SUB(NOW(), INTERVAL 90 DAY);

-- ═══════════════════════════════════════════════════════════
-- NOTE : "ADD INDEX IF NOT EXISTS" n'est pas supporté avant
-- MySQL 8.0.29. Les index sont désormais définis directement
-- dans le CREATE TABLE ci-dessus pour une compatibilité totale.
-- ═══════════════════════════════════════════════════════════
