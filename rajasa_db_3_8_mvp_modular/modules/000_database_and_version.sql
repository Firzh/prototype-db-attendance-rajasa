-- =========================================================
-- RAJASA DB 3.8 MVP MODULAR - DATABASE AND VERSION
-- =========================================================
CREATE DATABASE IF NOT EXISTS `sistem_absensi_lab_qr`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `sistem_absensi_lab_qr`;

SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `schema_versions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `version` VARCHAR(30) NOT NULL UNIQUE,
  `name` VARCHAR(150) NOT NULL,
  `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `checksum_sha256` CHAR(64) DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
