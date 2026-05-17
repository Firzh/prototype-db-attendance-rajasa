-- =========================================================
-- SEED AKUN DEMO MVP - PRESENSI QR SISWA
-- Target DB: sistem_absensi_lab_qr
-- Password semua akun demo: Rajasa@123
-- Hash: bcrypt/PHP password_hash, cocok untuk password_verify()
-- Aman dijalankan berulang. Tidak membuat tabel akses lama.
-- Jalankan setelah schema prototype-db-3.9 dan seed_permissions_mvp_presensi_qr.sql.
-- =========================================================

USE `sistem_absensi_lab_qr`;

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET collation_connection = 'utf8mb4_unicode_ci';
SET FOREIGN_KEY_CHECKS = 1;

START TRANSACTION;

SET @demo_password_hash := '$2y$12$qsBTAZEla6ytj21DsIFONuN4ZAEIDtr1OPUcVSHKioV1whJlIG4bC';

-- ---------------------------------------------------------
-- 1. Pastikan role dasar tersedia
-- ---------------------------------------------------------
INSERT INTO `roles` (`nama_role`, `role_slug`, `deskripsi`, `level_rank`, `is_system`) VALUES
  ('Super Admin', 'super_admin', 'Akses tertinggi sistem.', 100, 1),
  ('Admin', 'admin', 'Mengelola data utama, koreksi presensi, laporan, import, dan konfigurasi.', 80, 1),
  ('Guru', 'guru', 'Melakukan presensi rombel/piket, koreksi presensi, warning, dan laporan terkait.', 30, 1),
  ('Staff', 'staff', 'Melakukan presensi piket/rombel, koreksi presensi, warning, dan laporan terkait.', 30, 1),
  ('Intern Presensi', 'intern_presensi', 'Akses custom terbatas untuk membantu presensi.', 20, 1),
  ('Siswa', 'siswa', 'Melihat profil dan hasil presensi milik sendiri.', 10, 1)
ON DUPLICATE KEY UPDATE
  `nama_role` = VALUES(`nama_role`),
  `deskripsi` = VALUES(`deskripsi`),
  `level_rank` = VALUES(`level_rank`),
  `is_system` = VALUES(`is_system`),
  `status` = 'aktif';

-- ---------------------------------------------------------
-- 2. Data akademik demo
-- ---------------------------------------------------------
INSERT INTO `tahun_ajaran` (`nama_tahun_ajaran`, `semester_aktif`, `tanggal_mulai`, `tanggal_selesai`, `is_aktif`) VALUES
('2026/2027', 'ganjil', '2026-07-01', '2027-06-30', 1)
ON DUPLICATE KEY UPDATE
  `semester_aktif` = VALUES(`semester_aktif`),
  `tanggal_mulai` = VALUES(`tanggal_mulai`),
  `tanggal_selesai` = VALUES(`tanggal_selesai`),
  `is_aktif` = VALUES(`is_aktif`);

SET @tahun_ajaran_demo_id := (
  SELECT `tahun_ajaran_id`
  FROM `tahun_ajaran`
  WHERE `nama_tahun_ajaran` = '2026/2027'
  LIMIT 1
);

INSERT INTO `jurusan` (`kode_jurusan`, `nama_jurusan`, `ketua_jurusan`, `deskripsi_jurusan`, `status`) VALUES
('TKJ', 'Teknik Komputer dan Jaringan', NULL, 'Jurusan demo untuk presensi QR siswa.', 'aktif')
ON DUPLICATE KEY UPDATE
  `nama_jurusan` = VALUES(`nama_jurusan`),
  `deskripsi_jurusan` = VALUES(`deskripsi_jurusan`),
  `status` = 'aktif';

SET @jurusan_tkj_id := (
  SELECT `jurusan_id`
  FROM `jurusan`
  WHERE `kode_jurusan` = 'TKJ'
  LIMIT 1
);

INSERT INTO `rombel` (
  `tahun_ajaran_id`, `tingkatan`, `tingkat_angka`, `jurusan_id`, `nomor_rombel`,
  `is_nomor_rombel_inferred`, `label_rombel`, `label_rombel_raw`, `display_mode`,
  `is_inferred_from_import`, `status`
) VALUES
(@tahun_ajaran_demo_id, 'X', 10, @jurusan_tkj_id, 1, 0, 'X-TKJ-1', 'X-TKJ-1', 'dengan_nomor', 0, 'aktif'),
(@tahun_ajaran_demo_id, 'X', 10, @jurusan_tkj_id, 2, 0, 'X-TKJ-2', 'X-TKJ-2', 'dengan_nomor', 0, 'aktif')
ON DUPLICATE KEY UPDATE
  `tingkat_angka` = VALUES(`tingkat_angka`),
  `label_rombel` = VALUES(`label_rombel`),
  `label_rombel_raw` = VALUES(`label_rombel_raw`),
  `display_mode` = VALUES(`display_mode`),
  `status` = 'aktif';

SET @rombel_x_tkj_1_id := (
  SELECT `rombel_id`
  FROM `rombel`
  WHERE `tahun_ajaran_id` = @tahun_ajaran_demo_id
    AND `tingkatan` = 'X'
    AND `jurusan_id` = @jurusan_tkj_id
    AND `nomor_rombel` = 1
  LIMIT 1
);

SET @rombel_x_tkj_2_id := (
  SELECT `rombel_id`
  FROM `rombel`
  WHERE `tahun_ajaran_id` = @tahun_ajaran_demo_id
    AND `tingkatan` = 'X'
    AND `jurusan_id` = @jurusan_tkj_id
    AND `nomor_rombel` = 2
  LIMIT 1
);

-- Jam pembelajaran demo. Disediakan lagi agar aman jika seed schema awal dilewati.
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

-- ---------------------------------------------------------
-- 3. Data guru/staff demo
-- ---------------------------------------------------------
INSERT INTO `guru_staff` (`nip`, `nama_lengkap`, `no_telp`, `email`, `jenis_user`, `status`) VALUES
('SA001', 'Super Admin Demo', NULL, 'superadmin.demo@smksrajasa.sch.id', 'admin', 'aktif'),
('ADM001', 'Admin Demo', NULL, 'admin.demo@smksrajasa.sch.id', 'admin', 'aktif'),
('GURU001', 'Guru Demo', NULL, 'guru.demo@smksrajasa.sch.id', 'guru', 'aktif'),
('STAFF001', 'Staff Piket Demo', NULL, 'staff.demo@smksrajasa.sch.id', 'staff', 'aktif'),
('INT001', 'Intern Presensi Demo', NULL, 'intern.demo@smksrajasa.sch.id', 'intern', 'aktif')
ON DUPLICATE KEY UPDATE
  `nama_lengkap` = VALUES(`nama_lengkap`),
  `email` = VALUES(`email`),
  `jenis_user` = VALUES(`jenis_user`),
  `status` = 'aktif';

SET @superadmin_guru_id := (SELECT `guru_id` FROM `guru_staff` WHERE `nip` = 'SA001' LIMIT 1);
SET @admin_guru_id := (SELECT `guru_id` FROM `guru_staff` WHERE `nip` = 'ADM001' LIMIT 1);
SET @guru_demo_id := (SELECT `guru_id` FROM `guru_staff` WHERE `nip` = 'GURU001' LIMIT 1);
SET @staff_demo_id := (SELECT `guru_id` FROM `guru_staff` WHERE `nip` = 'STAFF001' LIMIT 1);
SET @intern_demo_id := (SELECT `guru_id` FROM `guru_staff` WHERE `nip` = 'INT001' LIMIT 1);

-- Guru demo dijadikan wali kelas X-TKJ-1 untuk uji notifikasi warning.
INSERT INTO `rombel_wali_kelas` (
  `rombel_id`, `guru_id`, `tahun_ajaran_id`, `semester`, `tanggal_mulai`, `tanggal_selesai`, `status`
) VALUES (
  @rombel_x_tkj_1_id, @guru_demo_id, @tahun_ajaran_demo_id, 'ganjil', '2026-07-01', NULL, 'aktif'
)
ON DUPLICATE KEY UPDATE
  `tanggal_mulai` = VALUES(`tanggal_mulai`),
  `tanggal_selesai` = VALUES(`tanggal_selesai`),
  `status` = 'aktif';

-- ---------------------------------------------------------
-- 4. Data siswa demo dan QR statis vendor
-- ---------------------------------------------------------
INSERT INTO `siswa` (
  `nisn`, `nis`, `nama_lengkap`, `jenis_kelamin`, `angkatan`,
  `jurusan_id_aktif`, `rombel_id_aktif`, `kelas_aktif`, `status`
) VALUES
('0099999999', '260001', 'Siswa Demo X TKJ 1', 'L', 2026, @jurusan_tkj_id, @rombel_x_tkj_1_id, 'X-TKJ-1', 'aktif'),
('0088888888', '260002', 'Siswa Warning Demo X TKJ 2', 'P', 2026, @jurusan_tkj_id, @rombel_x_tkj_2_id, 'X-TKJ-2', 'aktif')
ON DUPLICATE KEY UPDATE
  `nis` = VALUES(`nis`),
  `nama_lengkap` = VALUES(`nama_lengkap`),
  `jenis_kelamin` = VALUES(`jenis_kelamin`),
  `angkatan` = VALUES(`angkatan`),
  `jurusan_id_aktif` = VALUES(`jurusan_id_aktif`),
  `rombel_id_aktif` = VALUES(`rombel_id_aktif`),
  `kelas_aktif` = VALUES(`kelas_aktif`),
  `status` = 'aktif';

SET @siswa_demo_id := (SELECT `siswa_id` FROM `siswa` WHERE `nisn` = '0099999999' LIMIT 1);
SET @siswa_warning_id := (SELECT `siswa_id` FROM `siswa` WHERE `nisn` = '0088888888' LIMIT 1);

INSERT INTO `penempatan_siswa_rombel` (
  `siswa_id`, `rombel_id`, `tahun_ajaran_id`, `semester`, `tanggal_mulai`, `tanggal_selesai`, `is_aktif`
) VALUES
(@siswa_demo_id, @rombel_x_tkj_1_id, @tahun_ajaran_demo_id, 'ganjil', '2026-07-01', NULL, 1),
(@siswa_warning_id, @rombel_x_tkj_2_id, @tahun_ajaran_demo_id, 'ganjil', '2026-07-01', NULL, 1)
ON DUPLICATE KEY UPDATE
  `rombel_id` = VALUES(`rombel_id`),
  `tanggal_mulai` = VALUES(`tanggal_mulai`),
  `tanggal_selesai` = VALUES(`tanggal_selesai`),
  `is_aktif` = 1;

INSERT INTO `siswa_qr` (
  `siswa_id`, `payload_raw`, `payload_normalized`, `payload_nama`, `payload_nisn`
) VALUES
(
  @siswa_demo_id,
  'https://docs.google.com/forms/d/e/demo/viewform?entry.nama=Siswa%20Demo%20X%20TKJ%201&entry.nisn=0099999999',
  'https://docs.google.com/forms/d/e/demo/viewform?entry.nama=siswa%20demo%20x%20tkj%201&entry.nisn=0099999999',
  'Siswa Demo X TKJ 1',
  '0099999999'
),
(
  @siswa_warning_id,
  'https://docs.google.com/forms/d/e/demo/viewform?entry.nama=Siswa%20Warning%20Demo%20X%20TKJ%202&entry.nisn=0088888888',
  'https://docs.google.com/forms/d/e/demo/viewform?entry.nama=siswa%20warning%20demo%20x%20tkj%202&entry.nisn=0088888888',
  'Siswa Warning Demo X TKJ 2',
  '0088888888'
)
ON DUPLICATE KEY UPDATE
  `siswa_id` = VALUES(`siswa_id`),
  `payload_raw` = VALUES(`payload_raw`),
  `payload_normalized` = VALUES(`payload_normalized`),
  `payload_nama` = VALUES(`payload_nama`),
  `payload_nisn` = VALUES(`payload_nisn`);

-- ---------------------------------------------------------
-- 5. Akun user demo
-- ---------------------------------------------------------
INSERT INTO `users` (`username`, `password_hash`, `email`, `nama_tampilan`, `siswa_id`, `guru_id`, `status`) VALUES
('superadmin.demo', @demo_password_hash, 'superadmin.demo@smksrajasa.sch.id', 'Super Admin Demo', NULL, @superadmin_guru_id, 'aktif'),
('admin.demo', @demo_password_hash, 'admin.demo@smksrajasa.sch.id', 'Admin Demo', NULL, @admin_guru_id, 'aktif'),
('guru.demo', @demo_password_hash, 'guru.demo@smksrajasa.sch.id', 'Guru Demo', NULL, @guru_demo_id, 'aktif'),
('staff.demo', @demo_password_hash, 'staff.demo@smksrajasa.sch.id', 'Staff Piket Demo', NULL, @staff_demo_id, 'aktif'),
('intern.demo', @demo_password_hash, 'intern.demo@smksrajasa.sch.id', 'Intern Presensi Demo', NULL, @intern_demo_id, 'aktif'),
('siswa.demo', @demo_password_hash, 'siswa.demo@smksrajasa.sch.id', 'Siswa Demo X TKJ 1', @siswa_demo_id, NULL, 'aktif'),
('siswa.warning.demo', @demo_password_hash, 'siswa.warning.demo@smksrajasa.sch.id', 'Siswa Warning Demo X TKJ 2', @siswa_warning_id, NULL, 'aktif')
ON DUPLICATE KEY UPDATE
  `password_hash` = VALUES(`password_hash`),
  `email` = VALUES(`email`),
  `nama_tampilan` = VALUES(`nama_tampilan`),
  `siswa_id` = VALUES(`siswa_id`),
  `guru_id` = VALUES(`guru_id`),
  `status` = 'aktif';

-- ---------------------------------------------------------
-- 6. Hubungkan akun demo ke role
-- ---------------------------------------------------------
INSERT INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT u.`user_id`, r.`role_id`, 1
FROM `users` u
JOIN `roles` r
WHERE u.`username` = 'superadmin.demo'
  AND r.`role_slug` = 'super_admin'
ON DUPLICATE KEY UPDATE `is_active` = 1;

INSERT INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT u.`user_id`, r.`role_id`, 1
FROM `users` u
JOIN `roles` r
WHERE u.`username` = 'admin.demo'
  AND r.`role_slug` = 'admin'
ON DUPLICATE KEY UPDATE `is_active` = 1;

INSERT INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT u.`user_id`, r.`role_id`, 1
FROM `users` u
JOIN `roles` r
WHERE u.`username` = 'guru.demo'
  AND r.`role_slug` = 'guru'
ON DUPLICATE KEY UPDATE `is_active` = 1;

INSERT INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT u.`user_id`, r.`role_id`, 1
FROM `users` u
JOIN `roles` r
WHERE u.`username` = 'staff.demo'
  AND r.`role_slug` = 'staff'
ON DUPLICATE KEY UPDATE `is_active` = 1;

INSERT INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT u.`user_id`, r.`role_id`, 1
FROM `users` u
JOIN `roles` r
WHERE u.`username` = 'intern.demo'
  AND r.`role_slug` = 'intern_presensi'
ON DUPLICATE KEY UPDATE `is_active` = 1;

INSERT INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT u.`user_id`, r.`role_id`, 1
FROM `users` u
JOIN `roles` r
WHERE u.`username` = 'siswa.demo'
  AND r.`role_slug` = 'siswa'
ON DUPLICATE KEY UPDATE `is_active` = 1;

INSERT INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT u.`user_id`, r.`role_id`, 1
FROM `users` u
JOIN `roles` r
WHERE u.`username` = 'siswa.warning.demo'
  AND r.`role_slug` = 'siswa'
ON DUPLICATE KEY UPDATE `is_active` = 1;

COMMIT;

-- =========================================================
-- RINGKASAN AKUN DEMO
-- Password semua akun: Rajasa@123
--
-- superadmin.demo      -> role super_admin
-- admin.demo           -> role admin
-- guru.demo            -> role guru, wali kelas X-TKJ-1
-- staff.demo           -> role staff
-- intern.demo          -> role intern_presensi
-- siswa.demo           -> siswa X-TKJ-1
-- siswa.warning.demo   -> siswa X-TKJ-2 untuk uji warning beda rombel
--
-- Payload QR demo:
-- siswa.demo:
-- https://docs.google.com/forms/d/e/demo/viewform?entry.nama=Siswa%20Demo%20X%20TKJ%201&entry.nisn=0099999999
--
-- siswa.warning.demo:
-- https://docs.google.com/forms/d/e/demo/viewform?entry.nama=Siswa%20Warning%20Demo%20X%20TKJ%202&entry.nisn=0088888888
-- =========================================================
