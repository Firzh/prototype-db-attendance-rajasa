-- =========================================================
-- 008 - IMPORT WIZARD: import jobs, mappings, row logs
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE IF NOT EXISTS `import_jobs` (
  `import_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik proses import.',
  `import_code` VARCHAR(40) NOT NULL COMMENT 'Kode import untuk audit/UI. Contoh: IMP-20260430-0001.',
  `import_type` ENUM('master_siswa','siswa_penempatan_rombel','update_penempatan_rombel') NOT NULL COMMENT 'Jenis import yang diproses sistem.',
  `detected_type` ENUM('master_siswa','siswa_penempatan_rombel','update_penempatan_rombel','unknown') NOT NULL DEFAULT 'unknown' COMMENT 'Jenis data hasil deteksi parser.',
  `source_contract_version` VARCHAR(30) DEFAULT 'mitra-minimal-v1' COMMENT 'Kontrak sumber import. mitra-minimal-v1 berarti NO, NISN, NAMA, KELAS.',
  `detection_confidence` DECIMAL(5,2) DEFAULT NULL COMMENT 'Skor keyakinan parser 0-100.',
  `parser_engine` ENUM('openspout','fastexcelreader','papaparse','read_excel_file','manual','other') NOT NULL DEFAULT 'openspout' COMMENT 'Engine parser yang dipakai. Backend disarankan memakai openspout/fastexcelreader.',
  `original_filename` VARCHAR(255) NOT NULL COMMENT 'Nama file asli dari operator/admin.',
  `file_media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi media_berkas jika file import disimpan sebagai arsip.',
  `mime_type` VARCHAR(100) DEFAULT NULL,
  `file_size_bytes` BIGINT UNSIGNED DEFAULT NULL,
  `sheet_name` VARCHAR(100) DEFAULT NULL COMMENT 'Nama sheet aktif bila file XLSX memiliki banyak sheet.',
  `tahun_ajaran` VARCHAR(9) DEFAULT NULL COMMENT 'Periode akademik hasil deteksi/default aktif.',
  `semester` ENUM('ganjil','genap','pendek') DEFAULT NULL COMMENT 'Semester hasil deteksi/default aktif.',
  `status` ENUM('uploaded','detected','mapped','validated','processing','success','partial_failed','failed','cancelled') NOT NULL DEFAULT 'uploaded',
  `total_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `valid_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `warning_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `error_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `inserted_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `updated_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `skipped_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `options_json` JSON DEFAULT NULL COMMENT 'Opsi import. Contoh: mode pindah rombel, import valid saja, auto-create akun siswa.',
  `use_no_as_absen` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Default 0. Kolom NO dari file mitra adalah nomor urut sumber, bukan nomor absen, kecuali admin mengaktifkan opsi ini.',
  `kelas_display_mode` ENUM('tanpa_nomor','dengan_nomor','raw') NOT NULL DEFAULT 'tanpa_nomor' COMMENT 'Aturan display hasil parser KELAS. Default tanpa_nomor: 10 AKL tetap 10 AKL.',
  `error_summary` TEXT DEFAULT NULL COMMENT 'Ringkasan error untuk tampilan akhir import.',
  `created_by` INT UNSIGNED DEFAULT NULL COMMENT 'User operator/admin yang menjalankan import.',
  `started_at` DATETIME DEFAULT NULL,
  `finished_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`import_id`),
  UNIQUE KEY `uk_import_jobs_code` (`import_code`),
  KEY `idx_import_jobs_status` (`status`, `created_at`),
  KEY `idx_import_jobs_type_period` (`import_type`, `tahun_ajaran`, `semester`),
  KEY `idx_import_jobs_created_by` (`created_by`, `created_at`),
  CONSTRAINT `fk_import_jobs_media`
    FOREIGN KEY (`file_media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_import_jobs_created_by`
    FOREIGN KEY (`created_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_import_jobs_confidence`
    CHECK (`detection_confidence` IS NULL OR (`detection_confidence` >= 0 AND `detection_confidence` <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `import_column_mappings` (
  `mapping_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `import_id` BIGINT UNSIGNED NOT NULL,
  `source_column_index` SMALLINT UNSIGNED NOT NULL COMMENT 'Urutan kolom pada file, mulai 1.',
  `source_column_name` VARCHAR(150) NOT NULL COMMENT 'Header asli dari file.',
  `sample_value` VARCHAR(255) DEFAULT NULL COMMENT 'Contoh isi dari beberapa baris awal untuk UI mapping.',
  `target_field` VARCHAR(120) DEFAULT NULL COMMENT 'Field sistem. Contoh: siswa.nisn, siswa.nama_lengkap, penempatan_siswa_rombel.no_absen.',
  `confidence` DECIMAL(5,2) DEFAULT NULL COMMENT 'Skor keyakinan auto-mapping 0-100.',
  `is_required` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Apakah field target wajib untuk jenis import ini.',
  `is_confirmed` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Apakah mapping sudah dikonfirmasi operator/admin.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`mapping_id`),
  UNIQUE KEY `uk_import_mapping_column` (`import_id`, `source_column_index`),
  KEY `idx_import_mapping_target` (`import_id`, `target_field`),
  CONSTRAINT `fk_import_mappings_job`
    FOREIGN KEY (`import_id`) REFERENCES `import_jobs`(`import_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_import_mapping_confidence`
    CHECK (`confidence` IS NULL OR (`confidence` >= 0 AND `confidence` <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `import_row_logs` (
  `row_log_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `import_id` BIGINT UNSIGNED NOT NULL,
  `row_number` INT UNSIGNED NOT NULL COMMENT 'Nomor baris pada file asli.',
  `row_status` ENUM('valid','warning','error','skipped','imported') NOT NULL DEFAULT 'valid',
  `message` TEXT DEFAULT NULL COMMENT 'Pesan validasi/error. Contoh: NISN kosong, kode jurusan tidak ditemukan.',
  `source_data_json` JSON DEFAULT NULL COMMENT 'Data mentah baris import setelah parser membaca file.',
  `normalized_data_json` JSON DEFAULT NULL COMMENT 'Data hasil normalisasi sebelum insert/update.',
  `target_table` VARCHAR(80) DEFAULT NULL COMMENT 'Tabel target jika baris berhasil diproses.',
  `target_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'ID target jika baris berhasil diproses.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`row_log_id`),
  KEY `idx_import_row_logs_import_status` (`import_id`, `row_status`, `row_number`),
  CONSTRAINT `fk_import_row_logs_job`
    FOREIGN KEY (`import_id`) REFERENCES `import_jobs`(`import_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

