-- =========================================================
-- SEED PERMISSION MVP - PRESENSI QR SISWA
-- Target DB: sistem_absensi_lab_qr
-- Scope: role + permission + role_permissions MVP.
-- Aman dijalankan berulang. Tidak memakai tabel akses lama.
-- Jalankan setelah file schema prototype-db-3.9.
-- =========================================================

USE `sistem_absensi_lab_qr`;

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET collation_connection = 'utf8mb4_unicode_ci';
SET FOREIGN_KEY_CHECKS = 1;

START TRANSACTION;

-- ---------------------------------------------------------
-- 1. Role dasar MVP
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
-- 2. Permission granular MVP
-- ---------------------------------------------------------
INSERT INTO `permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`) VALUES
  ('dashboard.read', 'dashboard', 'read', 'Melihat ringkasan dashboard.'),
  ('account.self.read', 'account', 'read', 'Melihat profil akun sendiri.'),
  ('account.self.update', 'account', 'update', 'Mengubah profil ringan akun sendiri.'),
  ('account.self.password.update', 'account', 'update', 'Mengubah password akun sendiri.'),
  ('users.read', 'users', 'read', 'Melihat daftar dan detail akun user.'),
  ('users.create', 'users', 'create', 'Membuat akun user.'),
  ('users.update', 'users', 'update', 'Mengubah akun user.'),
  ('users.delete', 'users', 'delete', 'Menonaktifkan atau menghapus akun user.'),
  ('users.manage', 'users', 'manage', 'Mengelola akun dan hak akses user.'),
  ('roles.read', 'roles', 'read', 'Melihat role.'),
  ('roles.create', 'roles', 'create', 'Membuat role.'),
  ('roles.update', 'roles', 'update', 'Mengubah role.'),
  ('roles.delete', 'roles', 'delete', 'Menonaktifkan atau menghapus role.'),
  ('roles.manage', 'roles', 'manage', 'Mengelola role dan relasi permission.'),
  ('permissions.read', 'permissions', 'read', 'Melihat permission.'),
  ('permissions.create', 'permissions', 'create', 'Membuat permission.'),
  ('permissions.update', 'permissions', 'update', 'Mengubah permission.'),
  ('permissions.delete', 'permissions', 'delete', 'Menonaktifkan atau menghapus permission.'),
  ('permissions.manage', 'permissions', 'manage', 'Mengelola permission sistem.'),
  ('academic.read', 'academic', 'read', 'Melihat data akademik umum.'),
  ('academic.manage', 'academic', 'manage', 'Mengelola data akademik umum.'),
  ('tahun_ajaran.read', 'tahun_ajaran', 'read', 'Melihat tahun ajaran.'),
  ('tahun_ajaran.create', 'tahun_ajaran', 'create', 'Membuat tahun ajaran.'),
  ('tahun_ajaran.update', 'tahun_ajaran', 'update', 'Mengubah tahun ajaran.'),
  ('tahun_ajaran.delete', 'tahun_ajaran', 'delete', 'Menonaktifkan atau menghapus tahun ajaran.'),
  ('tahun_ajaran.manage', 'tahun_ajaran', 'manage', 'Mengelola tahun ajaran aktif.'),
  ('jurusan.read', 'jurusan', 'read', 'Melihat jurusan.'),
  ('jurusan.create', 'jurusan', 'create', 'Membuat jurusan.'),
  ('jurusan.update', 'jurusan', 'update', 'Mengubah jurusan.'),
  ('jurusan.delete', 'jurusan', 'delete', 'Menonaktifkan atau menghapus jurusan.'),
  ('rombel.read', 'rombel', 'read', 'Melihat rombel.'),
  ('rombel.create', 'rombel', 'create', 'Membuat rombel.'),
  ('rombel.update', 'rombel', 'update', 'Mengubah rombel.'),
  ('rombel.delete', 'rombel', 'delete', 'Menonaktifkan atau menghapus rombel.'),
  ('student_placements.read', 'student_placements', 'read', 'Melihat penempatan siswa ke rombel.'),
  ('student_placements.create', 'student_placements', 'create', 'Membuat penempatan siswa ke rombel.'),
  ('student_placements.update', 'student_placements', 'update', 'Mengubah penempatan siswa ke rombel.'),
  ('student_placements.delete', 'student_placements', 'delete', 'Menonaktifkan atau menghapus penempatan siswa.'),
  ('student_placements.manage', 'student_placements', 'manage', 'Mengelola penempatan siswa aktif.'),
  ('wali_kelas.read', 'wali_kelas', 'read', 'Melihat wali kelas rombel.'),
  ('wali_kelas.create', 'wali_kelas', 'create', 'Membuat relasi wali kelas.'),
  ('wali_kelas.update', 'wali_kelas', 'update', 'Mengubah relasi wali kelas.'),
  ('wali_kelas.delete', 'wali_kelas', 'delete', 'Menonaktifkan atau menghapus relasi wali kelas.'),
  ('wali_kelas.manage', 'wali_kelas', 'manage', 'Mengelola wali kelas.'),
  ('guru_staff.read', 'guru_staff', 'read', 'Melihat data guru dan staff.'),
  ('guru_staff.create', 'guru_staff', 'create', 'Membuat data guru dan staff.'),
  ('guru_staff.update', 'guru_staff', 'update', 'Mengubah data guru dan staff.'),
  ('guru_staff.delete', 'guru_staff', 'delete', 'Menonaktifkan atau menghapus data guru dan staff.'),
  ('guru_staff.export', 'guru_staff', 'export', 'Mengekspor data guru dan staff.'),
  ('students.read', 'students', 'read', 'Melihat data siswa.'),
  ('students.create', 'students', 'create', 'Membuat data siswa.'),
  ('students.update', 'students', 'update', 'Mengubah data siswa.'),
  ('students.delete', 'students', 'delete', 'Menonaktifkan atau menghapus data siswa.'),
  ('students.export', 'students', 'export', 'Mengekspor data siswa.'),
  ('students.self.read', 'students', 'read', 'Siswa melihat profilnya sendiri.'),
  ('students.self.update', 'students', 'update', 'Siswa mengubah data profil ringan sendiri.'),
  ('student_profile.read', 'student_profile', 'read', 'Melihat profil tambahan siswa.'),
  ('student_profile.update', 'student_profile', 'update', 'Mengubah profil tambahan siswa.'),
  ('student_qr.read', 'student_qr', 'read', 'Melihat mapping QR siswa.'),
  ('student_qr.create', 'student_qr', 'create', 'Membuat mapping QR siswa.'),
  ('student_qr.update', 'student_qr', 'update', 'Mengubah mapping QR siswa.'),
  ('student_qr.delete', 'student_qr', 'delete', 'Menghapus mapping QR siswa.'),
  ('student_qr.validate', 'student_qr', 'validate', 'Memvalidasi payload QR siswa.'),
  ('student_qr.export', 'student_qr', 'export', 'Mengekspor mapping QR siswa.'),
  ('jam_pembelajaran.read', 'jam_pembelajaran', 'read', 'Melihat jam pembelajaran.'),
  ('jam_pembelajaran.create', 'jam_pembelajaran', 'create', 'Membuat jam pembelajaran.'),
  ('jam_pembelajaran.update', 'jam_pembelajaran', 'update', 'Mengubah jam pembelajaran.'),
  ('jam_pembelajaran.delete', 'jam_pembelajaran', 'delete', 'Menonaktifkan atau menghapus jam pembelajaran.'),
  ('jam_pembelajaran.manage', 'jam_pembelajaran', 'manage', 'Mengelola jam pembelajaran.'),
  ('attendance.read', 'attendance', 'read', 'Melihat data presensi.'),
  ('attendance.student.view', 'attendance', 'read', 'Siswa melihat hasil presensi milik sendiri.'),
  ('attendance.scan', 'attendance', 'scan', 'Melakukan scan QR presensi.'),
  ('attendance.scan.rombel', 'attendance', 'scan', 'Melakukan presensi mode rombel.'),
  ('attendance.scan.piket', 'attendance', 'scan', 'Melakukan presensi mode piket atau terlambat.'),
  ('attendance.session.read', 'attendance_session', 'read', 'Melihat sesi presensi.'),
  ('attendance.session.create', 'attendance_session', 'create', 'Membuat sesi presensi.'),
  ('attendance.session.update', 'attendance_session', 'update', 'Mengubah status sesi presensi.'),
  ('attendance.session.manage', 'attendance_session', 'manage', 'Mengelola sesi presensi.'),
  ('attendance.edit', 'attendance', 'edit', 'Mengubah data presensi.'),
  ('attendance.manual.edit', 'attendance', 'edit', 'Mengubah presensi secara manual setelah scan.'),
  ('attendance.warning.read', 'attendance_warning', 'read', 'Melihat log warning presensi.'),
  ('attendance.warning.review', 'attendance_warning', 'review', 'Meninjau warning presensi.'),
  ('attendance.warning.resolve', 'attendance_warning', 'validate', 'Menyelesaikan warning presensi.'),
  ('attendance.warning.manage', 'attendance_warning', 'manage', 'Mengelola warning presensi.'),
  ('attendance.log.read', 'attendance_log', 'read', 'Melihat log scan presensi.'),
  ('reports.read', 'reports', 'read', 'Melihat laporan umum.'),
  ('reports.export', 'reports', 'export', 'Mengekspor laporan umum.'),
  ('reports.attendance.read', 'reports', 'read', 'Melihat laporan presensi.'),
  ('reports.attendance.export', 'reports', 'export', 'Mengekspor laporan presensi.'),
  ('reports.warning.read', 'reports', 'read', 'Melihat laporan warning presensi.'),
  ('reports.warning.export', 'reports', 'export', 'Mengekspor laporan warning presensi.'),
  ('import.read', 'import', 'read', 'Melihat riwayat import data.'),
  ('import.create', 'import', 'create', 'Membuat proses import data.'),
  ('import.submit', 'import', 'submit', 'Mengunggah dan mengirim data import.'),
  ('import.review', 'import', 'review', 'Meninjau hasil import data.'),
  ('import.manage', 'import', 'manage', 'Mengelola import data.'),
  ('import.mapping.manage', 'import_mapping', 'manage', 'Mengelola fallback mapping kolom import.'),
  ('notifications.read', 'notifications', 'read', 'Melihat notifikasi.'),
  ('notifications.self.read', 'notifications', 'read', 'Melihat notifikasi milik sendiri.'),
  ('notifications.manage', 'notifications', 'manage', 'Mengelola notifikasi.'),
  ('user_activities.read', 'user_activities', 'read', 'Melihat aktivitas user.'),
  ('system_errors.read', 'system_errors', 'read', 'Melihat error sistem.'),
  ('system_errors.review', 'system_errors', 'review', 'Meninjau error sistem.'),
  ('konfigurasi.read', 'konfigurasi', 'read', 'Melihat konfigurasi sistem.'),
  ('konfigurasi.manage', 'konfigurasi', 'manage', 'Mengelola konfigurasi sistem.')
ON DUPLICATE KEY UPDATE
  `module_name` = VALUES(`module_name`),
  `action_name` = VALUES(`action_name`),
  `keterangan` = VALUES(`keterangan`);

-- ---------------------------------------------------------
-- 3. Role permission default MVP
-- ---------------------------------------------------------
-- Role: super_admin
INSERT INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT r.`role_id`, p.`perm_id`, 1, '*'
FROM `roles` r
JOIN `permissions` p
WHERE r.`role_slug` = 'super_admin'
  AND p.`perm_slug` IN (
    'dashboard.read', 'account.self.read', 'account.self.update', 'account.self.password.update', 'users.read',
    'users.create', 'users.update', 'users.delete', 'users.manage', 'roles.read',
    'roles.create', 'roles.update', 'roles.delete', 'roles.manage', 'permissions.read',
    'permissions.create', 'permissions.update', 'permissions.delete', 'permissions.manage', 'academic.read',
    'academic.manage', 'tahun_ajaran.read', 'tahun_ajaran.create', 'tahun_ajaran.update', 'tahun_ajaran.delete',
    'tahun_ajaran.manage', 'jurusan.read', 'jurusan.create', 'jurusan.update', 'jurusan.delete',
    'rombel.read', 'rombel.create', 'rombel.update', 'rombel.delete', 'student_placements.read',
    'student_placements.create', 'student_placements.update', 'student_placements.delete', 'student_placements.manage', 'wali_kelas.read',
    'wali_kelas.create', 'wali_kelas.update', 'wali_kelas.delete', 'wali_kelas.manage', 'guru_staff.read',
    'guru_staff.create', 'guru_staff.update', 'guru_staff.delete', 'guru_staff.export', 'students.read',
    'students.create', 'students.update', 'students.delete', 'students.export', 'students.self.read',
    'students.self.update', 'student_profile.read', 'student_profile.update', 'student_qr.read', 'student_qr.create',
    'student_qr.update', 'student_qr.delete', 'student_qr.validate', 'student_qr.export', 'jam_pembelajaran.read',
    'jam_pembelajaran.create', 'jam_pembelajaran.update', 'jam_pembelajaran.delete', 'jam_pembelajaran.manage', 'attendance.read',
    'attendance.student.view', 'attendance.scan', 'attendance.scan.rombel', 'attendance.scan.piket', 'attendance.session.read',
    'attendance.session.create', 'attendance.session.update', 'attendance.session.manage', 'attendance.edit', 'attendance.manual.edit',
    'attendance.warning.read', 'attendance.warning.review', 'attendance.warning.resolve', 'attendance.warning.manage', 'attendance.log.read',
    'reports.read', 'reports.export', 'reports.attendance.read', 'reports.attendance.export', 'reports.warning.read',
    'reports.warning.export', 'import.read', 'import.create', 'import.submit', 'import.review',
    'import.manage', 'import.mapping.manage', 'notifications.read', 'notifications.self.read', 'notifications.manage',
    'user_activities.read', 'system_errors.read', 'system_errors.review', 'konfigurasi.read', 'konfigurasi.manage'
  )
ON DUPLICATE KEY UPDATE
  `is_allowed` = VALUES(`is_allowed`);
-- Role: admin
INSERT INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT r.`role_id`, p.`perm_id`, 1, '*'
FROM `roles` r
JOIN `permissions` p
WHERE r.`role_slug` = 'admin'
  AND p.`perm_slug` IN (
    'dashboard.read', 'account.self.read', 'account.self.update', 'account.self.password.update', 'users.read',
    'users.create', 'users.update', 'users.delete', 'users.manage', 'roles.read',
    'roles.create', 'roles.update', 'roles.delete', 'roles.manage', 'permissions.read',
    'permissions.create', 'permissions.update', 'permissions.delete', 'permissions.manage', 'academic.read',
    'academic.manage', 'tahun_ajaran.read', 'tahun_ajaran.create', 'tahun_ajaran.update', 'tahun_ajaran.delete',
    'tahun_ajaran.manage', 'jurusan.read', 'jurusan.create', 'jurusan.update', 'jurusan.delete',
    'rombel.read', 'rombel.create', 'rombel.update', 'rombel.delete', 'student_placements.read',
    'student_placements.create', 'student_placements.update', 'student_placements.delete', 'student_placements.manage', 'wali_kelas.read',
    'wali_kelas.create', 'wali_kelas.update', 'wali_kelas.delete', 'wali_kelas.manage', 'guru_staff.read',
    'guru_staff.create', 'guru_staff.update', 'guru_staff.delete', 'guru_staff.export', 'students.read',
    'students.create', 'students.update', 'students.delete', 'students.export', 'students.self.read',
    'students.self.update', 'student_profile.read', 'student_profile.update', 'student_qr.read', 'student_qr.create',
    'student_qr.update', 'student_qr.delete', 'student_qr.validate', 'student_qr.export', 'jam_pembelajaran.read',
    'jam_pembelajaran.create', 'jam_pembelajaran.update', 'jam_pembelajaran.delete', 'jam_pembelajaran.manage', 'attendance.read',
    'attendance.student.view', 'attendance.scan', 'attendance.scan.rombel', 'attendance.scan.piket', 'attendance.session.read',
    'attendance.session.create', 'attendance.session.update', 'attendance.session.manage', 'attendance.edit', 'attendance.manual.edit',
    'attendance.warning.read', 'attendance.warning.review', 'attendance.warning.resolve', 'attendance.warning.manage', 'attendance.log.read',
    'reports.read', 'reports.export', 'reports.attendance.read', 'reports.attendance.export', 'reports.warning.read',
    'reports.warning.export', 'import.read', 'import.create', 'import.submit', 'import.review',
    'import.manage', 'import.mapping.manage', 'notifications.read', 'notifications.self.read', 'notifications.manage',
    'user_activities.read', 'system_errors.read', 'system_errors.review', 'konfigurasi.read', 'konfigurasi.manage'
  )
ON DUPLICATE KEY UPDATE
  `is_allowed` = VALUES(`is_allowed`);
-- Role: guru
INSERT INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT r.`role_id`, p.`perm_id`, 1, '*'
FROM `roles` r
JOIN `permissions` p
WHERE r.`role_slug` = 'guru'
  AND p.`perm_slug` IN (
    'dashboard.read', 'account.self.read', 'account.self.update', 'account.self.password.update', 'notifications.self.read',
    'academic.read', 'tahun_ajaran.read', 'jurusan.read', 'rombel.read', 'student_placements.read',
    'wali_kelas.read', 'students.read', 'student_profile.read', 'student_qr.read', 'student_qr.validate',
    'jam_pembelajaran.read', 'attendance.read', 'attendance.scan', 'attendance.scan.rombel', 'attendance.scan.piket',
    'attendance.session.read', 'attendance.session.create', 'attendance.session.update', 'attendance.edit', 'attendance.manual.edit',
    'attendance.warning.read', 'attendance.warning.review', 'attendance.warning.resolve', 'attendance.log.read', 'reports.read',
    'reports.attendance.read', 'reports.attendance.export', 'reports.warning.read', 'reports.warning.export', 'notifications.read'
  )
ON DUPLICATE KEY UPDATE
  `is_allowed` = VALUES(`is_allowed`);
-- Role: staff
INSERT INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT r.`role_id`, p.`perm_id`, 1, '*'
FROM `roles` r
JOIN `permissions` p
WHERE r.`role_slug` = 'staff'
  AND p.`perm_slug` IN (
    'dashboard.read', 'account.self.read', 'account.self.update', 'account.self.password.update', 'notifications.self.read',
    'academic.read', 'tahun_ajaran.read', 'jurusan.read', 'rombel.read', 'student_placements.read',
    'wali_kelas.read', 'students.read', 'student_profile.read', 'student_qr.read', 'student_qr.validate',
    'jam_pembelajaran.read', 'attendance.read', 'attendance.scan', 'attendance.scan.rombel', 'attendance.scan.piket',
    'attendance.session.read', 'attendance.session.create', 'attendance.session.update', 'attendance.edit', 'attendance.manual.edit',
    'attendance.warning.read', 'attendance.warning.review', 'attendance.warning.resolve', 'attendance.log.read', 'reports.read',
    'reports.attendance.read', 'reports.attendance.export', 'reports.warning.read', 'reports.warning.export', 'notifications.read'
  )
ON DUPLICATE KEY UPDATE
  `is_allowed` = VALUES(`is_allowed`);
-- Role: intern_presensi
INSERT INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT r.`role_id`, p.`perm_id`, 1, '*'
FROM `roles` r
JOIN `permissions` p
WHERE r.`role_slug` = 'intern_presensi'
  AND p.`perm_slug` IN (
    'dashboard.read', 'account.self.read', 'account.self.update', 'account.self.password.update', 'notifications.self.read',
    'academic.read', 'rombel.read', 'students.read', 'student_qr.read', 'student_qr.validate',
    'jam_pembelajaran.read', 'attendance.read', 'attendance.scan', 'attendance.scan.rombel', 'attendance.scan.piket',
    'attendance.session.read', 'attendance.session.create', 'attendance.session.update', 'attendance.warning.read', 'attendance.log.read'
  )
ON DUPLICATE KEY UPDATE
  `is_allowed` = VALUES(`is_allowed`);
-- Role: siswa
INSERT INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT r.`role_id`, p.`perm_id`, 1, '*'
FROM `roles` r
JOIN `permissions` p
WHERE r.`role_slug` = 'siswa'
  AND p.`perm_slug` IN (
    'account.self.read', 'account.self.update', 'account.self.password.update', 'students.self.read', 'students.self.update',
    'attendance.student.view', 'notifications.self.read'
  )
ON DUPLICATE KEY UPDATE
  `is_allowed` = VALUES(`is_allowed`);

COMMIT;

-- =========================================================
-- END SEED PERMISSION MVP - PRESENSI QR SISWA
-- =========================================================
