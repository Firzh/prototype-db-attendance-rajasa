-- =========================================================
-- DB 3.8 ROLLBACK PATCH
-- Downgrade structural changes from prototype-db-3.8 to prototype-db-3.7
-- WARNING:
-- 1. Rollback dapat gagal jika data baru bergantung pada kolom DB 3.8.
-- 2. Jangan mengubah siswa.jenis_kelamin dan siswa.angkatan kembali NOT NULL
--    sebelum semua nilai NULL diselesaikan secara sadar oleh admin.
-- 3. Jangan mengisi gender/angkatan palsu hanya demi rollback.
-- =========================================================

DROP VIEW IF EXISTS `v_presensi_session_rekap`;
DROP VIEW IF EXISTS `v_import_siswa_minimal_rows`;
DROP VIEW IF EXISTS `v_rombel_display`;

-- Rollback presensi.
ALTER TABLE `presensi`
  DROP FOREIGN KEY `fk_presensi_ruangan`;

ALTER TABLE `presensi`
  DROP INDEX `uk_presensi_session_siswa`,
  DROP INDEX `idx_presensi_lokasi_mode`,
  DROP COLUMN `rombel_display_snapshot`,
  DROP COLUMN `ruangan_label_snapshot`,
  DROP COLUMN `lokasi_mode`,
  MODIFY COLUMN `ruangan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ruangan terkait.';

ALTER TABLE `presensi`
  ADD CONSTRAINT `fk_presensi_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Rollback scanner_sessions.
ALTER TABLE `scanner_sessions`
  DROP INDEX `idx_scanner_sessions_lokasi_mode`,
  DROP COLUMN `ruangan_label_snapshot`,
  DROP COLUMN `ruangan_label_manual`,
  DROP COLUMN `lokasi_mode`,
  MODIFY COLUMN `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Ruangan hasil turunan dari plotting_rombel aktif. Wajib diisi backend sebelum scan produktif.',
  DROP COLUMN `selected_rombel_label_snapshot`;

-- Rollback import row logs.
ALTER TABLE `import_row_logs`
  DROP INDEX `idx_import_row_logs_kelas`,
  DROP INDEX `idx_import_row_logs_nisn`,
  DROP COLUMN `use_no_as_absen`,
  DROP COLUMN `normalized_rombel_label`,
  DROP COLUMN `source_kelas`,
  DROP COLUMN `source_nama`,
  DROP COLUMN `source_nisn`,
  DROP COLUMN `source_no`;

-- Rollback import jobs.
ALTER TABLE `import_jobs`
  DROP COLUMN `kelas_display_mode`,
  DROP COLUMN `use_no_as_absen`,
  DROP COLUMN `source_contract_version`;

-- Rollback rombel.
ALTER TABLE `rombel`
  DROP CHECK `chk_rombel_tingkat_angka`,
  DROP INDEX `idx_rombel_display`,
  DROP COLUMN `is_inferred_from_import`,
  DROP COLUMN `display_mode`,
  DROP COLUMN `label_rombel_raw`,
  MODIFY COLUMN `label_rombel` VARCHAR(30) DEFAULT NULL COMMENT 'Buffer label custom/sorting. Contoh implementasi: XII-TKJ-1. Nilai dapat dibentuk backend dari tingkatan, jurusan, dan nomor rombel.',
  DROP COLUMN `is_nomor_rombel_inferred`,
  MODIFY COLUMN `nomor_rombel` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Nomor urut rombel dalam kombinasi tingkatan dan jurusan. Contoh implementasi: 1 untuk TKJ-1.',
  DROP COLUMN `tingkat_angka`;

-- Rollback siswa ke NOT NULL hanya dapat dilakukan setelah data NULL dibersihkan.
-- Jalankan query cek berikut lebih dulu:
-- SELECT COUNT(*) AS siswa_gender_null FROM siswa WHERE jenis_kelamin IS NULL;
-- SELECT COUNT(*) AS siswa_angkatan_null FROM siswa WHERE angkatan IS NULL;
-- Jika masih ada NULL, perintah berikut akan gagal. Itu lebih aman daripada membuat data palsu.
ALTER TABLE `siswa`
  MODIFY COLUMN `jenis_kelamin` ENUM('L','P') NOT NULL COMMENT 'L=Laki-laki, P=Perempuan',
  MODIFY COLUMN `angkatan` YEAR NOT NULL COMMENT 'Tahun angkatan siswa. Contoh implementasi: 2024.',
  MODIFY COLUMN `kelas_aktif` VARCHAR(20) DEFAULT NULL COMMENT 'Cache label kelas aktif untuk sorting/filter cepat. Kandidat tetap dipertahankan selama UI masih membutuhkan akses cepat tanpa join.';
