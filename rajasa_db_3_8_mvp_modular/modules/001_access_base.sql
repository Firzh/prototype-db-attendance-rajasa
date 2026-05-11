-- =========================================================
-- 001 - ACCESS BASE: roles, permissions, policies, groups
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `roles` (

  `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik role. Contoh implementasi: 1=Super Admin, 2=Admin Akademik.',
  `nama_role` VARCHAR(50) NOT NULL COMMENT 'Nama tampilan role. Contoh implementasi: ''Guru Pengawas''.',
  `role_slug` VARCHAR(50) NOT NULL COMMENT 'Slug role untuk pemanggilan sistem/API. Contoh implementasi: ''guru_pengawas''. Umumnya dibentuk dari nama role dengan format huruf kecil dan underscore.',
  `deskripsi` TEXT DEFAULT NULL COMMENT 'Penjelasan fungsi role. Contoh implementasi: ''Memantau jadwal, presensi, dan ujian''. Boleh NULL bila nama role sudah cukup jelas.',
  `is_system` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda role bawaan sistem. Contoh implementasi: 1=bawaan sistem, 0=role kustom.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uk_roles_nama_role` (`nama_role`),
  UNIQUE KEY `uk_roles_role_slug` (`role_slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `permissions` (

  `perm_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik permission. Contoh implementasi: 15 untuk attendance.read.',
  `perm_slug` VARCHAR(100) NOT NULL COMMENT 'Kode izin unik. Contoh implementasi: ''attendance.validate''.',
  `module_name` VARCHAR(50) NOT NULL COMMENT 'Nama modul asal izin. Contoh implementasi: ''attendance''.',
  `action_name` ENUM('read','create','update','delete','write','scan','validate','assign_role','generate','revoke','export','manage','submit','review','archive') NOT NULL DEFAULT 'read' COMMENT 'Aksi pada modul. Nilai dibatasi agar konsisten antar-permission. Contoh implementasi: ''read'', ''write'', ''validate'', ''submit'', atau ''review''.',
  `keterangan` TEXT DEFAULT NULL COMMENT 'Deskripsi izin. Contoh implementasi: ''Memvalidasi data presensi''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`perm_id`),
  UNIQUE KEY `uk_permissions_perm_slug` (`perm_slug`),
  KEY `idx_permissions_module_action` (`module_name`, `action_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `policies` (

  `policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik policy. Contoh implementasi: 1=FullAccess.',
  `policy_name` VARCHAR(100) NOT NULL COMMENT 'Nama tampilan policy untuk admin/developer. Contoh implementasi: ''AcademicAdminAccess'' atau ''TeacherSupervisorAccess''.',
  `policy_slug` VARCHAR(100) NOT NULL COMMENT 'Slug policy untuk referensi sistem/API. Contoh implementasi: ''academic_admin_access''.',
  `policy_type` ENUM('managed','inline') NOT NULL DEFAULT 'managed' COMMENT 'Jenis policy. ''managed'' dipakai untuk policy standar yang dikelola sistem dan dapat dipakai ulang oleh banyak role/user. ''inline'' dipakai untuk policy khusus yang menempel langsung pada role/user tertentu untuk kebutuhan pengecualian atau akses temporer.',
  `deskripsi` TEXT DEFAULT NULL COMMENT 'Penjelasan cakupan policy. Contoh implementasi: ''Akses administrasi akademik dan presensi''. Boleh NULL bila nama policy sudah cukup jelas.',
  `is_system` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda policy bawaan sistem. Contoh implementasi: 1 untuk policy standar.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`policy_id`),
  UNIQUE KEY `uk_policies_name` (`policy_name`),
  UNIQUE KEY `uk_policies_slug` (`policy_slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `policy_permissions` (

  `policy_permission_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi detail policy-permission.',
  `policy_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ke policy. Contoh implementasi: policy FullAccess.',
  `perm_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ke permission. Contoh implementasi: permission ''users.read''.',
  `effect` ENUM('allow','deny') NOT NULL DEFAULT 'allow' COMMENT 'Efek rule. Contoh implementasi: ''allow'' atau ''deny''.',
  `resource_scope` VARCHAR(150) NOT NULL DEFAULT '*' COMMENT 'Cakupan resource. Contoh implementasi: ''*'' untuk semua resource, ''self/*'' untuk data milik sendiri.',
  `conditions_json` JSON DEFAULT NULL COMMENT 'Kondisi tambahan berbentuk JSON. Contoh implementasi: {''jam_mulai'':''07:00'',''hari'':[''senin'',''selasa'']}. Boleh NULL jika rule tidak memerlukan kondisi tambahan.',
  `priority` SMALLINT UNSIGNED NOT NULL DEFAULT 100 COMMENT 'Prioritas evaluasi rule. Contoh implementasi: 1 lebih tinggi dari 100.',
  PRIMARY KEY (`policy_permission_id`),
  UNIQUE KEY `uk_policy_permissions_unique_rule` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`),
  KEY `idx_policy_permissions_perm` (`perm_id`),
  CONSTRAINT `fk_policy_permissions_policy`
    FOREIGN KEY (`policy_id`) REFERENCES `policies`(`policy_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_policy_permissions_permission`
    FOREIGN KEY (`perm_id`) REFERENCES `permissions`(`perm_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_permissions` (

  `role_id` INT UNSIGNED NOT NULL COMMENT 'Referensi role yang memperoleh permission.',
  `perm_id` INT UNSIGNED NOT NULL COMMENT 'Referensi permission pada role.',
  `is_allowed` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Override izin role. Contoh implementasi: 1=diizinkan, 0=ditolak.',
  `resource_scope` VARCHAR(150) NOT NULL DEFAULT '*' COMMENT 'Cakupan resource untuk role. Contoh implementasi: ''*'', ''room/LAB-TKJ-01'', atau ''self/*''. Nilai ini diisi manual oleh admin atau otomatis oleh backend saat membuat rule khusus.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`role_id`, `perm_id`, `resource_scope`),
  KEY `idx_role_permissions_perm` (`perm_id`),
  CONSTRAINT `fk_role_permissions_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_permissions_permission`
    FOREIGN KEY (`perm_id`) REFERENCES `permissions`(`perm_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `groups` (

  `group_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik group user.',
  `group_name` VARCHAR(100) NOT NULL COMMENT 'Nama tampilan group. Contoh implementasi: ''Operator Lab Gedung A''.',
  `group_slug` VARCHAR(100) NOT NULL COMMENT 'Slug group. Contoh implementasi: ''operator_lab_gedung_a''.',
  `deskripsi` TEXT DEFAULT NULL COMMENT 'Penjelasan fungsi group. Boleh NULL bila nama group sudah cukup jelas.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`group_id`),
  UNIQUE KEY `uk_groups_group_name` (`group_name`),
  UNIQUE KEY `uk_groups_group_slug` (`group_slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


ALTER TABLE `roles`
  ADD COLUMN `role_level` SMALLINT UNSIGNED NOT NULL DEFAULT 80 COMMENT 'Hierarki role. Angka lebih kecil berarti wewenang lebih tinggi.' AFTER `role_slug`;

ALTER TABLE `groups`
  ADD COLUMN `group_type` ENUM('generic','student','notification','attendance','import','academic') NOT NULL DEFAULT 'generic' AFTER `group_slug`,
  ADD COLUMN `group_level` SMALLINT UNSIGNED NOT NULL DEFAULT 80 AFTER `group_type`,
  ADD COLUMN `is_system` TINYINT(1) NOT NULL DEFAULT 0 AFTER `group_level`;
