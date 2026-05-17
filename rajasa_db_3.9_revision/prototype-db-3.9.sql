-- =========================================================-- PROTOTYPE DB ATTENDANCE RAJASA - VERSION 3.9 CLEAN
-- Revision date: 2026-05-17
-- Scope: 
-- Login guru, staff, admin, intern, atau custom user.
-- Role berbasis level akses.
-- Presensi dengan dua mode:
-- Rombel
-- Piket/Terlambat
-- Mode rombel wajib memilih rombel dan jam pembelajaran.
-- Jam pembelajaran 1 sampai 8.
-- Multi-select jam maksimal 3 dan harus berurutan.
-- Satu kali scan berlaku untuk semua jam yang dipilih.
-- Mode piket default untuk siswa terlambat.
-- Mode piket tidak terikat rombel.
-- Scan QR memakai kamera HP guru/staff.
-- QR vendor hanya berisi nama dan NISN.
-- Sistem tidak mengontrol QR vendor.
-- Presensi ganda dicegah.
-- Warning disimpan di log, bukan di tabel presensi utama.
-- Warning terjadi saat kartu siswa beda rombel terscan.
-- Data warning menampilkan nama dan NISN pemilik kartu.
-- Guru mencatat siswa pembawa kartu secara manual.
-- Sesi bisa aktif, suspended, selesai, gagal, atau terputus.
-- Data scan tetap tersimpan walaupun sesi belum selesai.
-- Admin/guru/staff tertentu bisa edit presensi.
-- Semua edit harus masuk audit log.
-- Siswa bisa melihat hasil presensi di akun siswa.
-- Wali kelas menerima pop-up saat ada warning terkait siswanya.
-- Laporan bisa difilter berdasarkan tanggal, rombel, guru, jam, dan status.
-- Export laporan: Excel, Word/Docs, PDF, CSV.
-- =========================================================

CREATE DATABASE IF NOT EXISTS `sistem_absensi_lab_qr`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `sistem_absensi_lab_qr`;

SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. AKSES DAN IDENTITAS USER
-- =========================================================

CREATE TABLE `roles` (
  `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nama_role` VARCHAR(80) NOT NULL,
  `role_slug` VARCHAR(80) NOT NULL,
  `deskripsi` TEXT DEFAULT NULL,
  `level_rank` SMALLINT UNSIGNED NOT NULL DEFAULT 10 COMMENT 'Semakin besar angka, semakin tinggi akses.',
  `is_system` TINYINT(1) NOT NULL DEFAULT 1,
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uk_roles_nama_role` (`nama_role`),
  UNIQUE KEY `uk_roles_role_slug` (`role_slug`),
  KEY `idx_roles_level_status` (`level_rank`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `permissions` (
  `perm_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `perm_slug` VARCHAR(120) NOT NULL,
  `module_name` VARCHAR(80) NOT NULL,
  `action_name` ENUM('read','create','update','delete','scan','edit','export','manage','submit','review','validate') NOT NULL DEFAULT 'read',
  `keterangan` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`perm_id`),
  UNIQUE KEY `uk_permissions_perm_slug` (`perm_slug`),
  KEY `idx_permissions_module_action` (`module_name`, `action_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_permissions` (
  `role_id` INT UNSIGNED NOT NULL,
  `perm_id` INT UNSIGNED NOT NULL,
  `is_allowed` TINYINT(1) NOT NULL DEFAULT 1,
  `resource_scope` VARCHAR(150) NOT NULL DEFAULT '*',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`, `perm_id`, `resource_scope`),
  KEY `idx_role_permissions_perm` (`perm_id`),
  CONSTRAINT `fk_role_permissions_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_permissions_permission`
    FOREIGN KEY (`perm_id`) REFERENCES `permissions`(`perm_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 2. MASTER AKADEMIK
-- =========================================================

CREATE TABLE `jurusan` (
  `jurusan_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `kode_jurusan` VARCHAR(20) NOT NULL,
  `nama_jurusan` VARCHAR(120) NOT NULL,
  `ketua_jurusan` VARCHAR(120) DEFAULT NULL,
  `deskripsi_jurusan` VARCHAR(255) DEFAULT NULL,
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`jurusan_id`),
  UNIQUE KEY `uk_jurusan_kode` (`kode_jurusan`),
  KEY `idx_jurusan_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tahun_ajaran` (
  `tahun_ajaran_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nama_tahun_ajaran` VARCHAR(9) NOT NULL COMMENT 'Contoh: 2026/2027.',
  `semester_aktif` ENUM('ganjil','genap','pendek') NOT NULL DEFAULT 'ganjil',
  `tanggal_mulai` DATE DEFAULT NULL,
  `tanggal_selesai` DATE DEFAULT NULL,
  `is_aktif` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`tahun_ajaran_id`),
  UNIQUE KEY `uk_tahun_ajaran_nama` (`nama_tahun_ajaran`),
  KEY `idx_tahun_ajaran_aktif` (`is_aktif`, `semester_aktif`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rombel` (
  `rombel_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tahun_ajaran_id` INT UNSIGNED DEFAULT NULL,
  `tingkatan` ENUM('X','XI','XII','XIII') NOT NULL,
  `tingkat_angka` TINYINT UNSIGNED DEFAULT NULL,
  `jurusan_id` INT UNSIGNED NOT NULL,
  `nomor_rombel` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `is_nomor_rombel_inferred` TINYINT(1) NOT NULL DEFAULT 1,
  `label_rombel` VARCHAR(50) DEFAULT NULL,
  `label_rombel_raw` VARCHAR(80) DEFAULT NULL,
  `display_mode` ENUM('tanpa_nomor','dengan_nomor','custom') NOT NULL DEFAULT 'tanpa_nomor',
  `is_inferred_from_import` TINYINT(1) NOT NULL DEFAULT 0,
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`rombel_id`),
  UNIQUE KEY `uk_rombel_periode` (`tahun_ajaran_id`, `tingkatan`, `jurusan_id`, `nomor_rombel`),
  KEY `idx_rombel_status` (`status`),
  KEY `idx_rombel_display` (`status`, `tingkat_angka`, `label_rombel`),
  CONSTRAINT `fk_rombel_tahun_ajaran`
    FOREIGN KEY (`tahun_ajaran_id`) REFERENCES `tahun_ajaran`(`tahun_ajaran_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rombel_jurusan`
    FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_rombel_tingkat_angka`
    CHECK (`tingkat_angka` IS NULL OR `tingkat_angka` IN (10,11,12,13))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `guru_staff` (
  `guru_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nip` VARCHAR(30) DEFAULT NULL,
  `nama_lengkap` VARCHAR(120) NOT NULL,
  `no_telp` VARCHAR(30) DEFAULT NULL,
  `email` VARCHAR(120) DEFAULT NULL,
  `jenis_user` ENUM('guru','staff','admin','intern') NOT NULL DEFAULT 'guru',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guru_id`),
  UNIQUE KEY `uk_guru_staff_nip` (`nip`),
  KEY `idx_guru_staff_status` (`jenis_user`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `siswa` (
  `siswa_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nisn` VARCHAR(20) NOT NULL,
  `nis` VARCHAR(30) DEFAULT NULL,
  `nama_lengkap` VARCHAR(120) NOT NULL,
  `jenis_kelamin` ENUM('L','P') DEFAULT NULL,
  `angkatan` YEAR DEFAULT NULL,
  `jurusan_id_aktif` INT UNSIGNED DEFAULT NULL,
  `rombel_id_aktif` INT UNSIGNED DEFAULT NULL,
  `kelas_aktif` VARCHAR(50) DEFAULT NULL,
  `status` ENUM('aktif','lulus','mutasi','keluar','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`siswa_id`),
  UNIQUE KEY `uk_siswa_nisn` (`nisn`),
  UNIQUE KEY `uk_siswa_nis` (`nis`),
  KEY `idx_siswa_nama` (`nama_lengkap`),
  KEY `idx_siswa_status` (`status`),
  KEY `idx_siswa_rombel` (`rombel_id_aktif`, `status`),
  CONSTRAINT `fk_siswa_jurusan_aktif`
    FOREIGN KEY (`jurusan_id_aktif`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_siswa_rombel_aktif`
    FOREIGN KEY (`rombel_id_aktif`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `profil_siswa` (
  `profil_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` INT UNSIGNED NOT NULL,
  `alamat` TEXT DEFAULT NULL,
  `no_telp` VARCHAR(30) DEFAULT NULL,
  `email` VARCHAR(120) DEFAULT NULL,
  `nama_wali` VARCHAR(120) DEFAULT NULL,
  `no_telp_wali` VARCHAR(30) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`profil_id`),
  UNIQUE KEY `uk_profil_siswa` (`siswa_id`),
  CONSTRAINT `fk_profil_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `siswa_mutasi` (
  `mutasi_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` INT UNSIGNED NOT NULL,
  `jenis_mutasi` ENUM('masuk','keluar','pindah_rombel','lulus','nonaktif') NOT NULL,
  `tanggal_mutasi` DATE NOT NULL,
  `rombel_lama_id` INT UNSIGNED DEFAULT NULL,
  `rombel_baru_id` INT UNSIGNED DEFAULT NULL,
  `keterangan` TEXT DEFAULT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`mutasi_id`),
  KEY `idx_siswa_mutasi_siswa` (`siswa_id`, `tanggal_mutasi`),
  KEY `idx_siswa_mutasi_jenis` (`jenis_mutasi`),
  CONSTRAINT `fk_siswa_mutasi_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_siswa_mutasi_rombel_lama`
    FOREIGN KEY (`rombel_lama_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_siswa_mutasi_rombel_baru`
    FOREIGN KEY (`rombel_baru_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `penempatan_siswa_rombel` (
  `penempatan_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` INT UNSIGNED NOT NULL,
  `rombel_id` INT UNSIGNED NOT NULL,
  `tahun_ajaran_id` INT UNSIGNED DEFAULT NULL,
  `semester` ENUM('ganjil','genap','pendek') NOT NULL DEFAULT 'ganjil',
  `tanggal_mulai` DATE DEFAULT NULL,
  `tanggal_selesai` DATE DEFAULT NULL,
  `is_aktif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`penempatan_id`),
  KEY `idx_penempatan_siswa_aktif` (`siswa_id`, `is_aktif`),
  KEY `idx_penempatan_rombel_aktif` (`rombel_id`, `is_aktif`),
  KEY `idx_penempatan_tahun` (`tahun_ajaran_id`, `semester`),
  CONSTRAINT `fk_penempatan_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_penempatan_rombel`
    FOREIGN KEY (`rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_penempatan_tahun_ajaran`
    FOREIGN KEY (`tahun_ajaran_id`) REFERENCES `tahun_ajaran`(`tahun_ajaran_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `users` (
  `user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(80) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `email` VARCHAR(120) DEFAULT NULL,
  `nama_tampilan` VARCHAR(120) DEFAULT NULL,
  `siswa_id` INT UNSIGNED DEFAULT NULL,
  `guru_id` INT UNSIGNED DEFAULT NULL,
  `status` ENUM('aktif','nonaktif','locked') NOT NULL DEFAULT 'aktif',
  `last_login_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_users_username` (`username`),
  UNIQUE KEY `uk_users_email` (`email`),
  KEY `idx_users_status` (`status`),
  KEY `idx_users_siswa` (`siswa_id`),
  KEY `idx_users_guru` (`guru_id`),
  CONSTRAINT `fk_users_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_users_guru`
    FOREIGN KEY (`guru_id`) REFERENCES `guru_staff`(`guru_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_users_identity`
    CHECK (`siswa_id` IS NULL OR `guru_id` IS NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `siswa_mutasi`
  ADD CONSTRAINT `fk_siswa_mutasi_created_by`
    FOREIGN KEY (`created_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE `user_roles` (
  `user_role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `assigned_by` INT UNSIGNED DEFAULT NULL,
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
  `user_id` INT UNSIGNED NOT NULL,
  `perm_id` INT UNSIGNED NOT NULL,
  `is_allowed` TINYINT(1) NOT NULL DEFAULT 1,
  `resource_scope` VARCHAR(150) NOT NULL DEFAULT '*',
  `valid_until` DATETIME DEFAULT NULL,
  `catatan` VARCHAR(255) DEFAULT NULL,
  `assigned_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
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

CREATE TABLE `user_sessions` (
  `session_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `session_token` VARCHAR(255) NOT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` TEXT DEFAULT NULL,
  `logged_in_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_activity` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `logout_at` DATETIME DEFAULT NULL,
  `is_online` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`session_id`),
  UNIQUE KEY `uk_user_sessions_token` (`session_token`(191)),
  KEY `idx_user_sessions_user_online` (`user_id`, `is_online`),
  CONSTRAINT `fk_user_sessions_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rombel_wali_kelas` (
  `wali_kelas_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `rombel_id` INT UNSIGNED NOT NULL,
  `guru_id` INT UNSIGNED NOT NULL,
  `tahun_ajaran_id` INT UNSIGNED DEFAULT NULL,
  `semester` ENUM('ganjil','genap','pendek') NOT NULL DEFAULT 'ganjil',
  `tanggal_mulai` DATE DEFAULT NULL,
  `tanggal_selesai` DATE DEFAULT NULL,
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`wali_kelas_id`),
  UNIQUE KEY `uk_rombel_wali_kelas_aktif` (`rombel_id`, `guru_id`, `tahun_ajaran_id`, `semester`),
  KEY `idx_wali_kelas_guru` (`guru_id`, `status`),
  CONSTRAINT `fk_wali_kelas_rombel`
    FOREIGN KEY (`rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_wali_kelas_guru`
    FOREIGN KEY (`guru_id`) REFERENCES `guru_staff`(`guru_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_wali_kelas_tahun_ajaran`
    FOREIGN KEY (`tahun_ajaran_id`) REFERENCES `tahun_ajaran`(`tahun_ajaran_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 3. QR DAN JAM PEMBELAJARAN
-- =========================================================

CREATE TABLE `siswa_qr` (
  `siswa_qr_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` INT UNSIGNED NOT NULL,
  `payload_raw` VARCHAR(255) NOT NULL COMMENT 'Isi QR dari kartu vendor. Minimal berisi nama dan NISN.',
  `payload_normalized` VARCHAR(255) NOT NULL,
  `payload_nama` VARCHAR(120) DEFAULT NULL,
  `payload_nisn` VARCHAR(20) DEFAULT NULL,
  `is_primary` TINYINT(1) NOT NULL DEFAULT 1,
  `status` ENUM('aktif','nonaktif','dicabut') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`siswa_qr_id`),
  UNIQUE KEY `uk_siswa_qr_payload` (`payload_normalized`),
  KEY `idx_siswa_qr_siswa` (`siswa_id`, `status`),
  KEY `idx_siswa_qr_nisn` (`payload_nisn`),
  CONSTRAINT `fk_siswa_qr_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_siswa_qr_payload_nisn_not_empty`
    CHECK (`payload_nisn` IS NOT NULL AND `payload_nisn` <> '');
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `jam_pembelajaran` (
  `jam_id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `jam_ke` TINYINT UNSIGNED NOT NULL,
  `label_jam` VARCHAR(50) NOT NULL,
  `waktu_mulai` TIME DEFAULT NULL,
  `waktu_selesai` TIME DEFAULT NULL,
  `tipe_hari` ENUM('normal','jumat','khusus') NOT NULL DEFAULT 'normal',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  PRIMARY KEY (`jam_id`),
  UNIQUE KEY `uk_jam_pembelajaran` (`jam_ke`, `tipe_hari`),
  KEY `idx_jam_pembelajaran_status` (`status`),
  CONSTRAINT `chk_jam_pembelajaran_range`
    CHECK (`jam_ke` BETWEEN 1 AND 8)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 4. PRESENSI QR
-- =========================================================

CREATE TABLE `presensi_sesi` (
  `presensi_sesi_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `session_uuid` CHAR(36) NOT NULL,
  `mode_presensi` ENUM('rombel','piket') NOT NULL,
  `rombel_id` INT UNSIGNED DEFAULT NULL COMMENT 'Wajib untuk mode rombel. Kosong untuk mode piket.',
  `tahun_ajaran_id` INT UNSIGNED DEFAULT NULL,
  `semester` ENUM('ganjil','genap','pendek') DEFAULT NULL,
  `tanggal` DATE NOT NULL,
  `status` ENUM('aktif','suspended','selesai','gagal','expired','terputus') NOT NULL DEFAULT 'aktif',
  `opened_by_user_id` INT UNSIGNED NOT NULL,
  `closed_by_user_id` INT UNSIGNED DEFAULT NULL,
  `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `paused_at` DATETIME DEFAULT NULL,
  `resumed_at` DATETIME DEFAULT NULL,
  `ended_at` DATETIME DEFAULT NULL,
  `last_seen_at` DATETIME DEFAULT NULL,
  `expires_at` DATETIME DEFAULT NULL,
  `ended_reason` VARCHAR(120) DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`presensi_sesi_id`),
  UNIQUE KEY `uk_presensi_sesi_uuid` (`session_uuid`),
  KEY `idx_presensi_sesi_user_date` (`opened_by_user_id`, `tanggal`, `status`),
  KEY `idx_presensi_sesi_mode_rombel` (`mode_presensi`, `rombel_id`, `tanggal`, `status`),
  KEY `idx_presensi_sesi_tahun` (`tahun_ajaran_id`, `semester`),
  CONSTRAINT `fk_presensi_sesi_rombel`
    FOREIGN KEY (`rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_sesi_tahun_ajaran`
    FOREIGN KEY (`tahun_ajaran_id`) REFERENCES `tahun_ajaran`(`tahun_ajaran_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_sesi_opened_by`
    FOREIGN KEY (`opened_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_sesi_closed_by`
    FOREIGN KEY (`closed_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_presensi_sesi_mode_rombel`
    CHECK (
      (`mode_presensi` = 'rombel' AND `rombel_id` IS NOT NULL)
      OR
      (`mode_presensi` = 'piket' AND `rombel_id` IS NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_sesi_jam` (
  `presensi_sesi_jam_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `presensi_sesi_id` BIGINT UNSIGNED NOT NULL,
  `jam_id` TINYINT UNSIGNED NOT NULL,
  `urutan` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`presensi_sesi_jam_id`),
  UNIQUE KEY `uk_presensi_sesi_jam` (`presensi_sesi_id`, `jam_id`),
  KEY `idx_presensi_sesi_jam_id` (`jam_id`),
  CONSTRAINT `fk_presensi_sesi_jam_sesi`
    FOREIGN KEY (`presensi_sesi_id`) REFERENCES `presensi_sesi`(`presensi_sesi_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_sesi_jam_jam`
    FOREIGN KEY (`jam_id`) REFERENCES `jam_pembelajaran`(`jam_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_presensi_sesi_jam_urutan`
    CHECK (`urutan` BETWEEN 1 AND 3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_scan_log` (
  `scan_log_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `presensi_sesi_id` BIGINT UNSIGNED DEFAULT NULL,
  `client_request_uuid` CHAR(36) NOT NULL,
  `tanggal` DATE NOT NULL,
  `scanned_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `scanned_by_user_id` INT UNSIGNED DEFAULT NULL,
  `payload_raw` VARCHAR(255) NOT NULL,
  `payload_normalized` VARCHAR(255) DEFAULT NULL,
  `payload_nama` VARCHAR(120) DEFAULT NULL,
  `payload_nisn` VARCHAR(20) DEFAULT NULL,
  `siswa_id` INT UNSIGNED DEFAULT NULL COMMENT 'Pemilik kartu yang terbaca dari QR.',
  `selected_rombel_id` INT UNSIGNED DEFAULT NULL COMMENT 'Rombel yang dipilih guru pada mode rombel.',
  `actual_rombel_id` INT UNSIGNED DEFAULT NULL COMMENT 'Rombel aktif pemilik kartu.',
  `status_scan` ENUM('berhasil','warning','invalid','ditolak','error') NOT NULL,
  `warning_reason` ENUM('none','siswa_tidak_sesuai_rombel','qr_dipakai_orang_lain','manual_review','lainnya') NOT NULL DEFAULT 'none',
  `catatan_siswa_pembawa_kartu` TEXT DEFAULT NULL,
  `resolved_by_user_id` INT UNSIGNED DEFAULT NULL,
  `resolved_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`scan_log_id`),
  UNIQUE KEY `uk_presensi_scan_log_request` (`client_request_uuid`),
  KEY `idx_scan_log_sesi` (`presensi_sesi_id`, `tanggal`, `status_scan`),
  KEY `idx_scan_log_siswa` (`siswa_id`, `tanggal`),
  KEY `idx_scan_log_scanned_by` (`scanned_by_user_id`, `tanggal`),
  KEY `idx_scan_log_warning` (`status_scan`, `warning_reason`, `tanggal`),
  CONSTRAINT `fk_scan_log_sesi`
    FOREIGN KEY (`presensi_sesi_id`) REFERENCES `presensi_sesi`(`presensi_sesi_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scan_log_scanned_by`
    FOREIGN KEY (`scanned_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scan_log_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scan_log_selected_rombel`
    FOREIGN KEY (`selected_rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scan_log_actual_rombel`
    FOREIGN KEY (`actual_rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scan_log_resolved_by`
    FOREIGN KEY (`resolved_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
  CONSTRAINT `chk_scan_log_warning_reason`
    CHECK (
      (`status_scan` = 'warning' AND `warning_reason` <> 'none')
      OR
      (`status_scan` <> 'warning' AND `warning_reason` = 'none')
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_jam_siswa` (
  `presensi_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tanggal` DATE NOT NULL,
  `siswa_id` INT UNSIGNED NOT NULL,
  `rombel_id_snapshot` INT UNSIGNED DEFAULT NULL,
  `tahun_ajaran_id_snapshot` INT UNSIGNED DEFAULT NULL,
  `semester_snapshot` ENUM('ganjil','genap','pendek') DEFAULT NULL,
  `jam_id` TINYINT UNSIGNED NOT NULL,
  `status` ENUM('alpha','hadir','terlambat','izin','sakit') NOT NULL DEFAULT 'alpha',
  `mode_presensi` ENUM('rombel','piket','manual') NOT NULL DEFAULT 'manual',
  `presensi_sesi_id` BIGINT UNSIGNED DEFAULT NULL,
  `scan_log_id` BIGINT UNSIGNED DEFAULT NULL,
  `input_by_user_id` INT UNSIGNED DEFAULT NULL,
  `scanned_at` DATETIME DEFAULT NULL,
  `edited_by_user_id` INT UNSIGNED DEFAULT NULL,
  `edited_at` DATETIME DEFAULT NULL,
  `keterangan` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`presensi_id`),
  UNIQUE KEY `uk_presensi_no_ganda` (`tanggal`, `siswa_id`, `jam_id`),
  KEY `idx_presensi_jam_status` (`tanggal`, `jam_id`, `status`),
  KEY `idx_presensi_rombel` (`tanggal`, `rombel_id_snapshot`, `status`),
  KEY `idx_presensi_sesi` (`presensi_sesi_id`),
  KEY `idx_presensi_scan_log` (`scan_log_id`),
  CONSTRAINT `fk_presensi_jam_siswa_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_jam_siswa_rombel`
    FOREIGN KEY (`rombel_id_snapshot`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_jam_siswa_jam`
    FOREIGN KEY (`jam_id`) REFERENCES `jam_pembelajaran`(`jam_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_jam_siswa_sesi`
    FOREIGN KEY (`presensi_sesi_id`) REFERENCES `presensi_sesi`(`presensi_sesi_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_jam_siswa_scan_log`
    FOREIGN KEY (`scan_log_id`) REFERENCES `presensi_scan_log`(`scan_log_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_jam_siswa_input_by`
    FOREIGN KEY (`input_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_jam_siswa_edited_by`
    FOREIGN KEY (`edited_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_edit_log` (
  `edit_log_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `presensi_id` BIGINT UNSIGNED NOT NULL,
  `field_name` VARCHAR(80) NOT NULL,
  `old_value` TEXT DEFAULT NULL,
  `new_value` TEXT DEFAULT NULL,
  `edited_by_user_id` INT UNSIGNED DEFAULT NULL,
  `edited_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `alasan_edit` TEXT DEFAULT NULL,
  PRIMARY KEY (`edit_log_id`),
  KEY `idx_presensi_edit_log_presensi` (`presensi_id`, `edited_at`),
  KEY `idx_presensi_edit_log_user` (`edited_by_user_id`, `edited_at`),
  CONSTRAINT `fk_presensi_edit_log_presensi`
    FOREIGN KEY (`presensi_id`) REFERENCES `presensi_jam_siswa`(`presensi_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_edit_log_user`
    FOREIGN KEY (`edited_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 5. IMPORT, KONFIGURASI, NOTIFIKASI, DAN AUDIT
-- =========================================================

CREATE TABLE `import_jobs` (
  `import_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `import_code` CHAR(36) NOT NULL,
  `import_type` ENUM('siswa','guru_staff','rombel','wali_kelas','lainnya') NOT NULL DEFAULT 'siswa',
  `original_filename` VARCHAR(255) DEFAULT NULL,
  `tahun_ajaran_id` INT UNSIGNED DEFAULT NULL,
  `semester` ENUM('ganjil','genap','pendek') DEFAULT NULL,
  `status` ENUM('draft','diproses','selesai','gagal','dibatalkan') NOT NULL DEFAULT 'draft',
  `total_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `valid_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `warning_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `error_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `inserted_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `updated_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `skipped_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `started_at` DATETIME DEFAULT NULL,
  `finished_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`import_id`),
  UNIQUE KEY `uk_import_jobs_code` (`import_code`),
  KEY `idx_import_jobs_status` (`status`, `created_at`),
  KEY `idx_import_jobs_tahun` (`tahun_ajaran_id`, `semester`),
  CONSTRAINT `fk_import_jobs_created_by`
    FOREIGN KEY (`created_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_import_jobs_tahun_ajaran`
    FOREIGN KEY (`tahun_ajaran_id`) REFERENCES `tahun_ajaran`(`tahun_ajaran_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `import_column_mappings` (
  `mapping_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `import_id` BIGINT UNSIGNED NOT NULL,
  `source_column` VARCHAR(120) NOT NULL,
  `target_field` VARCHAR(120) NOT NULL,
  `is_required` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`mapping_id`),
  KEY `idx_import_column_mappings_import` (`import_id`),
  CONSTRAINT `fk_import_column_mappings_import`
    FOREIGN KEY (`import_id`) REFERENCES `import_jobs`(`import_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `import_row_logs` (
  `row_log_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `import_id` BIGINT UNSIGNED NOT NULL,
  `row_number` INT UNSIGNED NOT NULL,
  `row_status` ENUM('valid','warning','error','skipped','inserted','updated') NOT NULL,
  `source_payload_json` JSON DEFAULT NULL,
  `message` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`row_log_id`),
  KEY `idx_import_row_logs_import` (`import_id`, `row_status`),
  CONSTRAINT `fk_import_row_logs_import`
    FOREIGN KEY (`import_id`) REFERENCES `import_jobs`(`import_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `konfigurasi` (
  `konfigurasi_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `kunci` VARCHAR(120) NOT NULL,
  `nilai` TEXT DEFAULT NULL,
  `tipe_nilai` ENUM('string','number','boolean','json') NOT NULL DEFAULT 'string',
  `keterangan` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`konfigurasi_id`),
  UNIQUE KEY `uk_konfigurasi_kunci` (`kunci`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notifikasi_user` (
  `notifikasi_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `tipe` ENUM('info','success','warning','error') NOT NULL DEFAULT 'info',
  `judul` VARCHAR(150) NOT NULL,
  `pesan` TEXT NOT NULL,
  `related_table` VARCHAR(80) DEFAULT NULL,
  `related_id` BIGINT UNSIGNED DEFAULT NULL,
  `popup_until` DATETIME DEFAULT NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `read_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`notifikasi_id`),
  KEY `idx_notifikasi_user_inbox` (`user_id`, `is_read`, `created_at`),
  KEY `idx_notifikasi_user_related` (`related_table`, `related_id`),
  CONSTRAINT `fk_notifikasi_user_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_activities` (
  `activity_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED DEFAULT NULL,
  `activity_type` VARCHAR(80) NOT NULL,
  `module_name` VARCHAR(80) DEFAULT NULL,
  `target_table` VARCHAR(80) DEFAULT NULL,
  `target_id` BIGINT UNSIGNED DEFAULT NULL,
  `activity_description` TEXT DEFAULT NULL,
  `metadata_json` JSON DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`activity_id`),
  KEY `idx_user_activities_user` (`user_id`, `created_at`),
  KEY `idx_user_activities_target` (`target_table`, `target_id`),
  KEY `idx_user_activities_module` (`module_name`, `created_at`),
  CONSTRAINT `fk_user_activities_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 6. VIEW BANTU
-- =========================================================

CREATE OR REPLACE VIEW `v_siswa_rombel_aktif` AS
SELECT
  s.`siswa_id`,
  s.`nisn`,
  s.`nis`,
  s.`nama_lengkap`,
  s.`status` AS `status_siswa`,
  rb.`rombel_id`,
  rb.`tingkatan`,
  rb.`tingkat_angka`,
  rb.`label_rombel`,
  j.`jurusan_id`,
  j.`kode_jurusan`,
  j.`nama_jurusan`,
  psr.`tahun_ajaran_id`,
  ta.`nama_tahun_ajaran`,
  psr.`semester`
FROM `siswa` s
LEFT JOIN `penempatan_siswa_rombel` psr
  ON psr.`siswa_id` = s.`siswa_id`
 AND psr.`is_aktif` = 1
LEFT JOIN `rombel` rb ON rb.`rombel_id` = COALESCE(psr.`rombel_id`, s.`rombel_id_aktif`)
LEFT JOIN `jurusan` j ON j.`jurusan_id` = COALESCE(rb.`jurusan_id`, s.`jurusan_id_aktif`)
LEFT JOIN `tahun_ajaran` ta ON ta.`tahun_ajaran_id` = psr.`tahun_ajaran_id`;

CREATE OR REPLACE VIEW `v_rombel_wali_kelas_aktif` AS
SELECT
  rwk.`wali_kelas_id`,
  rwk.`rombel_id`,
  rb.`label_rombel`,
  rwk.`guru_id`,
  gs.`nama_lengkap` AS `nama_wali_kelas`,
  rwk.`tahun_ajaran_id`,
  ta.`nama_tahun_ajaran`,
  rwk.`semester`,
  rwk.`status`
FROM `rombel_wali_kelas` rwk
JOIN `rombel` rb ON rb.`rombel_id` = rwk.`rombel_id`
JOIN `guru_staff` gs ON gs.`guru_id` = rwk.`guru_id`
LEFT JOIN `tahun_ajaran` ta ON ta.`tahun_ajaran_id` = rwk.`tahun_ajaran_id`
WHERE rwk.`status` = 'aktif';

CREATE OR REPLACE VIEW `v_presensi_recent` AS
SELECT
  p.`presensi_id`,
  p.`tanggal`,
  jp.`jam_ke`,
  jp.`label_jam`,
  p.`status`,
  p.`mode_presensi`,
  s.`siswa_id`,
  s.`nisn`,
  s.`nama_lengkap`,
  rb.`rombel_id`,
  rb.`label_rombel`,
  u.`username` AS `input_by_username`,
  p.`scanned_at`,
  p.`updated_at`
FROM `presensi_jam_siswa` p
JOIN `siswa` s ON s.`siswa_id` = p.`siswa_id`
JOIN `jam_pembelajaran` jp ON jp.`jam_id` = p.`jam_id`
LEFT JOIN `rombel` rb ON rb.`rombel_id` = p.`rombel_id_snapshot`
LEFT JOIN `users` u ON u.`user_id` = p.`input_by_user_id`;

CREATE OR REPLACE VIEW `v_presensi_rekap_harian` AS
SELECT
  p.`tanggal`,
  p.`rombel_id_snapshot` AS `rombel_id`,
  rb.`label_rombel`,
  jp.`jam_ke`,
  COUNT(*) AS `total_siswa_tercatat`,
  SUM(CASE WHEN p.`status` = 'hadir' THEN 1 ELSE 0 END) AS `total_hadir`,
  SUM(CASE WHEN p.`status` = 'terlambat' THEN 1 ELSE 0 END) AS `total_terlambat`,
  SUM(CASE WHEN p.`status` = 'alpha' THEN 1 ELSE 0 END) AS `total_alpha`,
  SUM(CASE WHEN p.`status` = 'izin' THEN 1 ELSE 0 END) AS `total_izin`,
  SUM(CASE WHEN p.`status` = 'sakit' THEN 1 ELSE 0 END) AS `total_sakit`
FROM `presensi_jam_siswa` p
JOIN `jam_pembelajaran` jp ON jp.`jam_id` = p.`jam_id`
LEFT JOIN `rombel` rb ON rb.`rombel_id` = p.`rombel_id_snapshot`
GROUP BY p.`tanggal`, p.`rombel_id_snapshot`, rb.`label_rombel`, jp.`jam_ke`;

CREATE OR REPLACE VIEW `v_scan_warning_unresolved` AS
SELECT
  l.`scan_log_id`,
  l.`presensi_sesi_id`,
  ps.`session_uuid`,
  l.`tanggal`,
  l.`scanned_at`,
  l.`payload_nama`,
  l.`payload_nisn`,
  l.`siswa_id` AS `kartu_siswa_id`,
  s.`nama_lengkap` AS `kartu_nama_siswa`,
  s.`nisn` AS `kartu_nisn`,
  l.`selected_rombel_id`,
  rb_sel.`label_rombel` AS `selected_label_rombel`,
  l.`actual_rombel_id`,
  rb_act.`label_rombel` AS `actual_label_rombel`,
  l.`warning_reason`,
  l.`catatan_siswa_pembawa_kartu`,
  u.`username` AS `scanned_by_username`
FROM `presensi_scan_log` l
LEFT JOIN `presensi_sesi` ps ON ps.`presensi_sesi_id` = l.`presensi_sesi_id`
LEFT JOIN `siswa` s ON s.`siswa_id` = l.`siswa_id`
LEFT JOIN `rombel` rb_sel ON rb_sel.`rombel_id` = l.`selected_rombel_id`
LEFT JOIN `rombel` rb_act ON rb_act.`rombel_id` = l.`actual_rombel_id`
LEFT JOIN `users` u ON u.`user_id` = l.`scanned_by_user_id`
WHERE l.`status_scan` = 'warning'
  AND l.`resolved_at` IS NULL;

CREATE OR REPLACE VIEW `v_notifikasi_user_inbox` AS
SELECT
  n.`notifikasi_id`,
  n.`user_id`,
  u.`username`,
  n.`tipe`,
  n.`judul`,
  n.`pesan`,
  n.`related_table`,
  n.`related_id`,
  n.`popup_until`,
  n.`is_read`,
  n.`read_at`,
  n.`created_at`
FROM `notifikasi_user` n
JOIN `users` u ON u.`user_id` = n.`user_id`;

CREATE OR REPLACE VIEW `v_import_jobs_ringkas` AS
SELECT
  ij.`import_id`,
  ij.`import_code`,
  ij.`import_type`,
  ij.`original_filename`,
  ij.`tahun_ajaran_id`,
  ta.`nama_tahun_ajaran`,
  ij.`semester`,
  ij.`status`,
  ij.`total_rows`,
  ij.`valid_rows`,
  ij.`warning_rows`,
  ij.`error_rows`,
  ij.`inserted_rows`,
  ij.`updated_rows`,
  ij.`skipped_rows`,
  u.`username` AS `created_by_username`,
  ij.`created_at`,
  ij.`updated_at`
FROM `import_jobs` ij
LEFT JOIN `tahun_ajaran` ta ON ta.`tahun_ajaran_id` = ij.`tahun_ajaran_id`
LEFT JOIN `users` u ON u.`user_id` = ij.`created_by`;

-- =========================================================
-- 7. SEED DATA DASAR
-- =========================================================

INSERT INTO `roles` (`nama_role`, `role_slug`, `deskripsi`, `level_rank`, `is_system`) VALUES
  ('Super Admin', 'super_admin', 'Akses tertinggi sistem.', 100, 1),
  ('Admin', 'admin', 'Mengelola data utama dan koreksi presensi.', 80, 1),
  ('Guru', 'guru', 'Melakukan presensi rombel dan melihat laporan terkait.', 30, 1),
  ('Staff', 'staff', 'Melakukan presensi piket dan melihat laporan terkait.', 30, 1),
  ('Intern Presensi', 'intern_presensi', 'Akses khusus presensi sesuai izin yang diberikan.', 20, 1),
  ('Siswa', 'siswa', 'Melihat hasil presensi milik sendiri.', 10, 1)
ON DUPLICATE KEY UPDATE
  `deskripsi` = VALUES(`deskripsi`),
  `level_rank` = VALUES(`level_rank`),
  `is_system` = VALUES(`is_system`);

INSERT INTO `permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`) VALUES
  ('attendance.read', 'attendance', 'read', 'Melihat data presensi.'),
  ('attendance.scan', 'attendance', 'scan', 'Melakukan scan QR presensi.'),
  ('attendance.scan.rombel', 'attendance', 'scan', 'Melakukan presensi mode rombel.'),
  ('attendance.scan.piket', 'attendance', 'scan', 'Melakukan presensi mode piket atau terlambat.'),
  ('attendance.edit', 'attendance', 'edit', 'Mengubah data presensi.'),
  ('attendance.export', 'attendance', 'export', 'Mengekspor laporan presensi.'),
  ('attendance.warning.read', 'attendance', 'read', 'Melihat log warning presensi.'),
  ('attendance.warning.resolve', 'attendance', 'validate', 'Menyelesaikan log warning presensi.'),
  ('attendance.student.view', 'attendance', 'read', 'Siswa melihat hasil presensi milik sendiri.'),
  ('academic.read', 'academic', 'read', 'Melihat data akademik.'),
  ('academic.manage', 'academic', 'manage', 'Mengelola data akademik.'),
  ('users.manage', 'users', 'manage', 'Mengelola akun dan hak akses.'),
  ('reports.read', 'reports', 'read', 'Melihat laporan.'),
  ('reports.export', 'reports', 'export', 'Mengekspor laporan.'),
  ('import.manage', 'import', 'manage', 'Mengelola import data.'),
  ('notifications.read', 'notifications', 'read', 'Melihat notifikasi.'),
  ('notifications.manage', 'notifications', 'manage', 'Mengelola notifikasi.')
ON DUPLICATE KEY UPDATE
  `module_name` = VALUES(`module_name`),
  `action_name` = VALUES(`action_name`),
  `keterangan` = VALUES(`keterangan`);

INSERT IGNORE INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT r.`role_id`, p.`perm_id`, 1, '*'
FROM `roles` r
JOIN `permissions` p
WHERE r.`role_slug` IN ('super_admin','admin')
  AND p.`perm_slug` IN (
    'attendance.read','attendance.scan','attendance.scan.rombel','attendance.scan.piket','attendance.edit','attendance.export',
    'attendance.warning.read','attendance.warning.resolve','attendance.student.view','academic.read','academic.manage',
    'users.manage','reports.read','reports.export','import.manage','notifications.read','notifications.manage'
  );

INSERT IGNORE INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT r.`role_id`, p.`perm_id`, 1, '*'
FROM `roles` r
JOIN `permissions` p
WHERE r.`role_slug` IN ('guru','staff')
  AND p.`perm_slug` IN (
    'attendance.read','attendance.scan','attendance.scan.rombel','attendance.scan.piket',
    'attendance.edit','attendance.export','attendance.warning.read','attendance.warning.resolve',
    'reports.read','reports.export','notifications.read'
  );

INSERT IGNORE INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT r.`role_id`, p.`perm_id`, 1, '*'
FROM `roles` r
JOIN `permissions` p
WHERE r.`role_slug` = 'intern_presensi'
  AND p.`perm_slug` IN ('attendance.read','attendance.scan','attendance.scan.rombel','attendance.scan.piket','notifications.read');

INSERT IGNORE INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT r.`role_id`, p.`perm_id`, 1, 'self/*'
FROM `roles` r
JOIN `permissions` p
WHERE r.`role_slug` = 'siswa'
  AND p.`perm_slug` IN ('attendance.student.view','notifications.read');

INSERT INTO `jam_pembelajaran` (`jam_ke`, `label_jam`, `tipe_hari`, `status`) VALUES
  (1, 'Jam ke-1', 'normal', 'aktif'),
  (2, 'Jam ke-2', 'normal', 'aktif'),
  (3, 'Jam ke-3', 'normal', 'aktif'),
  (4, 'Jam ke-4', 'normal', 'aktif'),
  (5, 'Jam ke-5', 'normal', 'aktif'),
  (6, 'Jam ke-6', 'normal', 'aktif'),
  (7, 'Jam ke-7', 'normal', 'aktif'),
  (8, 'Jam ke-8', 'normal', 'aktif')
ON DUPLICATE KEY UPDATE
  `label_jam` = VALUES(`label_jam`),
  `status` = VALUES(`status`);

INSERT INTO `konfigurasi` (`kunci`, `nilai`, `tipe_nilai`, `keterangan`) VALUES
  ('db.prototype_version', '3.9-clean', 'string', 'Versi prototype database aktif.'),
  ('attendance.scan.max_selected_jam', '3', 'number', 'Batas maksimal jam pembelajaran dalam satu sesi rombel.'),
  ('attendance.scan.require_sequential_jam', 'true', 'boolean', 'Pilihan jam pembelajaran harus berurutan.'),
  ('attendance.scan.session_timeout_minutes', '20', 'number', 'Batas sesi aktif sebelum ditandai expired. Status suspended menghentikan timer di sisi aplikasi.'),
  ('attendance.scan.pause_on_warning', 'true', 'boolean', 'Scan berhenti sementara saat QR tidak sesuai rombel.'),
  ('attendance.scan.success_banner_ms', '1500', 'number', 'Durasi banner Presensi Berhasil pada halaman scan.'),
  ('attendance.piket.default_jam_ke', '1', 'number', 'Default jam untuk mode piket atau terlambat.'),
  ('notification.warning.popup_seconds', '10', 'number', 'Durasi popup wali kelas saat ada warning presensi.')
ON DUPLICATE KEY UPDATE
  `nilai` = VALUES(`nilai`),
  `tipe_nilai` = VALUES(`tipe_nilai`),
  `keterangan` = VALUES(`keterangan`);

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- END PROTOTYPE DB ATTENDANCE RAJASA - VERSION 3.9 CLEAN
-- =========================================================
