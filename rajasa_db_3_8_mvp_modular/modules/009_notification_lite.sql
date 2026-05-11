-- =========================================================
-- 009 - NOTIFICATION LITE: in-app/system only
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `notification_rules` (
  `rule_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_key` VARCHAR(100) NOT NULL COMMENT 'Kode event unik. Contoh: student_import_partial_failed.',
  `rule_name` VARCHAR(150) NOT NULL COMMENT 'Nama rule untuk UI admin.',
  `module_name` VARCHAR(50) NOT NULL COMMENT 'Modul pemilik notifikasi. Contoh: academic, students, attendance, import.',
  `entity_type` VARCHAR(50) DEFAULT NULL COMMENT 'Tipe entity terkait. Contoh: import_jobs.',
  `default_level_notif` ENUM('info','warning','error','critical') NOT NULL DEFAULT 'info',
  `importance_level` ENUM('optional','required','urgent','critical') NOT NULL DEFAULT 'optional',
  `required_perm_slug` VARCHAR(100) DEFAULT NULL COMMENT 'Permission minimal agar user menjadi target notifikasi.',
  `target_role_slug` VARCHAR(50) DEFAULT NULL COMMENT 'Role default target bila rule berbasis role.',
  `target_group_slug` VARCHAR(100) DEFAULT NULL COMMENT 'Group default target bila rule berbasis group.',
  `target_policy_slug` VARCHAR(100) DEFAULT NULL COMMENT 'Policy default target bila rule berbasis policy.',
  `default_frequency` ENUM('instant','daily','weekly','manual') NOT NULL DEFAULT 'instant',
  `default_popup_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `default_inbox_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `default_system_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `user_configurable` TINYINT(1) NOT NULL DEFAULT 1,
  `admin_configurable` TINYINT(1) NOT NULL DEFAULT 1,
  `rule_ui_group` VARCHAR(80) DEFAULT NULL,
  `recommended_action` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_critical_locked` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Jika 1, user preference tidak boleh mematikan notifikasi ini.',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`rule_id`),
  UNIQUE KEY `uk_notification_rules_event` (`event_key`),
  KEY `idx_notification_rules_module` (`module_name`, `is_active`),
  KEY `idx_notification_rules_importance` (`importance_level`, `is_active`),
  KEY `idx_notification_rules_perm` (`required_perm_slug`),
  KEY `idx_notification_rules_role` (`target_role_slug`),
  KEY `idx_notification_rules_group` (`target_group_slug`),
  KEY `idx_notification_rules_policy` (`target_policy_slug`),
  CONSTRAINT `fk_notification_rules_permission`
    FOREIGN KEY (`required_perm_slug`) REFERENCES `permissions`(`perm_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notification_rules_role`
    FOREIGN KEY (`target_role_slug`) REFERENCES `roles`(`role_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notification_rules_group`
    FOREIGN KEY (`target_group_slug`) REFERENCES `groups`(`group_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notification_rules_policy`
    FOREIGN KEY (`target_policy_slug`) REFERENCES `policies`(`policy_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notification_rules_created_by`
    FOREIGN KEY (`created_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notifikasi` (
  `notif_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `rule_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi rule yang memicu notifikasi.',
  `event_key` VARCHAR(100) NOT NULL,
  `module_name` VARCHAR(50) NOT NULL,
  `entity_type` VARCHAR(50) DEFAULT NULL,
  `entity_id` BIGINT UNSIGNED DEFAULT NULL,
  `dedupe_key` VARCHAR(180) DEFAULT NULL COMMENT 'Kunci untuk mencegah spam notifikasi event yang sama.',
  `pesan` TEXT NOT NULL,
  `level_notif` ENUM('info','warning','error','critical') NOT NULL DEFAULT 'info',
  `importance_level` ENUM('optional','required','urgent','critical') NOT NULL DEFAULT 'optional',
  `required_perm_slug` VARCHAR(100) DEFAULT NULL,
  `target_role_slug` VARCHAR(50) DEFAULT NULL,
  `target_group_slug` VARCHAR(100) DEFAULT NULL,
  `target_policy_slug` VARCHAR(100) DEFAULT NULL,
  `action_label` VARCHAR(80) DEFAULT NULL,
  `action_url` VARCHAR(255) DEFAULT NULL,
  `frequency` ENUM('instant','daily','weekly','manual') NOT NULL DEFAULT 'instant',
  `resolution_type` ENUM('auto','manual') NOT NULL DEFAULT 'auto',
  `is_resolved` TINYINT(1) NOT NULL DEFAULT 0,
  `open_unique_key` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `is_resolved` = 0 AND `dedupe_key` IS NOT NULL THEN 1 ELSE NULL END) STORED,
  `resolved_at` DATETIME DEFAULT NULL,
  `resolved_by` INT UNSIGNED DEFAULT NULL,
  `metadata_json` JSON DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`notif_id`),
  UNIQUE KEY `uk_notifikasi_dedupe_open` (`dedupe_key`, `open_unique_key`),
  KEY `idx_notifikasi_module` (`module_name`, `event_key`),
  KEY `idx_notifikasi_resolved` (`is_resolved`, `created_at`),
  KEY `idx_notifikasi_entity` (`entity_type`, `entity_id`),
  KEY `idx_notifikasi_perm` (`required_perm_slug`),
  CONSTRAINT `fk_notifikasi_rule`
    FOREIGN KEY (`rule_id`) REFERENCES `notification_rules`(`rule_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_permission`
    FOREIGN KEY (`required_perm_slug`) REFERENCES `permissions`(`perm_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_target_role`
    FOREIGN KEY (`target_role_slug`) REFERENCES `roles`(`role_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_target_group`
    FOREIGN KEY (`target_group_slug`) REFERENCES `groups`(`group_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_target_policy`
    FOREIGN KEY (`target_policy_slug`) REFERENCES `policies`(`policy_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_resolved_by`
    FOREIGN KEY (`resolved_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notifikasi_penerima` (
  `recipient_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `notif_id` BIGINT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `delivery_channel` ENUM('in_app','system') NOT NULL DEFAULT 'in_app',
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `read_at` DATETIME DEFAULT NULL,
  `delivered_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`recipient_id`),
  UNIQUE KEY `uk_notifikasi_penerima_user` (`notif_id`, `user_id`, `delivery_channel`),
  KEY `idx_notifikasi_penerima_inbox` (`user_id`, `is_read`, `created_at`),
  CONSTRAINT `fk_notifikasi_penerima_notif`
    FOREIGN KEY (`notif_id`) REFERENCES `notifikasi`(`notif_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_penerima_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_notification_preferences` (
  `preference_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `module_name` VARCHAR(50) NOT NULL,
  `event_key` VARCHAR(100) DEFAULT NULL,
  `frequency` ENUM('instant','daily','weekly','off') NOT NULL DEFAULT 'instant',
  `popup_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `inbox_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `system_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `is_muted` TINYINT(1) NOT NULL DEFAULT 0,
  `configured_by_user_id` INT UNSIGNED DEFAULT NULL,
  `configuration_source` ENUM('self','admin','system','role_default','group_default','policy_default') NOT NULL DEFAULT 'self',
  `is_admin_enforced` TINYINT(1) NOT NULL DEFAULT 0,
  `admin_note` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`preference_id`),
  UNIQUE KEY `uk_user_notification_pref` (`user_id`, `module_name`, `event_key`),
  KEY `idx_user_notification_pref_module` (`module_name`, `event_key`),
  KEY `idx_user_notification_pref_configured_by` (`configured_by_user_id`),
  CONSTRAINT `fk_user_notification_pref_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_notification_pref_configured_by`
    FOREIGN KEY (`configured_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_notification_preferences` (
  `role_notification_pref_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `principal_type` ENUM('role','group','policy','permission','custom') NOT NULL DEFAULT 'role',
  `principal_key` VARCHAR(150) NOT NULL,
  `role_id` INT UNSIGNED DEFAULT NULL,
  `group_id` INT UNSIGNED DEFAULT NULL,
  `policy_id` INT UNSIGNED DEFAULT NULL,
  `required_perm_slug` VARCHAR(100) DEFAULT NULL,
  `module_name` VARCHAR(50) NOT NULL,
  `event_key` VARCHAR(100) DEFAULT NULL,
  `event_key_key` VARCHAR(100) GENERATED ALWAYS AS (IFNULL(`event_key`, '*')) STORED,
  `frequency` ENUM('inherit','instant','daily','weekly','off') NOT NULL DEFAULT 'inherit',
  `popup_enabled` TINYINT(1) DEFAULT NULL,
  `inbox_enabled` TINYINT(1) DEFAULT NULL,
  `system_enabled` TINYINT(1) DEFAULT NULL,
  `is_muted` TINYINT(1) NOT NULL DEFAULT 0,
  `is_enforced` TINYINT(1) NOT NULL DEFAULT 0,
  `priority` SMALLINT UNSIGNED NOT NULL DEFAULT 100,
  `conditions_json` JSON DEFAULT NULL,
  `configured_by_user_id` INT UNSIGNED DEFAULT NULL,
  `admin_note` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_notification_pref_id`),
  UNIQUE KEY `uk_role_notification_pref` (`principal_type`, `principal_key`, `module_name`, `event_key_key`),
  KEY `idx_role_notification_pref_role` (`role_id`),
  KEY `idx_role_notification_pref_group` (`group_id`),
  KEY `idx_role_notification_pref_policy` (`policy_id`),
  KEY `idx_role_notification_pref_permission` (`required_perm_slug`),
  KEY `idx_role_notification_pref_module` (`module_name`, `event_key`, `priority`),
  KEY `idx_role_notification_pref_configured_by` (`configured_by_user_id`),
  CONSTRAINT `fk_role_notification_pref_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_notification_pref_group`
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`group_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_notification_pref_policy`
    FOREIGN KEY (`policy_id`) REFERENCES `policies`(`policy_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_notification_pref_permission`
    FOREIGN KEY (`required_perm_slug`) REFERENCES `permissions`(`perm_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_role_notification_pref_configured_by`
    FOREIGN KEY (`configured_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_role_notification_pref_principal_ref`
    CHECK (
      (`principal_type`='role' AND `role_id` IS NOT NULL)
      OR (`principal_type`='group' AND `group_id` IS NOT NULL)
      OR (`principal_type`='policy' AND `policy_id` IS NOT NULL)
      OR (`principal_type`='permission' AND `required_perm_slug` IS NOT NULL)
      OR (`principal_type`='custom')
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

