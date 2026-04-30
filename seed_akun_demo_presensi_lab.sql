-- =========================================================
-- SEED AKUN DEMO - Presensi Lab Rajasa
-- Target DB: sistem_absensi_lab_qr / prototype-db-3.5
-- Password semua akun: Rajasa@123
-- Hash: bcrypt/PHP password_hash, cocok untuk password_verify()
-- =========================================================

USE `sistem_absensi_lab_qr`;

SET @demo_password_hash := '$2y$12$qsBTAZEla6ytj21DsIFONuN4ZAEIDtr1OPUcVSHKioV1whJlIG4bC';

-- ---------------------------------------------------------
-- 1. Pastikan role dasar tersedia
-- ---------------------------------------------------------
INSERT INTO `roles` (`nama_role`, `role_slug`, `deskripsi`, `is_system`) VALUES
('Admin Akademik', 'admin_akademik', 'Kelola data akademik dan presensi', 1),
('Operator Lab', 'operator_lab', 'Mengelola perangkat, scan, dan ruangan lab', 1),
('Guru Pengawas', 'guru_pengawas', 'Memantau jadwal, presensi, dan ujian', 1),
('Siswa', 'siswa', 'Akses mandiri terbatas untuk profil dan riwayat presensi', 1)
ON DUPLICATE KEY UPDATE
  `deskripsi` = VALUES(`deskripsi`),
  `is_system` = VALUES(`is_system`);

-- ---------------------------------------------------------
-- 2. Data pendukung siswa demo: Jurusan + Rombel
-- ---------------------------------------------------------
INSERT INTO `jurusan` (`kode_jurusan`, `nama_jurusan`, `ketua_jurusan`, `deskripsi_jurusan`, `status`) VALUES
('TKJ', 'Teknik Komputer dan Jaringan', NULL, 'Jurusan demo untuk akun siswa', 'aktif')
ON DUPLICATE KEY UPDATE
  `nama_jurusan` = VALUES(`nama_jurusan`),
  `status` = 'aktif';

SET @jurusan_tkj_id := (
  SELECT `jurusan_id` FROM `jurusan` WHERE `kode_jurusan` = 'TKJ' LIMIT 1
);

INSERT INTO `rombel` (`tingkatan`, `jurusan_id`, `nomor_rombel`, `label_rombel`, `status`) VALUES
('X', @jurusan_tkj_id, 1, 'X-TKJ-1', 'aktif')
ON DUPLICATE KEY UPDATE
  `label_rombel` = VALUES(`label_rombel`),
  `status` = 'aktif';

SET @rombel_x_tkj_1_id := (
  SELECT `rombel_id`
  FROM `rombel`
  WHERE `tingkatan` = 'X'
    AND `jurusan_id` = @jurusan_tkj_id
    AND `nomor_rombel` = 1
  LIMIT 1
);

-- ---------------------------------------------------------
-- 3. Profil guru/staff untuk akun admin, operator, dan guru
-- ---------------------------------------------------------
INSERT INTO `guru_staff` (`nip`, `nama_lengkap`, `no_telp`, `email`, `jabatan`, `status`) VALUES
('ADM001', 'Admin Akademik Demo', NULL, 'admin.demo@smksrajasa.sch.id', 'Admin Akademik', 'aktif')
ON DUPLICATE KEY UPDATE
  `nama_lengkap` = VALUES(`nama_lengkap`),
  `email` = VALUES(`email`),
  `jabatan` = VALUES(`jabatan`),
  `status` = 'aktif';

INSERT INTO `guru_staff` (`nip`, `nama_lengkap`, `no_telp`, `email`, `jabatan`, `status`) VALUES
('OPLAB001', 'Operator Lab Demo', NULL, 'operator.demo@smksrajasa.sch.id', 'Operator Lab', 'aktif')
ON DUPLICATE KEY UPDATE
  `nama_lengkap` = VALUES(`nama_lengkap`),
  `email` = VALUES(`email`),
  `jabatan` = VALUES(`jabatan`),
  `status` = 'aktif';

INSERT INTO `guru_staff` (`nip`, `nama_lengkap`, `no_telp`, `email`, `jabatan`, `status`) VALUES
('GURU001', 'Guru Pengawas Demo', NULL, 'guru.demo@smksrajasa.sch.id', 'Guru Pengawas', 'aktif')
ON DUPLICATE KEY UPDATE
  `nama_lengkap` = VALUES(`nama_lengkap`),
  `email` = VALUES(`email`),
  `jabatan` = VALUES(`jabatan`),
  `status` = 'aktif';

SET @admin_guru_id := (SELECT `guru_id` FROM `guru_staff` WHERE `nip` = 'ADM001' LIMIT 1);
SET @operator_guru_id := (SELECT `guru_id` FROM `guru_staff` WHERE `nip` = 'OPLAB001' LIMIT 1);
SET @guru_pengawas_id := (SELECT `guru_id` FROM `guru_staff` WHERE `nip` = 'GURU001' LIMIT 1);

-- ---------------------------------------------------------
-- 4. Profil siswa demo
-- ---------------------------------------------------------
INSERT INTO `siswa` (
  `nisn`, `nis`, `nama_lengkap`, `jenis_kelamin`, `angkatan`,
  `jurusan_id_aktif`, `rombel_id_aktif`, `kelas_aktif`, `status`
) VALUES (
  '0099999999', '260001', 'Siswa Demo', 'L', 2026,
  @jurusan_tkj_id, @rombel_x_tkj_1_id, 'X-TKJ-1', 'aktif'
)
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

INSERT INTO `penempatan_siswa_rombel` (
  `siswa_id`, `rombel_id`, `tahun_ajaran`, `semester`, `no_absen`, `tanggal_mulai`, `is_aktif`
) VALUES (
  @siswa_demo_id, @rombel_x_tkj_1_id, '2026/2027', 'ganjil', 1, '2026-07-01', 1
)
ON DUPLICATE KEY UPDATE
  `no_absen` = VALUES(`no_absen`),
  `tanggal_mulai` = VALUES(`tanggal_mulai`),
  `is_aktif` = 1;

-- ---------------------------------------------------------
-- 5. Akun login
-- ---------------------------------------------------------
INSERT INTO `users` (`username`, `password_hash`, `user_type`, `siswa_id`, `guru_id`, `valid_until`, `status`) VALUES
('admin', @demo_password_hash, 'guru_staff', NULL, @admin_guru_id, NULL, 'aktif')
ON DUPLICATE KEY UPDATE
  `password_hash` = VALUES(`password_hash`),
  `user_type` = 'guru_staff',
  `siswa_id` = NULL,
  `guru_id` = @admin_guru_id,
  `valid_until` = NULL,
  `status` = 'aktif';

INSERT INTO `users` (`username`, `password_hash`, `user_type`, `siswa_id`, `guru_id`, `valid_until`, `status`) VALUES
('operator', @demo_password_hash, 'guru_staff', NULL, @operator_guru_id, NULL, 'aktif')
ON DUPLICATE KEY UPDATE
  `password_hash` = VALUES(`password_hash`),
  `user_type` = 'guru_staff',
  `siswa_id` = NULL,
  `guru_id` = @operator_guru_id,
  `valid_until` = NULL,
  `status` = 'aktif';

INSERT INTO `users` (`username`, `password_hash`, `user_type`, `siswa_id`, `guru_id`, `valid_until`, `status`) VALUES
('guru', @demo_password_hash, 'guru_staff', NULL, @guru_pengawas_id, NULL, 'aktif')
ON DUPLICATE KEY UPDATE
  `password_hash` = VALUES(`password_hash`),
  `user_type` = 'guru_staff',
  `siswa_id` = NULL,
  `guru_id` = @guru_pengawas_id,
  `valid_until` = NULL,
  `status` = 'aktif';

INSERT INTO `users` (`username`, `password_hash`, `user_type`, `siswa_id`, `guru_id`, `valid_until`, `status`) VALUES
('siswa', @demo_password_hash, 'siswa', @siswa_demo_id, NULL, NULL, 'aktif')
ON DUPLICATE KEY UPDATE
  `password_hash` = VALUES(`password_hash`),
  `user_type` = 'siswa',
  `siswa_id` = @siswa_demo_id,
  `guru_id` = NULL,
  `valid_until` = NULL,
  `status` = 'aktif';

SET @user_admin_id := (SELECT `user_id` FROM `users` WHERE `username` = 'admin' LIMIT 1);
SET @user_operator_id := (SELECT `user_id` FROM `users` WHERE `username` = 'operator' LIMIT 1);
SET @user_guru_id := (SELECT `user_id` FROM `users` WHERE `username` = 'guru' LIMIT 1);
SET @user_siswa_id := (SELECT `user_id` FROM `users` WHERE `username` = 'siswa' LIMIT 1);

-- ---------------------------------------------------------
-- 6. Assign role akun
-- ---------------------------------------------------------
INSERT IGNORE INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT @user_admin_id, `role_id`, 1 FROM `roles` WHERE `role_slug` = 'admin_akademik';

INSERT IGNORE INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT @user_operator_id, `role_id`, 1 FROM `roles` WHERE `role_slug` = 'operator_lab';

INSERT IGNORE INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT @user_guru_id, `role_id`, 1 FROM `roles` WHERE `role_slug` = 'guru_pengawas';

INSERT IGNORE INTO `user_roles` (`user_id`, `role_id`, `is_active`)
SELECT @user_siswa_id, `role_id`, 1 FROM `roles` WHERE `role_slug` = 'siswa';

-- ---------------------------------------------------------
-- 7. Opsional: refresh buffer tampilan manage user
-- Source of truth tetap users, user_roles, roles, siswa, guru_staff.
-- ---------------------------------------------------------
INSERT INTO `user_manage_buffer` (
  `user_id`, `username`, `nama_lengkap`, `nisn`, `role_summary`, `primary_role_slug`,
  `user_type`, `jurusan_id`, `kode_jurusan`, `nama_jurusan`, `status`, `valid_until`,
  `valid_until_class`, `last_login`, `online_status`, `last_activity`,
  `created_at_source`, `updated_at_source`, `synced_at`
)
SELECT
  v.user_id,
  v.username,
  v.nama_lengkap,
  v.nisn,
  v.role,
  v.primary_role_slug,
  v.tipe_user,
  v.jurusan_id,
  v.kode_jurusan,
  v.nama_jurusan,
  v.status,
  v.valid_until,
  v.valid_until_class,
  v.last_login,
  v.online_status,
  v.last_activity,
  v.created_at,
  v.updated_at,
  NOW()
FROM `v_manage_users` v
WHERE v.username IN ('admin', 'operator', 'guru', 'siswa')
ON DUPLICATE KEY UPDATE
  `username` = VALUES(`username`),
  `nama_lengkap` = VALUES(`nama_lengkap`),
  `nisn` = VALUES(`nisn`),
  `role_summary` = VALUES(`role_summary`),
  `primary_role_slug` = VALUES(`primary_role_slug`),
  `user_type` = VALUES(`user_type`),
  `jurusan_id` = VALUES(`jurusan_id`),
  `kode_jurusan` = VALUES(`kode_jurusan`),
  `nama_jurusan` = VALUES(`nama_jurusan`),
  `status` = VALUES(`status`),
  `valid_until` = VALUES(`valid_until`),
  `valid_until_class` = VALUES(`valid_until_class`),
  `last_login` = VALUES(`last_login`),
  `online_status` = VALUES(`online_status`),
  `last_activity` = VALUES(`last_activity`),
  `created_at_source` = VALUES(`created_at_source`),
  `updated_at_source` = VALUES(`updated_at_source`),
  `synced_at` = NOW();

-- ---------------------------------------------------------
-- 8. Cek hasil
-- ---------------------------------------------------------
SELECT
  v.username,
  'Rajasa@123' AS password_default,
  v.nama_lengkap,
  v.role,
  v.tipe_user,
  v.status
FROM `v_manage_users` v
WHERE v.username IN ('admin', 'operator', 'guru', 'siswa')
ORDER BY FIELD(v.username, 'admin', 'operator', 'guru', 'siswa');
