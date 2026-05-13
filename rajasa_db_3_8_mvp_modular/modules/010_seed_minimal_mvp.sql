-- =========================================================
-- 010 - SEED MINIMAL MVP
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;


INSERT INTO `roles` (`nama_role`, `role_slug`, `role_level`, `deskripsi`, `is_system`) VALUES
('Super Admin', 'super_admin', 10, 'Akses penuh ke seluruh modul aktif', 1),
('Admin Akademik', 'admin_akademik', 20, 'Kelola data akademik dan presensi', 1),
('Guru Pengawas', 'guru_pengawas', 40, 'Memantau jadwal dan presensi', 1),
('Operator Lab', 'operator_lab', 40, 'Mengelola perangkat, scan, dan ruangan lab', 1),
('Siswa', 'siswa', 80, 'Akses mandiri terbatas untuk profil dan riwayat presensi', 1),
('Intern', 'intern', 90, 'Akses terbatas sementara', 1)
ON DUPLICATE KEY UPDATE
  `role_level` = VALUES(`role_level`),
  `deskripsi` = VALUES(`deskripsi`),
  `is_system` = VALUES(`is_system`);

INSERT INTO `groups` (`group_name`, `group_slug`, `group_type`, `group_level`, `is_system`, `deskripsi`) VALUES
('Super Admins', 'super_admins', 'generic', 10, 1, 'Group bawaan super admin'),
('Academic Admins', 'academic_admins', 'academic', 20, 1, 'Group bawaan admin akademik'),
('Lab Operators', 'lab_operators', 'attendance', 40, 1, 'Group bawaan operator lab'),
('Teacher Supervisors', 'teacher_supervisors', 'attendance', 40, 1, 'Group bawaan guru pengawas'),
('Students Default', 'students_default', 'student', 80, 1, 'Default massal siswa'),
('Import Operators', 'import_operators', 'import', 40, 1, 'Operator import data')
ON DUPLICATE KEY UPDATE
  `group_type` = VALUES(`group_type`),
  `group_level` = VALUES(`group_level`),
  `is_system` = VALUES(`is_system`),
  `deskripsi` = VALUES(`deskripsi`);

INSERT INTO `master_jenis_ruangan` (`kode_jenis_ruangan`, `nama_jenis_ruangan`, `deskripsi`, `is_system`, `status`) VALUES
('lab', 'Laboratorium', 'Ruangan praktik/lab yang menjadi lokasi utama presensi QR.', 1, 'aktif'),
('kelas_teori', 'Kelas Teori', 'Ruangan pembelajaran teori.', 1, 'aktif'),
('kantor', 'Kantor', 'Ruangan kerja staf/guru.', 1, 'aktif'),
('perpustakaan', 'Perpustakaan', 'Ruangan perpustakaan atau ruang literasi.', 1, 'aktif'),
('fleksibel', 'Ruang Fleksibel', 'Fallback ketika lokasi presensi tidak dicatat atau berubah-ubah.', 1, 'aktif')
ON DUPLICATE KEY UPDATE
  `nama_jenis_ruangan` = VALUES(`nama_jenis_ruangan`),
  `status` = VALUES(`status`);

INSERT INTO `jurusan` (`kode_jurusan`, `nama_jurusan`, `deskripsi_jurusan`, `status`) VALUES
('AKL', 'Akuntansi dan Keuangan Lembaga', 'Seed DB 3.8 MVP untuk mendukung data mitra minimal 10 AKL.', 'aktif'),
('TKJ', 'Teknik Komputer dan Jaringan', 'Seed umum jurusan SMK.', 'aktif'),
('RPL', 'Rekayasa Perangkat Lunak', 'Seed umum jurusan SMK.', 'aktif')
ON DUPLICATE KEY UPDATE
  `nama_jurusan` = VALUES(`nama_jurusan`),
  `status` = 'aktif',
  `updated_at` = CURRENT_TIMESTAMP;

INSERT INTO `permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`) VALUES
('users.read', 'users', 'read', 'Melihat data user'),
('users.create', 'users', 'create', 'Membuat user baru'),
('users.update', 'users', 'update', 'Mengubah user'),
('users.delete', 'users', 'delete', 'Menghapus user'),
('users.assign_role', 'users', 'assign_role', 'Mengatur role user'),
('students.read', 'students', 'read', 'Melihat data siswa'),
('students.write', 'students', 'write', 'Mengelola data siswa'),
('academic.read', 'academic', 'read', 'Melihat data jurusan, rombel, plotting, jadwal'),
('academic.write', 'academic', 'write', 'Mengelola data jurusan, rombel, plotting, jadwal'),
('rooms.read', 'rooms', 'read', 'Melihat data ruangan'),
('rooms.write', 'rooms', 'write', 'Mengelola data ruangan'),
('devices.read', 'devices', 'read', 'Melihat data perangkat'),
('devices.write', 'devices', 'write', 'Mengelola data perangkat'),
('attendance.scan', 'attendance', 'scan', 'Melakukan scan presensi'),
('attendance.scan.web', 'attendance', 'scan', 'Melakukan scan QR presensi melalui kamera HP/browser website'),
('attendance.scan.any_rombel', 'attendance', 'scan', 'Melakukan scan QR untuk semua rombel'),
('attendance.scan.own_rombel', 'attendance', 'scan', 'Melakukan scan QR untuk rombel yang menjadi tanggung jawabnya'),
('attendance.scan.resolve_flag', 'attendance', 'validate', 'Menyelesaikan warning/flagged scan QR beda rombel atau kartu tidak sesuai'),
('attendance.scan.manual_override', 'attendance', 'validate', 'Melakukan override presensi manual saat scan gagal atau perlu koreksi'),
('attendance.read', 'attendance', 'read', 'Melihat data presensi'),
('attendance.write', 'attendance', 'write', 'Mengelola data presensi'),
('attendance.validate', 'attendance', 'validate', 'Memvalidasi data presensi'),
('attendance.online_submit', 'attendance', 'submit', 'Mengirim pengajuan presensi online beserta lampiran'),
('attendance.online_review', 'attendance', 'review', 'Meninjau dan memverifikasi presensi online'),
('qr.read', 'qr', 'read', 'Melihat token QR'),
('qr.generate', 'qr', 'generate', 'Membuat / reset QR'),
('qr.revoke', 'qr', 'revoke', 'Menonaktifkan QR'),
('reports.read', 'reports', 'read', 'Melihat rekap/laporan'),
('reports.export', 'reports', 'export', 'Mengunduh / ekspor laporan'),
('settings.read', 'settings', 'read', 'Melihat konfigurasi'),
('settings.write', 'settings', 'write', 'Mengubah konfigurasi'),
('notifications.read', 'notifications', 'read', 'Melihat notifikasi in-app/system'),
('notifications.write', 'notifications', 'write', 'Membuat/ubah notifikasi in-app/system'),
('notification_preferences.read', 'notification_preferences', 'read', 'Melihat preferensi notifikasi'),
('notification_preferences.update_self', 'notification_preferences', 'update', 'Mengubah preferensi notifikasi opsional milik sendiri'),
('notification_preferences.update_managed', 'notification_preferences', 'manage', 'Admin mengatur preferensi user di bawahnya'),
('role_notification_preferences.manage', 'role_notification_preferences', 'manage', 'Mengelola default preferensi notifikasi role/group/policy'),
('audit.read', 'audit', 'read', 'Melihat audit log'),
('media.read', 'media', 'read', 'Melihat metadata dan berkas pendukung'),
('media.write', 'media', 'write', 'Mengelola metadata dan unggahan berkas'),
('archive.read', 'archive', 'read', 'Melihat batch dan detail arsip'),
('archive.archive', 'archive', 'archive', 'Menjalankan proses arsip atau restore data'),
('session.manage', 'session', 'manage', 'Mengelola sesi login'),
('import.read', 'import', 'read', 'Melihat riwayat dan hasil import data'),
('import.write', 'import', 'write', 'Menjalankan import data siswa dan penempatan rombel')
ON DUPLICATE KEY UPDATE
  `module_name` = VALUES(`module_name`),
  `action_name` = VALUES(`action_name`),
  `keterangan` = VALUES(`keterangan`);

INSERT INTO `policies` (`policy_name`, `policy_slug`, `policy_type`, `deskripsi`, `is_system`) VALUES
('FullAccess', 'full_access', 'managed', 'Akses penuh ke seluruh resource aktif', 1),
('AcademicAdminAccess', 'academic_admin_access', 'managed', 'Akses administrasi akademik dan presensi', 1),
('TeacherSupervisorAccess', 'teacher_supervisor_access', 'managed', 'Akses guru pengawas', 1),
('LabOperatorAccess', 'lab_operator_access', 'managed', 'Akses operator lab dan perangkat', 1),
('StudentSelfService', 'student_self_service', 'managed', 'Akses siswa untuk data diri dan presensi sendiri', 1),
('InternReadOnly', 'intern_read_only', 'managed', 'Akses baca terbatas untuk pengguna sementara', 1)
ON DUPLICATE KEY UPDATE
  `deskripsi` = VALUES(`deskripsi`),
  `is_system` = VALUES(`is_system`);

-- Full access mendapat semua permission aktif.
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 1
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'full_access'
ON DUPLICATE KEY UPDATE `effect` = VALUES(`effect`);

-- Academic admin tanpa ujian, nilai, AI, dan channel notifikasi external channel.
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 10
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'academic_admin_access'
  AND pm.perm_slug IN (
    'students.read','students.write','academic.read','academic.write',
    'attendance.read','attendance.write','attendance.validate','attendance.online_review',
    'reports.read','reports.export','notifications.read','notifications.write',
    'notification_preferences.read','notification_preferences.update_managed','role_notification_preferences.manage',
    'qr.read','qr.generate','qr.revoke','media.read','media.write','archive.read','archive.archive',
    'import.read','import.write'
  )
ON DUPLICATE KEY UPDATE `effect` = VALUES(`effect`);

INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 20
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'teacher_supervisor_access'
  AND pm.perm_slug IN (
    'students.read','academic.read','attendance.read','attendance.validate','attendance.online_review',
    'attendance.scan.web','attendance.scan.own_rombel','attendance.scan.resolve_flag',
    'reports.read','notifications.read','notification_preferences.read','notification_preferences.update_self','media.read'
  )
ON DUPLICATE KEY UPDATE `effect` = VALUES(`effect`);

INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 20
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'lab_operator_access'
  AND pm.perm_slug IN (
    'rooms.read','rooms.write','devices.read','devices.write',
    'attendance.scan','attendance.scan.web','attendance.scan.any_rombel','attendance.read','qr.read','notifications.read',
    'reports.read','audit.read','media.read','import.read','import.write'
  )
ON DUPLICATE KEY UPDATE `effect` = VALUES(`effect`);

INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', 'self/*', 30
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'student_self_service'
  AND pm.perm_slug IN ('attendance.read','attendance.online_submit','qr.read','notifications.read','notification_preferences.read','notification_preferences.update_self','media.read')
ON DUPLICATE KEY UPDATE `effect` = VALUES(`effect`);

INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 40
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'intern_read_only'
  AND pm.perm_slug IN (
    'students.read','academic.read','rooms.read','devices.read',
    'attendance.read','reports.read','notifications.read','media.read','archive.read'
  )
ON DUPLICATE KEY UPDATE `effect` = VALUES(`effect`);

INSERT INTO `role_policies` (`role_id`, `policy_id`)
SELECT r.role_id, p.policy_id
FROM `roles` r
JOIN `policies` p
WHERE (r.role_slug = 'super_admin' AND p.policy_slug = 'full_access')
   OR (r.role_slug = 'admin_akademik' AND p.policy_slug = 'academic_admin_access')
   OR (r.role_slug = 'guru_pengawas' AND p.policy_slug = 'teacher_supervisor_access')
   OR (r.role_slug = 'operator_lab' AND p.policy_slug = 'lab_operator_access')
   OR (r.role_slug = 'siswa' AND p.policy_slug = 'student_self_service')
   OR (r.role_slug = 'intern' AND p.policy_slug = 'intern_read_only')
ON DUPLICATE KEY UPDATE `policy_id` = VALUES(`policy_id`);

INSERT INTO `konfigurasi` (`kunci`, `nilai`, `tipe_nilai`, `keterangan`)
VALUES
  ('academic.tahun_ajaran_aktif', NULL, 'string', 'Tahun ajaran aktif untuk default import/plotting. Diisi oleh admin.'),
  ('academic.semester_aktif', 'ganjil', 'string', 'Semester aktif default untuk import/plotting.'),
  ('import.default_backend_parser', 'openspout', 'string', 'Parser backend default untuk import Excel/CSV.'),
  ('scanner.default_lokasi_mode', 'tidak_dicatat', 'string', 'Default lokasi sesi scan agar guru tidak wajib update ruangan setiap pindah ruang.'),
  ('notification.channels.enabled', '["in_app","system"]', 'json', 'Channel notifikasi aktif pada MVP. Channel eksternal tidak disertakan.')
ON DUPLICATE KEY UPDATE
  `nilai` = VALUES(`nilai`),
  `tipe_nilai` = VALUES(`tipe_nilai`),
  `keterangan` = VALUES(`keterangan`);

INSERT INTO `notification_rules` (
  `event_key`, `rule_name`, `module_name`, `entity_type`, `default_level_notif`, `importance_level`,
  `required_perm_slug`, `target_role_slug`, `target_group_slug`, `default_frequency`,
  `default_popup_enabled`, `default_inbox_enabled`, `default_system_enabled`,
  `user_configurable`, `admin_configurable`, `rule_ui_group`, `recommended_action`, `is_active`, `is_critical_locked`
)
VALUES
  ('plotting_incomplete', 'Rombel belum diplotting', 'academic', 'plotting_rombel', 'warning', 'optional', 'academic.write', 'admin_akademik', 'academic_admins', 'daily', 1, 1, 1, 1, 1, 'Akademik', 'Periksa plotting rombel bila jadwal/ruangan stabil sudah tersedia.', 1, 0),
  ('student_without_rombel', 'Siswa aktif belum punya rombel aktif', 'students', 'siswa', 'warning', 'required', 'students.write', 'admin_akademik', 'academic_admins', 'daily', 1, 1, 1, 0, 1, 'Data Siswa', 'Lengkapi penempatan rombel siswa.', 1, 0),
  ('student_import_partial_failed', 'Import siswa selesai dengan sebagian error', 'import', 'import_jobs', 'error', 'required', 'import.write', 'admin_akademik', 'import_operators', 'instant', 1, 1, 1, 0, 1, 'Import', 'Buka detail import dan perbaiki baris error.', 1, 0),
  ('attendance_scan_flagged_unresolved', 'Scan QR bermasalah belum di-resolve', 'attendance', 'log_scan_qr', 'warning', 'required', 'attendance.scan.resolve_flag', 'guru_pengawas', 'teacher_supervisors', 'instant', 1, 1, 1, 0, 1, 'Presensi QR', 'Buka halaman resolve scan.', 1, 0),
  ('attendance_scan_session_interrupted', 'Sesi scan terputus', 'attendance', 'scanner_sessions', 'error', 'urgent', 'attendance.scan.web', 'guru_pengawas', 'teacher_supervisors', 'instant', 1, 1, 1, 0, 1, 'Presensi QR', 'Lanjutkan atau tutup sesi scan.', 1, 0),
  ('attendance_rombel_unfinished', 'Rombel belum selesai presensi', 'attendance', 'scanner_sessions', 'warning', 'required', 'attendance.read', 'guru_pengawas', 'teacher_supervisors', 'daily', 1, 1, 1, 0, 1, 'Presensi QR', 'Periksa rekap sesi rombel.', 1, 0),
  ('system_storage_critical', 'Storage sistem kritis', 'system', NULL, 'critical', 'critical', 'settings.write', 'super_admin', 'super_admins', 'instant', 1, 1, 1, 0, 1, 'Sistem', 'Periksa kapasitas storage server.', 1, 1)
ON DUPLICATE KEY UPDATE
  `rule_name` = VALUES(`rule_name`),
  `importance_level` = VALUES(`importance_level`),
  `default_popup_enabled` = VALUES(`default_popup_enabled`),
  `default_inbox_enabled` = VALUES(`default_inbox_enabled`),
  `default_system_enabled` = VALUES(`default_system_enabled`),
  `recommended_action` = VALUES(`recommended_action`),
  `is_active` = VALUES(`is_active`),
  `is_critical_locked` = VALUES(`is_critical_locked`);

INSERT INTO `role_notification_preferences` (
  `principal_type`, `principal_key`, `role_id`, `module_name`, `event_key`, `frequency`,
  `popup_enabled`, `inbox_enabled`, `system_enabled`, `is_muted`, `is_enforced`, `priority`, `admin_note`
)
SELECT 'role', r.role_slug, r.role_id, 'attendance', NULL, 'instant', 1, 1, 1, 0, 1, 20,
       'Default MVP: notifikasi presensi hanya in-app/system.'
FROM `roles` r
WHERE r.role_slug IN ('super_admin','admin_akademik','operator_lab','guru_pengawas')
ON DUPLICATE KEY UPDATE
  `frequency` = VALUES(`frequency`),
  `popup_enabled` = VALUES(`popup_enabled`),
  `inbox_enabled` = VALUES(`inbox_enabled`),
  `system_enabled` = VALUES(`system_enabled`),
  `admin_note` = VALUES(`admin_note`);

INSERT INTO `schema_versions` (`version`, `name`, `notes`)
VALUES (
  '3.8-mvp-modular',
  'prototype-db-3.8-mvp-modular',
  'Fresh modular schema. Removed AI recognition jobs, exams, grades, and external notification channels channels. Rombel display keeps 10 AKL without increment.'
)
ON DUPLICATE KEY UPDATE
  `applied_at` = CURRENT_TIMESTAMP,
  `notes` = VALUES(`notes`);

SET FOREIGN_KEY_CHECKS = 1;
