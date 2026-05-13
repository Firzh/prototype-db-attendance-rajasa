-- =========================================================
-- 007 - SUPPORT CONFIG BUFFERS: konfigurasi, legacy notif admin, cache/buffer
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `konfigurasi` (

  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik item konfigurasi.',
  `kunci` VARCHAR(50) NOT NULL COMMENT 'Kunci konfigurasi. Contoh implementasi: ''presensi.toleransi_menit''.',
  `nilai` TEXT DEFAULT NULL COMMENT 'Nilai konfigurasi. Contoh implementasi: ''15'' atau JSON pengaturan.',
  `tipe_nilai` ENUM('string','number','boolean','json','text') NOT NULL DEFAULT 'string' COMMENT 'Tipe data konfigurasi. Contoh implementasi: ''number'' atau ''json''.',
  `keterangan` VARCHAR(255) DEFAULT NULL COMMENT 'Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.',
  `updated_by` INT UNSIGNED DEFAULT NULL COMMENT 'User terakhir yang mengubah data. Contoh implementasi: admin sistem.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_konfigurasi_kunci` (`kunci`),
  CONSTRAINT `fk_konfigurasi_updated_by`
    FOREIGN KEY (`updated_by`) REFERENCES `users`(`user_id`)
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

CREATE TABLE `kalender_akademik` (

  `kalender_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik kalender akademik.',
  `tanggal` DATE NOT NULL COMMENT 'Tanggal kejadian/transaksi. Contoh implementasi: ''2026-07-15''.',
  `tanggal_selesai` DATE DEFAULT NULL COMMENT 'Tanggal selesai berlaku. Contoh implementasi: akhir semester atau akhir event.',
  `keterangan` VARCHAR(100) NOT NULL COMMENT 'Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.',
  `tipe` ENUM('libur_nasional','libur_sekolah','event_khusus') NOT NULL DEFAULT 'libur_sekolah' COMMENT 'Jenis item kalender. Contoh implementasi: ''libur_nasional''.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`kalender_id`),
  KEY `idx_kalender_akademik_tanggal` (`tanggal`, `tipe`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- NOTE:
-- presensi_snapshot_buffer pernah dirancang sebagai buffer snapshot presensi,
-- tetapi tidak dipakai pada MVP modular karena alur presensi memakai scanner_sessions.
-- Jangan aktifkan kembali tanpa kebutuhan backend yang jelas.

-- CREATE TABLE `presensi_snapshot_buffer` (
--
--   `snapshot_buffer_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
--   `plotting_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi plotting jika context berasal dari plotting reguler.',
--   `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi ruangan context.',
--   `jurusan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi jurusan context bila tersedia.',
--   `jurusan_snapshot` VARCHAR(100) DEFAULT NULL COMMENT 'Nama jurusan hasil snapshot/buffer.',
--   `kelas_snapshot` VARCHAR(20) DEFAULT NULL COMMENT 'Kelas hasil snapshot/buffer.',
--   `rombel_snapshot` VARCHAR(30) DEFAULT NULL COMMENT 'Rombel hasil snapshot/buffer.',
--   `tahun_ajaran_snapshot` VARCHAR(9) DEFAULT NULL COMMENT 'Tahun ajaran hasil snapshot/buffer.',
--   `semester_snapshot` ENUM('ganjil','genap','pendek') DEFAULT NULL COMMENT 'Semester hasil snapshot/buffer.',
--   `sumber_context` ENUM('plotting','manual','sinkron_online','custom_event') NOT NULL DEFAULT 'plotting',
--   `signature_hash` CHAR(64) DEFAULT NULL COMMENT 'Hash kombinasi context agar snapshot identik bisa dipakai ulang.',
--   `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
--   `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--
--   PRIMARY KEY (`snapshot_buffer_id`),
--   UNIQUE KEY `uk_presensi_snapshot_signature` (`signature_hash`),
--   KEY `idx_presensi_snapshot_lookup` (`plotting_id`,`ruangan_id`,`tahun_ajaran_snapshot`,`semester_snapshot`),
--
--   CONSTRAINT `fk_presensi_snapshot_plotting`
--     FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
--     ON DELETE SET NULL ON UPDATE CASCADE,
--
--   CONSTRAINT `fk_presensi_snapshot_ruangan`
--     FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
--     ON DELETE SET NULL ON UPDATE CASCADE,
--
--   CONSTRAINT `fk_presensi_snapshot_jurusan`
--     FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
--     ON DELETE SET NULL ON UPDATE CASCADE
--
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_ui_preferences` (
  `preference_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `theme_mode` ENUM('light','dark','system') NOT NULL DEFAULT 'system',
  `sidebar_collapsed` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`preference_id`),
  UNIQUE KEY `uk_user_ui_preferences_user` (`user_id`),
  CONSTRAINT `fk_user_ui_preferences_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

