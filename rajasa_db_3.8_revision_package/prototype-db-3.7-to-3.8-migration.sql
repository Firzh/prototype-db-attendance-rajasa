-- =========================================================
-- DB 3.8 MIGRATION PATCH
-- Upgrade from prototype-db-3.7.sql to prototype-db-3.8.sql
-- Focus:
-- 1) Data mitra minimal: NO, NISN, NAMA, KELAS.
-- 2) Rombel tanpa inkremen di UI: 10 AKL tetap tampil 10 AKL.
-- 3) nomor_rombel=1 hanya dipakai internal ketika hanya ada satu rombel.
-- 4) Ruangan fisik fleksibel dan tidak menjadi syarat presensi MVP.
-- 5) Presensi QR web berbasis scanner_session + siswa.
-- =========================================================

-- =========================================================
-- 1. PATCH SISWA: FIELD DARI MITRA TIDAK LENGKAP
-- =========================================================
ALTER TABLE `siswa`
  MODIFY COLUMN `jenis_kelamin` ENUM('L','P') NULL COMMENT 'L=Laki-laki, P=Perempuan. DB 3.8: boleh NULL karena file mitra tidak menyediakan gender.',
  MODIFY COLUMN `angkatan` YEAR NULL COMMENT 'Tahun angkatan siswa. DB 3.8: boleh NULL karena file mitra hanya menyediakan NO, NISN, NAMA, KELAS.',
  MODIFY COLUMN `kelas_aktif` VARCHAR(20) DEFAULT NULL COMMENT 'Cache label kelas aktif untuk UI. DB 3.8: gunakan format familiar guru, misalnya 10 AKL, bukan X AKL atau 10 AKL 1.';

-- =========================================================
-- 2. PATCH ROMBEL: INTERNAL BOLEH NOMOR 1, UI TETAP TANPA INKREMEN
-- =========================================================
ALTER TABLE `rombel`
  ADD COLUMN `tingkat_angka` TINYINT UNSIGNED DEFAULT NULL COMMENT 'Angka tingkat dari label mitra: 10, 11, 12, atau 13. Dipakai untuk tampilan UI guru/admin.' AFTER `tingkatan`,
  MODIFY COLUMN `nomor_rombel` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Nomor internal rombel. DB 3.8: jika input 10 AKL dan hanya ada satu rombel, simpan 1 secara internal tetapi jangan tampilkan sebagai 10 AKL 1.',
  ADD COLUMN `is_nomor_rombel_inferred` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 jika nomor_rombel dibuat otomatis karena data mitra tidak menyediakan nomor rombel eksplisit.' AFTER `nomor_rombel`,
  MODIFY COLUMN `label_rombel` VARCHAR(30) DEFAULT NULL COMMENT 'Label tampilan rombel untuk UI. DB 3.8: contoh 10 AKL. Jangan otomatis menambahkan angka 1 jika hanya ada satu rombel.',
  ADD COLUMN `label_rombel_raw` VARCHAR(50) DEFAULT NULL COMMENT 'Label kelas/rombel mentah dari sumber import. Contoh: 10 AKL.' AFTER `label_rombel`,
  ADD COLUMN `display_mode` ENUM('tanpa_nomor','dengan_nomor','custom') NOT NULL DEFAULT 'tanpa_nomor' COMMENT 'Aturan tampilan rombel. Default tanpa_nomor agar 10 AKL tidak tampil sebagai 10 AKL 1.' AFTER `label_rombel_raw`,
  ADD COLUMN `is_inferred_from_import` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 jika rombel dibuat otomatis dari parser KELAS file mitra.' AFTER `display_mode`,
  ADD KEY `idx_rombel_display` (`status`, `tingkat_angka`, `label_rombel`),
  ADD CONSTRAINT `chk_rombel_tingkat_angka`
    CHECK (`tingkat_angka` IS NULL OR `tingkat_angka` IN (10,11,12,13));

-- Backfill angka tingkat dari format internal lama.
UPDATE `rombel`
SET `tingkat_angka` = CASE `tingkatan`
  WHEN 'X' THEN 10
  WHEN 'XI' THEN 11
  WHEN 'XII' THEN 12
  WHEN 'XIII' THEN 13
  ELSE NULL
END
WHERE `tingkat_angka` IS NULL;

-- Backfill label tampilan agar UI tidak perlu menebak format.
UPDATE `rombel` r
JOIN `jurusan` j ON j.`jurusan_id` = r.`jurusan_id`
SET
  r.`label_rombel` = COALESCE(NULLIF(r.`label_rombel`, ''), CONCAT(COALESCE(r.`tingkat_angka`, CASE r.`tingkatan` WHEN 'X' THEN 10 WHEN 'XI' THEN 11 WHEN 'XII' THEN 12 WHEN 'XIII' THEN 13 END), ' ', j.`kode_jurusan`)),
  r.`label_rombel_raw` = COALESCE(NULLIF(r.`label_rombel_raw`, ''), CONCAT(COALESCE(r.`tingkat_angka`, CASE r.`tingkatan` WHEN 'X' THEN 10 WHEN 'XI' THEN 11 WHEN 'XII' THEN 12 WHEN 'XIII' THEN 13 END), ' ', j.`kode_jurusan`)),
  r.`display_mode` = 'tanpa_nomor',
  r.`is_nomor_rombel_inferred` = 1
WHERE r.`nomor_rombel` = 1;

-- Pastikan kode jurusan AKL tersedia karena contoh data mitra memakai 10 AKL.
INSERT INTO `jurusan` (`kode_jurusan`, `nama_jurusan`, `deskripsi_jurusan`, `status`)
VALUES ('AKL', 'Akuntansi dan Keuangan Lembaga', 'Seed DB 3.8 untuk mendukung data mitra minimal 10 AKL.', 'aktif')
ON DUPLICATE KEY UPDATE
  `nama_jurusan` = VALUES(`nama_jurusan`),
  `status` = 'aktif',
  `updated_at` = CURRENT_TIMESTAMP;

-- =========================================================
-- 3. PATCH IMPORT: KONTRAK DATA MITRA MINIMAL
-- =========================================================
ALTER TABLE `import_jobs`
  ADD COLUMN `source_contract_version` VARCHAR(30) DEFAULT 'mitra-minimal-v1' COMMENT 'Kontrak sumber import. DB 3.8: mitra-minimal-v1 berarti NO, NISN, NAMA, KELAS.' AFTER `detected_type`,
  ADD COLUMN `use_no_as_absen` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Default 0. Kolom NO dari file mitra adalah nomor urut sumber, bukan nomor absen, kecuali admin mengaktifkan opsi ini.' AFTER `options_json`,
  ADD COLUMN `kelas_display_mode` ENUM('tanpa_nomor','dengan_nomor','raw') NOT NULL DEFAULT 'tanpa_nomor' COMMENT 'Aturan display hasil parser KELAS. Default tanpa_nomor: 10 AKL tetap 10 AKL.' AFTER `use_no_as_absen`;

ALTER TABLE `import_row_logs`
  ADD COLUMN `source_no` VARCHAR(20) DEFAULT NULL COMMENT 'Nilai NO dari file sumber. Default hanya nomor urut sumber, bukan nomor absen.' AFTER `row_number`,
  ADD COLUMN `source_nisn` VARCHAR(20) DEFAULT NULL COMMENT 'Nilai NISN mentah dari file sumber. Disimpan sebagai teks agar nol di depan tidak hilang.' AFTER `source_no`,
  ADD COLUMN `source_nama` VARCHAR(120) DEFAULT NULL COMMENT 'Nilai NAMA mentah dari file sumber.' AFTER `source_nisn`,
  ADD COLUMN `source_kelas` VARCHAR(50) DEFAULT NULL COMMENT 'Nilai KELAS mentah dari file sumber. Contoh: 10 AKL.' AFTER `source_nama`,
  ADD COLUMN `normalized_rombel_label` VARCHAR(30) DEFAULT NULL COMMENT 'Hasil normalisasi tampilan rombel. Contoh DB 3.8: 10 AKL.' AFTER `source_kelas`,
  ADD COLUMN `use_no_as_absen` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Snapshot opsi apakah NO dipakai sebagai nomor absen pada import ini.' AFTER `normalized_rombel_label`,
  ADD KEY `idx_import_row_logs_nisn` (`import_id`, `source_nisn`),
  ADD KEY `idx_import_row_logs_kelas` (`import_id`, `source_kelas`);

-- =========================================================
-- 4. PATCH SCANNER SESSION: RUANGAN FLEKSIBEL
-- =========================================================
ALTER TABLE `scanner_sessions`
  ADD COLUMN `selected_rombel_label_snapshot` VARCHAR(30) DEFAULT NULL COMMENT 'Snapshot label rombel saat sesi dibuka. Contoh: 10 AKL.' AFTER `selected_rombel_id`,
  MODIFY COLUMN `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Ruangan opsional pada DB 3.8. Tidak wajib karena ruang kelas/lab dapat berganti-ganti.',
  ADD COLUMN `lokasi_mode` ENUM('master_ruangan','input_manual','tidak_dicatat','fleksibel') NOT NULL DEFAULT 'tidak_dicatat' COMMENT 'Mode lokasi presensi. Default tidak_dicatat agar guru tidak wajib update ruangan setiap pindah ruang.' AFTER `ruangan_id`,
  ADD COLUMN `ruangan_label_manual` VARCHAR(100) DEFAULT NULL COMMENT 'Nama lokasi manual saat lokasi_mode=input_manual. Contoh: Ruang sementara lantai 2.' AFTER `lokasi_mode`,
  ADD COLUMN `ruangan_label_snapshot` VARCHAR(100) DEFAULT NULL COMMENT 'Snapshot label lokasi pada saat sesi dibuka. Bisa berasal dari master, manual, atau fleksibel.' AFTER `ruangan_label_manual`,
  ADD KEY `idx_scanner_sessions_lokasi_mode` (`lokasi_mode`, `tanggal`, `status`);

-- =========================================================
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

-- =========================================================
-- 6. VIEW BANTU UNTUK BACKEND/FRONTEND
-- =========================================================
CREATE OR REPLACE VIEW `v_rombel_display` AS
SELECT
  r.`rombel_id`,
  r.`tingkatan`,
  r.`tingkat_angka`,
  r.`jurusan_id`,
  j.`kode_jurusan`,
  j.`nama_jurusan`,
  r.`nomor_rombel`,
  r.`is_nomor_rombel_inferred`,
  r.`display_mode`,
  r.`label_rombel_raw`,
  CASE
    WHEN r.`display_mode` = 'custom' AND r.`label_rombel` IS NOT NULL AND r.`label_rombel` <> '' THEN r.`label_rombel`
    WHEN r.`display_mode` = 'dengan_nomor' THEN CONCAT(COALESCE(r.`tingkat_angka`, CASE r.`tingkatan` WHEN 'X' THEN 10 WHEN 'XI' THEN 11 WHEN 'XII' THEN 12 WHEN 'XIII' THEN 13 END), ' ', j.`kode_jurusan`, ' ', r.`nomor_rombel`)
    ELSE CONCAT(COALESCE(r.`tingkat_angka`, CASE r.`tingkatan` WHEN 'X' THEN 10 WHEN 'XI' THEN 11 WHEN 'XII' THEN 12 WHEN 'XIII' THEN 13 END), ' ', j.`kode_jurusan`)
  END AS `display_label`,
  r.`status`,
  r.`is_inferred_from_import`,
  r.`created_at`,
  r.`updated_at`
FROM `rombel` r
JOIN `jurusan` j ON j.`jurusan_id` = r.`jurusan_id`;

CREATE OR REPLACE VIEW `v_import_siswa_minimal_rows` AS
SELECT
  ir.`import_id`,
  ir.`row_log_id`,
  ir.`row_number`,
  ir.`source_no`,
  ir.`source_nisn`,
  ir.`source_nama`,
  ir.`source_kelas`,
  ir.`normalized_rombel_label`,
  ir.`use_no_as_absen`,
  ir.`row_status`,
  ir.`message`,
  ir.`source_data_json`,
  ir.`normalized_data_json`,
  ir.`target_table`,
  ir.`target_id`,
  ir.`created_at`
FROM `import_row_logs` ir;

CREATE OR REPLACE VIEW `v_presensi_session_rekap` AS
SELECT
  p.`scanner_session_id`,
  p.`tanggal`,
  COALESCE(p.`rombel_display_snapshot`, p.`rombel_snapshot`, ss.`selected_rombel_label_snapshot`) AS `rombel_display`,
  p.`lokasi_mode`,
  COALESCE(p.`ruangan_label_snapshot`, ss.`ruangan_label_snapshot`, ss.`ruangan_label_manual`) AS `lokasi_display`,
  COUNT(*) AS `total_presensi`,
  SUM(CASE WHEN p.`status` = 'hadir' THEN 1 ELSE 0 END) AS `total_hadir`,
  SUM(CASE WHEN p.`status` = 'terlambat' THEN 1 ELSE 0 END) AS `total_terlambat`,
  SUM(CASE WHEN p.`status` = 'alpha' THEN 1 ELSE 0 END) AS `total_alpha`,
  SUM(CASE WHEN p.`status` = 'izin' THEN 1 ELSE 0 END) AS `total_izin`,
  SUM(CASE WHEN p.`status` = 'sakit' THEN 1 ELSE 0 END) AS `total_sakit`
FROM `presensi` p
LEFT JOIN `scanner_sessions` ss ON ss.`scanner_session_id` = p.`scanner_session_id`
GROUP BY
  p.`scanner_session_id`,
  p.`tanggal`,
  COALESCE(p.`rombel_display_snapshot`, p.`rombel_snapshot`, ss.`selected_rombel_label_snapshot`),
  p.`lokasi_mode`,
  COALESCE(p.`ruangan_label_snapshot`, ss.`ruangan_label_snapshot`, ss.`ruangan_label_manual`);

-- =========================================================
-- 7. CATATAN BACKEND WAJIB UNTUK DB 3.8
-- =========================================================
-- Parser KELAS wajib mengikuti keputusan berikut:
-- Input: 10 AKL
-- Internal: tingkatan='X', tingkat_angka=10, kode_jurusan='AKL', nomor_rombel=1, is_nomor_rombel_inferred=1
-- Display: label_rombel='10 AKL', display_mode='tanpa_nomor'
-- Larangan: jangan tampilkan 10 AKL 1 kecuali data sumber eksplisit berisi nomor rombel atau admin memilih display_mode='dengan_nomor'.
-- Kolom NO dari file mitra wajib dianggap source_no, bukan no_absen, selama use_no_as_absen=0.
-- Ruangan presensi tidak wajib. Gunakan lokasi_mode dan snapshot lokasi pada scanner_sessions/presensi.
