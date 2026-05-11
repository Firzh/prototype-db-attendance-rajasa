-- =========================================================
-- 003 - USERS ACCESS RUNTIME: users, roles relations, sessions
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `users` (

  `user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik akun login.',
  `username` VARCHAR(50) NOT NULL COMMENT 'Username akun login. Contoh implementasi: ''siswa.220145''.',
  `password_hash` VARCHAR(255) NOT NULL COMMENT 'Hash password, bukan password mentah. Contoh implementasi: hasil bcrypt/argon2.',
  `user_type` ENUM('siswa','guru_staff','system') NOT NULL DEFAULT 'system' COMMENT 'Jenis pemilik akun. Contoh implementasi: ''siswa'', ''guru_staff'', atau ''system''.',
  `siswa_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi siswa terkait.',
  `guru_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi guru/staff terkait.',
  `valid_until` DATETIME DEFAULT NULL COMMENT 'Khusus akses sementara seperti intern atau akun tamu',
  `status` ENUM('aktif','nonaktif','terblokir') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `last_login` DATETIME DEFAULT NULL COMMENT 'Waktu login terakhir user. Contoh implementasi: ''2026-04-09 07:21:00''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_users_username` (`username`),
  UNIQUE KEY `uk_users_siswa_id` (`siswa_id`),
  UNIQUE KEY `uk_users_guru_id` (`guru_id`),
  KEY `idx_users_status_type` (`status`, `user_type`),
  CONSTRAINT `fk_users_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_users_guru`
    FOREIGN KEY (`guru_id`) REFERENCES `guru_staff`(`guru_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_roles` (

  `user_role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi user-role.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user yang terkait. Contoh implementasi: user admin yang login atau menerima notifikasi.',
  `role_id` INT UNSIGNED NOT NULL COMMENT 'Referensi role terkait. Contoh implementasi: role ''operator_lab''.',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda relasi aktif. Contoh implementasi: 1=aktif, 0=nonaktif.',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom assigned_at. Contoh implementasi: isi sesuai kebutuhan modul user_roles.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  PRIMARY KEY (`user_role_id`),
  UNIQUE KEY `uk_user_roles_active` (`user_id`, `role_id`),
  KEY `idx_user_roles_role_active` (`role_id`, `is_active`),
  CONSTRAINT `fk_user_roles_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_roles_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_roles_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_permissions` (

  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user yang terkait. Contoh implementasi: user admin yang login atau menerima notifikasi.',
  `perm_id` INT UNSIGNED NOT NULL COMMENT 'Referensi permission terkait.',
  `is_allowed` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda izin diperbolehkan atau ditolak. Contoh implementasi: 1=allow, 0=deny.',
  `resource_scope` VARCHAR(150) NOT NULL DEFAULT '*' COMMENT 'Cakupan resource yang diizinkan. Contoh implementasi: ''*'', ''self/*'', atau ''room/LAB-TKJ-01''.',
  `valid_until` DATETIME DEFAULT NULL COMMENT 'Batas akhir akun/izin berlaku. Contoh implementasi: akun intern aktif sampai ''2026-06-30 23:59:59''.',
  `catatan` VARCHAR(255) DEFAULT NULL COMMENT 'Catatan tambahan. Contoh implementasi: ''Akses sementara untuk supervisi ujian''.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`user_id`, `perm_id`, `resource_scope`),
  KEY `idx_user_permissions_perm` (`perm_id`),
  CONSTRAINT `fk_user_permissions_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_permissions_permission`
    FOREIGN KEY (`perm_id`) REFERENCES `permissions`(`perm_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_permissions_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_policies` (

  `role_policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi role-policy.',
  `role_id` INT UNSIGNED NOT NULL COMMENT 'Referensi role terkait. Contoh implementasi: role ''operator_lab''.',
  `policy_id` INT UNSIGNED NOT NULL COMMENT 'Referensi policy terkait.',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom assigned_at. Contoh implementasi: isi sesuai kebutuhan modul role_policies.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  PRIMARY KEY (`role_policy_id`),
  UNIQUE KEY `uk_role_policies_role_policy` (`role_id`, `policy_id`),
  CONSTRAINT `fk_role_policies_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_policies_policy`
    FOREIGN KEY (`policy_id`) REFERENCES `policies`(`policy_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_policies_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_policies` (

  `user_policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi user-policy.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user yang terkait. Contoh implementasi: user admin yang login atau menerima notifikasi.',
  `policy_id` INT UNSIGNED NOT NULL COMMENT 'Referensi policy terkait.',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom assigned_at. Contoh implementasi: isi sesuai kebutuhan modul user_policies.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  PRIMARY KEY (`user_policy_id`),
  UNIQUE KEY `uk_user_policies_user_policy` (`user_id`, `policy_id`),
  CONSTRAINT `fk_user_policies_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_policies_policy`
    FOREIGN KEY (`policy_id`) REFERENCES `policies`(`policy_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_policies_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `group_users` (

  `group_user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik anggota group.',
  `group_id` INT UNSIGNED NOT NULL COMMENT 'Referensi group terkait.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user yang terkait. Contoh implementasi: user admin yang login atau menerima notifikasi.',
  `added_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom added_at. Contoh implementasi: isi sesuai kebutuhan modul group_users.',
  `added_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user yang menambahkan anggota ke group.',
  PRIMARY KEY (`group_user_id`),
  UNIQUE KEY `uk_group_users_group_user` (`group_id`, `user_id`),
  CONSTRAINT `fk_group_users_group`
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`group_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_users_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_users_added_by`
    FOREIGN KEY (`added_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `group_roles` (

  `group_role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi group-role.',
  `group_id` INT UNSIGNED NOT NULL COMMENT 'Referensi group terkait.',
  `role_id` INT UNSIGNED NOT NULL COMMENT 'Referensi role terkait. Contoh implementasi: role ''operator_lab''.',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom assigned_at. Contoh implementasi: isi sesuai kebutuhan modul group_roles.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  PRIMARY KEY (`group_role_id`),
  UNIQUE KEY `uk_group_roles_group_role` (`group_id`, `role_id`),
  CONSTRAINT `fk_group_roles_group`
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`group_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_roles_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_roles_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `group_policies` (

  `group_policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi group-policy.',
  `group_id` INT UNSIGNED NOT NULL COMMENT 'Referensi group terkait.',
  `policy_id` INT UNSIGNED NOT NULL COMMENT 'Referensi policy terkait.',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom assigned_at. Contoh implementasi: isi sesuai kebutuhan modul group_policies.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  PRIMARY KEY (`group_policy_id`),
  UNIQUE KEY `uk_group_policies_group_policy` (`group_id`, `policy_id`),
  CONSTRAINT `fk_group_policies_group`
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`group_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_policies_policy`
    FOREIGN KEY (`policy_id`) REFERENCES `policies`(`policy_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_policies_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_sessions` (

  `session_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik sesi login.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user yang terkait. Contoh implementasi: user admin yang login atau menerima notifikasi.',
  `session_token` VARCHAR(255) NOT NULL COMMENT 'JWT/session token',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT 'Alamat IP client/perangkat. Contoh implementasi: ''192.168.1.10''.',
  `user_agent` TEXT DEFAULT NULL COMMENT 'Identitas browser/perangkat. Contoh implementasi: ''Mozilla/5.0 ...''.',
  `logged_in_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu mulai sesi login. Contoh implementasi: ''2026-04-09 07:00:00''.',
  `last_activity` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu aktivitas terakhir pada sesi. Contoh implementasi: ''2026-04-09 07:45:00''.',
  `logout_at` DATETIME DEFAULT NULL COMMENT 'Waktu logout user. Contoh implementasi: ''2026-04-09 08:00:00''.',
  `is_online` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Status sesi masih aktif. Contoh implementasi: 1=online, 0=offline.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`session_id`),
  UNIQUE KEY `uk_user_sessions_token` (`session_token`(191)),
  KEY `idx_user_sessions_user_online` (`user_id`, `is_online`),
  CONSTRAINT `fk_user_sessions_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_access_tokens` (

  `token_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik custom QR/token akses user. Dipakai untuk akun sementara seperti pengawas, intern, atau magang.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user penerima token akses.',
  `token_reference` VARCHAR(100) NOT NULL COMMENT 'Kode referensi internal token. Contoh: UAT-2026-04-INTERN-001.',
  `token_payload_hash` CHAR(64) NOT NULL COMMENT 'Hash payload QR/token. Payload mentah tidak disimpan sebagai kunci utama.',
  `token_type` ENUM('temporary_login','custom_qr_access','pengawas','intern','magang','other') NOT NULL DEFAULT 'custom_qr_access' COMMENT 'Jenis token akses user.',
  `valid_from` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu mulai token berlaku.',
  `valid_until` DATETIME DEFAULT NULL COMMENT 'Waktu token berakhir. NULL berarti mengikuti valid_until akun user.',
  `max_use_count` INT UNSIGNED DEFAULT NULL COMMENT 'Batas jumlah pemakaian token. NULL berarti tidak dibatasi oleh jumlah pakai.',
  `used_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Jumlah token sudah digunakan.',
  `status` ENUM('aktif','nonaktif','dicabut','kedaluwarsa') NOT NULL DEFAULT 'aktif' COMMENT 'Status token akses user.',
  `issued_by` INT UNSIGNED DEFAULT NULL COMMENT 'User yang menerbitkan token.',
  `revoked_by` INT UNSIGNED DEFAULT NULL COMMENT 'User yang mencabut token.',
  `revoked_at` DATETIME DEFAULT NULL COMMENT 'Waktu token dicabut.',
  `revoked_reason` VARCHAR(255) DEFAULT NULL COMMENT 'Alasan pencabutan token.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis.',
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `uk_user_access_token_reference` (`token_reference`),
  UNIQUE KEY `uk_user_access_token_payload_hash` (`token_payload_hash`),
  KEY `idx_user_access_tokens_user_status` (`user_id`, `status`, `valid_until`),
  KEY `idx_user_access_tokens_type_status` (`token_type`, `status`, `valid_until`),
  CONSTRAINT `fk_user_access_tokens_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_access_tokens_issued_by`
    FOREIGN KEY (`issued_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_user_access_tokens_revoked_by`
    FOREIGN KEY (`revoked_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

