-- =========================================================
-- 005 - FILES ARCHIVE AUDIT: media, arsip, audit activity
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

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

CREATE TABLE `user_activities` (

  `log_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik audit aktivitas user. Mengganti admin_activities pada versi 3.2.',
  `user_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pelaku aktivitas. Boleh NULL agar log historis tetap bertahan jika akun dihapus.',
  `username_snapshot` VARCHAR(50) DEFAULT NULL COMMENT 'Snapshot username saat aktivitas terjadi.',
  `nama_lengkap_snapshot` VARCHAR(100) DEFAULT NULL COMMENT 'Snapshot nama lengkap saat aktivitas terjadi. Sumber dari siswa/guru_staff/system profile.',
  `nisn_snapshot` VARCHAR(20) DEFAULT NULL COMMENT 'Snapshot NISN bila user adalah siswa. NULL untuk guru_staff atau system.',
  `role_snapshot` VARCHAR(50) DEFAULT NULL COMMENT 'Snapshot nama role saat aktivitas terjadi.',
  `role_slug_snapshot` VARCHAR(50) DEFAULT NULL COMMENT 'Snapshot slug role saat aktivitas terjadi.',
  `user_type_snapshot` ENUM('siswa','guru_staff','system') DEFAULT NULL COMMENT 'Snapshot tipe user saat aktivitas terjadi.',
  `action_type` ENUM('login','logout','failed_login','create_data','update_data','delete_data','import_data','export_data','export_report','upload_file','download_file','validate_data','reject_data','assign_role','revoke_role','reset_password','change_password','generate_qr','revoke_qr','change_setting','archive_data','restore_data','refresh_buffer','system_error','other') NOT NULL DEFAULT 'other' COMMENT 'Jenis aktivitas user yang dicatat untuk audit.',
  `module_name` VARCHAR(50) DEFAULT NULL COMMENT 'Nama modul aplikasi. Contoh: users, presensi, laporan, qr_tokens, user_access_tokens, konfigurasi.',
  `target_table` VARCHAR(50) DEFAULT NULL COMMENT 'Nama tabel target yang terdampak. Contoh: users, presensi, ruangan.',
  `target_id` VARCHAR(100) DEFAULT NULL COMMENT 'Primary key atau identifier target yang terdampak dalam bentuk teks.',
  `status` ENUM('sukses','gagal','peringatan','ditolak','dibatalkan') NOT NULL DEFAULT 'sukses' COMMENT 'Status hasil aktivitas.',
  `activity_description` TEXT DEFAULT NULL COMMENT 'Keterangan aktivitas. Ruangan dapat ditulis di sini bila aktivitas hanya berupa konteks backend.',
  `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi ruangan bila aktivitas memang terkait ruangan. NULL untuk aktivitas backend umum.',
  `kode_ruangan_snapshot` VARCHAR(30) DEFAULT NULL COMMENT 'Snapshot kode ruangan saat aktivitas terjadi.',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT 'Alamat IP client/perangkat untuk audit teknis.',
  `user_agent` TEXT DEFAULT NULL COMMENT 'Browser/device mentah dari request header untuk audit teknis.',
  `archive_status` ENUM('hot','archived') NOT NULL DEFAULT 'hot' COMMENT 'Status penyimpanan log. hot=aktif, archived=sudah masuk cold archive.',
  `archived_at` DATETIME DEFAULT NULL COMMENT 'Waktu log masuk cold archive.',
  `cold_archive_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Relasi ke user_activity_cold_archives jika log sudah diekspor dan dikompres.',
  `arsip_batch_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Relasi opsional ke arsip_batch umum.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp aktivitas. Dipakai sebagai timestamp utama log.',
  PRIMARY KEY (`log_id`),
  KEY `idx_user_activities_user_time` (`user_id`, `created_at`),
  KEY `idx_user_activities_username` (`username_snapshot`, `created_at`),
  KEY `idx_user_activities_nisn` (`nisn_snapshot`, `created_at`),
  KEY `idx_user_activities_role_type` (`role_slug_snapshot`, `user_type_snapshot`, `created_at`),
  KEY `idx_user_activities_action_module` (`action_type`, `module_name`, `created_at`),
  KEY `idx_user_activities_status_time` (`status`, `created_at`),
  KEY `idx_user_activities_target` (`target_table`, `target_id`),
  KEY `idx_user_activities_ruangan` (`ruangan_id`, `created_at`),
  KEY `idx_user_activities_archive` (`archive_status`, `created_at`),
  KEY `idx_user_activities_cold_archive` (`cold_archive_id`),
  KEY `idx_user_activities_archive_batch` (`arsip_batch_id`),
  CONSTRAINT `fk_user_activities_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_user_activities_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_user_activities_cold_archive`
    FOREIGN KEY (`cold_archive_id`) REFERENCES `user_activity_cold_archives`(`cold_archive_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_user_activities_archive_batch`
    FOREIGN KEY (`arsip_batch_id`) REFERENCES `arsip_batch`(`arsip_batch_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


ALTER TABLE `user_activities`
  ADD COLUMN `metadata_json` JSON DEFAULT NULL COMMENT 'Metadata tambahan aktivitas. Untuk scanner session dapat berisi session_uuid, pilihan lanjutkan/selesai, total siswa belum presensi, atau alasan keluar halaman.' AFTER `activity_description`;
