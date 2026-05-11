-- =========================================================
-- 004 - FACILITY SCHEDULE SCANNER: ruang, perangkat, plotting, jadwal, scanner
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

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

CREATE TABLE `jadwal_lab` (

  `jadwal_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik jadwal lab.',
  `plotting_id` INT UNSIGNED NOT NULL COMMENT 'Referensi plotting rombel terkait.',
  `hari` ENUM('senin','selasa','rabu','kamis','jumat','sabtu','minggu') NOT NULL COMMENT 'Hari pelaksanaan jadwal. Contoh implementasi: ''senin''.',
  `jam_mulai` TIME NOT NULL COMMENT 'Jam mulai jadwal. Contoh implementasi: ''07:00:00''.',
  `jam_selesai` TIME NOT NULL COMMENT 'Jam selesai jadwal. Contoh implementasi: ''09:30:00''.',
  `toleransi_terlambat_menit` SMALLINT UNSIGNED NOT NULL DEFAULT 15 COMMENT 'Batas keterlambatan dalam menit. Contoh implementasi: 15.',
  `qr_checkout_wajib` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Penanda apakah scan pulang wajib. Nilai 1 berarti siswa wajib melakukan scan saat keluar agar status pulang dianggap lengkap. Nilai 0 berarti checkout tidak diwajibkan.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`jadwal_id`),
  UNIQUE KEY `uk_jadwal_lab_unique` (`plotting_id`, `hari`, `jam_mulai`, `jam_selesai`),
  KEY `idx_jadwal_lab_lookup` (`hari`, `jam_mulai`, `status`),
  CONSTRAINT `fk_jadwal_lab_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
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

CREATE TABLE `scanner_sessions` (
  `scanner_session_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik sesi scan web.',
  `session_uuid` CHAR(36) NOT NULL COMMENT 'UUID sesi scan. Dibuat backend saat user membuka halaman scan.',
  `scanner_device_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi device scanner web.',
  `opened_by_user_id` INT UNSIGNED NOT NULL COMMENT 'User yang membuka sesi scan. Umumnya guru, admin, atau staff.',
  `closed_by_user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User yang menutup sesi scan. Boleh NULL jika sesi kedaluwarsa/terputus.',
  `context_type` ENUM('rombel','ruangan','jadwal') NOT NULL DEFAULT 'rombel' COMMENT 'Konteks scan. Untuk opsi A, default rombel.',
  `selected_rombel_id` INT UNSIGNED DEFAULT NULL COMMENT 'Rombel yang dipilih user sebelum scan. Wajib untuk opsi A.',
  `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Ruangan hasil turunan dari plotting_rombel aktif. Wajib diisi backend sebelum scan produktif.',
  `plotting_id` INT UNSIGNED DEFAULT NULL COMMENT 'Plotting aktif yang menjadi dasar relasi rombel ke ruangan.',
  `jadwal_id` INT UNSIGNED DEFAULT NULL COMMENT 'Jadwal terkait bila sesi scan berbasis jadwal lab.',
  `scan_type_default` ENUM('checkin','checkout') NOT NULL DEFAULT 'checkin' COMMENT 'Jenis scan default pada sesi ini.',
  `tanggal` DATE NOT NULL COMMENT 'Tanggal sesi scan.',
  `tahun_ajaran` VARCHAR(9) DEFAULT NULL COMMENT 'Snapshot tahun ajaran saat sesi dibuat. Biasanya dari konfigurasi academic.tahun_ajaran_aktif.',
  `semester` ENUM('ganjil','genap','pendek') DEFAULT NULL COMMENT 'Snapshot semester saat sesi dibuat.',
  `status` ENUM('aktif','dijeda','selesai','dibatalkan','kedaluwarsa','terputus') NOT NULL DEFAULT 'aktif' COMMENT 'Status operasional sesi scan.',
  `ended_reason` ENUM('selesai_normal','user_keluar_halaman','pause_manual','resume_manual','timeout','dibatalkan_user','system_cleanup','lainnya') DEFAULT NULL COMMENT 'Alasan sesi berubah/berakhir. Detail event tetap dapat dicatat di user_activities.',
  `open_unique_key` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `status` IN ('aktif','dijeda','terputus') THEN 1 ELSE NULL END) STORED COMMENT 'Kunci bantu agar user tidak membuka beberapa sesi aktif untuk rombel dan tipe scan yang sama.',
  `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu sesi dimulai.',
  `last_seen_at` DATETIME DEFAULT NULL COMMENT 'Heartbeat terakhir dari halaman scan. Dipakai untuk mendeteksi user keluar/terputus.',
  `paused_at` DATETIME DEFAULT NULL COMMENT 'Waktu sesi dijeda manual oleh user.',
  `resumed_at` DATETIME DEFAULT NULL COMMENT 'Waktu sesi dilanjutkan setelah pause.',
  `ended_at` DATETIME DEFAULT NULL COMMENT 'Waktu sesi selesai/dibatalkan/kedaluwarsa.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`scanner_session_id`),
  UNIQUE KEY `uk_scanner_sessions_uuid` (`session_uuid`),
  UNIQUE KEY `uk_scanner_sessions_open_context` (`opened_by_user_id`, `tanggal`, `selected_rombel_id`, `scan_type_default`, `open_unique_key`),
  KEY `idx_scanner_sessions_user_date` (`opened_by_user_id`, `tanggal`, `status`),
  KEY `idx_scanner_sessions_context` (`context_type`, `selected_rombel_id`, `ruangan_id`, `jadwal_id`, `status`),
  KEY `idx_scanner_sessions_plotting` (`plotting_id`, `tanggal`, `status`),
  CONSTRAINT `fk_scanner_sessions_device`
    FOREIGN KEY (`scanner_device_id`) REFERENCES `scanner_devices`(`scanner_device_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_opened_by`
    FOREIGN KEY (`opened_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_closed_by`
    FOREIGN KEY (`closed_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_rombel`
    FOREIGN KEY (`selected_rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_jadwal`
    FOREIGN KEY (`jadwal_id`) REFERENCES `jadwal_lab`(`jadwal_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. PATCH SCANNER SESSION: RUANGAN FLEKSIBEL
-- =========================================================
ALTER TABLE `scanner_sessions`
  ADD COLUMN `selected_rombel_label_snapshot` VARCHAR(30) DEFAULT NULL COMMENT 'Snapshot label rombel saat sesi dibuka. Contoh: 10 AKL.' AFTER `selected_rombel_id`,
  MODIFY COLUMN `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Ruangan opsional pada DB 3.8. Tidak wajib karena ruang kelas/lab dapat berganti-ganti.',
  ADD COLUMN `lokasi_mode` ENUM('master_ruangan','input_manual','tidak_dicatat','fleksibel') NOT NULL DEFAULT 'tidak_dicatat' COMMENT 'Mode lokasi presensi. Default tidak_dicatat agar guru tidak wajib update ruangan setiap pindah ruang.' AFTER `ruangan_id`,
  ADD COLUMN `ruangan_label_manual` VARCHAR(100) DEFAULT NULL COMMENT 'Nama lokasi manual saat lokasi_mode=input_manual. Contoh: Ruang sementara lantai 2.' AFTER `lokasi_mode`,
  ADD COLUMN `ruangan_label_snapshot` VARCHAR(100) DEFAULT NULL COMMENT 'Snapshot label lokasi pada saat sesi dibuka. Bisa berasal dari master, manual, atau fleksibel.' AFTER `ruangan_label_manual`,
  ADD KEY `idx_scanner_sessions_lokasi_mode` (`lokasi_mode`, `tanggal`, `status`);

