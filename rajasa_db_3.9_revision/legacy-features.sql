CREATE TABLE IF NOT EXISTS `notifikasi_penerima` (
  `recipient_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `notif_id` BIGINT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `delivery_channel` ENUM('in_app','email','whatsapp','system') NOT NULL DEFAULT 'in_app',
  `is_read` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Status baca user tertentu. Tidak sama dengan is_resolved.',
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

CREATE TABLE `notifikasi_admin` (

  `notif_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik notifikasi admin.',
  `user_id` INT UNSIGNED DEFAULT NULL COMMENT 'Boleh NULL jika notifikasi broadcast',
  `pesan` TEXT NOT NULL COMMENT 'Isi pesan notifikasi. Contoh implementasi: ''Scan QR gagal di LAB-TKJ-01''.',
  `level_notif` ENUM('info','warning','error','critical') NOT NULL DEFAULT 'info' COMMENT 'Level notifikasi. Contoh implementasi: ''warning'' atau ''critical''.',
  `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi ruangan terkait.',
  `related_log_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi log scan terkait notifikasi.',
  `is_read` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Status baca notifikasi. Contoh implementasi: 0=belum dibaca, 1=sudah dibaca.',
  `read_at` DATETIME DEFAULT NULL COMMENT 'Waktu notifikasi dibaca. Contoh implementasi: ''2026-04-09 08:30:00''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`notif_id`),
  KEY `idx_notifikasi_admin_read` (`user_id`, `is_read`, `created_at`),
  CONSTRAINT `fk_notifikasi_admin_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_admin_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_admin_related_log`
    FOREIGN KEY (`related_log_id`) REFERENCES `log_scan_qr`(`log_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_notification_preferences` (
  `preference_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `module_name` VARCHAR(50) NOT NULL,
  `event_key` VARCHAR(100) DEFAULT NULL COMMENT 'NULL berarti preferensi umum untuk module_name tersebut.',
  `frequency` ENUM('instant','daily','weekly','off') NOT NULL DEFAULT 'instant',
  `popup_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `inbox_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `email_enabled` TINYINT(1) NOT NULL DEFAULT 0,
  `is_muted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Critical locked tetap dikirim walau user mute.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`preference_id`),
  UNIQUE KEY `uk_user_notification_pref` (`user_id`, `module_name`, `event_key`),
  KEY `idx_user_notification_pref_module` (`module_name`, `event_key`),
  CONSTRAINT `fk_user_notification_pref_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_notification_preferences` (
  `role_notification_pref_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `principal_type` ENUM('role','group','policy','permission','custom') NOT NULL DEFAULT 'role' COMMENT 'Jenis sumber default preferensi. Mendukung pola AWS-like: role, group, policy, permission, atau custom.',
  `principal_key` VARCHAR(150) NOT NULL COMMENT 'Kunci principal. Contoh: role_slug, group_slug, policy_slug, perm_slug, atau nama scope custom.',
  `role_id` INT UNSIGNED DEFAULT NULL COMMENT 'Diisi jika principal_type=role.',
  `group_id` INT UNSIGNED DEFAULT NULL COMMENT 'Diisi jika principal_type=group. Dipakai agar siswa bisa memakai default group, bukan per-user.',
  `policy_id` INT UNSIGNED DEFAULT NULL COMMENT 'Diisi jika principal_type=policy.',
  `required_perm_slug` VARCHAR(100) DEFAULT NULL COMMENT 'Diisi jika principal_type=permission atau untuk membatasi default berdasarkan permission efektif.',
  `module_name` VARCHAR(50) NOT NULL COMMENT 'Module notifikasi. Contoh: attendance, import, notifications.',
  `event_key` VARCHAR(100) DEFAULT NULL COMMENT 'NULL berarti default untuk semua event pada module tersebut.',
  `event_key_key` VARCHAR(100) GENERATED ALWAYS AS (IFNULL(`event_key`, '*')) STORED,
  `frequency` ENUM('inherit','instant','daily','weekly','off') NOT NULL DEFAULT 'inherit',
  `popup_enabled` TINYINT(1) DEFAULT NULL COMMENT 'NULL berarti inherit dari notification_rules.',
  `inbox_enabled` TINYINT(1) DEFAULT NULL COMMENT 'NULL berarti inherit dari notification_rules.',
  `email_enabled` TINYINT(1) DEFAULT NULL COMMENT 'NULL berarti inherit dari notification_rules.',
  `whatsapp_enabled` TINYINT(1) DEFAULT NULL COMMENT 'NULL berarti inherit dari notification_rules.',
  `system_enabled` TINYINT(1) DEFAULT NULL COMMENT 'NULL berarti inherit dari notification_rules.',
  `is_muted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Default mute pada principal. Tidak berlaku untuk required/urgent/critical yang dikunci.',
  `is_enforced` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Jika 1, default ini tidak boleh dioverride oleh user dengan level setara/bawah.',
  `priority` SMALLINT UNSIGNED NOT NULL DEFAULT 100 COMMENT 'Prioritas resolver. Angka lebih kecil menang.',
  `conditions_json` JSON DEFAULT NULL COMMENT 'Kondisi AWS-like. Contoh: {"resource_scope":"self/*"}.',
  `configured_by_user_id` INT UNSIGNED DEFAULT NULL,
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_notification_pref_id`),
  UNIQUE KEY `uk_role_notification_pref_principal` (`principal_type`, `principal_key`, `module_name`, `event_key_key`),
  KEY `idx_role_notification_pref_role` (`role_id`, `module_name`, `status`),
  KEY `idx_role_notification_pref_group` (`group_id`, `module_name`, `status`),
  KEY `idx_role_notification_pref_policy` (`policy_id`, `module_name`, `status`),
  KEY `idx_role_notification_pref_permission` (`required_perm_slug`, `module_name`, `status`),
  KEY `idx_role_notification_pref_resolver` (`principal_type`, `principal_key`, `priority`, `status`),
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
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `notification_rules` (
  `rule_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_key` VARCHAR(100) NOT NULL COMMENT 'Kode event unik. Contoh: plotting_incomplete, student_import_partial_failed.',
  `rule_name` VARCHAR(150) NOT NULL COMMENT 'Nama rule untuk UI admin.',
  `module_name` VARCHAR(50) NOT NULL COMMENT 'Modul pemilik notifikasi. Contoh: academic, students, attendance, import.',
  `entity_type` VARCHAR(50) DEFAULT NULL COMMENT 'Tipe entity terkait. Contoh: plotting_rombel, import_jobs.',
  `default_level_notif` ENUM('info','warning','error','critical') NOT NULL DEFAULT 'info',
  `required_perm_slug` VARCHAR(100) DEFAULT NULL COMMENT 'Permission minimal agar user menjadi target notifikasi.',
  `target_role_slug` VARCHAR(50) DEFAULT NULL COMMENT 'Role default target bila rule berbasis role.',
  `default_frequency` ENUM('instant','daily','weekly','manual') NOT NULL DEFAULT 'instant',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_critical_locked` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Jika 1, user preference tidak boleh mematikan notifikasi ini.',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`rule_id`),
  UNIQUE KEY `uk_notification_rules_event` (`event_key`),
  KEY `idx_notification_rules_module` (`module_name`, `is_active`),
  KEY `idx_notification_rules_perm` (`required_perm_slug`),
  KEY `idx_notification_rules_role` (`target_role_slug`),
  CONSTRAINT `fk_notification_rules_permission`
    FOREIGN KEY (`required_perm_slug`) REFERENCES `permissions`(`perm_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notification_rules_role`
    FOREIGN KEY (`target_role_slug`) REFERENCES `roles`(`role_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notification_rules_created_by`
    FOREIGN KEY (`created_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `scanner_devices` (
  `scanner_device_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik perangkat scanner umum. Dipakai untuk HP, tablet, desktop browser, atau perangkat lain.',
  `device_uuid` CHAR(36) NOT NULL COMMENT 'UUID device dari aplikasi/browser. Untuk web, nilai dapat disimpan di localStorage agar device dikenali ulang.',
  `user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User terakhir/utama yang memakai device. Boleh NULL untuk device yang belum terikat permanen.',
  `device_label` VARCHAR(100) DEFAULT NULL COMMENT 'Label tampilan device. Contoh: HP Pak Budi, Tablet Staff TU.',
  `device_type` ENUM('web_mobile','web_tablet','web_desktop','esp32_cam','other') NOT NULL DEFAULT 'web_mobile' COMMENT 'Tipe device scanner. Untuk alur baru umumnya web_mobile.',
  `browser_name` VARCHAR(100) DEFAULT NULL COMMENT 'Nama browser hasil parsing user agent. Contoh: Chrome Mobile.',
  `browser_version` VARCHAR(50) DEFAULT NULL COMMENT 'Versi browser hasil parsing user agent.',
  `os_name` VARCHAR(100) DEFAULT NULL COMMENT 'Nama OS device. Contoh: Android, iOS, Windows.',
  `user_agent` TEXT DEFAULT NULL COMMENT 'User agent mentah dari request untuk audit teknis.',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT 'IP terakhir yang dipakai device saat scan.',
  `status` ENUM('aktif','nonaktif','blokir') NOT NULL DEFAULT 'aktif' COMMENT 'Status device scanner. Device dengan status blokir tidak boleh memulai sesi scan.',
  `trusted_at` DATETIME DEFAULT NULL COMMENT 'Waktu device ditandai dipercaya oleh admin/sistem. Boleh NULL jika belum memakai mekanisme trusted device.',
  `blocked_reason` VARCHAR(255) DEFAULT NULL COMMENT 'Alasan device diblokir bila status=blokir.',
  `last_used_at` DATETIME DEFAULT NULL COMMENT 'Waktu terakhir device dipakai untuk membuka/melanjutkan sesi scan.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`scanner_device_id`),
  UNIQUE KEY `uk_scanner_devices_uuid` (`device_uuid`),
  KEY `idx_scanner_devices_user_status` (`user_id`, `status`),
  KEY `idx_scanner_devices_type_status` (`device_type`, `status`),
  CONSTRAINT `fk_scanner_devices_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `jurusan_ruangan_buffer` (

  `buffer_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `jurusan_id` INT UNSIGNED NOT NULL,
  `ruangan_id` INT UNSIGNED NOT NULL,
  `jenis_ruangan` ENUM('kelas','lab','kantor') NOT NULL DEFAULT 'kelas',
  `nama_ruangan` VARCHAR(100) NOT NULL COMMENT 'Nama ruangan. Contoh implementasi: ''Lab TKJ 1''.',
  `urut_auto` SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Contoh implementasi: ''Lab TKJ 1,''Lab KJ 2''.',
  `status` ENUM('aktif','nonaktif','maintenance') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`buffer_id`),
  UNIQUE KEY `uk_jurusan_ruangan` (`jurusan_id`,`nama_ruangan`),
  CONSTRAINT `fk_buffer_jurusan` FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_buffer_ruangan` FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- memilih jenis ruangan saja
-- nama ruangan auto generate dari jenis_ruangan, jurusan, dan auto increment


CREATE TABLE `jurusan_dashboard_buffer` (

  `buffer_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `jurusan_id` INT UNSIGNED NOT NULL,
  `kode_jurusan` VARCHAR(10) NOT NULL,
  `nama_jurusan` VARCHAR(100) NOT NULL,
  `ketua_jurusan_nama` VARCHAR(100) DEFAULT NULL,
  `guru_id_ketua` INT UNSIGNED DEFAULT NULL,
  `total_siswa` INT UNSIGNED NOT NULL DEFAULT 0,
  `total_ruang_kelas` INT UNSIGNED NOT NULL DEFAULT 0,
  `total_ruang_lab` INT UNSIGNED NOT NULL DEFAULT 0,
  `tahun_ajaran` VARCHAR(9) DEFAULT NULL,
  `semester` ENUM('ganjil','genap','pendek') DEFAULT NULL,
  `status_jurusan` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `sumber_perhitungan` ENUM('otomatis','manual') NOT NULL DEFAULT 'otomatis',
  `last_sync_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`buffer_id`),
  UNIQUE KEY `uk_jurusan_dashboard_buffer` (`jurusan_id`, `tahun_ajaran`, `semester`),
  KEY `idx_jurusan_dashboard_status` (`status_jurusan`),
  CONSTRAINT `fk_jurusan_dashboard_buffer_jurusan`
    FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_jurusan_dashboard_buffer_guru`
    FOREIGN KEY (`guru_id_ketua`) REFERENCES `guru_staff`(`guru_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `user_activity_display_buffer` (

  `buffer_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik buffer tampilan log users.',
  `log_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referensi user_activities.log_id.',
  `user_label` VARCHAR(100) DEFAULT NULL COMMENT 'Nama tampil user untuk kolom User.',
  `username_snapshot` VARCHAR(50) DEFAULT NULL,
  `nisn_snapshot` VARCHAR(20) DEFAULT NULL,
  `role_snapshot` VARCHAR(50) DEFAULT NULL,
  `role_slug_snapshot` VARCHAR(50) DEFAULT NULL,
  `user_type_snapshot` ENUM('siswa','guru_staff','system') DEFAULT NULL,
  `action_type` VARCHAR(50) NOT NULL,
  `module_name` VARCHAR(50) DEFAULT NULL,
  `target_table` VARCHAR(50) DEFAULT NULL,
  `target_id` VARCHAR(100) DEFAULT NULL,
  `status` ENUM('sukses','gagal','peringatan','ditolak','dibatalkan') NOT NULL DEFAULT 'sukses',
  `keterangan_ringkas` VARCHAR(255) DEFAULT NULL COMMENT 'Ringkasan activity_description untuk tabel utama.',
  `ruangan_id` INT UNSIGNED DEFAULT NULL,
  `ruangan_label` VARCHAR(100) DEFAULT NULL COMMENT 'Kode/nama ruangan jika relevan.',
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `browser_device` VARCHAR(150) DEFAULT NULL COMMENT 'Ringkasan user_agent untuk filter audit teknis.',
  `activity_created_at` DATETIME NOT NULL COMMENT 'Timestamp aktivitas dari user_activities.created_at.',
  `archive_status` ENUM('hot','archived') NOT NULL DEFAULT 'hot',
  `synced_at` DATETIME DEFAULT NULL COMMENT 'Waktu terakhir buffer disinkronkan.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`buffer_id`),
  UNIQUE KEY `uk_user_activity_display_log` (`log_id`),
  KEY `idx_user_activity_display_user` (`username_snapshot`, `nisn_snapshot`, `user_label`),
  KEY `idx_user_activity_display_role_type` (`role_slug_snapshot`, `user_type_snapshot`),
  KEY `idx_user_activity_display_action_module` (`action_type`, `module_name`, `activity_created_at`),
  KEY `idx_user_activity_display_status` (`status`, `activity_created_at`),
  KEY `idx_user_activity_display_target` (`target_table`, `target_id`),
  KEY `idx_user_activity_display_ruangan` (`ruangan_id`, `activity_created_at`),
  KEY `idx_user_activity_display_ip` (`ip_address`, `activity_created_at`),
  KEY `idx_user_activity_display_archive` (`archive_status`, `activity_created_at`),
  CONSTRAINT `fk_user_activity_display_log`
    FOREIGN KEY (`log_id`) REFERENCES `user_activities`(`log_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_activity_display_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `user_manage_buffer` (

  `buffer_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik buffer tampilan manage users.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi akun pada tabel users.',
  `username` VARCHAR(50) NOT NULL,
  `nama_lengkap` VARCHAR(100) DEFAULT NULL,
  `nisn` VARCHAR(20) DEFAULT NULL,
  `role_summary` VARCHAR(255) DEFAULT NULL COMMENT 'Gabungan role aktif untuk tampilan ringkas.',
  `primary_role_slug` VARCHAR(50) DEFAULT NULL COMMENT 'Role utama untuk filter cepat.',
  `user_type` ENUM('siswa','guru_staff','system') NOT NULL,
  `jurusan_id` INT UNSIGNED DEFAULT NULL,
  `kode_jurusan` VARCHAR(10) DEFAULT NULL,
  `nama_jurusan` VARCHAR(100) DEFAULT NULL,
  `status` ENUM('aktif','nonaktif','terblokir') NOT NULL DEFAULT 'aktif',
  `valid_until` DATETIME DEFAULT NULL,
  `valid_until_class` ENUM('permanen','aktif_sementara','segera_berakhir','expired') NOT NULL DEFAULT 'permanen' COMMENT 'Klasifikasi valid_until hasil refresh aplikasi/scheduler.',
  `last_login` DATETIME DEFAULT NULL,
  `online_status` ENUM('online','offline') NOT NULL DEFAULT 'offline',
  `last_activity` DATETIME DEFAULT NULL,
  `created_at_source` DATETIME DEFAULT NULL COMMENT 'users.created_at untuk sorting/filter created_at.',
  `updated_at_source` DATETIME DEFAULT NULL COMMENT 'users.updated_at untuk informasi perubahan akun.',
  `synced_at` DATETIME DEFAULT NULL COMMENT 'Waktu terakhir buffer disinkronkan.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`buffer_id`),
  UNIQUE KEY `uk_user_manage_buffer_user` (`user_id`),
  KEY `idx_user_manage_search` (`username`, `nisn`, `nama_lengkap`),
  KEY `idx_user_manage_role_type` (`primary_role_slug`, `user_type`),
  KEY `idx_user_manage_jurusan` (`jurusan_id`, `status`),
  KEY `idx_user_manage_valid` (`valid_until_class`, `valid_until`),
  KEY `idx_user_manage_login` (`last_login`),
  KEY `idx_user_manage_online` (`online_status`, `last_activity`),
  CONSTRAINT `fk_user_manage_buffer_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_manage_buffer_jurusan`
    FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_activity_cold_archives` (

  `cold_archive_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik metadata cold archive user_activities.',
  `periode_tahun` SMALLINT UNSIGNED NOT NULL COMMENT 'Tahun periode log yang diekspor. Contoh: 2026.',
  `periode_bulan` TINYINT UNSIGNED NOT NULL COMMENT 'Bulan periode log yang diekspor. Contoh: 4 untuk April.',
  `periode_mulai` DATE NOT NULL COMMENT 'Tanggal awal periode log yang masuk archive.',
  `periode_selesai` DATE NOT NULL COMMENT 'Tanggal akhir periode log yang masuk archive.',
  `source_table` VARCHAR(50) NOT NULL DEFAULT 'user_activities' COMMENT 'Tabel sumber archive.',
  `record_count` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Jumlah record log yang diekspor ke archive.',
  `exported_file_name` VARCHAR(255) DEFAULT NULL COMMENT 'Nama file hasil export sebelum kompres. Contoh: user_activities_2026_04.csv.',
  `compressed_file_name` VARCHAR(255) DEFAULT NULL COMMENT 'Nama file hasil kompres. Contoh: user_activities_2026_04.csv.gz.',
  `compressed_format` ENUM('zip','gzip','zstd') NOT NULL DEFAULT 'gzip' COMMENT 'Format kompresi cold archive.',
  `storage_disk` VARCHAR(50) NOT NULL DEFAULT 'local' COMMENT 'Disk/driver penyimpanan archive. Contoh: local, s3, nas.',
  `storage_path` VARCHAR(500) DEFAULT NULL COMMENT 'Path file cold archive hasil kompres.',
  `checksum_sha256` CHAR(64) DEFAULT NULL COMMENT 'Checksum SHA-256 file kompres untuk validasi integritas.',
  `file_size_bytes` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Ukuran file kompres dalam byte.',
  `arsip_batch_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Relasi ke batch arsip umum jika proses dicatat juga di arsip_batch.',
  `media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Relasi ke media_berkas jika file archive dicatat sebagai media.',
  `status` ENUM('draft','exported','compressed','verified','failed','restored') NOT NULL DEFAULT 'draft' COMMENT 'Status proses cold archive bulanan.',
  `executed_by` INT UNSIGNED DEFAULT NULL COMMENT 'User yang menjalankan archive, atau NULL jika dijalankan scheduler system.',
  `started_at` DATETIME DEFAULT NULL COMMENT 'Waktu mulai proses export/archive.',
  `finished_at` DATETIME DEFAULT NULL COMMENT 'Waktu selesai proses export/archive.',
  `error_message` TEXT DEFAULT NULL COMMENT 'Pesan error bila proses archive gagal.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`cold_archive_id`),
  UNIQUE KEY `uk_user_activity_cold_archive_period` (`source_table`, `periode_tahun`, `periode_bulan`),
  KEY `idx_user_activity_cold_archive_status` (`status`, `periode_mulai`, `periode_selesai`),
  KEY `idx_user_activity_cold_archive_batch` (`arsip_batch_id`),
  KEY `idx_user_activity_cold_archive_media` (`media_id`),
  CONSTRAINT `fk_user_activity_cold_archive_batch`
    FOREIGN KEY (`arsip_batch_id`) REFERENCES `arsip_batch`(`arsip_batch_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_user_activity_cold_archive_media`
    FOREIGN KEY (`media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_user_activity_cold_archive_user`
    FOREIGN KEY (`executed_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_user_activity_cold_archive_month`
    CHECK (`periode_bulan` BETWEEN 1 AND 12)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `arsip_detail` (

  `arsip_detail_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik detail item dalam batch arsip.',
  `arsip_batch_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referensi batch pengarsipan.',
  `nama_tabel_sumber` VARCHAR(50) NOT NULL COMMENT 'Nama tabel sumber data. Contoh implementasi: ''presensi'' atau ''log_scan_qr''.',
  `primary_key_sumber` VARCHAR(100) NOT NULL COMMENT 'Primary key data sumber dalam bentuk teks.',
  `media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi metadata media jika item arsip berupa file/berkas.',
  `path_sumber` VARCHAR(500) DEFAULT NULL COMMENT 'Path asal file sebelum diarsipkan.',
  `path_arsip` VARCHAR(500) DEFAULT NULL COMMENT 'Path tujuan file setelah dipindahkan ke arsip.',
  `checksum_sha256` CHAR(64) DEFAULT NULL COMMENT 'Checksum file/data saat diarsipkan untuk audit integritas.',
  `status` ENUM('dijadwalkan','diarsipkan','dipulihkan','gagal') NOT NULL DEFAULT 'dijadwalkan' COMMENT 'Status detail item arsip.',
  `archived_at` DATETIME DEFAULT NULL COMMENT 'Waktu item berhasil diarsipkan.',
  `restored_at` DATETIME DEFAULT NULL COMMENT 'Waktu item dipulihkan dari arsip.',
  `catatan` TEXT DEFAULT NULL COMMENT 'Catatan teknis hasil arsip/pemulihan.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`arsip_detail_id`),
  KEY `idx_arsip_detail_lookup` (`arsip_batch_id`, `nama_tabel_sumber`, `status`),
  CONSTRAINT `fk_arsip_detail_batch`
    FOREIGN KEY (`arsip_batch_id`) REFERENCES `arsip_batch`(`arsip_batch_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_arsip_detail_media`
    FOREIGN KEY (`media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `arsip_batch` (

  `arsip_batch_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik batch pengarsipan.',
  `nama_batch` VARCHAR(150) NOT NULL COMMENT 'Nama batch arsip. Contoh implementasi: ''arsip_semester_ganjil_2026''.',
  `periode_mulai` DATE NOT NULL COMMENT 'Tanggal awal data yang masuk batch arsip.',
  `periode_selesai` DATE NOT NULL COMMENT 'Tanggal akhir data yang masuk batch arsip.',
  `jenis_batch` ENUM('presensi','scan_qr','presensi_online','media','audit','campuran') NOT NULL DEFAULT 'campuran' COMMENT 'Jenis batch arsip.',
  `target_lokasi` ENUM('database_arsip','cold_storage','object_storage','zip_export') NOT NULL DEFAULT 'object_storage' COMMENT 'Tujuan akhir arsip.',
  `status` ENUM('draft','diproses','selesai','gagal','dipulihkan') NOT NULL DEFAULT 'draft' COMMENT 'Status proses batch arsip.',
  `diproses_oleh` INT UNSIGNED DEFAULT NULL COMMENT 'User yang mengeksekusi atau menyetujui batch arsip.',
  `catatan` TEXT DEFAULT NULL COMMENT 'Catatan proses arsip, termasuk alasan atau hasil eksekusi.',
  `started_at` DATETIME DEFAULT NULL COMMENT 'Waktu mulai proses arsip.',
  `finished_at` DATETIME DEFAULT NULL COMMENT 'Waktu selesai proses arsip.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`arsip_batch_id`),
  UNIQUE KEY `uk_arsip_batch_nama` (`nama_batch`),
  KEY `idx_arsip_batch_periode` (`periode_mulai`, `periode_selesai`, `status`),
  CONSTRAINT `fk_arsip_batch_user`
    FOREIGN KEY (`diproses_oleh`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `media_berkas` (

  `media_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik metadata file/berkas.',
  `owner_table` VARCHAR(50) NOT NULL COMMENT 'Nama tabel pemilik utama berkas. Contoh implementasi: ''presensi'', ''log_scan_qr'', ''presensi_online''.',
  `owner_id` VARCHAR(100) NOT NULL COMMENT 'Primary key data pemilik dalam bentuk teks agar fleksibel. Contoh implementasi: ''12501'' atau UUID submission.',
  `kategori_berkas` ENUM('foto_scan_masuk','foto_scan_keluar','bukti_izin_sakit','foto_capture_qr','foto_selfie','screenshot_zoom','screenshot_gmeet','bukti_chat_wa','dokumen_pendukung','arsip_lainnya') NOT NULL COMMENT 'Kategori berkas. Contoh implementasi: ''foto_selfie'' atau ''bukti_chat_wa''.',
  `file_nama_asli` VARCHAR(255) DEFAULT NULL COMMENT 'Nama file saat diunggah. Contoh implementasi: ''IMG_1234.jpg''.',
  `file_nama_sistem` VARCHAR(255) NOT NULL COMMENT 'Nama file hasil penamaan sistem. Contoh implementasi: ''220145_20260409_070500.jpg''.',
  `mime_type` VARCHAR(100) DEFAULT NULL COMMENT 'Tipe MIME berkas. Contoh implementasi: ''image/jpeg'' atau ''image/png''.',
  `ekstensi_file` VARCHAR(20) DEFAULT NULL COMMENT 'Ekstensi file. Contoh implementasi: ''jpg'', ''png'', ''pdf''.',
  `ukuran_byte` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Ukuran file dalam byte. Contoh implementasi: 245812.',
  `checksum_sha256` CHAR(64) DEFAULT NULL COMMENT 'Checksum SHA-256 file untuk validasi integritas berkas.',
  `storage_disk` VARCHAR(50) NOT NULL DEFAULT 'local' COMMENT 'Nama disk/driver penyimpanan. Contoh implementasi: ''local'', ''s3'', ''nas''.',
  `storage_path` VARCHAR(500) NOT NULL COMMENT 'Path relatif atau key object storage. Contoh implementasi: ''presensi/2026/04/09/scan_masuk/220145.jpg''.',
  `is_public` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Penanda akses publik. Contoh implementasi: 0=private, 1=public.',
  `uploaded_by_user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User yang mengunggah atau merekam metadata file.',
  `uploaded_by_siswa_id` INT UNSIGNED DEFAULT NULL COMMENT 'Siswa pengunggah langsung, dipakai terutama untuk presensi online mandiri.',
  `retention_days` INT UNSIGNED DEFAULT NULL COMMENT 'Masa simpan aktif dalam hari sebelum masuk jadwal arsip. Contoh implementasi: 180.',
  `archive_status` ENUM('aktif','dijadwalkan','diarsipkan','dipulihkan','dihapus_logis') NOT NULL DEFAULT 'aktif' COMMENT 'Status siklus hidup berkas.',
  `archived_at` DATETIME DEFAULT NULL COMMENT 'Waktu file dipindah ke lokasi arsip.',
  `deleted_at` DATETIME DEFAULT NULL COMMENT 'Waktu file dihapus logis dari sistem aktif.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`media_id`),
  KEY `idx_media_owner` (`owner_table`, `owner_id`),
  KEY `idx_media_kategori_status` (`kategori_berkas`, `archive_status`),
  KEY `idx_media_retention` (`retention_days`, `archive_status`),
  CONSTRAINT `fk_media_uploaded_by_user`
    FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_media_uploaded_by_siswa`
    FOREIGN KEY (`uploaded_by_siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `plotting_rombel` (

  `plotting_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik plotting rombel ke ruangan.',
  `rombel_id` INT UNSIGNED NOT NULL COMMENT 'Referensi rombel terkait.',
  `ruangan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ruangan terkait.',
  `tahun_ajaran` VARCHAR(9) NOT NULL COMMENT 'Contoh: 2025/2026',
  `semester` ENUM('ganjil','genap','pendek') NOT NULL DEFAULT 'ganjil' COMMENT 'Semester akademik. Contoh implementasi: ''ganjil''.',
  `user_id` INT UNSIGNED DEFAULT NULL COMMENT 'Guru pengawas / penanggung jawab',
  `jam_pulang_default` TIME NOT NULL DEFAULT '15:00:00' COMMENT 'Jam pulang default. Contoh implementasi: ''15:00:00''.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`plotting_id`),
  UNIQUE KEY `uk_plotting_rombel_unique` (`rombel_id`, `ruangan_id`, `tahun_ajaran`, `semester`),
  KEY `idx_plotting_lookup` (`tahun_ajaran`, `semester`, `ruangan_id`, `status`),
  CONSTRAINT `fk_plotting_rombel_rombel`
    FOREIGN KEY (`rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_plotting_rombel_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_plotting_rombel_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `ruangan_perangkat` (

  `ruangan_perangkat_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi ruangan-perangkat.',
  `ruangan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ruangan terkait.',
  `perangkat_id` INT UNSIGNED NOT NULL COMMENT 'Referensi perangkat terkait.',
  `fungsi_perangkat` ENUM('scanner_qr','kamera','display','gateway','lainnya') NOT NULL DEFAULT 'scanner_qr' COMMENT 'Peran perangkat di ruangan. Contoh implementasi: ''scanner_qr'' atau ''kamera''.',
  `is_primary` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda perangkat utama/token utama. Contoh implementasi: 1=utama.',
  `mulai_dipakai` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu mulai perangkat dipakai di ruangan. Contoh implementasi: ''2026-01-10 06:30:00''.',
  `selesai_dipakai` DATETIME DEFAULT NULL COMMENT 'Waktu selesai penggunaan relasi. Contoh implementasi: NULL bila masih aktif.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  PRIMARY KEY (`ruangan_perangkat_id`),
  UNIQUE KEY `uk_ruangan_perangkat_active_pair` (`ruangan_id`, `perangkat_id`, `mulai_dipakai`),
  KEY `idx_ruangan_perangkat_lookup` (`ruangan_id`, `status`, `is_primary`),
  CONSTRAINT `fk_ruangan_perangkat_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ruangan_perangkat_perangkat`
    FOREIGN KEY (`perangkat_id`) REFERENCES `perangkat_esp32`(`perangkat_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `perangkat_esp32` (

  `perangkat_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik perangkat ESP32.',
  `mac_address` VARCHAR(17) NOT NULL COMMENT 'MAC address perangkat. Contoh implementasi: ''A4:CF:12:34:56:78''.',
  `serial_number` VARCHAR(50) DEFAULT NULL COMMENT 'Nomor seri perangkat. Contoh implementasi: ''ESP32-QR-0001''.',
  `device_type` ENUM('esp32','esp32_cam','esp32_qr_scanner') NOT NULL DEFAULT 'esp32_cam' COMMENT 'Tipe perangkat. Contoh implementasi: ''esp32_qr_scanner''.',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT 'Alamat IP client/perangkat. Contoh implementasi: ''192.168.1.10''.',
  `versi_firmware` VARCHAR(20) DEFAULT NULL COMMENT 'Versi firmware/perangkat lunak perangkat. Contoh implementasi: ''1.0.7''.',
  `status_perangkat` ENUM('online','offline','maintenance') NOT NULL DEFAULT 'online' COMMENT 'Status operasional perangkat. Contoh implementasi: ''online''.',
  `last_ping` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu heartbeat terakhir perangkat. Contoh implementasi: ''2026-04-09 08:10:00''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`perangkat_id`),
  UNIQUE KEY `uk_perangkat_mac_address` (`mac_address`),
  UNIQUE KEY `uk_perangkat_serial_number` (`serial_number`),
  KEY `idx_perangkat_status_type` (`status_perangkat`, `device_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `ruangan` (

  `ruangan_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik ruangan.',
  `kode_ruangan` VARCHAR(20) NOT NULL COMMENT 'Kode unik ruangan. Contoh implementasi: ''LAB-TKJ-01'' atau ''KLS-RPL-02''.',
  `kapasitas` INT UNSIGNED NOT NULL DEFAULT 30 COMMENT 'Kapasitas maksimum ruangan. Contoh implementasi: 36 siswa.',
  `fasilitas` TEXT DEFAULT NULL COMMENT 'Deskripsi fasilitas ruangan. Contoh implementasi: ''36 PC, projector, AC''.',
  `lokasi` VARCHAR(100) DEFAULT NULL COMMENT 'Lokasi fisik ruangan. Contoh implementasi: ''Gedung A Lantai 2''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`ruangan_id`),
  UNIQUE KEY `uk_ruangan_kode` (`kode_ruangan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `master_jenis_ruangan` (

  `kode_jenis_ruangan` VARCHAR(30) NOT NULL COMMENT 'Kode jenis ruangan yang fleksibel dan dapat ditambah tanpa mengubah struktur tabel utama. Contoh implementasi: ''lab'', ''kelas_teori'', ''kantor'', ''perpustakaan'', atau ''studio''.',
  `nama_jenis_ruangan` VARCHAR(100) NOT NULL COMMENT 'Nama tampilan jenis ruangan. Contoh implementasi: ''Laboratorium''.',
  `deskripsi` TEXT DEFAULT NULL COMMENT 'Penjelasan tambahan untuk jenis ruangan. Contoh implementasi: ''Ruangan praktik dengan perangkat komputer''.',
  `is_system` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda jenis ruangan bawaan sistem. Contoh implementasi: 1=bawaan, 0=custom sekolah.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status master jenis ruangan. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`kode_jenis_ruangan`),
  UNIQUE KEY `uk_master_jenis_ruangan_nama` (`nama_jenis_ruangan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
