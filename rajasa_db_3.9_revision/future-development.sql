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

