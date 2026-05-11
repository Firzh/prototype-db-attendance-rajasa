-- =========================================================
-- 006 - ATTENDANCE QR ONLINE: qr token, scan log, presensi, online submission
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `qr_tokens` (

  `qr_token_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik token QR.',
  `siswa_id` INT UNSIGNED NOT NULL COMMENT 'Referensi siswa terkait.',
  `qr_reference` VARCHAR(100) NOT NULL COMMENT 'Kode referensi/slug QR internal untuk tampilan, pencarian, atau cetak. Dapat dibentuk dari nama/NISN agar mudah ditelusuri meskipun payload vendor berupa link dinamis.',
  `qr_payload_hash` CHAR(64) NOT NULL COMMENT 'Hash payload QR, bukan payload mentah. Dipakai untuk mencocokkan QR vendor yang dinamis tanpa menyimpan link sensitif sebagai kunci utama.',
  `qr_vendor_link` TEXT DEFAULT NULL COMMENT 'Link QR dari vendor bila payload memang berupa URL dinamis. Kolom ini disimpan sebagai referensi operasional, sedangkan pencocokan utama tetap dapat memakai hash dan identitas siswa.',
  `qr_version` VARCHAR(20) DEFAULT 'v1' COMMENT 'Versi format QR. Contoh implementasi: ''v1''.',
  `is_primary` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda perangkat utama/token utama. Contoh implementasi: 1=utama.',
  `issued_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu token QR diterbitkan atau dicatat masuk ke sistem. Penting untuk audit, historisasi pergantian QR, dan sinkronisasi dengan vendor dinamis.',
  `expired_at` DATETIME DEFAULT NULL COMMENT 'Waktu token QR berakhir bila sekolah menerapkan masa berlaku internal. Boleh NULL bila QR vendor dianggap aktif terus sampai dicabut.',
  `status` ENUM('aktif','nonaktif','dicabut','kedaluwarsa') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `revoked_reason` VARCHAR(255) DEFAULT NULL COMMENT 'Alasan pencabutan token QR. Contoh implementasi: ''QR bocor, diganti token baru''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`qr_token_id`),
  UNIQUE KEY `uk_qr_tokens_reference` (`qr_reference`),
  UNIQUE KEY `uk_qr_tokens_payload_hash` (`qr_payload_hash`),
  KEY `idx_qr_tokens_siswa_status` (`siswa_id`, `status`, `is_primary`),
  CONSTRAINT `fk_qr_tokens_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `log_scan_qr` (

  `log_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik log scan QR.',
  `scan_uuid` CHAR(36) DEFAULT NULL COMMENT 'UUID unik per kejadian scan. Contoh implementasi: ''550e8400-e29b-41d4-a716-446655440000''.',
  `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi ruangan terkait. DB 3.8 MVP: boleh NULL karena sesi scan dapat memakai lokasi tidak_dicatat/input_manual.',
  `perangkat_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi perangkat terkait.',
  `jadwal_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi jadwal lab terkait.',
  `siswa_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi siswa terkait.',
  `qr_token_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi token QR yang dipakai saat scan.',
  `scanned_payload_hash` CHAR(64) DEFAULT NULL COMMENT 'Hash payload hasil scan saat kejadian. Contoh implementasi: hash QR yang dibaca scanner.',
  `scan_method` ENUM('qr','manual') NOT NULL DEFAULT 'qr' COMMENT 'Metode input scan. Contoh implementasi: ''qr'' otomatis atau ''manual'' oleh operator.',
  `scan_type` ENUM('checkin','checkout','uji_coba','akses') NOT NULL DEFAULT 'checkin' COMMENT 'Jenis scan. Contoh implementasi: ''checkin'', ''checkout'', ''uji_coba'', atau ''akses''.',
  `foto_capture` VARCHAR(255) DEFAULT NULL COMMENT 'Lokasi file foto capture dari ESP32-CAM bila dipakai. Kolom path ini dipertahankan untuk kompatibilitas cepat.',
  `foto_capture_media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi ke media_berkas untuk foto capture scan QR agar arsip dan restore dapat dilacak per file.',
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
  ) NOT NULL COMMENT 'Status hasil scan QR. Contoh implementasi: ''berhasil'', ''qr_kedaluwarsa'', atau ''manual_override''.',
  `keterangan` TEXT DEFAULT NULL COMMENT 'Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.',
  `tanggal` DATE NOT NULL COMMENT 'Tanggal kejadian/transaksi. Contoh implementasi: ''2026-07-15''.',
  `waktu` TIME NOT NULL COMMENT 'Waktu kejadian. Contoh implementasi: ''07:12:05''.',
  `scanned_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Tanggal dan waktu lengkap scan. Contoh implementasi: ''2026-04-09 07:12:05''.',
  `origin_ip` VARCHAR(45) DEFAULT NULL COMMENT 'IP asal request scan. Contoh implementasi: IP gateway scanner atau server API.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`log_id`),
  UNIQUE KEY `uk_log_scan_qr_uuid` (`scan_uuid`),
  KEY `idx_log_scan_qr_time` (`tanggal`, `waktu`, `ruangan_id`),
  KEY `idx_log_scan_qr_status` (`status`, `scan_type`),
  KEY `idx_log_scan_qr_siswa` (`siswa_id`, `tanggal`),
  CONSTRAINT `fk_log_scan_qr_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
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
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_log_scan_qr_foto_capture_media`
    FOREIGN KEY (`foto_capture_media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi` (

  `presensi_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik data presensi harian.',
  `siswa_id` INT UNSIGNED NOT NULL COMMENT 'Referensi siswa terkait.',
  `ruangan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ruangan terkait.',
  `plotting_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi plotting rombel terkait. Kolom ini sengaja boleh NULL untuk kasus presensi manual, presensi susulan, presensi online yang disinkronkan, atau aktivitas di luar plotting reguler.',
  `jadwal_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi jadwal lab terkait.',
  `tanggal` DATE NOT NULL COMMENT 'Tanggal kejadian/transaksi. Contoh implementasi: ''2026-07-15''.',
  `waktu_masuk` TIME DEFAULT NULL COMMENT 'Jam masuk presensi. Contoh implementasi: ''07:05:00''.',
  `waktu_keluar` TIME DEFAULT NULL COMMENT 'Jam keluar presensi. Contoh implementasi: ''14:55:00''.',
  `waktu_pulang_plan` TIME NOT NULL DEFAULT '15:00:00' COMMENT 'Jam pulang yang direncanakan. Contoh implementasi: ''15:00:00''. Nilai default dapat dioverride dari plotting/jadwal/custom event oleh backend saat record presensi dibuat.',
  `status` ENUM('hadir','terlambat','alpha','izin','sakit') NOT NULL DEFAULT 'alpha' COMMENT 'Status hasil presensi. Contoh implementasi: ''hadir'', ''terlambat'', ''izin'', ''sakit'', atau ''alpha''.',
  `status_checkout` ENUM('belum_checkout','sudah_checkout','pulang_cepat') NOT NULL DEFAULT 'belum_checkout' COMMENT 'Status checkout/pulang. Default ''belum_checkout'' dipakai sampai ada scan keluar atau verifikasi pulang manual.',
  `bukti_izin_sakit` VARCHAR(255) DEFAULT NULL COMMENT 'Lokasi file bukti izin/sakit. Contoh implementasi: ''izin/2026-04-09/surat_dokter_220145.jpg''. Path ini tetap disimpan untuk akses cepat aplikasi lama.',
  `bukti_izin_media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi media_berkas untuk bukti izin/sakit agar file dapat dilacak dan diarsipkan secara formal.',
  `foto_scan_masuk` VARCHAR(255) DEFAULT NULL COMMENT 'Foto saat scan masuk. Contoh implementasi: ''scan_masuk/220145_20260409_070500.jpg''. Path ini dipertahankan untuk kompatibilitas cepat.',
  `foto_scan_masuk_media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi media_berkas untuk foto scan masuk.',
  `foto_scan_keluar` VARCHAR(255) DEFAULT NULL COMMENT 'Foto saat scan keluar. Contoh implementasi: ''scan_keluar/220145_20260409_145500.jpg''. Path ini dipertahankan untuk kompatibilitas cepat.',
  `foto_scan_keluar_media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi media_berkas untuk foto scan keluar.',
  `scan_masuk_log_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi log scan untuk masuk.',
  `scan_keluar_log_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi log scan untuk keluar.',
  `jurusan_snapshot` VARCHAR(50) NOT NULL COMMENT 'Nama jurusan saat presensi diambil',
  `kelas_snapshot` VARCHAR(20) NOT NULL COMMENT 'Label kelas saat presensi diambil',
  `rombel_snapshot` VARCHAR(20) DEFAULT NULL COMMENT 'Label rombel saat presensi diambil',
  `tahun_ajaran_snapshot` VARCHAR(9) DEFAULT NULL COMMENT 'Tahun ajaran saat presensi diambil. Contoh implementasi: ''2025/2026''.',
  `semester_snapshot` ENUM('ganjil','genap','pendek') DEFAULT NULL COMMENT 'Semester saat presensi diambil. Contoh implementasi: ''ganjil''.',
  `validasi` ENUM('valid','tidak_valid','pending') NOT NULL DEFAULT 'valid' COMMENT 'Status validasi data. Contoh implementasi: ''valid'', ''pending'', atau ''tidak_valid''.',
  `diverifikasi_oleh` INT UNSIGNED DEFAULT NULL COMMENT 'User yang memverifikasi data. Contoh implementasi: admin akademik.',
  `waktu_verifikasi` DATETIME DEFAULT NULL COMMENT 'Waktu data diverifikasi. Contoh implementasi: ''2026-04-09 09:00:00''.',
  `keterangan` TEXT DEFAULT NULL COMMENT 'Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
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
  CONSTRAINT `fk_presensi_bukti_izin_media`
    FOREIGN KEY (`bukti_izin_media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_foto_scan_masuk_media`
    FOREIGN KEY (`foto_scan_masuk_media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_foto_scan_keluar_media`
    FOREIGN KEY (`foto_scan_keluar_media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_diverifikasi_oleh`
    FOREIGN KEY (`diverifikasi_oleh`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_online` (

  `presensi_online_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik pengajuan presensi online.',
  `submission_uuid` CHAR(36) NOT NULL COMMENT 'UUID unik submission agar aman dipakai di sisi client/API.',
  `siswa_id` INT UNSIGNED NOT NULL COMMENT 'Referensi siswa yang mengajukan presensi online.',
  `tanggal_presensi` DATE NOT NULL COMMENT 'Tanggal presensi online yang diajukan.',
  `waktu_submit` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu siswa mengirim bukti presensi online.',
  `plotting_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi plotting rombel bila presensi online masih terkait kelas/rombel reguler.',
  `jadwal_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi jadwal bila presensi online terkait sesi terjadwal.',
  `mode_pembelajaran` ENUM('daring_sinkron','daring_asinkron','tugas_wa','blended','lainnya') NOT NULL DEFAULT 'daring_sinkron' COMMENT 'Mode pembelajaran yang diikuti siswa.',
  `platform_bukti` ENUM('zoom','gmeet','wa','lms','upload_manual','lainnya') NOT NULL DEFAULT 'upload_manual' COMMENT 'Platform utama sumber bukti presensi.',
  `status_pengajuan` ENUM('draft','diajukan','ditinjau','disetujui','ditolak','perlu_perbaikan') NOT NULL DEFAULT 'diajukan' COMMENT 'Status alur pengajuan presensi online.',
  `status_presensi_final` ENUM('hadir','izin','sakit','tugas','alpha') NOT NULL DEFAULT 'hadir' COMMENT 'Keputusan status presensi akhir setelah diverifikasi.',
  `metode_verifikasi` ENUM('manual') NOT NULL DEFAULT 'manual' COMMENT 'Metode verifikasi MVP. AI recognition tidak disertakan pada paket modular ini.',
  `catatan_siswa` TEXT DEFAULT NULL COMMENT 'Catatan dari siswa saat mengirim bukti. Contoh implementasi: ''Mengikuti Zoom dari rumah, lampiran screenshot dan selfie''.',
  `catatan_verifikator` TEXT DEFAULT NULL COMMENT 'Catatan guru/operator saat meninjau pengajuan. Field ini menyimpan snapshot keputusan terakhir untuk akses cepat; histori lengkap tetap dicatat di presensi_online_verifikasi.',
  `diverifikasi_oleh` INT UNSIGNED DEFAULT NULL COMMENT 'User guru/staff yang memverifikasi pengajuan presensi online terakhir. Histori lengkap tetap dicatat di presensi_online_verifikasi.',
  `waktu_verifikasi` DATETIME DEFAULT NULL COMMENT 'Waktu keputusan verifikasi terakhir dibuat. Histori lengkap tetap dicatat di presensi_online_verifikasi.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`presensi_online_id`),
  UNIQUE KEY `uk_presensi_online_submission_uuid` (`submission_uuid`),
  KEY `idx_presensi_online_lookup` (`tanggal_presensi`, `status_pengajuan`, `status_presensi_final`),
  KEY `idx_presensi_online_siswa` (`siswa_id`, `tanggal_presensi`),
  CONSTRAINT `fk_presensi_online_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_online_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_online_jadwal`
    FOREIGN KEY (`jadwal_id`) REFERENCES `jadwal_lab`(`jadwal_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_online_diverifikasi_oleh`
    FOREIGN KEY (`diverifikasi_oleh`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_online_lampiran` (

  `lampiran_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik lampiran bukti presensi online.',
  `presensi_online_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referensi pengajuan presensi online.',
  `media_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referensi metadata file pada media_berkas.',
  `jenis_bukti` ENUM('selfie','screenshot_zoom','screenshot_gmeet','bukti_chat_wa','dokumen_pendukung') NOT NULL COMMENT 'Jenis bukti yang dilampirkan.',
  `is_utama` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Penanda lampiran utama yang paling representatif.',
  `urutan_tampil` SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Urutan tampilan lampiran di UI review.',
  `catatan` VARCHAR(255) DEFAULT NULL COMMENT 'Catatan singkat lampiran. Contoh implementasi: ''Selfie saat kelas dimulai''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`lampiran_id`),
  UNIQUE KEY `uk_presensi_online_lampiran_media` (`presensi_online_id`, `media_id`),
  KEY `idx_presensi_online_lampiran_jenis` (`jenis_bukti`, `is_utama`),
  CONSTRAINT `fk_presensi_online_lampiran_submission`
    FOREIGN KEY (`presensi_online_id`) REFERENCES `presensi_online`(`presensi_online_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_online_lampiran_media`
    FOREIGN KEY (`media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_online_verifikasi` (

  `verifikasi_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik riwayat verifikasi presensi online.',
  `presensi_online_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referensi pengajuan presensi online.',
  `verifikator_user_id` INT UNSIGNED NOT NULL COMMENT 'User guru/staff yang melakukan review.',
  `keputusan` ENUM('ditinjau','disetujui','ditolak','perlu_perbaikan') NOT NULL DEFAULT 'ditinjau' COMMENT 'Keputusan verifikasi untuk submission tertentu.',
  `status_presensi_hasil` ENUM('hadir','izin','sakit','tugas','alpha') NOT NULL DEFAULT 'hadir' COMMENT 'Status presensi hasil review.',
  `catatan_verifikasi` TEXT DEFAULT NULL COMMENT 'Catatan detail review manual. Contoh implementasi: ''Selfie sesuai, screenshot Zoom valid''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`verifikasi_id`),
  KEY `idx_presensi_online_verifikasi_submission` (`presensi_online_id`, `created_at`),
  CONSTRAINT `fk_presensi_online_verifikasi_submission`
    FOREIGN KEY (`presensi_online_id`) REFERENCES `presensi_online`(`presensi_online_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_online_verifikasi_user`
    FOREIGN KEY (`verifikator_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. REVISI LOG SCAN QR UNTUK WEB SCANNER, FLAGGED, DAN IDEMPOTENCY
-- =========================================================
ALTER TABLE `log_scan_qr`
  ADD COLUMN `scanner_device_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi scanner_devices untuk scan via HP/browser.' AFTER `perangkat_id`,
  ADD COLUMN `scanner_session_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi scanner_sessions untuk konteks scan web.' AFTER `scanner_device_id`,
  ADD COLUMN `scanned_by_user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User login yang melakukan scan via website.' AFTER `scanner_session_id`,
  ADD COLUMN `client_request_uuid` CHAR(36) DEFAULT NULL COMMENT 'UUID idempotency dari frontend agar request scan yang terkirim ulang tidak diproses ganda.' AFTER `scan_uuid`,
  ADD COLUMN `scan_source` ENUM('legacy_esp32','web_hp','web_tablet','web_desktop','manual_web','system') NOT NULL DEFAULT 'legacy_esp32' COMMENT 'Sumber kejadian scan. Untuk alur baru umumnya web_hp.' AFTER `scan_method`,
  ADD COLUMN `context_type` ENUM('rombel','ruangan','jadwal','legacy_esp32') NOT NULL DEFAULT 'legacy_esp32' COMMENT 'Konteks scan saat kejadian. Untuk opsi A memakai rombel.' AFTER `scan_type`,
  ADD COLUMN `selected_rombel_id` INT UNSIGNED DEFAULT NULL COMMENT 'Rombel yang dipilih pada halaman scan. Dipakai untuk validasi siswa beda rombel.' AFTER `context_type`,
  ADD COLUMN `actual_rombel_id` INT UNSIGNED DEFAULT NULL COMMENT 'Rombel aktif pemilik QR menurut penempatan_siswa_rombel saat scan.' AFTER `selected_rombel_id`,
  ADD COLUMN `is_flagged` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 jika scan terdeteksi warning, misalnya QR siswa tidak sesuai rombel yang dipilih.' AFTER `actual_rombel_id`,
  ADD COLUMN `flag_reason` ENUM('none','siswa_tidak_sesuai_rombel','qr_dipakai_orang_lain','duplikat_scan','manual_review','lainnya') NOT NULL DEFAULT 'none' COMMENT 'Alasan flag/warning scan.' AFTER `is_flagged`,
  ADD COLUMN `flag_resolution_status` ENUM('tidak_perlu','belum_resolve','resolved','diabaikan') NOT NULL DEFAULT 'tidak_perlu' COMMENT 'Status tindak lanjut flagged scan pada halaman presensi.' AFTER `flag_reason`,
  ADD COLUMN `flagged_actual_siswa_id` INT UNSIGNED DEFAULT NULL COMMENT 'Siswa pelaku sebenarnya bila guru berhasil mencatat nama asli siswa yang memakai kartu orang lain.' AFTER `flag_resolution_status`,
  ADD COLUMN `flag_resolved_by_user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User yang menyelesaikan flagged scan.' AFTER `flagged_actual_siswa_id`,
  ADD COLUMN `flag_resolved_at` DATETIME DEFAULT NULL COMMENT 'Waktu flagged scan diselesaikan.' AFTER `flag_resolved_by_user_id`,
  ADD COLUMN `flag_note` TEXT DEFAULT NULL COMMENT 'Catatan guru/admin saat resolve flagged scan. Contoh: nama siswa yang melakukan kejahilan.' AFTER `flag_resolved_at`;

ALTER TABLE `log_scan_qr`
  MODIFY COLUMN `status` ENUM(
    'berhasil',
    'qr_tidak_terdaftar',
    'qr_nonaktif',
    'qr_kedaluwarsa',
    'ruangan_tidak_cocok',
    'jadwal_tidak_cocok',
    'duplikat_scan',
    'foto_buram',
    'manual_override',
    'akses_ditolak',
    'siswa_tidak_sesuai_rombel',
    'sesi_tidak_aktif',
    'siswa_tidak_aktif',
    'penempatan_tidak_ditemukan',
    'lainnya'
  ) NOT NULL COMMENT 'Status hasil scan QR. Contoh implementasi: berhasil, siswa_tidak_sesuai_rombel, duplikat_scan, atau manual_override.';

ALTER TABLE `log_scan_qr`
  ADD UNIQUE KEY `uk_log_scan_qr_client_request` (`client_request_uuid`),
  ADD KEY `idx_log_scan_qr_scanner_session` (`scanner_session_id`, `tanggal`, `status`),
  ADD KEY `idx_log_scan_qr_scanned_by` (`scanned_by_user_id`, `tanggal`),
  ADD KEY `idx_log_scan_qr_selected_rombel` (`selected_rombel_id`, `tanggal`),
  ADD KEY `idx_log_scan_qr_flagged` (`is_flagged`, `flag_resolution_status`, `tanggal`),
  ADD CONSTRAINT `fk_log_scan_qr_scanner_device`
    FOREIGN KEY (`scanner_device_id`) REFERENCES `scanner_devices`(`scanner_device_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_scanner_session`
    FOREIGN KEY (`scanner_session_id`) REFERENCES `scanner_sessions`(`scanner_session_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_scanned_by_user`
    FOREIGN KEY (`scanned_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_selected_rombel`
    FOREIGN KEY (`selected_rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_actual_rombel`
    FOREIGN KEY (`actual_rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_flagged_actual_siswa`
    FOREIGN KEY (`flagged_actual_siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_flag_resolved_by`
    FOREIGN KEY (`flag_resolved_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 4. REVISI PRESENSI UNTUK WEB SCANNER DAN ANTI DOUBLE SCAN
-- =========================================================
ALTER TABLE `presensi`
  ADD COLUMN `presensi_source` ENUM('qr_esp32','qr_web','manual','online_sync') NOT NULL DEFAULT 'qr_esp32' COMMENT 'Sumber presensi. Untuk alur HP via website gunakan qr_web.' AFTER `scan_keluar_log_id`,
  ADD COLUMN `scanner_session_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Sesi scanner web yang menghasilkan presensi ini, bila ada.' AFTER `presensi_source`,
  ADD COLUMN `input_by_user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User yang membuat/menginput presensi. Untuk qr_web biasanya guru/admin/staff yang login.' AFTER `scanner_session_id`,
  ADD COLUMN `plotting_key` INT UNSIGNED GENERATED ALWAYS AS (IFNULL(`plotting_id`, 0)) STORED COMMENT 'Generated key agar unique presensi tetap bekerja walau plotting_id NULL.' AFTER `jadwal_id`,
  ADD COLUMN `jadwal_key` INT UNSIGNED GENERATED ALWAYS AS (IFNULL(`jadwal_id`, 0)) STORED COMMENT 'Generated key agar unique presensi tetap bekerja walau jadwal_id NULL.' AFTER `plotting_key`;

ALTER TABLE `presensi`
  ADD UNIQUE KEY `uk_presensi_siswa_sesi_qr` (`siswa_id`, `tanggal`, `ruangan_id`, `plotting_key`, `jadwal_key`),
  ADD KEY `idx_presensi_scanner_session` (`scanner_session_id`, `tanggal`),
  ADD KEY `idx_presensi_source_session` (`presensi_source`, `scanner_session_id`, `tanggal`),
  ADD KEY `idx_presensi_input_by` (`input_by_user_id`, `tanggal`),
  ADD CONSTRAINT `fk_presensi_scanner_session`
    FOREIGN KEY (`scanner_session_id`) REFERENCES `scanner_sessions`(`scanner_session_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_presensi_input_by_user`
    FOREIGN KEY (`input_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 5. PATCH PRESENSI: SNAPSHOT LOKASI + UNIQUE PER SESSION
-- =========================================================
ALTER TABLE `presensi`
  DROP FOREIGN KEY `fk_presensi_ruangan`;

ALTER TABLE `presensi`
  MODIFY COLUMN `ruangan_id` INT UNSIGNED NULL COMMENT 'Referensi ruangan opsional. DB 3.8: boleh NULL karena presensi QR web berbasis scanner_session dan lokasi dapat tidak dicatat.',
  ADD COLUMN `lokasi_mode` ENUM('master_ruangan','input_manual','tidak_dicatat','fleksibel') NOT NULL DEFAULT 'tidak_dicatat' COMMENT 'Snapshot mode lokasi dari sesi presensi.' AFTER `ruangan_id`,
  ADD COLUMN `ruangan_label_snapshot` VARCHAR(100) DEFAULT NULL COMMENT 'Snapshot nama lokasi saat presensi dibuat. Contoh: Ruang sementara lantai 2.' AFTER `lokasi_mode`,
  ADD COLUMN `rombel_display_snapshot` VARCHAR(30) DEFAULT NULL COMMENT 'Snapshot label rombel tampilan. Contoh: 10 AKL, bukan 10 AKL 1.' AFTER `rombel_snapshot`,
  ADD UNIQUE KEY `uk_presensi_session_siswa` (`scanner_session_id`, `siswa_id`),
  ADD KEY `idx_presensi_lokasi_mode` (`lokasi_mode`, `tanggal`, `status`);

ALTER TABLE `presensi`
  ADD CONSTRAINT `fk_presensi_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE;

