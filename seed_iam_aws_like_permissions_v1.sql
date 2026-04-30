-- =========================================================
-- SEED IAM AWS-LIKE TERPISAH - PRESENSI LAB RAJASA
-- Target DB: prototype-db-3.5 / sistem_absensi_lab_qr
-- Tujuan: permission granular + managed policy + role/group attachment + notification rights
-- Aman untuk dijalankan berulang: memakai ON DUPLICATE / DELETE scoped untuk policy seed.
-- =========================================================
USE `sistem_absensi_lab_qr`;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET collation_connection = 'utf8mb4_unicode_ci';
SET FOREIGN_KEY_CHECKS = 1;
START TRANSACTION;

-- 1) Permission granular
CREATE TEMPORARY TABLE `_seed_permissions` (`perm_slug` VARCHAR(100) COLLATE utf8mb4_unicode_ci PRIMARY KEY, `module_name` VARCHAR(50) COLLATE utf8mb4_unicode_ci, `action_name` ENUM('read','create','update','delete','write','scan','validate','assign_role','generate','revoke','export','manage','submit','review','archive') COLLATE utf8mb4_unicode_ci, `keterangan` TEXT COLLATE utf8mb4_unicode_ci) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `_seed_permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`) VALUES
  ('users.read' , 'users' , 'read' , 'Melihat daftar dan detail akun user.'),
  ('users.create' , 'users' , 'create' , 'Membuat akun user baru.'),
  ('users.update' , 'users' , 'update' , 'Mengubah data akun user.'),
  ('users.delete' , 'users' , 'delete' , 'Menghapus atau menonaktifkan akun user.'),
  ('roles.read' , 'roles' , 'read' , 'Melihat daftar dan detail role.'),
  ('roles.create' , 'roles' , 'create' , 'Membuat role baru.'),
  ('roles.update' , 'roles' , 'update' , 'Mengubah data role.'),
  ('roles.delete' , 'roles' , 'delete' , 'Menghapus atau menonaktifkan role.'),
  ('permissions.read' , 'permissions' , 'read' , 'Melihat daftar dan detail permission.'),
  ('permissions.create' , 'permissions' , 'create' , 'Membuat permission baru.'),
  ('permissions.update' , 'permissions' , 'update' , 'Mengubah data permission.'),
  ('permissions.delete' , 'permissions' , 'delete' , 'Menghapus atau menonaktifkan permission.'),
  ('policies.read' , 'policies' , 'read' , 'Melihat daftar dan detail policy.'),
  ('policies.create' , 'policies' , 'create' , 'Membuat policy baru.'),
  ('policies.update' , 'policies' , 'update' , 'Mengubah data policy.'),
  ('policies.delete' , 'policies' , 'delete' , 'Menghapus atau menonaktifkan policy.'),
  ('groups.read' , 'groups' , 'read' , 'Melihat daftar dan detail group.'),
  ('groups.create' , 'groups' , 'create' , 'Membuat group baru.'),
  ('groups.update' , 'groups' , 'update' , 'Mengubah data group.'),
  ('groups.delete' , 'groups' , 'delete' , 'Menghapus atau menonaktifkan group.'),
  ('users.assign_role' , 'users' , 'assign_role' , 'Menetapkan/mencabut role pada user.'),
  ('users.assign_policy' , 'users' , 'assign_role' , 'Menetapkan/mencabut policy langsung pada user.'),
  ('users.reset_password' , 'users' , 'update' , 'Reset password user.'),
  ('users.block' , 'users' , 'update' , 'Memblokir/membuka blokir akun user.'),
  ('users.self.read' , 'users' , 'read' , 'Melihat profil akun sendiri.'),
  ('users.self.update' , 'users' , 'update' , 'Mengubah profil ringan akun sendiri.'),
  ('users.self.password.update' , 'users' , 'update' , 'Mengubah password akun sendiri.'),
  ('roles.assign_policy' , 'roles' , 'assign_role' , 'Menetapkan/mencabut policy pada role.'),
  ('groups.assign_role' , 'groups' , 'assign_role' , 'Menetapkan/mencabut role pada group.'),
  ('groups.assign_policy' , 'groups' , 'assign_role' , 'Menetapkan/mencabut policy pada group.'),
  ('groups.manage_member' , 'groups' , 'manage' , 'Menambah/mengeluarkan anggota group.'),
  ('sessions.read' , 'sessions' , 'read' , 'Melihat sesi login aktif.'),
  ('sessions.revoke' , 'sessions' , 'revoke' , 'Mencabut sesi login user.'),
  ('access_tokens.read' , 'access_tokens' , 'read' , 'Melihat token akses sementara.'),
  ('access_tokens.generate' , 'access_tokens' , 'generate' , 'Membuat token akses sementara.'),
  ('access_tokens.revoke' , 'access_tokens' , 'revoke' , 'Mencabut token akses sementara.'),
  ('departments.read' , 'departments' , 'read' , 'Melihat data jurusan.'),
  ('departments.create' , 'departments' , 'create' , 'Membuat data jurusan.'),
  ('departments.update' , 'departments' , 'update' , 'Mengubah data jurusan.'),
  ('departments.delete' , 'departments' , 'delete' , 'Menghapus/menonaktifkan data jurusan.'),
  ('class_groups.read' , 'class_groups' , 'read' , 'Melihat data rombel.'),
  ('class_groups.create' , 'class_groups' , 'create' , 'Membuat data rombel.'),
  ('class_groups.update' , 'class_groups' , 'update' , 'Mengubah data rombel.'),
  ('class_groups.delete' , 'class_groups' , 'delete' , 'Menghapus/menonaktifkan data rombel.'),
  ('student_placements.read' , 'student_placements' , 'read' , 'Melihat data penempatan siswa ke rombel.'),
  ('student_placements.create' , 'student_placements' , 'create' , 'Membuat data penempatan siswa ke rombel.'),
  ('student_placements.update' , 'student_placements' , 'update' , 'Mengubah data penempatan siswa ke rombel.'),
  ('student_placements.delete' , 'student_placements' , 'delete' , 'Menghapus/menonaktifkan data penempatan siswa ke rombel.'),
  ('homerooms.read' , 'homerooms' , 'read' , 'Melihat data wali kelas.'),
  ('homerooms.create' , 'homerooms' , 'create' , 'Membuat data wali kelas.');
INSERT INTO `_seed_permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`) VALUES
  ('homerooms.update' , 'homerooms' , 'update' , 'Mengubah data wali kelas.'),
  ('homerooms.delete' , 'homerooms' , 'delete' , 'Menghapus/menonaktifkan data wali kelas.'),
  ('subjects.read' , 'subjects' , 'read' , 'Melihat data mata pelajaran.'),
  ('subjects.create' , 'subjects' , 'create' , 'Membuat data mata pelajaran.'),
  ('subjects.update' , 'subjects' , 'update' , 'Mengubah data mata pelajaran.'),
  ('subjects.delete' , 'subjects' , 'delete' , 'Menghapus/menonaktifkan data mata pelajaran.'),
  ('calendar.read' , 'calendar' , 'read' , 'Melihat data kalender akademik.'),
  ('calendar.create' , 'calendar' , 'create' , 'Membuat data kalender akademik.'),
  ('calendar.update' , 'calendar' , 'update' , 'Mengubah data kalender akademik.'),
  ('calendar.delete' , 'calendar' , 'delete' , 'Menghapus/menonaktifkan data kalender akademik.'),
  ('lab_schedules.read' , 'lab_schedules' , 'read' , 'Melihat data jadwal lab.'),
  ('lab_schedules.create' , 'lab_schedules' , 'create' , 'Membuat data jadwal lab.'),
  ('lab_schedules.update' , 'lab_schedules' , 'update' , 'Mengubah data jadwal lab.'),
  ('lab_schedules.delete' , 'lab_schedules' , 'delete' , 'Menghapus/menonaktifkan data jadwal lab.'),
  ('room_plotting.read' , 'room_plotting' , 'read' , 'Melihat data plotting rombel-ruangan.'),
  ('room_plotting.create' , 'room_plotting' , 'create' , 'Membuat data plotting rombel-ruangan.'),
  ('room_plotting.update' , 'room_plotting' , 'update' , 'Mengubah data plotting rombel-ruangan.'),
  ('room_plotting.delete' , 'room_plotting' , 'delete' , 'Menghapus/menonaktifkan data plotting rombel-ruangan.'),
  ('academic.period.read' , 'academic' , 'read' , 'Melihat tahun ajaran dan semester aktif.'),
  ('academic.period.update' , 'academic' , 'update' , 'Mengubah tahun ajaran dan semester aktif.'),
  ('academic.dashboard.read' , 'academic' , 'read' , 'Melihat ringkasan dashboard akademik.'),
  ('students.read' , 'students' , 'read' , 'Melihat data siswa.'),
  ('students.create' , 'students' , 'create' , 'Membuat data siswa.'),
  ('students.update' , 'students' , 'update' , 'Mengubah data siswa.'),
  ('students.delete' , 'students' , 'delete' , 'Menghapus/menonaktifkan data siswa.'),
  ('student_profiles.read' , 'student_profiles' , 'read' , 'Melihat data profil siswa.'),
  ('student_profiles.create' , 'student_profiles' , 'create' , 'Membuat data profil siswa.'),
  ('student_profiles.update' , 'student_profiles' , 'update' , 'Mengubah data profil siswa.'),
  ('student_profiles.delete' , 'student_profiles' , 'delete' , 'Menghapus/menonaktifkan data profil siswa.'),
  ('student_mutations.read' , 'student_mutations' , 'read' , 'Melihat data mutasi siswa.'),
  ('student_mutations.create' , 'student_mutations' , 'create' , 'Membuat data mutasi siswa.'),
  ('student_mutations.update' , 'student_mutations' , 'update' , 'Mengubah data mutasi siswa.'),
  ('student_mutations.delete' , 'student_mutations' , 'delete' , 'Menghapus/menonaktifkan data mutasi siswa.'),
  ('staff.read' , 'staff' , 'read' , 'Melihat data guru/staff.'),
  ('staff.create' , 'staff' , 'create' , 'Membuat data guru/staff.'),
  ('staff.update' , 'staff' , 'update' , 'Mengubah data guru/staff.'),
  ('staff.delete' , 'staff' , 'delete' , 'Menghapus/menonaktifkan data guru/staff.'),
  ('students.self.read' , 'students' , 'read' , 'Siswa melihat data dirinya sendiri.'),
  ('student_profiles.self.update' , 'student_profiles' , 'update' , 'Siswa memperbarui data kontak ringan miliknya sendiri.'),
  ('students.export' , 'students' , 'export' , 'Ekspor data siswa.'),
  ('staff.export' , 'staff' , 'export' , 'Ekspor data guru/staff.'),
  ('room_types.read' , 'room_types' , 'read' , 'Melihat data jenis ruangan.'),
  ('room_types.create' , 'room_types' , 'create' , 'Membuat data jenis ruangan.'),
  ('room_types.update' , 'room_types' , 'update' , 'Mengubah data jenis ruangan.'),
  ('room_types.delete' , 'room_types' , 'delete' , 'Menghapus/menonaktifkan data jenis ruangan.'),
  ('rooms.read' , 'rooms' , 'read' , 'Melihat data ruangan.'),
  ('rooms.create' , 'rooms' , 'create' , 'Membuat data ruangan.'),
  ('rooms.update' , 'rooms' , 'update' , 'Mengubah data ruangan.'),
  ('rooms.delete' , 'rooms' , 'delete' , 'Menghapus/menonaktifkan data ruangan.'),
  ('devices.read' , 'devices' , 'read' , 'Melihat data perangkat ESP32.');
INSERT INTO `_seed_permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`) VALUES
  ('devices.create' , 'devices' , 'create' , 'Membuat data perangkat ESP32.'),
  ('devices.update' , 'devices' , 'update' , 'Mengubah data perangkat ESP32.'),
  ('devices.delete' , 'devices' , 'delete' , 'Menghapus/menonaktifkan data perangkat ESP32.'),
  ('room_devices.read' , 'room_devices' , 'read' , 'Melihat data relasi ruangan-perangkat.'),
  ('room_devices.create' , 'room_devices' , 'create' , 'Membuat data relasi ruangan-perangkat.'),
  ('room_devices.update' , 'room_devices' , 'update' , 'Mengubah data relasi ruangan-perangkat.'),
  ('room_devices.delete' , 'room_devices' , 'delete' , 'Menghapus/menonaktifkan data relasi ruangan-perangkat.'),
  ('devices.pair' , 'devices' , 'manage' , 'Melakukan pairing perangkat dengan ruangan.'),
  ('devices.revoke' , 'devices' , 'revoke' , 'Mencabut/mematikan perangkat dari sistem.'),
  ('devices.health.read' , 'devices' , 'read' , 'Melihat status koneksi dan heartbeat perangkat.'),
  ('qr_tokens.read' , 'qr_tokens' , 'read' , 'Melihat token QR presensi.'),
  ('qr_tokens.generate' , 'qr_tokens' , 'generate' , 'Membuat/mereset token QR.'),
  ('qr_tokens.revoke' , 'qr_tokens' , 'revoke' , 'Menonaktifkan token QR.'),
  ('qr_scan_logs.read' , 'qr_scan_logs' , 'read' , 'Melihat log scan QR.'),
  ('attendance.scan' , 'attendance' , 'scan' , 'Melakukan scan presensi.'),
  ('attendance.read' , 'attendance' , 'read' , 'Melihat semua data presensi sesuai scope.'),
  ('attendance.self.read' , 'attendance' , 'read' , 'Siswa melihat presensi miliknya sendiri.'),
  ('attendance.create' , 'attendance' , 'create' , 'Membuat catatan presensi manual.'),
  ('attendance.update' , 'attendance' , 'update' , 'Mengubah catatan presensi.'),
  ('attendance.delete' , 'attendance' , 'delete' , 'Menghapus catatan presensi.'),
  ('attendance.validate' , 'attendance' , 'validate' , 'Memvalidasi catatan presensi.'),
  ('attendance.export' , 'attendance' , 'export' , 'Ekspor laporan presensi.'),
  ('attendance_online.read' , 'attendance_online' , 'read' , 'Melihat pengajuan presensi online.'),
  ('attendance_online.self.submit' , 'attendance_online' , 'submit' , 'Siswa membuat pengajuan presensi online miliknya sendiri.'),
  ('attendance_online.self.read' , 'attendance_online' , 'read' , 'Siswa melihat pengajuan presensi online miliknya sendiri.'),
  ('attendance_online.review' , 'attendance_online' , 'review' , 'Meninjau dan memutuskan pengajuan presensi online.'),
  ('attendance_online.update' , 'attendance_online' , 'update' , 'Mengubah status/catatan pengajuan presensi online.'),
  ('attendance_online.delete' , 'attendance_online' , 'delete' , 'Menghapus pengajuan presensi online.'),
  ('exam_sessions.read' , 'exam_sessions' , 'read' , 'Melihat data sesi ujian.'),
  ('exam_sessions.create' , 'exam_sessions' , 'create' , 'Membuat data sesi ujian.'),
  ('exam_sessions.update' , 'exam_sessions' , 'update' , 'Mengubah data sesi ujian.'),
  ('exam_sessions.delete' , 'exam_sessions' , 'delete' , 'Menghapus data sesi ujian.'),
  ('exam_participants.read' , 'exam_participants' , 'read' , 'Melihat data peserta ujian.'),
  ('exam_participants.create' , 'exam_participants' , 'create' , 'Membuat data peserta ujian.'),
  ('exam_participants.update' , 'exam_participants' , 'update' , 'Mengubah data peserta ujian.'),
  ('exam_participants.delete' , 'exam_participants' , 'delete' , 'Menghapus data peserta ujian.'),
  ('grades.read' , 'grades' , 'read' , 'Melihat data nilai akademik.'),
  ('grades.create' , 'grades' , 'create' , 'Membuat data nilai akademik.'),
  ('grades.update' , 'grades' , 'update' , 'Mengubah data nilai akademik.'),
  ('grades.delete' , 'grades' , 'delete' , 'Menghapus data nilai akademik.'),
  ('grades.self.read' , 'grades' , 'read' , 'Siswa melihat nilai miliknya sendiri.'),
  ('grades.export' , 'grades' , 'export' , 'Ekspor data nilai akademik.'),
  ('imports.read' , 'imports' , 'read' , 'Melihat daftar dan detail job import.'),
  ('imports.create' , 'imports' , 'create' , 'Membuat job import baru.'),
  ('imports.submit' , 'imports' , 'submit' , 'Menjalankan proses import.'),
  ('imports.review' , 'imports' , 'review' , 'Meninjau hasil import dan error row.'),
  ('imports.rollback' , 'imports' , 'revoke' , 'Rollback/membatalkan hasil import jika tersedia.'),
  ('import_mappings.read' , 'import_mappings' , 'read' , 'Melihat mapping kolom import.'),
  ('import_mappings.write' , 'import_mappings' , 'write' , 'Membuat/mengubah mapping kolom import.'),
  ('import_logs.read' , 'import_logs' , 'read' , 'Melihat log row import.');
INSERT INTO `_seed_permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`) VALUES
  ('reports.read' , 'reports' , 'read' , 'Melihat rekap dan laporan.'),
  ('reports.export' , 'reports' , 'export' , 'Mengunduh/mengekspor laporan.'),
  ('reports.template.manage' , 'reports' , 'manage' , 'Mengelola template laporan.'),
  ('media.read' , 'media' , 'read' , 'Melihat metadata berkas.'),
  ('media.create' , 'media' , 'create' , 'Mengunggah metadata/berkas baru.'),
  ('media.update' , 'media' , 'update' , 'Mengubah metadata berkas.'),
  ('media.delete' , 'media' , 'delete' , 'Menghapus metadata/berkas.'),
  ('archives.read' , 'archives' , 'read' , 'Melihat batch dan detail arsip.'),
  ('archives.archive' , 'archives' , 'archive' , 'Menjalankan proses arsip data.'),
  ('archives.restore' , 'archives' , 'archive' , 'Restore data dari arsip.'),
  ('settings.read' , 'settings' , 'read' , 'Melihat konfigurasi sistem.'),
  ('settings.update' , 'settings' , 'update' , 'Mengubah konfigurasi sistem.'),
  ('audit.read' , 'audit' , 'read' , 'Melihat audit log aktivitas user.'),
  ('audit.export' , 'audit' , 'export' , 'Ekspor audit log.'),
  ('audit.archive' , 'audit' , 'archive' , 'Mengarsipkan audit log.'),
  ('ai_jobs.read' , 'ai_jobs' , 'read' , 'Melihat job AI recognition.'),
  ('ai_jobs.manage' , 'ai_jobs' , 'manage' , 'Mengelola antrian dan hasil AI recognition.'),
  ('buffers.read' , 'buffers' , 'read' , 'Melihat cache/buffer tampilan.'),
  ('buffers.refresh' , 'buffers' , 'manage' , 'Menyegarkan ulang cache/buffer tampilan.'),
  ('notifications.inbox.read' , 'notifications' , 'read' , 'Melihat inbox notifikasi milik sendiri.'),
  ('notifications.inbox.update' , 'notifications' , 'update' , 'Menandai notifikasi sendiri sebagai dibaca/belum dibaca.'),
  ('notifications.inbox.delete' , 'notifications' , 'delete' , 'Menghapus notifikasi dari inbox sendiri.'),
  ('notifications.read' , 'notifications' , 'read' , 'Melihat semua notifikasi sesuai scope.'),
  ('notifications.create' , 'notifications' , 'create' , 'Membuat notifikasi manual/sistem.'),
  ('notifications.update' , 'notifications' , 'update' , 'Mengubah status/resolusi notifikasi.'),
  ('notifications.delete' , 'notifications' , 'delete' , 'Menghapus notifikasi.'),
  ('notifications.resolve' , 'notifications' , 'update' , 'Menandai notifikasi sebagai resolved.'),
  ('notifications.dispatch' , 'notifications' , 'manage' , 'Mengirim atau menjadwalkan distribusi notifikasi.'),
  ('notifications.recipients.read' , 'notifications' , 'read' , 'Melihat daftar penerima notifikasi.'),
  ('notifications.recipients.manage' , 'notifications' , 'manage' , 'Mengelola penerima dan channel notifikasi.'),
  ('notification_rules.read' , 'notification_rules' , 'read' , 'Melihat rule notifikasi.'),
  ('notification_rules.create' , 'notification_rules' , 'create' , 'Membuat rule notifikasi.'),
  ('notification_rules.update' , 'notification_rules' , 'update' , 'Mengubah rule notifikasi.'),
  ('notification_rules.delete' , 'notification_rules' , 'delete' , 'Menghapus rule notifikasi.'),
  ('notification_preferences.read' , 'notification_preferences' , 'read' , 'Melihat preferensi notifikasi.'),
  ('notification_preferences.self.update' , 'notification_preferences' , 'update' , 'Mengubah preferensi notifikasi milik sendiri.'),
  ('notification_preferences.manage' , 'notification_preferences' , 'manage' , 'Mengelola preferensi notifikasi user lain.'),
  ('notification_channels.manage' , 'notification_channels' , 'manage' , 'Mengelola channel notifikasi email/WA/in-app/system.'),
  ('notification_critical.manage' , 'notification_critical' , 'manage' , 'Mengelola notifikasi critical locked.'),
  ('academic.read' , 'academic' , 'read' , 'Alias kompatibilitas: melihat data akademik.'),
  ('academic.write' , 'academic' , 'write' , 'Alias kompatibilitas: mengelola data akademik.'),
  ('students.write' , 'students' , 'write' , 'Alias kompatibilitas: mengelola data siswa.'),
  ('rooms.write' , 'rooms' , 'write' , 'Alias kompatibilitas: mengelola ruangan.'),
  ('devices.write' , 'devices' , 'write' , 'Alias kompatibilitas: mengelola perangkat.'),
  ('attendance.write' , 'attendance' , 'write' , 'Alias kompatibilitas: mengelola presensi.'),
  ('attendance.online_submit' , 'attendance' , 'submit' , 'Alias kompatibilitas: mengirim presensi online.'),
  ('attendance.online_review' , 'attendance' , 'review' , 'Alias kompatibilitas: review presensi online.'),
  ('qr.read' , 'qr' , 'read' , 'Alias kompatibilitas: melihat QR.'),
  ('qr.generate' , 'qr' , 'generate' , 'Alias kompatibilitas: membuat QR.'),
  ('qr.revoke' , 'qr' , 'revoke' , 'Alias kompatibilitas: revoke QR.');
INSERT INTO `_seed_permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`) VALUES
  ('exams.read' , 'exams' , 'read' , 'Alias kompatibilitas: melihat ujian.'),
  ('exams.write' , 'exams' , 'write' , 'Alias kompatibilitas: mengelola ujian.'),
  ('notifications.write' , 'notifications' , 'write' , 'Alias kompatibilitas: menulis notifikasi.'),
  ('archive.read' , 'archive' , 'read' , 'Alias kompatibilitas: melihat arsip.'),
  ('archive.archive' , 'archive' , 'archive' , 'Alias kompatibilitas: arsip/restore.'),
  ('ai.manage' , 'ai' , 'manage' , 'Alias kompatibilitas: mengelola AI.'),
  ('session.manage' , 'session' , 'manage' , 'Alias kompatibilitas: mengelola session.'),
  ('import.read' , 'import' , 'read' , 'Alias kompatibilitas: melihat import.'),
  ('import.write' , 'import' , 'write' , 'Alias kompatibilitas: menjalankan import.'),
  ('grades.write' , 'grades' , 'write' , 'Alias kompatibilitas: mengelola nilai.'),
  ('student_portal.read' , 'student_portal' , 'read' , 'Alias kompatibilitas: akses portal siswa.'),
  ('student_attendance.read' , 'student_attendance' , 'read' , 'Alias kompatibilitas: presensi siswa.'),
  ('student_grade.read' , 'student_grade' , 'read' , 'Alias kompatibilitas: nilai siswa.');
INSERT INTO `permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`)
SELECT `perm_slug`, `module_name`, `action_name`, `keterangan` FROM `_seed_permissions`
ON DUPLICATE KEY UPDATE
  `module_name` = VALUES(`module_name`),
  `action_name` = VALUES(`action_name`),
  `keterangan` = VALUES(`keterangan`);

-- 2) Managed policies granular
CREATE TEMPORARY TABLE `_seed_policies` (`policy_name` VARCHAR(100) COLLATE utf8mb4_unicode_ci, `policy_slug` VARCHAR(100) COLLATE utf8mb4_unicode_ci PRIMARY KEY, `policy_type` ENUM('managed','inline') COLLATE utf8mb4_unicode_ci, `deskripsi` TEXT COLLATE utf8mb4_unicode_ci, `is_system` TINYINT(1)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `_seed_policies` (`policy_name`, `policy_slug`, `policy_type`, `deskripsi`, `is_system`) VALUES
  ('FullAccess' , 'full_access' , 'managed' , 'Akses penuh ke seluruh permission dan resource.' , 1),
  ('IamReadOnlyAccess' , 'iam_read_only_access' , 'managed' , 'Melihat konfigurasi IAM tanpa perubahan.' , 1),
  ('IamUserAdminAccess' , 'iam_user_admin_access' , 'managed' , 'Mengelola user, reset password, blokir akun, dan assignment user.' , 1),
  ('IamRolePolicyAdminAccess' , 'iam_role_policy_admin_access' , 'managed' , 'Mengelola role, permission, policy, dan group IAM.' , 1),
  ('SessionAdminAccess' , 'session_admin_access' , 'managed' , 'Melihat dan mencabut sesi/token akses.' , 1),
  ('SelfAccountAccess' , 'self_account_access' , 'managed' , 'Akses user untuk akun dan preferensinya sendiri.' , 1),
  ('StudentReadAccess' , 'student_read_access' , 'managed' , 'Melihat data siswa dan profil siswa.' , 1),
  ('StudentWriteAccess' , 'student_write_access' , 'managed' , 'Mengelola data siswa, profil, mutasi, dan penempatan.' , 1),
  ('StaffReadAccess' , 'staff_read_access' , 'managed' , 'Melihat data guru/staff.' , 1),
  ('StaffWriteAccess' , 'staff_write_access' , 'managed' , 'Mengelola data guru/staff.' , 1),
  ('AcademicReadAccess' , 'academic_read_access' , 'managed' , 'Melihat master akademik, jadwal, plotting, kalender, dan dashboard.' , 1),
  ('AcademicWriteAccess' , 'academic_write_access' , 'managed' , 'Mengelola master akademik, jadwal, plotting, kalender, dan periode aktif.' , 1),
  ('LabReadAccess' , 'lab_read_access' , 'managed' , 'Melihat ruangan, jenis ruangan, perangkat, dan relasi ruangan-perangkat.' , 1),
  ('LabWriteAccess' , 'lab_write_access' , 'managed' , 'Mengelola ruangan, perangkat, pairing, dan relasi ruangan-perangkat.' , 1),
  ('QrReadAccess' , 'qr_read_access' , 'managed' , 'Melihat token QR dan log scan QR.' , 1),
  ('QrManageAccess' , 'qr_manage_access' , 'managed' , 'Generate dan revoke token QR.' , 1),
  ('AttendanceScanAccess' , 'attendance_scan_access' , 'managed' , 'Melakukan scan presensi.' , 1),
  ('AttendanceReadAccess' , 'attendance_read_access' , 'managed' , 'Melihat data presensi dan pengajuan online.' , 1),
  ('AttendanceWriteAccess' , 'attendance_write_access' , 'managed' , 'Membuat/mengubah/menghapus catatan presensi.' , 1),
  ('AttendanceValidateAccess' , 'attendance_validate_access' , 'managed' , 'Validasi presensi dan review presensi online.' , 1),
  ('StudentAttendanceSelfService' , 'student_attendance_self_service' , 'managed' , 'Akses siswa untuk presensi dan pengajuan online milik sendiri.' , 1),
  ('ExamReadAccess' , 'exam_read_access' , 'managed' , 'Melihat sesi dan peserta ujian.' , 1),
  ('ExamWriteAccess' , 'exam_write_access' , 'managed' , 'Mengelola sesi dan peserta ujian.' , 1),
  ('GradeReadAccess' , 'grade_read_access' , 'managed' , 'Melihat data nilai akademik.' , 1),
  ('GradeWriteAccess' , 'grade_write_access' , 'managed' , 'Mengelola data nilai akademik.' , 1),
  ('StudentGradeSelfService' , 'student_grade_self_service' , 'managed' , 'Siswa melihat nilai miliknya sendiri.' , 1),
  ('ImportReadAccess' , 'import_read_access' , 'managed' , 'Melihat job import, mapping, dan log import.' , 1),
  ('ImportExecuteAccess' , 'import_execute_access' , 'managed' , 'Membuat, menjalankan, review, rollback import, dan mengelola mapping.' , 1),
  ('ReportReadAccess' , 'report_read_access' , 'managed' , 'Melihat rekap/laporan.' , 1),
  ('ReportExportAccess' , 'report_export_access' , 'managed' , 'Ekspor laporan dan template laporan.' , 1),
  ('MediaReadAccess' , 'media_read_access' , 'managed' , 'Melihat metadata berkas.' , 1),
  ('MediaWriteAccess' , 'media_write_access' , 'managed' , 'Mengunggah, mengubah, dan menghapus media.' , 1),
  ('ArchiveReadAccess' , 'archive_read_access' , 'managed' , 'Melihat arsip.' , 1),
  ('ArchiveManageAccess' , 'archive_manage_access' , 'managed' , 'Menjalankan arsip dan restore.' , 1),
  ('NotificationInboxAccess' , 'notification_inbox_access' , 'managed' , 'Akses inbox notifikasi milik sendiri.' , 1),
  ('NotificationReadAccess' , 'notification_read_access' , 'managed' , 'Melihat notifikasi dan penerima sesuai scope.' , 1),
  ('NotificationWriteAccess' , 'notification_write_access' , 'managed' , 'Membuat, update, resolve, dan dispatch notifikasi.' , 1),
  ('NotificationRuleAdminAccess' , 'notification_rule_admin_access' , 'managed' , 'Mengelola rule notifikasi.' , 1),
  ('NotificationPreferenceSelfAccess' , 'notification_pref_self_access' , 'managed' , 'Mengubah preferensi notifikasi milik sendiri.' , 1),
  ('NotificationPreferenceAdminAccess' , 'notification_pref_admin_access' , 'managed' , 'Mengelola preferensi dan channel notifikasi user lain.' , 1),
  ('AuditReadAccess' , 'audit_read_access' , 'managed' , 'Melihat dan ekspor audit log.' , 1),
  ('AuditArchiveAccess' , 'audit_archive_access' , 'managed' , 'Mengarsipkan audit log.' , 1),
  ('SettingsReadAccess' , 'settings_read_access' , 'managed' , 'Melihat konfigurasi sistem.' , 1),
  ('SettingsWriteAccess' , 'settings_write_access' , 'managed' , 'Mengubah konfigurasi sistem.' , 1),
  ('AiJobReadAccess' , 'ai_job_read_access' , 'managed' , 'Melihat job AI recognition.' , 1),
  ('AiJobManageAccess' , 'ai_job_manage_access' , 'managed' , 'Mengelola job AI recognition.' , 1),
  ('BufferReadAccess' , 'buffer_read_access' , 'managed' , 'Melihat buffer/cache tampilan.' , 1),
  ('BufferRefreshAccess' , 'buffer_refresh_access' , 'managed' , 'Refresh buffer/cache tampilan.' , 1),
  ('InternReadOnly' , 'intern_read_only' , 'managed' , 'Akses baca terbatas untuk intern/tamu.' , 1),
  ('DangerousActionDenyForNonSuper' , 'dangerous_action_deny_non_super' , 'managed' , 'Explicit deny untuk aksi berisiko tinggi pada role non-super-admin.' , 1);
INSERT INTO `_seed_policies` (`policy_name`, `policy_slug`, `policy_type`, `deskripsi`, `is_system`) VALUES
  ('AcademicAdminAccess' , 'academic_admin_access' , 'managed' , 'Bundle kompatibilitas lama; tidak dipakai sebagai role-policy utama.' , 1),
  ('TeacherSupervisorAccess' , 'teacher_supervisor_access' , 'managed' , 'Bundle kompatibilitas lama; tidak dipakai sebagai role-policy utama.' , 1),
  ('LabOperatorAccess' , 'lab_operator_access' , 'managed' , 'Bundle kompatibilitas lama; tidak dipakai sebagai role-policy utama.' , 1),
  ('StudentSelfService' , 'student_self_service' , 'managed' , 'Bundle kompatibilitas lama; tidak dipakai sebagai role-policy utama.' , 1);
INSERT INTO `policies` (`policy_name`, `policy_slug`, `policy_type`, `deskripsi`, `is_system`)
SELECT `policy_name`, `policy_slug`, `policy_type`, `deskripsi`, `is_system` FROM `_seed_policies`
ON DUPLICATE KEY UPDATE
  `policy_name` = VALUES(`policy_name`),
  `policy_type` = VALUES(`policy_type`),
  `deskripsi` = VALUES(`deskripsi`),
  `is_system` = VALUES(`is_system`);

-- 3) Policy -> permission rules
CREATE TEMPORARY TABLE `_seed_policy_permissions` (`policy_slug` VARCHAR(100) COLLATE utf8mb4_unicode_ci, `perm_slug` VARCHAR(100) COLLATE utf8mb4_unicode_ci, `effect` ENUM('allow','deny') COLLATE utf8mb4_unicode_ci, `resource_scope` VARCHAR(150) COLLATE utf8mb4_unicode_ci, `conditions_json` JSON NULL, `priority` SMALLINT UNSIGNED) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `_seed_policy_permissions` (`policy_slug`, `perm_slug`, `effect`, `resource_scope`, `conditions_json`, `priority`) VALUES
  ('iam_read_only_access', 'users.read', 'allow', '*', NULL, 10),
  ('iam_read_only_access', 'roles.read', 'allow', '*', NULL, 10),
  ('iam_read_only_access', 'permissions.read', 'allow', '*', NULL, 10),
  ('iam_read_only_access', 'policies.read', 'allow', '*', NULL, 10),
  ('iam_read_only_access', 'groups.read', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'users.read', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'users.create', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'users.update', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'users.delete', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'users.assign_role', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'users.assign_policy', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'users.reset_password', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'users.block', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'roles.read', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'policies.read', 'allow', '*', NULL, 10),
  ('iam_user_admin_access', 'groups.read', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'roles.read', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'roles.create', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'roles.update', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'roles.delete', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'roles.assign_policy', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'permissions.read', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'permissions.create', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'permissions.update', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'permissions.delete', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'policies.read', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'policies.create', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'policies.update', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'policies.delete', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'groups.read', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'groups.create', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'groups.update', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'groups.delete', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'groups.assign_role', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'groups.assign_policy', 'allow', '*', NULL, 10),
  ('iam_role_policy_admin_access', 'groups.manage_member', 'allow', '*', NULL, 10),
  ('session_admin_access', 'sessions.read', 'allow', '*', NULL, 10),
  ('session_admin_access', 'sessions.revoke', 'allow', '*', NULL, 10),
  ('session_admin_access', 'access_tokens.read', 'allow', '*', NULL, 10),
  ('session_admin_access', 'access_tokens.generate', 'allow', '*', NULL, 10),
  ('session_admin_access', 'access_tokens.revoke', 'allow', '*', NULL, 10),
  ('session_admin_access', 'session.manage', 'allow', '*', NULL, 10),
  ('self_account_access', 'users.self.read', 'allow', 'self/*', NULL, 50),
  ('self_account_access', 'users.self.update', 'allow', 'self/*', NULL, 50),
  ('self_account_access', 'users.self.password.update', 'allow', 'self/*', NULL, 50),
  ('self_account_access', 'notification_preferences.read', 'allow', 'self/*', NULL, 50),
  ('self_account_access', 'notification_preferences.self.update', 'allow', 'self/*', NULL, 50),
  ('student_read_access', 'students.read', 'allow', '*', NULL, 20),
  ('student_read_access', 'student_profiles.read', 'allow', '*', NULL, 20),
  ('student_read_access', 'student_mutations.read', 'allow', '*', NULL, 20);
INSERT INTO `_seed_policy_permissions` (`policy_slug`, `perm_slug`, `effect`, `resource_scope`, `conditions_json`, `priority`) VALUES
  ('student_read_access', 'student_placements.read', 'allow', '*', NULL, 20),
  ('student_read_access', 'students.export', 'allow', '*', NULL, 20),
  ('student_write_access', 'students.read', 'allow', '*', NULL, 20),
  ('student_write_access', 'students.create', 'allow', '*', NULL, 20),
  ('student_write_access', 'students.update', 'allow', '*', NULL, 20),
  ('student_write_access', 'students.delete', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_profiles.read', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_profiles.create', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_profiles.update', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_profiles.delete', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_mutations.read', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_mutations.create', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_mutations.update', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_mutations.delete', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_placements.read', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_placements.create', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_placements.update', 'allow', '*', NULL, 20),
  ('student_write_access', 'student_placements.delete', 'allow', '*', NULL, 20),
  ('student_write_access', 'students.write', 'allow', '*', NULL, 20),
  ('staff_read_access', 'staff.read', 'allow', '*', NULL, 20),
  ('staff_read_access', 'staff.export', 'allow', '*', NULL, 20),
  ('staff_write_access', 'staff.read', 'allow', '*', NULL, 20),
  ('staff_write_access', 'staff.create', 'allow', '*', NULL, 20),
  ('staff_write_access', 'staff.update', 'allow', '*', NULL, 20),
  ('staff_write_access', 'staff.delete', 'allow', '*', NULL, 20),
  ('academic_read_access', 'departments.read', 'allow', '*', NULL, 20),
  ('academic_read_access', 'class_groups.read', 'allow', '*', NULL, 20),
  ('academic_read_access', 'homerooms.read', 'allow', '*', NULL, 20),
  ('academic_read_access', 'subjects.read', 'allow', '*', NULL, 20),
  ('academic_read_access', 'calendar.read', 'allow', '*', NULL, 20),
  ('academic_read_access', 'lab_schedules.read', 'allow', '*', NULL, 20),
  ('academic_read_access', 'room_plotting.read', 'allow', '*', NULL, 20),
  ('academic_read_access', 'academic.period.read', 'allow', '*', NULL, 20),
  ('academic_read_access', 'academic.dashboard.read', 'allow', '*', NULL, 20),
  ('academic_read_access', 'academic.read', 'allow', '*', NULL, 20),
  ('academic_write_access', 'departments.read', 'allow', '*', NULL, 20),
  ('academic_write_access', 'departments.create', 'allow', '*', NULL, 20),
  ('academic_write_access', 'departments.update', 'allow', '*', NULL, 20),
  ('academic_write_access', 'departments.delete', 'allow', '*', NULL, 20),
  ('academic_write_access', 'class_groups.read', 'allow', '*', NULL, 20),
  ('academic_write_access', 'class_groups.create', 'allow', '*', NULL, 20),
  ('academic_write_access', 'class_groups.update', 'allow', '*', NULL, 20),
  ('academic_write_access', 'class_groups.delete', 'allow', '*', NULL, 20),
  ('academic_write_access', 'homerooms.read', 'allow', '*', NULL, 20),
  ('academic_write_access', 'homerooms.create', 'allow', '*', NULL, 20),
  ('academic_write_access', 'homerooms.update', 'allow', '*', NULL, 20),
  ('academic_write_access', 'homerooms.delete', 'allow', '*', NULL, 20),
  ('academic_write_access', 'subjects.read', 'allow', '*', NULL, 20),
  ('academic_write_access', 'subjects.create', 'allow', '*', NULL, 20),
  ('academic_write_access', 'subjects.update', 'allow', '*', NULL, 20);
INSERT INTO `_seed_policy_permissions` (`policy_slug`, `perm_slug`, `effect`, `resource_scope`, `conditions_json`, `priority`) VALUES
  ('academic_write_access', 'subjects.delete', 'allow', '*', NULL, 20),
  ('academic_write_access', 'calendar.read', 'allow', '*', NULL, 20),
  ('academic_write_access', 'calendar.create', 'allow', '*', NULL, 20),
  ('academic_write_access', 'calendar.update', 'allow', '*', NULL, 20),
  ('academic_write_access', 'calendar.delete', 'allow', '*', NULL, 20),
  ('academic_write_access', 'lab_schedules.read', 'allow', '*', NULL, 20),
  ('academic_write_access', 'lab_schedules.create', 'allow', '*', NULL, 20),
  ('academic_write_access', 'lab_schedules.update', 'allow', '*', NULL, 20),
  ('academic_write_access', 'lab_schedules.delete', 'allow', '*', NULL, 20),
  ('academic_write_access', 'room_plotting.read', 'allow', '*', NULL, 20),
  ('academic_write_access', 'room_plotting.create', 'allow', '*', NULL, 20),
  ('academic_write_access', 'room_plotting.update', 'allow', '*', NULL, 20),
  ('academic_write_access', 'room_plotting.delete', 'allow', '*', NULL, 20),
  ('academic_write_access', 'academic.period.read', 'allow', '*', NULL, 20),
  ('academic_write_access', 'academic.period.update', 'allow', '*', NULL, 20),
  ('academic_write_access', 'academic.write', 'allow', '*', NULL, 20),
  ('lab_read_access', 'room_types.read', 'allow', '*', NULL, 20),
  ('lab_read_access', 'rooms.read', 'allow', '*', NULL, 20),
  ('lab_read_access', 'devices.read', 'allow', '*', NULL, 20),
  ('lab_read_access', 'room_devices.read', 'allow', '*', NULL, 20),
  ('lab_read_access', 'devices.health.read', 'allow', '*', NULL, 20),
  ('lab_write_access', 'room_types.read', 'allow', '*', NULL, 20),
  ('lab_write_access', 'room_types.create', 'allow', '*', NULL, 20),
  ('lab_write_access', 'room_types.update', 'allow', '*', NULL, 20),
  ('lab_write_access', 'room_types.delete', 'allow', '*', NULL, 20),
  ('lab_write_access', 'rooms.read', 'allow', '*', NULL, 20),
  ('lab_write_access', 'rooms.create', 'allow', '*', NULL, 20),
  ('lab_write_access', 'rooms.update', 'allow', '*', NULL, 20),
  ('lab_write_access', 'rooms.delete', 'allow', '*', NULL, 20),
  ('lab_write_access', 'devices.read', 'allow', '*', NULL, 20),
  ('lab_write_access', 'devices.create', 'allow', '*', NULL, 20),
  ('lab_write_access', 'devices.update', 'allow', '*', NULL, 20),
  ('lab_write_access', 'devices.delete', 'allow', '*', NULL, 20),
  ('lab_write_access', 'devices.pair', 'allow', '*', NULL, 20),
  ('lab_write_access', 'devices.revoke', 'allow', '*', NULL, 20),
  ('lab_write_access', 'devices.health.read', 'allow', '*', NULL, 20),
  ('lab_write_access', 'room_devices.read', 'allow', '*', NULL, 20),
  ('lab_write_access', 'room_devices.create', 'allow', '*', NULL, 20),
  ('lab_write_access', 'room_devices.update', 'allow', '*', NULL, 20),
  ('lab_write_access', 'room_devices.delete', 'allow', '*', NULL, 20),
  ('lab_write_access', 'rooms.write', 'allow', '*', NULL, 20),
  ('lab_write_access', 'devices.write', 'allow', '*', NULL, 20),
  ('qr_read_access', 'qr_tokens.read', 'allow', '*', NULL, 20),
  ('qr_read_access', 'qr_scan_logs.read', 'allow', '*', NULL, 20),
  ('qr_read_access', 'qr.read', 'allow', '*', NULL, 20),
  ('qr_manage_access', 'qr_tokens.read', 'allow', '*', NULL, 20),
  ('qr_manage_access', 'qr_tokens.generate', 'allow', '*', NULL, 20),
  ('qr_manage_access', 'qr_tokens.revoke', 'allow', '*', NULL, 20),
  ('qr_manage_access', 'qr_scan_logs.read', 'allow', '*', NULL, 20),
  ('qr_manage_access', 'qr.generate', 'allow', '*', NULL, 20);
INSERT INTO `_seed_policy_permissions` (`policy_slug`, `perm_slug`, `effect`, `resource_scope`, `conditions_json`, `priority`) VALUES
  ('qr_manage_access', 'qr.revoke', 'allow', '*', NULL, 20),
  ('attendance_scan_access', 'attendance.scan', 'allow', '*', NULL, 20),
  ('attendance_scan_access', 'qr_tokens.read', 'allow', '*', NULL, 20),
  ('attendance_scan_access', 'qr_scan_logs.read', 'allow', '*', NULL, 20),
  ('attendance_read_access', 'attendance.read', 'allow', '*', NULL, 20),
  ('attendance_read_access', 'attendance_online.read', 'allow', '*', NULL, 20),
  ('attendance_read_access', 'attendance.export', 'allow', '*', NULL, 20),
  ('attendance_write_access', 'attendance.read', 'allow', '*', NULL, 20),
  ('attendance_write_access', 'attendance.create', 'allow', '*', NULL, 20),
  ('attendance_write_access', 'attendance.update', 'allow', '*', NULL, 20),
  ('attendance_write_access', 'attendance.delete', 'allow', '*', NULL, 20),
  ('attendance_write_access', 'attendance.write', 'allow', '*', NULL, 20),
  ('attendance_validate_access', 'attendance.read', 'allow', '*', NULL, 20),
  ('attendance_validate_access', 'attendance.validate', 'allow', '*', NULL, 20),
  ('attendance_validate_access', 'attendance_online.read', 'allow', '*', NULL, 20),
  ('attendance_validate_access', 'attendance_online.review', 'allow', '*', NULL, 20),
  ('attendance_validate_access', 'attendance_online.update', 'allow', '*', NULL, 20),
  ('attendance_validate_access', 'attendance.online_review', 'allow', '*', NULL, 20),
  ('student_attendance_self_service', 'attendance.self.read', 'allow', 'self/*', NULL, 50),
  ('student_attendance_self_service', 'attendance_online.self.read', 'allow', 'self/*', NULL, 50),
  ('student_attendance_self_service', 'attendance_online.self.submit', 'allow', 'self/*', NULL, 50),
  ('student_attendance_self_service', 'attendance.online_submit', 'allow', 'self/*', NULL, 50),
  ('student_attendance_self_service', 'student_attendance.read', 'allow', 'self/*', NULL, 50),
  ('exam_read_access', 'exam_sessions.read', 'allow', '*', NULL, 20),
  ('exam_read_access', 'exam_participants.read', 'allow', '*', NULL, 20),
  ('exam_read_access', 'exams.read', 'allow', '*', NULL, 20),
  ('exam_write_access', 'exam_sessions.read', 'allow', '*', NULL, 20),
  ('exam_write_access', 'exam_sessions.create', 'allow', '*', NULL, 20),
  ('exam_write_access', 'exam_sessions.update', 'allow', '*', NULL, 20),
  ('exam_write_access', 'exam_sessions.delete', 'allow', '*', NULL, 20),
  ('exam_write_access', 'exam_participants.read', 'allow', '*', NULL, 20),
  ('exam_write_access', 'exam_participants.create', 'allow', '*', NULL, 20),
  ('exam_write_access', 'exam_participants.update', 'allow', '*', NULL, 20),
  ('exam_write_access', 'exam_participants.delete', 'allow', '*', NULL, 20),
  ('exam_write_access', 'exams.write', 'allow', '*', NULL, 20),
  ('grade_read_access', 'grades.read', 'allow', '*', NULL, 20),
  ('grade_read_access', 'grades.export', 'allow', '*', NULL, 20),
  ('grade_write_access', 'grades.read', 'allow', '*', NULL, 20),
  ('grade_write_access', 'grades.create', 'allow', '*', NULL, 20),
  ('grade_write_access', 'grades.update', 'allow', '*', NULL, 20),
  ('grade_write_access', 'grades.delete', 'allow', '*', NULL, 20),
  ('grade_write_access', 'grades.write', 'allow', '*', NULL, 20),
  ('grade_write_access', 'grades.export', 'allow', '*', NULL, 20),
  ('student_grade_self_service', 'grades.self.read', 'allow', 'self/*', NULL, 50),
  ('student_grade_self_service', 'student_grade.read', 'allow', 'self/*', NULL, 50),
  ('import_read_access', 'imports.read', 'allow', '*', NULL, 20),
  ('import_read_access', 'imports.review', 'allow', '*', NULL, 20),
  ('import_read_access', 'import_mappings.read', 'allow', '*', NULL, 20),
  ('import_read_access', 'import_logs.read', 'allow', '*', NULL, 20),
  ('import_read_access', 'import.read', 'allow', '*', NULL, 20);
INSERT INTO `_seed_policy_permissions` (`policy_slug`, `perm_slug`, `effect`, `resource_scope`, `conditions_json`, `priority`) VALUES
  ('import_execute_access', 'imports.read', 'allow', '*', NULL, 20),
  ('import_execute_access', 'imports.create', 'allow', '*', NULL, 20),
  ('import_execute_access', 'imports.submit', 'allow', '*', NULL, 20),
  ('import_execute_access', 'imports.review', 'allow', '*', NULL, 20),
  ('import_execute_access', 'imports.rollback', 'allow', '*', NULL, 20),
  ('import_execute_access', 'import_mappings.read', 'allow', '*', NULL, 20),
  ('import_execute_access', 'import_mappings.write', 'allow', '*', NULL, 20),
  ('import_execute_access', 'import_logs.read', 'allow', '*', NULL, 20),
  ('import_execute_access', 'import.write', 'allow', '*', NULL, 20),
  ('report_read_access', 'reports.read', 'allow', '*', NULL, 20),
  ('report_export_access', 'reports.read', 'allow', '*', NULL, 20),
  ('report_export_access', 'reports.export', 'allow', '*', NULL, 20),
  ('report_export_access', 'reports.template.manage', 'allow', '*', NULL, 20),
  ('media_read_access', 'media.read', 'allow', '*', NULL, 20),
  ('media_write_access', 'media.read', 'allow', '*', NULL, 20),
  ('media_write_access', 'media.create', 'allow', '*', NULL, 20),
  ('media_write_access', 'media.update', 'allow', '*', NULL, 20),
  ('media_write_access', 'media.delete', 'allow', '*', NULL, 20),
  ('media_write_access', 'media.write', 'allow', '*', NULL, 20),
  ('archive_read_access', 'archives.read', 'allow', '*', NULL, 20),
  ('archive_read_access', 'archive.read', 'allow', '*', NULL, 20),
  ('archive_manage_access', 'archives.read', 'allow', '*', NULL, 20),
  ('archive_manage_access', 'archives.archive', 'allow', '*', NULL, 20),
  ('archive_manage_access', 'archives.restore', 'allow', '*', NULL, 20),
  ('archive_manage_access', 'archive.archive', 'allow', '*', NULL, 20),
  ('notification_inbox_access', 'notifications.inbox.read', 'allow', 'self/*', NULL, 50),
  ('notification_inbox_access', 'notifications.inbox.update', 'allow', 'self/*', NULL, 50),
  ('notification_inbox_access', 'notifications.inbox.delete', 'allow', 'self/*', NULL, 50),
  ('notification_inbox_access', 'notification_preferences.read', 'allow', 'self/*', NULL, 50),
  ('notification_inbox_access', 'notification_preferences.self.update', 'allow', 'self/*', NULL, 50),
  ('notification_inbox_access', 'notifications.read', 'allow', 'self/*', NULL, 50),
  ('notification_read_access', 'notifications.read', 'allow', '*', NULL, 20),
  ('notification_read_access', 'notifications.recipients.read', 'allow', '*', NULL, 20),
  ('notification_read_access', 'notification_rules.read', 'allow', '*', NULL, 20),
  ('notification_write_access', 'notifications.read', 'allow', '*', NULL, 20),
  ('notification_write_access', 'notifications.create', 'allow', '*', NULL, 20),
  ('notification_write_access', 'notifications.update', 'allow', '*', NULL, 20),
  ('notification_write_access', 'notifications.delete', 'allow', '*', NULL, 20),
  ('notification_write_access', 'notifications.resolve', 'allow', '*', NULL, 20),
  ('notification_write_access', 'notifications.dispatch', 'allow', '*', NULL, 20),
  ('notification_write_access', 'notifications.recipients.read', 'allow', '*', NULL, 20),
  ('notification_write_access', 'notifications.recipients.manage', 'allow', '*', NULL, 20),
  ('notification_write_access', 'notifications.write', 'allow', '*', NULL, 20),
  ('notification_rule_admin_access', 'notification_rules.read', 'allow', '*', NULL, 20),
  ('notification_rule_admin_access', 'notification_rules.create', 'allow', '*', NULL, 20),
  ('notification_rule_admin_access', 'notification_rules.update', 'allow', '*', NULL, 20),
  ('notification_rule_admin_access', 'notification_rules.delete', 'allow', '*', NULL, 20),
  ('notification_pref_self_access', 'notification_preferences.read', 'allow', 'self/*', NULL, 50),
  ('notification_pref_self_access', 'notification_preferences.self.update', 'allow', 'self/*', NULL, 50),
  ('notification_pref_admin_access', 'notification_preferences.read', 'allow', '*', NULL, 20);
INSERT INTO `_seed_policy_permissions` (`policy_slug`, `perm_slug`, `effect`, `resource_scope`, `conditions_json`, `priority`) VALUES
  ('notification_pref_admin_access', 'notification_preferences.manage', 'allow', '*', NULL, 20),
  ('notification_pref_admin_access', 'notification_channels.manage', 'allow', '*', NULL, 20),
  ('notification_pref_admin_access', 'notification_critical.manage', 'allow', '*', NULL, 20),
  ('audit_read_access', 'audit.read', 'allow', '*', NULL, 20),
  ('audit_read_access', 'audit.export', 'allow', '*', NULL, 20),
  ('audit_archive_access', 'audit.read', 'allow', '*', NULL, 20),
  ('audit_archive_access', 'audit.archive', 'allow', '*', NULL, 20),
  ('settings_read_access', 'settings.read', 'allow', '*', NULL, 20),
  ('settings_write_access', 'settings.read', 'allow', '*', NULL, 20),
  ('settings_write_access', 'settings.update', 'allow', '*', NULL, 20),
  ('settings_write_access', 'settings.write', 'allow', '*', NULL, 20),
  ('ai_job_read_access', 'ai_jobs.read', 'allow', '*', NULL, 20),
  ('ai_job_manage_access', 'ai_jobs.read', 'allow', '*', NULL, 20),
  ('ai_job_manage_access', 'ai_jobs.manage', 'allow', '*', NULL, 20),
  ('ai_job_manage_access', 'ai.manage', 'allow', '*', NULL, 20),
  ('buffer_read_access', 'buffers.read', 'allow', '*', NULL, 20),
  ('buffer_refresh_access', 'buffers.read', 'allow', '*', NULL, 20),
  ('buffer_refresh_access', 'buffers.refresh', 'allow', '*', NULL, 20),
  ('intern_read_only', 'users.self.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'students.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'student_profiles.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'staff.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'departments.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'class_groups.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'homerooms.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'subjects.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'calendar.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'lab_schedules.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'room_plotting.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'rooms.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'room_types.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'devices.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'attendance.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'attendance_online.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'reports.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'media.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'archives.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'notification_rules.read', 'allow', '*', NULL, 60),
  ('intern_read_only', 'notifications.inbox.read', 'allow', '*', NULL, 60),
  ('dangerous_action_deny_non_super', 'permissions.create', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'permissions.update', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'permissions.delete', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'policies.create', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'policies.update', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'policies.delete', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'roles.delete', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'users.delete', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'settings.update', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'settings.write', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'archives.restore', 'deny', '*', NULL, 1);
INSERT INTO `_seed_policy_permissions` (`policy_slug`, `perm_slug`, `effect`, `resource_scope`, `conditions_json`, `priority`) VALUES
  ('dangerous_action_deny_non_super', 'audit.archive', 'deny', '*', NULL, 1),
  ('dangerous_action_deny_non_super', 'notification_critical.manage', 'deny', '*', NULL, 1);

-- Reset scoped hanya untuk policy yang dikelola seed ini agar mapping lama yang terlalu lebar tidak ikut aktif.
DELETE pp FROM `policy_permissions` pp
JOIN `policies` p ON p.policy_id = pp.policy_id
JOIN `_seed_policies` sp ON sp.policy_slug = p.policy_slug;

-- FullAccess selalu memperoleh seluruh permission yang ada pada DB.
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `conditions_json`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', NULL, 1
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'full_access';

-- Policy granular selain FullAccess.
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `conditions_json`, `priority`)
SELECT p.policy_id, pm.perm_id, spp.effect, spp.resource_scope, spp.conditions_json, spp.priority
FROM `_seed_policy_permissions` spp
JOIN `policies` p ON p.policy_slug = spp.policy_slug
JOIN `permissions` pm ON pm.perm_slug = spp.perm_slug;

-- 4) Attach policy ke role sistem secara terpisah/atomic
CREATE TEMPORARY TABLE `_seed_role_policies` (`role_slug` VARCHAR(50) COLLATE utf8mb4_unicode_ci, `policy_slug` VARCHAR(100) COLLATE utf8mb4_unicode_ci, PRIMARY KEY (`role_slug`,`policy_slug`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `_seed_role_policies` (`role_slug`, `policy_slug`) VALUES
  ('super_admin','full_access'),
  ('admin_akademik','self_account_access'),
  ('admin_akademik','iam_read_only_access'),
  ('admin_akademik','iam_user_admin_access'),
  ('admin_akademik','student_read_access'),
  ('admin_akademik','student_write_access'),
  ('admin_akademik','staff_read_access'),
  ('admin_akademik','staff_write_access'),
  ('admin_akademik','academic_read_access'),
  ('admin_akademik','academic_write_access'),
  ('admin_akademik','lab_read_access'),
  ('admin_akademik','qr_read_access'),
  ('admin_akademik','qr_manage_access'),
  ('admin_akademik','attendance_read_access'),
  ('admin_akademik','attendance_write_access'),
  ('admin_akademik','attendance_validate_access'),
  ('admin_akademik','exam_read_access'),
  ('admin_akademik','exam_write_access'),
  ('admin_akademik','grade_read_access'),
  ('admin_akademik','grade_write_access'),
  ('admin_akademik','import_read_access'),
  ('admin_akademik','import_execute_access'),
  ('admin_akademik','report_read_access'),
  ('admin_akademik','report_export_access'),
  ('admin_akademik','media_read_access'),
  ('admin_akademik','media_write_access'),
  ('admin_akademik','archive_read_access'),
  ('admin_akademik','archive_manage_access'),
  ('admin_akademik','notification_inbox_access'),
  ('admin_akademik','notification_read_access'),
  ('admin_akademik','notification_write_access'),
  ('admin_akademik','notification_rule_admin_access'),
  ('admin_akademik','notification_pref_admin_access'),
  ('admin_akademik','audit_read_access'),
  ('admin_akademik','settings_read_access'),
  ('admin_akademik','ai_job_read_access'),
  ('admin_akademik','ai_job_manage_access'),
  ('admin_akademik','buffer_read_access'),
  ('admin_akademik','buffer_refresh_access'),
  ('admin_akademik','dangerous_action_deny_non_super'),
  ('operator_lab','self_account_access'),
  ('operator_lab','lab_read_access'),
  ('operator_lab','lab_write_access'),
  ('operator_lab','qr_read_access'),
  ('operator_lab','qr_manage_access'),
  ('operator_lab','attendance_scan_access'),
  ('operator_lab','attendance_read_access'),
  ('operator_lab','report_read_access'),
  ('operator_lab','media_read_access'),
  ('operator_lab','notification_inbox_access'),
  ('operator_lab','notification_read_access'),
  ('operator_lab','audit_read_access'),
  ('operator_lab','settings_read_access'),
  ('operator_lab','buffer_read_access'),
  ('operator_lab','dangerous_action_deny_non_super'),
  ('guru_pengawas','self_account_access'),
  ('guru_pengawas','student_read_access'),
  ('guru_pengawas','staff_read_access'),
  ('guru_pengawas','academic_read_access'),
  ('guru_pengawas','lab_read_access'),
  ('guru_pengawas','qr_read_access'),
  ('guru_pengawas','attendance_read_access'),
  ('guru_pengawas','attendance_validate_access'),
  ('guru_pengawas','exam_read_access'),
  ('guru_pengawas','exam_write_access'),
  ('guru_pengawas','grade_read_access'),
  ('guru_pengawas','grade_write_access'),
  ('guru_pengawas','report_read_access'),
  ('guru_pengawas','report_export_access'),
  ('guru_pengawas','media_read_access'),
  ('guru_pengawas','notification_inbox_access'),
  ('guru_pengawas','notification_read_access'),
  ('guru_pengawas','settings_read_access'),
  ('guru_pengawas','buffer_read_access'),
  ('guru_pengawas','dangerous_action_deny_non_super'),
  ('siswa','self_account_access'),
  ('siswa','student_attendance_self_service'),
  ('siswa','student_grade_self_service'),
  ('siswa','notification_inbox_access'),
  ('siswa','notification_pref_self_access');
INSERT INTO `_seed_role_policies` (`role_slug`, `policy_slug`) VALUES
  ('siswa','qr_read_access'),
  ('intern','self_account_access'),
  ('intern','intern_read_only'),
  ('intern','notification_inbox_access');

DELETE rp FROM `role_policies` rp
JOIN `roles` r ON r.role_id = rp.role_id
WHERE r.role_slug IN ('super_admin','admin_akademik','operator_lab','guru_pengawas','siswa','intern');

INSERT INTO `role_policies` (`role_id`, `policy_id`)
SELECT r.role_id, p.policy_id
FROM `_seed_role_policies` srp
JOIN `roles` r ON r.role_slug = srp.role_slug
JOIN `policies` p ON p.policy_slug = srp.policy_slug;

-- Sinkronisasi compatibility table role_permissions dari role_policies baru.
DELETE rp FROM `role_permissions` rp
JOIN `roles` r ON r.role_id = rp.role_id
WHERE r.role_slug IN ('super_admin','admin_akademik','operator_lab','guru_pengawas','siswa','intern');

INSERT INTO `role_permissions` (`role_id`, `perm_id`, `is_allowed`, `resource_scope`)
SELECT
  r.role_id,
  pp.perm_id,
  CASE WHEN SUM(CASE WHEN pp.effect = 'deny' THEN 1 ELSE 0 END) > 0 THEN 0 ELSE 1 END AS is_allowed,
  pp.resource_scope
FROM `roles` r
JOIN `role_policies` rpol ON rpol.role_id = r.role_id
JOIN `policy_permissions` pp ON pp.policy_id = rpol.policy_id
WHERE r.role_slug IN ('super_admin','admin_akademik','operator_lab','guru_pengawas','siswa','intern')
GROUP BY r.role_id, pp.perm_id, pp.resource_scope;

-- 5) Group IAM opsional seperti AWS IAM groups
INSERT INTO `groups` (`group_name`, `group_slug`, `deskripsi`) VALUES
  ('Super Admins', 'super_admins', 'Group pemilik akses penuh sistem.'),
  ('Admin Akademik', 'academic_admins', 'Group admin akademik dan presensi.'),
  ('Operator Lab', 'lab_operators', 'Group operator perangkat dan ruangan lab.'),
  ('Guru Pengawas', 'teacher_supervisors', 'Group guru pengawas jadwal/presensi/ujian.'),
  ('Siswa Default', 'students_default', 'Group default siswa.'),
  ('Intern Read Only', 'interns_read_only', 'Group intern/tamu dengan akses baca.'),
  ('Notification Admins', 'notification_admins', 'Group pengelola rule, dispatch, dan preferensi notifikasi.'),
  ('Import Operators', 'import_operators', 'Group operator import data.')
ON DUPLICATE KEY UPDATE `group_name` = VALUES(`group_name`), `deskripsi` = VALUES(`deskripsi`);
CREATE TEMPORARY TABLE `_seed_group_policies` (`group_slug` VARCHAR(100) COLLATE utf8mb4_unicode_ci, `policy_slug` VARCHAR(100) COLLATE utf8mb4_unicode_ci, PRIMARY KEY (`group_slug`,`policy_slug`)) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO `_seed_group_policies` (`group_slug`, `policy_slug`) VALUES
  ('super_admins','full_access'),
  ('academic_admins','self_account_access'),
  ('academic_admins','iam_read_only_access'),
  ('academic_admins','iam_user_admin_access'),
  ('academic_admins','student_read_access'),
  ('academic_admins','student_write_access'),
  ('academic_admins','staff_read_access'),
  ('academic_admins','staff_write_access'),
  ('academic_admins','academic_read_access'),
  ('academic_admins','academic_write_access'),
  ('academic_admins','lab_read_access'),
  ('academic_admins','qr_read_access'),
  ('academic_admins','qr_manage_access'),
  ('academic_admins','attendance_read_access'),
  ('academic_admins','attendance_write_access'),
  ('academic_admins','attendance_validate_access'),
  ('academic_admins','exam_read_access'),
  ('academic_admins','exam_write_access'),
  ('academic_admins','grade_read_access'),
  ('academic_admins','grade_write_access'),
  ('academic_admins','import_read_access'),
  ('academic_admins','import_execute_access'),
  ('academic_admins','report_read_access'),
  ('academic_admins','report_export_access'),
  ('academic_admins','media_read_access'),
  ('academic_admins','media_write_access'),
  ('academic_admins','archive_read_access'),
  ('academic_admins','archive_manage_access'),
  ('academic_admins','notification_inbox_access'),
  ('academic_admins','notification_read_access'),
  ('academic_admins','notification_write_access'),
  ('academic_admins','notification_rule_admin_access'),
  ('academic_admins','notification_pref_admin_access'),
  ('academic_admins','audit_read_access'),
  ('academic_admins','settings_read_access'),
  ('academic_admins','ai_job_read_access'),
  ('academic_admins','ai_job_manage_access'),
  ('academic_admins','buffer_read_access'),
  ('academic_admins','buffer_refresh_access'),
  ('lab_operators','self_account_access'),
  ('lab_operators','lab_read_access'),
  ('lab_operators','lab_write_access'),
  ('lab_operators','qr_read_access'),
  ('lab_operators','qr_manage_access'),
  ('lab_operators','attendance_scan_access'),
  ('lab_operators','attendance_read_access'),
  ('lab_operators','report_read_access'),
  ('lab_operators','media_read_access'),
  ('lab_operators','notification_inbox_access'),
  ('lab_operators','notification_read_access'),
  ('lab_operators','audit_read_access'),
  ('lab_operators','settings_read_access'),
  ('lab_operators','buffer_read_access'),
  ('teacher_supervisors','self_account_access'),
  ('teacher_supervisors','student_read_access'),
  ('teacher_supervisors','staff_read_access'),
  ('teacher_supervisors','academic_read_access'),
  ('teacher_supervisors','lab_read_access'),
  ('teacher_supervisors','qr_read_access'),
  ('teacher_supervisors','attendance_read_access'),
  ('teacher_supervisors','attendance_validate_access'),
  ('teacher_supervisors','exam_read_access'),
  ('teacher_supervisors','exam_write_access'),
  ('teacher_supervisors','grade_read_access'),
  ('teacher_supervisors','grade_write_access'),
  ('teacher_supervisors','report_read_access'),
  ('teacher_supervisors','report_export_access'),
  ('teacher_supervisors','media_read_access'),
  ('teacher_supervisors','notification_inbox_access'),
  ('teacher_supervisors','notification_read_access'),
  ('teacher_supervisors','settings_read_access'),
  ('teacher_supervisors','buffer_read_access'),
  ('students_default','self_account_access'),
  ('students_default','student_attendance_self_service'),
  ('students_default','student_grade_self_service'),
  ('students_default','notification_inbox_access'),
  ('students_default','notification_pref_self_access'),
  ('students_default','qr_read_access'),
  ('interns_read_only','self_account_access'),
  ('interns_read_only','intern_read_only');
INSERT INTO `_seed_group_policies` (`group_slug`, `policy_slug`) VALUES
  ('interns_read_only','notification_inbox_access'),
  ('notification_admins','notification_read_access'),
  ('notification_admins','notification_write_access'),
  ('notification_admins','notification_rule_admin_access'),
  ('notification_admins','notification_pref_admin_access'),
  ('notification_admins','notification_inbox_access'),
  ('import_operators','import_read_access'),
  ('import_operators','import_execute_access'),
  ('import_operators','student_read_access'),
  ('import_operators','student_write_access'),
  ('import_operators','grade_read_access'),
  ('import_operators','grade_write_access'),
  ('import_operators','notification_inbox_access');

DELETE gp FROM `group_policies` gp
JOIN `groups` g ON g.group_id = gp.group_id
WHERE g.group_slug IN ('super_admins','academic_admins','lab_operators','teacher_supervisors','students_default','interns_read_only','notification_admins','import_operators');

INSERT INTO `group_policies` (`group_id`, `policy_id`)
SELECT g.group_id, p.policy_id
FROM `_seed_group_policies` sgp
JOIN `groups` g ON g.group_slug = sgp.group_slug
JOIN `policies` p ON p.policy_slug = sgp.policy_slug;

-- 6) Notification rules granular
INSERT INTO `notification_rules` (`event_key`, `rule_name`, `module_name`, `entity_type`, `default_level_notif`, `required_perm_slug`, `target_role_slug`, `default_frequency`, `is_active`, `is_critical_locked`) VALUES
  ('user_created', 'User baru dibuat', 'users', 'users', 'info', 'users.read', 'admin_akademik', 'instant', 1, 0),
  ('user_blocked', 'User diblokir', 'users', 'users', 'warning', 'users.block', 'admin_akademik', 'instant', 1, 0),
  ('user_role_changed', 'Role user berubah', 'users', 'user_roles', 'info', 'users.assign_role', 'admin_akademik', 'instant', 1, 0),
  ('user_policy_changed', 'Policy user berubah', 'users', 'user_policies', 'warning', 'users.assign_policy', 'admin_akademik', 'instant', 1, 0),
  ('session_suspicious_login', 'Login mencurigakan', 'sessions', 'user_sessions', 'critical', 'sessions.revoke', 'super_admin', 'instant', 1, 1),
  ('student_without_rombel', 'Siswa aktif belum punya rombel aktif', 'students', 'siswa', 'warning', 'student_placements.create', 'admin_akademik', 'daily', 1, 0),
  ('student_mutation_created', 'Mutasi siswa dibuat', 'students', 'siswa_mutasi', 'info', 'student_mutations.read', 'admin_akademik', 'instant', 1, 0),
  ('rombel_without_homeroom', 'Rombel belum memiliki wali kelas', 'homerooms', 'rombel_wali_kelas', 'warning', 'homerooms.create', 'admin_akademik', 'daily', 1, 0),
  ('plotting_incomplete', 'Rombel belum diplotting', 'room_plotting', 'plotting_rombel', 'warning', 'room_plotting.create', 'admin_akademik', 'daily', 1, 0),
  ('room_class_slot_full', 'Ruang kelas mencapai batas rombel', 'room_plotting', 'plotting_rombel', 'warning', 'room_plotting.update', 'admin_akademik', 'instant', 1, 0),
  ('lab_schedule_conflict', 'Jadwal lab bentrok', 'lab_schedules', 'jadwal_lab', 'error', 'lab_schedules.update', 'admin_akademik', 'instant', 1, 0),
  ('device_offline', 'Perangkat lab offline', 'devices', 'perangkat_esp32', 'error', 'devices.health.read', 'operator_lab', 'instant', 1, 0),
  ('device_pairing_changed', 'Pairing perangkat berubah', 'devices', 'ruangan_perangkat', 'info', 'devices.pair', 'operator_lab', 'instant', 1, 0),
  ('qr_token_generated', 'QR token dibuat/reset', 'qr_tokens', 'qr_tokens', 'info', 'qr_tokens.generate', 'operator_lab', 'instant', 1, 0),
  ('qr_token_revoked', 'QR token dicabut', 'qr_tokens', 'qr_tokens', 'warning', 'qr_tokens.revoke', 'operator_lab', 'instant', 1, 0),
  ('qr_scan_failed_repeated', 'Scan QR gagal berulang', 'qr_scan_logs', 'log_scan_qr', 'warning', 'qr_scan_logs.read', 'operator_lab', 'instant', 1, 0),
  ('attendance_late_spike', 'Keterlambatan presensi meningkat', 'attendance', 'presensi', 'warning', 'attendance.read', 'guru_pengawas', 'daily', 1, 0),
  ('attendance_manual_created', 'Presensi manual dibuat', 'attendance', 'presensi', 'info', 'attendance.create', 'guru_pengawas', 'instant', 1, 0),
  ('attendance_validated', 'Presensi divalidasi', 'attendance', 'presensi', 'info', 'attendance.validate', 'guru_pengawas', 'instant', 1, 0),
  ('attendance_online_pending_review', 'Presensi online menunggu review', 'attendance_online', 'presensi_online', 'warning', 'attendance_online.review', 'guru_pengawas', 'instant', 1, 0),
  ('attendance_online_approved', 'Presensi online disetujui', 'attendance_online', 'presensi_online', 'info', 'attendance_online.self.read', 'siswa', 'instant', 1, 0),
  ('attendance_online_rejected', 'Presensi online ditolak', 'attendance_online', 'presensi_online', 'warning', 'attendance_online.self.read', 'siswa', 'instant', 1, 0),
  ('exam_session_opened', 'Sesi ujian dibuka', 'exam_sessions', 'sesi_ujian', 'info', 'exam_sessions.read', 'guru_pengawas', 'instant', 1, 0),
  ('exam_participant_missing', 'Peserta ujian belum lengkap', 'exam_participants', 'peserta_ujian', 'warning', 'exam_participants.update', 'guru_pengawas', 'instant', 1, 0),
  ('grade_import_partial_failed', 'Import nilai sebagian gagal', 'imports', 'import_jobs', 'error', 'imports.review', 'admin_akademik', 'instant', 1, 0),
  ('student_import_partial_failed', 'Import siswa sebagian gagal', 'imports', 'import_jobs', 'error', 'imports.review', 'admin_akademik', 'instant', 1, 0),
  ('import_completed', 'Import selesai', 'imports', 'import_jobs', 'info', 'imports.read', 'admin_akademik', 'instant', 1, 0),
  ('report_export_ready', 'Ekspor laporan siap diunduh', 'reports', 'media_berkas', 'info', 'reports.export', 'admin_akademik', 'instant', 1, 0),
  ('media_upload_failed', 'Upload media gagal', 'media', 'media_berkas', 'error', 'media.create', 'admin_akademik', 'instant', 1, 0),
  ('archive_job_completed', 'Arsip selesai dibuat', 'archives', 'arsip_batch', 'info', 'archives.read', 'super_admin', 'instant', 1, 0),
  ('archive_job_failed', 'Arsip gagal dibuat', 'archives', 'arsip_batch', 'critical', 'archives.archive', 'super_admin', 'instant', 1, 1),
  ('audit_archive_due', 'Audit log perlu diarsipkan', 'audit', 'user_activity_cold_archives', 'warning', 'audit.archive', 'super_admin', 'weekly', 1, 0),
  ('system_storage_critical', 'Storage sistem kritis', 'system', NULL, 'critical', 'settings.update', 'super_admin', 'instant', 1, 1),
  ('ai_job_failed', 'AI recognition job gagal', 'ai_jobs', 'ai_recognition_jobs', 'error', 'ai_jobs.manage', 'admin_akademik', 'instant', 1, 0),
  ('notification_rule_changed', 'Rule notifikasi berubah', 'notification_rules', 'notification_rules', 'info', 'notification_rules.update', 'super_admin', 'instant', 1, 0)
ON DUPLICATE KEY UPDATE
  `rule_name` = VALUES(`rule_name`),
  `module_name` = VALUES(`module_name`),
  `entity_type` = VALUES(`entity_type`),
  `default_level_notif` = VALUES(`default_level_notif`),
  `required_perm_slug` = VALUES(`required_perm_slug`),
  `target_role_slug` = VALUES(`target_role_slug`),
  `default_frequency` = VALUES(`default_frequency`),
  `is_active` = VALUES(`is_active`),
  `is_critical_locked` = VALUES(`is_critical_locked`);

-- 7) Default preference untuk user demo jika akun sudah ada
CREATE TEMPORARY TABLE `_seed_user_notification_preferences` (
  `module_name` VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_key` VARCHAR(100) COLLATE utf8mb4_unicode_ci NULL,
  `frequency` ENUM('instant','daily','weekly','off') COLLATE utf8mb4_unicode_ci NOT NULL,
  `popup_enabled` TINYINT(1) NOT NULL,
  `inbox_enabled` TINYINT(1) NOT NULL,
  `email_enabled` TINYINT(1) NOT NULL,
  `is_muted` TINYINT(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `_seed_user_notification_preferences` (`module_name`, `event_key`, `frequency`, `popup_enabled`, `inbox_enabled`, `email_enabled`, `is_muted`) VALUES
  ('notifications', NULL, 'instant', 1, 1, 0, 0),
  ('attendance', NULL, 'instant', 1, 1, 0, 0),
  ('import', NULL, 'instant', 1, 1, 0, 0),
  ('system', 'system_storage_critical', 'instant', 1, 1, 1, 0);

UPDATE `user_notification_preferences` up
JOIN `users` u ON u.user_id = up.user_id
JOIN `_seed_user_notification_preferences` x
  ON x.module_name = up.module_name
 AND x.event_key <=> up.event_key
SET
  up.`frequency` = x.`frequency`,
  up.`popup_enabled` = x.`popup_enabled`,
  up.`inbox_enabled` = x.`inbox_enabled`,
  up.`email_enabled` = x.`email_enabled`,
  up.`is_muted` = x.`is_muted`
WHERE u.username IN ('admin','operator','guru','siswa');

INSERT INTO `user_notification_preferences` (`user_id`, `module_name`, `event_key`, `frequency`, `popup_enabled`, `inbox_enabled`, `email_enabled`, `is_muted`)
SELECT u.user_id, x.module_name, x.event_key, x.frequency, x.popup_enabled, x.inbox_enabled, x.email_enabled, x.is_muted
FROM `users` u
JOIN `_seed_user_notification_preferences` x
WHERE u.username IN ('admin','operator','guru','siswa')
  AND NOT EXISTS (
    SELECT 1
    FROM `user_notification_preferences` up
    WHERE up.user_id = u.user_id
      AND up.module_name = x.module_name
      AND up.event_key <=> x.event_key
  );

-- 8) View bantu untuk debugging/evaluasi efektif permission
CREATE OR REPLACE VIEW `v_role_effective_policy_permissions` AS
SELECT
  r.role_slug,
  r.nama_role,
  p.policy_slug,
  p.policy_name,
  pm.perm_slug,
  pm.module_name,
  pm.action_name,
  pp.effect,
  pp.resource_scope,
  pp.conditions_json,
  pp.priority
FROM `roles` r
JOIN `role_policies` rp ON rp.role_id = r.role_id
JOIN `policies` p ON p.policy_id = rp.policy_id
JOIN `policy_permissions` pp ON pp.policy_id = p.policy_id
JOIN `permissions` pm ON pm.perm_id = pp.perm_id;

CREATE OR REPLACE VIEW `v_user_effective_policy_permissions` AS
SELECT DISTINCT
  u.user_id,
  u.username,
  src.source_type,
  src.source_slug,
  pm.perm_slug,
  pm.module_name,
  pm.action_name,
  pp.effect,
  pp.resource_scope,
  pp.conditions_json,
  pp.priority
FROM `users` u
JOIN (
  SELECT ur.user_id, 'role' AS source_type, r.role_slug AS source_slug, rp.policy_id
  FROM `user_roles` ur
  JOIN `roles` r ON r.role_id = ur.role_id
  JOIN `role_policies` rp ON rp.role_id = r.role_id
  WHERE ur.is_active = 1
  UNION ALL
  SELECT up.user_id, 'user_policy' AS source_type, p.policy_slug AS source_slug, up.policy_id
  FROM `user_policies` up
  JOIN `policies` p ON p.policy_id = up.policy_id
  UNION ALL
  SELECT gu.user_id, 'group' AS source_type, g.group_slug AS source_slug, gp.policy_id
  FROM `group_users` gu
  JOIN `groups` g ON g.group_id = gu.group_id
  JOIN `group_policies` gp ON gp.group_id = g.group_id
) src ON src.user_id = u.user_id
JOIN `policy_permissions` pp ON pp.policy_id = src.policy_id
JOIN `permissions` pm ON pm.perm_id = pp.perm_id;

COMMIT;

-- =========================================================
-- QUICK CHECK
-- =========================================================
SELECT 'permissions' AS item, COUNT(*) AS total FROM `permissions`
UNION ALL SELECT 'policies', COUNT(*) FROM `policies`
UNION ALL SELECT 'policy_permissions', COUNT(*) FROM `policy_permissions`
UNION ALL SELECT 'role_policies', COUNT(*) FROM `role_policies`
UNION ALL SELECT 'notification_rules', COUNT(*) FROM `notification_rules`;

SELECT role_slug, COUNT(*) AS total_rules
FROM `v_role_effective_policy_permissions`
WHERE role_slug IN ('super_admin','admin_akademik','operator_lab','guru_pengawas','siswa','intern')
GROUP BY role_slug
ORDER BY FIELD(role_slug,'super_admin','admin_akademik','operator_lab','guru_pengawas','siswa','intern');
