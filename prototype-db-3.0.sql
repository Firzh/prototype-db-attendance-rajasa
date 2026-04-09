-- =========================================================
-- DATABASE: sistem_absensi_lab_qr
-- VERSI   : 3.0 (hasil konsolidasi prototype-db-2.4.sql + prototype-db-2.4-fixed.sql)
-- FOKUS   : Absensi lab berbasis QR code, bukan RFID
-- ENGINE  : MySQL 8+
-- =========================================================

-- ---------------------------------------------------------
-- CATATAN DESAIN PENTING
-- 1) Field/tabel berjejak RFID tidak dipakai lagi sebagai sumber utama.
--    Fungsinya diganti oleh tabel qr_tokens dan log_scan_qr.
-- 2) siswa_transfer_masuk dan siswa_transfer_keluar digabung menjadi siswa_mutasi
--    agar tidak ada duplikasi data. View kompatibilitas tetap disediakan.
-- 3) Relasi ruangan -> perangkat tidak lagi ditaruh langsung pada satu field di tabel ruangan,
--    karena satu ruangan bisa memiliki beberapa perangkat dan perangkat bisa diganti.
--    Untuk itu dipakai tabel buffer ruangan_perangkat.
-- 4) Sistem hak akses dibuat hybrid:
--    - tetap ada roles, permissions, role_permissions, user_permissions (kompatibel)
--    - ditambah policy-based access ala AWS-like untuk skala besar.
-- 5) Beberapa field snapshot dan field teks legacy tetap dipertahankan karena berguna untuk
--    sorting spesifik, filter custom, riwayat historis, dan kompatibilitas laporan.
-- ---------------------------------------------------------

CREATE DATABASE IF NOT EXISTS `sistem_absensi_lab_qr`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `sistem_absensi_lab_qr`;

-- =========================================================
-- 1. IAM / ACCESS CONTROL (AWS-LIKE + COMPATIBLE)
-- =========================================================

CREATE TABLE `roles` (
  `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nama_role` VARCHAR(50) NOT NULL,
  `role_slug` VARCHAR(50) NOT NULL,
  `deskripsi` TEXT DEFAULT NULL,
  `is_system` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uk_roles_nama_role` (`nama_role`),
  UNIQUE KEY `uk_roles_role_slug` (`role_slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `permissions` (
  `perm_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `perm_slug` VARCHAR(100) NOT NULL,
  `module_name` VARCHAR(50) NOT NULL,
  `action_name` VARCHAR(50) NOT NULL,
  `keterangan` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`perm_id`),
  UNIQUE KEY `uk_permissions_perm_slug` (`perm_slug`),
  KEY `idx_permissions_module_action` (`module_name`, `action_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `policies` (
  `policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `policy_name` VARCHAR(100) NOT NULL,
  `policy_slug` VARCHAR(100) NOT NULL,
  `policy_type` ENUM('managed','inline') NOT NULL DEFAULT 'managed',
  `deskripsi` TEXT DEFAULT NULL,
  `is_system` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`policy_id`),
  UNIQUE KEY `uk_policies_name` (`policy_name`),
  UNIQUE KEY `uk_policies_slug` (`policy_slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `policy_permissions` (
  `policy_permission_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `policy_id` INT UNSIGNED NOT NULL,
  `perm_id` INT UNSIGNED NOT NULL,
  `effect` ENUM('allow','deny') NOT NULL DEFAULT 'allow',
  `resource_scope` VARCHAR(150) NOT NULL DEFAULT '*',
  `conditions_json` JSON DEFAULT NULL,
  `priority` SMALLINT UNSIGNED NOT NULL DEFAULT 100,
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

-- Kompatibel dengan 2.4-fixed, tetapi ditambah resource_scope
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

CREATE TABLE `groups` (
  `group_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_name` VARCHAR(100) NOT NULL,
  `group_slug` VARCHAR(100) NOT NULL,
  `deskripsi` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`group_id`),
  UNIQUE KEY `uk_groups_group_name` (`group_name`),
  UNIQUE KEY `uk_groups_group_slug` (`group_slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 2. MASTER AKADEMIK & IDENTITAS
-- =========================================================

CREATE TABLE `jurusan` (
  `jurusan_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `kode_jurusan` VARCHAR(10) NOT NULL COMMENT 'Kode unik jurusan, ex: TKJ, RPL, MM',
  `nama_jurusan` VARCHAR(100) NOT NULL COMMENT 'Nama lengkap jurusan',
  `singkatan` VARCHAR(10) NOT NULL COMMENT 'Singkatan jurusan',
  `ketua_jurusan` VARCHAR(100) DEFAULT NULL COMMENT 'Nama ketua jurusan',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`jurusan_id`),
  UNIQUE KEY `uk_jurusan_kode` (`kode_jurusan`),
  UNIQUE KEY `uk_jurusan_singkatan` (`singkatan`),
  KEY `idx_jurusan_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rombel` (
  `rombel_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tingkatan` ENUM('X','XI','XII','XIII') NOT NULL,
  `jurusan_id` INT UNSIGNED NOT NULL,
  `nomor_rombel` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Contoh: 1 untuk TKJ-1',
  `label_rombel` VARCHAR(30) DEFAULT NULL COMMENT 'Buffer label custom/sorting, ex: XII-TKJ-1',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`rombel_id`),
  UNIQUE KEY `uk_rombel_unique` (`tingkatan`, `jurusan_id`, `nomor_rombel`),
  KEY `idx_rombel_status` (`status`),
  CONSTRAINT `fk_rombel_jurusan`
    FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `guru_staff` (
  `guru_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nip` VARCHAR(20) DEFAULT NULL,
  `nama_lengkap` VARCHAR(100) NOT NULL,
  `no_telp` VARCHAR(20) DEFAULT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `jabatan` VARCHAR(50) DEFAULT NULL,
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guru_id`),
  UNIQUE KEY `uk_guru_staff_nip` (`nip`),
  UNIQUE KEY `uk_guru_staff_email` (`email`),
  KEY `idx_guru_staff_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `siswa` (
  `siswa_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nisn` VARCHAR(20) NOT NULL,
  `nis` VARCHAR(20) DEFAULT NULL,
  `nama_lengkap` VARCHAR(100) NOT NULL,
  `jenis_kelamin` ENUM('L','P') NOT NULL COMMENT 'L=Laki-laki, P=Perempuan',
  `angkatan` YEAR NOT NULL,
  `jurusan_id_aktif` INT UNSIGNED DEFAULT NULL COMMENT 'Disimpan untuk sorting/filter cepat',
  `rombel_id_aktif` INT UNSIGNED DEFAULT NULL COMMENT 'Disimpan untuk sorting/filter cepat',
  `kelas_aktif` VARCHAR(20) DEFAULT NULL COMMENT 'Label kelas custom/snapshot cepat',
  `qr_vendor_link` TEXT DEFAULT NULL COMMENT 'Link URL vendor QR lama/opsional',
  `status` ENUM('aktif','lulus','keluar','mutasi') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`siswa_id`),
  UNIQUE KEY `uk_siswa_nisn` (`nisn`),
  UNIQUE KEY `uk_siswa_nis` (`nis`),
  KEY `idx_siswa_status` (`status`),
  KEY `idx_siswa_sorting` (`status`, `angkatan`, `jurusan_id_aktif`, `kelas_aktif`),
  CONSTRAINT `fk_siswa_jurusan_aktif`
    FOREIGN KEY (`jurusan_id_aktif`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_siswa_rombel_aktif`
    FOREIGN KEY (`rombel_id_aktif`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `profil_siswa` (
  `profil_siswa_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` INT UNSIGNED NOT NULL,
  `tempat_lahir` VARCHAR(50) DEFAULT NULL,
  `tanggal_lahir` DATE DEFAULT NULL,
  `alamat` TEXT DEFAULT NULL,
  `no_telp` VARCHAR(20) DEFAULT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `rombel` VARCHAR(20) DEFAULT NULL COMMENT 'Field legacy/custom label, dipertahankan untuk sorting spesifik',
  `nama_ortu` VARCHAR(100) DEFAULT NULL,
  `no_telp_ortu` VARCHAR(20) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`profil_siswa_id`),
  UNIQUE KEY `uk_profil_siswa_siswa_id` (`siswa_id`),
  UNIQUE KEY `uk_profil_siswa_email` (`email`),
  CONSTRAINT `fk_profil_siswa_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `siswa_mutasi` (
  `mutasi_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` INT UNSIGNED NOT NULL,
  `jenis_mutasi` ENUM('masuk','keluar') NOT NULL,
  `tanggal` DATE NOT NULL,
  `sekolah_asal_tujuan` VARCHAR(100) DEFAULT NULL,
  `alasan` TEXT DEFAULT NULL,
  `nomor_surat` VARCHAR(100) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`mutasi_id`),
  KEY `idx_siswa_mutasi_siswa_tanggal` (`siswa_id`, `tanggal`),
  KEY `idx_siswa_mutasi_jenis` (`jenis_mutasi`),
  CONSTRAINT `fk_siswa_mutasi_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `penempatan_siswa_rombel` (
  `penempatan_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` INT UNSIGNED NOT NULL,
  `rombel_id` INT UNSIGNED NOT NULL,
  `tahun_ajaran` VARCHAR(9) NOT NULL COMMENT 'Contoh: 2025/2026',
  `semester` ENUM('ganjil','genap','pendek') NOT NULL DEFAULT 'ganjil',
  `no_absen` SMALLINT UNSIGNED DEFAULT NULL,
  `tanggal_mulai` DATE DEFAULT NULL,
  `tanggal_selesai` DATE DEFAULT NULL,
  `is_aktif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`penempatan_id`),
  UNIQUE KEY `uk_penempatan_siswa_rombel` (`siswa_id`, `rombel_id`, `tahun_ajaran`, `semester`),
  KEY `idx_penempatan_rombel_lookup` (`rombel_id`, `tahun_ajaran`, `semester`, `is_aktif`),
  CONSTRAINT `fk_penempatan_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_penempatan_rombel`
    FOREIGN KEY (`rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 3. USER LOGIN / AKUN
-- =========================================================

CREATE TABLE `users` (
  `user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(50) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `user_type` ENUM('siswa','guru_staff','system') NOT NULL DEFAULT 'system',
  `siswa_id` INT UNSIGNED DEFAULT NULL,
  `guru_id` INT UNSIGNED DEFAULT NULL,
  `valid_until` DATETIME DEFAULT NULL COMMENT 'Khusus akses sementara seperti intern atau akun tamu',
  `status` ENUM('aktif','nonaktif','terblokir') NOT NULL DEFAULT 'aktif',
  `last_login` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
  `user_role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `assigned_by` INT UNSIGNED DEFAULT NULL,
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

CREATE TABLE `role_policies` (
  `role_policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_id` INT UNSIGNED NOT NULL,
  `policy_id` INT UNSIGNED NOT NULL,
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `assigned_by` INT UNSIGNED DEFAULT NULL,
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
  `user_policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `policy_id` INT UNSIGNED NOT NULL,
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `assigned_by` INT UNSIGNED DEFAULT NULL,
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
  `group_user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `added_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `added_by` INT UNSIGNED DEFAULT NULL,
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
  `group_role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_id` INT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `assigned_by` INT UNSIGNED DEFAULT NULL,
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
  `group_policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_id` INT UNSIGNED NOT NULL,
  `policy_id` INT UNSIGNED NOT NULL,
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `assigned_by` INT UNSIGNED DEFAULT NULL,
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
  `session_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `session_token` VARCHAR(255) NOT NULL COMMENT 'JWT/session token',
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` TEXT DEFAULT NULL,
  `logged_in_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_activity` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `logout_at` DATETIME DEFAULT NULL,
  `is_online` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`session_id`),
  UNIQUE KEY `uk_user_sessions_token` (`session_token`(191)),
  KEY `idx_user_sessions_user_online` (`user_id`, `is_online`),
  CONSTRAINT `fk_user_sessions_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 4. PERANGKAT, RUANGAN, PLOTTING, JADWAL
-- =========================================================

CREATE TABLE `ruangan` (
  `ruangan_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `kode_ruangan` VARCHAR(20) NOT NULL COMMENT 'Contoh: LAB-TKJ-01',
  `nama_ruangan` VARCHAR(50) NOT NULL,
  `jenis_ruangan` ENUM('lab','kelas_teori','kantor','perpustakaan') NOT NULL,
  `kapasitas` INT UNSIGNED NOT NULL DEFAULT 30,
  `fasilitas` TEXT DEFAULT NULL,
  `lokasi` VARCHAR(100) DEFAULT NULL,
  `status` ENUM('aktif','nonaktif','maintenance') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ruangan_id`),
  UNIQUE KEY `uk_ruangan_kode` (`kode_ruangan`),
  KEY `idx_ruangan_status_jenis` (`status`, `jenis_ruangan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `perangkat_esp32` (
  `perangkat_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `mac_address` VARCHAR(17) NOT NULL,
  `serial_number` VARCHAR(50) DEFAULT NULL,
  `device_type` ENUM('esp32','esp32_cam','esp32_qr_scanner') NOT NULL DEFAULT 'esp32_qr_scanner',
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `versi_firmware` VARCHAR(20) DEFAULT NULL,
  `status_perangkat` ENUM('online','offline','maintenance') NOT NULL DEFAULT 'online',
  `last_ping` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`perangkat_id`),
  UNIQUE KEY `uk_perangkat_mac_address` (`mac_address`),
  UNIQUE KEY `uk_perangkat_serial_number` (`serial_number`),
  KEY `idx_perangkat_status_type` (`status_perangkat`, `device_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabel buffer relasi ruangan <-> perangkat, ditambah histori penggunaan perangkat
CREATE TABLE `ruangan_perangkat` (
  `ruangan_perangkat_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ruangan_id` INT UNSIGNED NOT NULL,
  `perangkat_id` INT UNSIGNED NOT NULL,
  `fungsi_perangkat` ENUM('scanner_qr','kamera','display','gateway','lainnya') NOT NULL DEFAULT 'scanner_qr',
  `is_primary` TINYINT(1) NOT NULL DEFAULT 1,
  `mulai_dipakai` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `selesai_dipakai` DATETIME DEFAULT NULL,
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
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

CREATE TABLE `plotting_rombel` (
  `plotting_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `rombel_id` INT UNSIGNED NOT NULL,
  `ruangan_id` INT UNSIGNED NOT NULL,
  `tahun_ajaran` VARCHAR(9) NOT NULL COMMENT 'Contoh: 2025/2026',
  `semester` ENUM('ganjil','genap','pendek') NOT NULL DEFAULT 'ganjil',
  `user_id` INT UNSIGNED DEFAULT NULL COMMENT 'Guru pengawas / penanggung jawab',
  `jam_pulang_default` TIME NOT NULL DEFAULT '15:00:00',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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

-- Tabel buffer jadwal aktual agar plotting tidak terlalu kaku
CREATE TABLE `jadwal_lab` (
  `jadwal_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plotting_id` INT UNSIGNED NOT NULL,
  `hari` ENUM('senin','selasa','rabu','kamis','jumat','sabtu','minggu') NOT NULL,
  `jam_mulai` TIME NOT NULL,
  `jam_selesai` TIME NOT NULL,
  `toleransi_terlambat_menit` SMALLINT UNSIGNED NOT NULL DEFAULT 15,
  `qr_checkout_wajib` TINYINT(1) NOT NULL DEFAULT 0,
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`jadwal_id`),
  UNIQUE KEY `uk_jadwal_lab_unique` (`plotting_id`, `hari`, `jam_mulai`, `jam_selesai`),
  KEY `idx_jadwal_lab_lookup` (`hari`, `jam_mulai`, `status`),
  CONSTRAINT `fk_jadwal_lab_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 5. QR TOKEN & LOG SCAN
-- =========================================================

CREATE TABLE `qr_tokens` (
  `qr_token_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` INT UNSIGNED NOT NULL,
  `qr_reference` VARCHAR(100) NOT NULL COMMENT 'Kode referensi/slug QR untuk tampilan atau print',
  `qr_payload_hash` CHAR(64) NOT NULL COMMENT 'Hash payload QR, bukan payload mentah',
  `qr_vendor_link` TEXT DEFAULT NULL COMMENT 'Dipertahankan untuk integrasi vendor lama jika ada',
  `qr_version` VARCHAR(20) DEFAULT 'v1',
  `is_primary` TINYINT(1) NOT NULL DEFAULT 1,
  `issued_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expired_at` DATETIME DEFAULT NULL,
  `status` ENUM('aktif','nonaktif','dicabut','kedaluwarsa') NOT NULL DEFAULT 'aktif',
  `revoked_reason` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`qr_token_id`),
  UNIQUE KEY `uk_qr_tokens_reference` (`qr_reference`),
  UNIQUE KEY `uk_qr_tokens_payload_hash` (`qr_payload_hash`),
  KEY `idx_qr_tokens_siswa_status` (`siswa_id`, `status`, `is_primary`),
  CONSTRAINT `fk_qr_tokens_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `log_scan_qr` (
  `log_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `scan_uuid` CHAR(36) DEFAULT NULL,
  `ruangan_id` INT UNSIGNED NOT NULL,
  `perangkat_id` INT UNSIGNED DEFAULT NULL,
  `jadwal_id` INT UNSIGNED DEFAULT NULL,
  `siswa_id` INT UNSIGNED DEFAULT NULL,
  `qr_token_id` INT UNSIGNED DEFAULT NULL,
  `scanned_payload_hash` CHAR(64) DEFAULT NULL,
  `scan_method` ENUM('qr','manual') NOT NULL DEFAULT 'qr',
  `scan_type` ENUM('checkin','checkout','uji_coba','akses') NOT NULL DEFAULT 'checkin',
  `foto_capture` VARCHAR(255) DEFAULT NULL COMMENT 'Foto dari ESP32-CAM bila dipakai',
  `status` ENUM(
    'berhasil',
    'qr_tidak_terdaftar',
    'qr_nonaktif',
    'qr_kedaluwarsa',
    'ruangan_tidak_cocok',
    'jadwal_tidak_cocok',
    'duplikat_scan',
    'foto_buram',
    'manual_override',
    'lainnya'
  ) NOT NULL,
  `keterangan` TEXT DEFAULT NULL,
  `tanggal` DATE NOT NULL,
  `waktu` TIME NOT NULL,
  `scanned_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `origin_ip` VARCHAR(45) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  UNIQUE KEY `uk_log_scan_qr_uuid` (`scan_uuid`),
  KEY `idx_log_scan_qr_time` (`tanggal`, `waktu`, `ruangan_id`),
  KEY `idx_log_scan_qr_status` (`status`, `scan_type`),
  KEY `idx_log_scan_qr_siswa` (`siswa_id`, `tanggal`),
  CONSTRAINT `fk_log_scan_qr_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_log_scan_qr_perangkat`
    FOREIGN KEY (`perangkat_id`) REFERENCES `perangkat_esp32`(`perangkat_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_log_scan_qr_jadwal`
    FOREIGN KEY (`jadwal_id`) REFERENCES `jadwal_lab`(`jadwal_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_log_scan_qr_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_log_scan_qr_qr_token`
    FOREIGN KEY (`qr_token_id`) REFERENCES `qr_tokens`(`qr_token_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 6. PRESENSI
-- =========================================================

CREATE TABLE `presensi` (
  `presensi_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` INT UNSIGNED NOT NULL,
  `ruangan_id` INT UNSIGNED NOT NULL,
  `plotting_id` INT UNSIGNED DEFAULT NULL,
  `jadwal_id` INT UNSIGNED DEFAULT NULL,
  `tanggal` DATE NOT NULL,
  `waktu_masuk` TIME DEFAULT NULL,
  `waktu_keluar` TIME DEFAULT NULL,
  `waktu_pulang_plan` TIME NOT NULL DEFAULT '15:00:00',
  `status` ENUM('hadir','terlambat','alpha','izin','sakit') NOT NULL DEFAULT 'alpha',
  `status_checkout` ENUM('belum_checkout','sudah_checkout','pulang_cepat') NOT NULL DEFAULT 'belum_checkout',
  `bukti_izin_sakit` VARCHAR(255) DEFAULT NULL,
  `foto_scan_masuk` VARCHAR(255) DEFAULT NULL,
  `foto_scan_keluar` VARCHAR(255) DEFAULT NULL,
  `scan_masuk_log_id` INT UNSIGNED DEFAULT NULL,
  `scan_keluar_log_id` INT UNSIGNED DEFAULT NULL,
  `jurusan_snapshot` VARCHAR(50) NOT NULL COMMENT 'Nama jurusan saat presensi diambil',
  `kelas_snapshot` VARCHAR(20) NOT NULL COMMENT 'Label kelas saat presensi diambil',
  `rombel_snapshot` VARCHAR(20) DEFAULT NULL COMMENT 'Label rombel saat presensi diambil',
  `validasi` ENUM('valid','tidak_valid','pending') NOT NULL DEFAULT 'valid',
  `diverifikasi_oleh` INT UNSIGNED DEFAULT NULL,
  `waktu_verifikasi` DATETIME DEFAULT NULL,
  `keterangan` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`presensi_id`),
  KEY `idx_presensi_tanggal_siswa` (`tanggal`, `siswa_id`),
  KEY `idx_presensi_rekap` (`tanggal`, `ruangan_id`, `status`),
  KEY `idx_presensi_validasi` (`validasi`, `tanggal`),
  CONSTRAINT `fk_presensi_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_jadwal`
    FOREIGN KEY (`jadwal_id`) REFERENCES `jadwal_lab`(`jadwal_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_scan_masuk`
    FOREIGN KEY (`scan_masuk_log_id`) REFERENCES `log_scan_qr`(`log_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_scan_keluar`
    FOREIGN KEY (`scan_keluar_log_id`) REFERENCES `log_scan_qr`(`log_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_diverifikasi_oleh`
    FOREIGN KEY (`diverifikasi_oleh`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 7. UJIAN
-- =========================================================

CREATE TABLE `sesi_ujian` (
  `sesi_ujian_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `kode_ujian` VARCHAR(20) NOT NULL,
  `nama_ujian` VARCHAR(100) NOT NULL,
  `jurusan_id` INT UNSIGNED NOT NULL,
  `ruangan_id` INT UNSIGNED NOT NULL,
  `plotting_id` INT UNSIGNED DEFAULT NULL,
  `tahun_ajaran` VARCHAR(9) DEFAULT NULL,
  `semester` ENUM('ganjil','genap','pendek') DEFAULT NULL,
  `tanggal_mulai` DATE NOT NULL,
  `tanggal_selesai` DATE NOT NULL,
  `waktu_mulai` TIME NOT NULL,
  `waktu_selesai` TIME NOT NULL,
  `durasi_menit` INT UNSIGNED NOT NULL DEFAULT 90,
  `mata_pelajaran` VARCHAR(100) DEFAULT NULL,
  `pengawas_id` INT UNSIGNED DEFAULT NULL,
  `keterangan` TEXT DEFAULT NULL,
  `status` ENUM('draft','aktif','selesai','dibatalkan') NOT NULL DEFAULT 'draft',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`sesi_ujian_id`),
  UNIQUE KEY `uk_sesi_ujian_kode` (`kode_ujian`),
  KEY `idx_sesi_ujian_lookup` (`tanggal_mulai`, `status`, `ruangan_id`),
  CONSTRAINT `fk_sesi_ujian_jurusan`
    FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_sesi_ujian_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_sesi_ujian_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_sesi_ujian_pengawas`
    FOREIGN KEY (`pengawas_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_sesi_ujian_created_by`
    FOREIGN KEY (`created_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `peserta_ujian` (
  `peserta_ujian_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sesi_ujian_id` INT UNSIGNED NOT NULL,
  `siswa_id` INT UNSIGNED NOT NULL,
  `no_urut` INT UNSIGNED DEFAULT NULL COMMENT 'Nomor urut duduk',
  `status_kehadiran` ENUM('hadir','tidak_hadir','izin','sakit') NOT NULL DEFAULT 'tidak_hadir',
  `waktu_hadir` DATETIME DEFAULT NULL,
  `nilai` DECIMAL(5,2) DEFAULT NULL,
  `keterangan` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`peserta_ujian_id`),
  UNIQUE KEY `uk_peserta_ujian_unique` (`sesi_ujian_id`, `siswa_id`),
  KEY `idx_peserta_ujian_lookup` (`sesi_ujian_id`, `status_kehadiran`, `no_urut`),
  CONSTRAINT `fk_peserta_ujian_sesi`
    FOREIGN KEY (`sesi_ujian_id`) REFERENCES `sesi_ujian`(`sesi_ujian_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_peserta_ujian_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 8. KONFIGURASI, LOG, NOTIFIKASI, KALENDER
-- =========================================================

CREATE TABLE `konfigurasi` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `kunci` VARCHAR(50) NOT NULL,
  `nilai` TEXT DEFAULT NULL,
  `tipe_nilai` ENUM('string','number','boolean','json','text') NOT NULL DEFAULT 'string',
  `keterangan` VARCHAR(255) DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_konfigurasi_kunci` (`kunci`),
  CONSTRAINT `fk_konfigurasi_updated_by`
    FOREIGN KEY (`updated_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `admin_activities` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `activity_type` VARCHAR(50) NOT NULL,
  `module_name` VARCHAR(50) DEFAULT NULL,
  `target_table` VARCHAR(50) DEFAULT NULL,
  `target_id` VARCHAR(100) DEFAULT NULL,
  `activity_description` TEXT DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_admin_activities_user_time` (`user_id`, `created_at`),
  KEY `idx_admin_activities_module` (`module_name`, `activity_type`),
  CONSTRAINT `fk_admin_activities_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notifikasi_admin` (
  `notif_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED DEFAULT NULL COMMENT 'Boleh NULL jika notifikasi broadcast',
  `pesan` TEXT NOT NULL,
  `level_notif` ENUM('info','warning','error','critical') NOT NULL DEFAULT 'info',
  `ruangan_id` INT UNSIGNED DEFAULT NULL,
  `related_log_id` INT UNSIGNED DEFAULT NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `read_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
  `kalender_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tanggal` DATE NOT NULL,
  `tanggal_selesai` DATE DEFAULT NULL,
  `keterangan` VARCHAR(100) NOT NULL,
  `tipe` ENUM('libur_nasional','libur_sekolah','event_khusus') NOT NULL DEFAULT 'libur_sekolah',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`kalender_id`),
  KEY `idx_kalender_akademik_tanggal` (`tanggal`, `tipe`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 9. SEED DATA MINIMAL IAM
-- =========================================================

INSERT INTO `roles` (`nama_role`, `role_slug`, `deskripsi`, `is_system`) VALUES
('Super Admin', 'super_admin', 'Akses penuh ke seluruh modul', 1),
('Admin Akademik', 'admin_akademik', 'Kelola data akademik dan presensi', 1),
('Guru Pengawas', 'guru_pengawas', 'Memantau jadwal, presensi, dan ujian', 1),
('Operator Lab', 'operator_lab', 'Mengelola perangkat, scan, dan ruangan lab', 1),
('Siswa', 'siswa', 'Akses mandiri terbatas untuk profil dan riwayat presensi', 1),
('Intern', 'intern', 'Akses terbatas sementara', 1);

INSERT INTO `permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`) VALUES
('users.read', 'users', 'read', 'Melihat data user'),
('users.create', 'users', 'create', 'Membuat user baru'),
('users.update', 'users', 'update', 'Mengubah user'),
('users.delete', 'users', 'delete', 'Menghapus user'),
('users.assign_role', 'users', 'assign_role', 'Mengatur role user'),
('students.read', 'students', 'read', 'Melihat data siswa'),
('students.write', 'students', 'write', 'Mengelola data siswa'),
('academic.read', 'academic', 'read', 'Melihat data jurusan, rombel, plotting, jadwal'),
('academic.write', 'academic', 'write', 'Mengelola data jurusan, rombel, plotting, jadwal'),
('rooms.read', 'rooms', 'read', 'Melihat data ruangan'),
('rooms.write', 'rooms', 'write', 'Mengelola data ruangan'),
('devices.read', 'devices', 'read', 'Melihat data perangkat'),
('devices.write', 'devices', 'write', 'Mengelola data perangkat'),
('attendance.scan', 'attendance', 'scan', 'Melakukan scan presensi'),
('attendance.read', 'attendance', 'read', 'Melihat data presensi'),
('attendance.write', 'attendance', 'write', 'Mengelola data presensi'),
('attendance.validate', 'attendance', 'validate', 'Memvalidasi data presensi'),
('qr.read', 'qr', 'read', 'Melihat token QR'),
('qr.generate', 'qr', 'generate', 'Membuat / reset QR'),
('qr.revoke', 'qr', 'revoke', 'Menonaktifkan QR'),
('exams.read', 'exams', 'read', 'Melihat data ujian'),
('exams.write', 'exams', 'write', 'Mengelola sesi ujian'),
('reports.read', 'reports', 'read', 'Melihat rekap/laporan'),
('reports.export', 'reports', 'export', 'Mengunduh / ekspor laporan'),
('settings.read', 'settings', 'read', 'Melihat konfigurasi'),
('settings.write', 'settings', 'write', 'Mengubah konfigurasi'),
('notifications.read', 'notifications', 'read', 'Melihat notifikasi'),
('notifications.write', 'notifications', 'write', 'Membuat/ubah notifikasi'),
('audit.read', 'audit', 'read', 'Melihat audit log'),
('session.manage', 'session', 'manage', 'Mengelola sesi login');

INSERT INTO `policies` (`policy_name`, `policy_slug`, `policy_type`, `deskripsi`, `is_system`) VALUES
('FullAccess', 'full_access', 'managed', 'Akses penuh ke seluruh resource', 1),
('AcademicAdminAccess', 'academic_admin_access', 'managed', 'Akses administrasi akademik dan presensi', 1),
('TeacherSupervisorAccess', 'teacher_supervisor_access', 'managed', 'Akses guru pengawas', 1),
('LabOperatorAccess', 'lab_operator_access', 'managed', 'Akses operator lab dan perangkat', 1),
('StudentSelfService', 'student_self_service', 'managed', 'Akses siswa untuk data diri dan presensi sendiri', 1),
('InternReadOnly', 'intern_read_only', 'managed', 'Akses baca terbatas untuk pengguna sementara', 1);

-- Full access
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 1
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'full_access';

-- Academic admin
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 10
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'academic_admin_access'
  AND pm.perm_slug IN (
    'students.read','students.write','academic.read','academic.write',
    'attendance.read','attendance.write','attendance.validate',
    'reports.read','reports.export','notifications.read','notifications.write',
    'qr.read','qr.generate','qr.revoke','exams.read','exams.write'
  );

-- Teacher supervisor
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 20
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'teacher_supervisor_access'
  AND pm.perm_slug IN (
    'students.read','academic.read','attendance.read','attendance.validate',
    'reports.read','notifications.read','exams.read','exams.write'
  );

-- Lab operator
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 20
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'lab_operator_access'
  AND pm.perm_slug IN (
    'rooms.read','rooms.write','devices.read','devices.write',
    'attendance.scan','attendance.read','qr.read','notifications.read',
    'reports.read','audit.read'
  );

-- Student self service
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', 'self/*', 30
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'student_self_service'
  AND pm.perm_slug IN ('attendance.read','qr.read','notifications.read');

-- Intern read only
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 40
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'intern_read_only'
  AND pm.perm_slug IN (
    'students.read','academic.read','rooms.read','devices.read',
    'attendance.read','reports.read','notifications.read'
  );

INSERT INTO `role_policies` (`role_id`, `policy_id`)
SELECT r.role_id, p.policy_id
FROM `roles` r
JOIN `policies` p
WHERE (r.role_slug = 'super_admin' AND p.policy_slug = 'full_access')
   OR (r.role_slug = 'admin_akademik' AND p.policy_slug = 'academic_admin_access')
   OR (r.role_slug = 'guru_pengawas' AND p.policy_slug = 'teacher_supervisor_access')
   OR (r.role_slug = 'operator_lab' AND p.policy_slug = 'lab_operator_access')
   OR (r.role_slug = 'siswa' AND p.policy_slug = 'student_self_service')
   OR (r.role_slug = 'intern' AND p.policy_slug = 'intern_read_only');

-- =========================================================
-- 10. VIEWS
-- =========================================================

CREATE OR REPLACE VIEW `v_siswa_transfer_masuk` AS
SELECT
  sm.mutasi_id AS transfer_id,
  s.siswa_id,
  s.nisn,
  s.nama_lengkap,
  sm.sekolah_asal_tujuan AS asal_sekolah,
  sm.tanggal AS tanggal_masuk,
  sm.alasan AS keterangan
FROM `siswa_mutasi` sm
JOIN `siswa` s ON s.siswa_id = sm.siswa_id
WHERE sm.jenis_mutasi = 'masuk';

CREATE OR REPLACE VIEW `v_siswa_transfer_keluar` AS
SELECT
  sm.mutasi_id AS transfer_id,
  sm.siswa_id,
  sm.sekolah_asal_tujuan AS tujuan_sekolah,
  sm.tanggal AS tanggal_keluar,
  sm.alasan
FROM `siswa_mutasi` sm
WHERE sm.jenis_mutasi = 'keluar';

CREATE OR REPLACE VIEW `v_log_scan_qr_detail` AS
SELECT
  l.log_id,
  l.scan_uuid,
  l.status,
  l.scan_type,
  l.scan_method,
  l.keterangan,
  l.tanggal,
  l.waktu,
  l.scanned_at,
  l.foto_capture,
  r.kode_ruangan,
  r.nama_ruangan,
  s.nisn,
  s.nis,
  s.nama_lengkap AS nama_siswa,
  j.nama_jurusan,
  qt.qr_reference,
  p.mac_address,
  p.versi_firmware
FROM `log_scan_qr` l
JOIN `ruangan` r ON r.ruangan_id = l.ruangan_id
LEFT JOIN `siswa` s ON s.siswa_id = l.siswa_id
LEFT JOIN `jurusan` j ON j.jurusan_id = s.jurusan_id_aktif
LEFT JOIN `qr_tokens` qt ON qt.qr_token_id = l.qr_token_id
LEFT JOIN `perangkat_esp32` p ON p.perangkat_id = l.perangkat_id;

CREATE OR REPLACE VIEW `v_presensi_detail` AS
SELECT
  pr.presensi_id,
  pr.tanggal,
  pr.waktu_masuk,
  pr.waktu_keluar,
  pr.waktu_pulang_plan,
  pr.status,
  pr.status_checkout,
  pr.keterangan,
  pr.validasi,
  s.nisn,
  s.nis,
  s.nama_lengkap AS nama_siswa,
  pr.kelas_snapshot AS kelas,
  pr.rombel_snapshot AS rombel,
  pr.jurusan_snapshot,
  r.nama_ruangan,
  r.kode_ruangan,
  qt.qr_reference,
  pr.bukti_izin_sakit,
  pr.foto_scan_masuk,
  pr.foto_scan_keluar
FROM `presensi` pr
JOIN `siswa` s ON s.siswa_id = pr.siswa_id
JOIN `ruangan` r ON r.ruangan_id = pr.ruangan_id
LEFT JOIN `log_scan_qr` ls ON ls.log_id = pr.scan_masuk_log_id
LEFT JOIN `qr_tokens` qt ON qt.qr_token_id = ls.qr_token_id;

CREATE OR REPLACE VIEW `v_rekap_harian` AS
SELECT
  pr.tanggal,
  pr.jurusan_snapshot AS nama_jurusan,
  r.nama_ruangan,
  SUM(CASE WHEN pr.status = 'hadir' THEN 1 ELSE 0 END) AS total_hadir,
  SUM(CASE WHEN pr.status = 'terlambat' THEN 1 ELSE 0 END) AS total_terlambat,
  SUM(CASE WHEN pr.status = 'sakit' THEN 1 ELSE 0 END) AS total_sakit,
  SUM(CASE WHEN pr.status = 'izin' THEN 1 ELSE 0 END) AS total_izin,
  SUM(CASE WHEN pr.status = 'alpha' THEN 1 ELSE 0 END) AS total_alpha,
  COUNT(*) AS total_siswa_tercatat
FROM `presensi` pr
JOIN `ruangan` r ON r.ruangan_id = pr.ruangan_id
GROUP BY pr.tanggal, pr.jurusan_snapshot, r.nama_ruangan;

-- =========================================================
-- SELESAI
-- =========================================================
