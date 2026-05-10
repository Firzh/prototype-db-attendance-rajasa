# Seed Permission Notifikasi 3.7

File ini berisi rancangan seed permission dan policy notifikasi yang dipakai pada `prototype-db-3.7.sql`.

Tujuan seed:

1. Memisahkan akses inbox pribadi, rule admin, preference user, dan preference admin.
2. Mendukung pengaturan notifikasi berbasis role, group, policy, permission, dan custom scope.
3. Menjaga agar siswa tidak perlu memiliki banyak data preferensi individual.
4. Menyediakan dasar untuk halaman notifikasi modular berbasis hak akses.

## 1. Permission baru

```sql
INSERT INTO `permissions` (`perm_slug`, `module_name`, `action_name`, `keterangan`) VALUES
  ('notifications.inbox.read', 'notifications', 'read', 'Melihat inbox notifikasi milik sendiri.'),
  ('notifications.inbox.update', 'notifications', 'update', 'Menandai notifikasi sendiri sebagai dibaca/belum dibaca.'),
  ('notifications.inbox.delete', 'notifications', 'delete', 'Menghapus notifikasi dari inbox sendiri.'),
  ('notifications.create', 'notifications', 'create', 'Membuat notifikasi manual/sistem.'),
  ('notifications.update', 'notifications', 'update', 'Mengubah status/resolusi notifikasi.'),
  ('notifications.delete', 'notifications', 'delete', 'Menghapus notifikasi.'),
  ('notifications.resolve', 'notifications', 'update', 'Menandai notifikasi sebagai resolved.'),
  ('notifications.dispatch', 'notifications', 'manage', 'Mengirim atau menjadwalkan distribusi notifikasi.'),
  ('notifications.recipients.read', 'notifications', 'read', 'Melihat daftar penerima notifikasi.'),
  ('notifications.recipients.manage', 'notifications', 'manage', 'Mengelola penerima dan channel notifikasi.'),
  ('notification_rules.read', 'notification_rules', 'read', 'Melihat rule notifikasi.'),
  ('notification_rules.create', 'notification_rules', 'create', 'Membuat rule notifikasi.'),
  ('notification_rules.update', 'notification_rules', 'update', 'Mengubah rule notifikasi.'),
  ('notification_rules.delete', 'notification_rules', 'delete', 'Menghapus rule notifikasi.'),
  ('notification_preferences.read', 'notification_preferences', 'read', 'Melihat preferensi notifikasi.'),
  ('notification_preferences.self.update', 'notification_preferences', 'update', 'Mengubah preferensi notifikasi milik sendiri.'),
  ('notification_preferences.manage', 'notification_preferences', 'manage', 'Mengelola preferensi notifikasi user lain.'),
  ('notification_channels.manage', 'notification_channels', 'manage', 'Mengelola channel notifikasi email/WA/in-app/system.'),
  ('notification_critical.manage', 'notification_critical', 'manage', 'Mengelola notifikasi critical locked.')
ON DUPLICATE KEY UPDATE
  `module_name` = VALUES(`module_name`),
  `action_name` = VALUES(`action_name`),
  `keterangan` = VALUES(`keterangan`);
```

## 2. Policy baru

| Policy | Fungsi |
|---|---|
| `notification_inbox_access` | akses inbox pribadi |
| `notification_read_access` | membaca notifikasi dan rule |
| `notification_write_access` | membuat, mengubah, resolve, dispatch notifikasi |
| `notification_rule_admin_access` | mengelola notification rules |
| `notification_pref_self_access` | mengatur preferensi sendiri |
| `notification_pref_admin_access` | mengatur preferensi user lain di bawah kewenangan |

```sql
INSERT INTO `policies` (`policy_name`, `policy_slug`, `policy_type`, `deskripsi`, `is_system`) VALUES
  ('NotificationInboxAccess', 'notification_inbox_access', 'managed', 'Akses inbox notifikasi pribadi.', 1),
  ('NotificationReadAccess', 'notification_read_access', 'managed', 'Akses baca notifikasi sesuai scope.', 1),
  ('NotificationWriteAccess', 'notification_write_access', 'managed', 'Akses mengelola notifikasi dan penerima.', 1),
  ('NotificationRuleAdminAccess', 'notification_rule_admin_access', 'managed', 'Akses mengelola notification rules.', 1),
  ('NotificationPreferenceSelfAccess', 'notification_pref_self_access', 'managed', 'Akses mengatur preferensi notifikasi milik sendiri.', 1),
  ('NotificationPreferenceAdminAccess', 'notification_pref_admin_access', 'managed', 'Akses mengatur preferensi notifikasi user lain di bawah kewenangannya.', 1)
ON DUPLICATE KEY UPDATE
  `policy_name` = VALUES(`policy_name`),
  `policy_type` = VALUES(`policy_type`),
  `deskripsi` = VALUES(`deskripsi`),
  `is_system` = VALUES(`is_system`);
```

## 3. Rekomendasi assignment policy

### 3.1 Super admin dan admin akademik

```text
notification_inbox_access
notification_read_access
notification_write_access
notification_rule_admin_access
notification_pref_admin_access
```

### 3.2 Guru pengawas dan operator lab

```text
notification_inbox_access
notification_read_access
notification_pref_self_access
```

### 3.3 Siswa dan intern

```text
notification_inbox_access
notification_pref_self_access
```

## 4. Group default notifikasi

Group default yang dipakai untuk preference massal:

| Group | Fungsi |
|---|---|
| `academic_admins` | admin akademik |
| `lab_operators` | operator lab |
| `teacher_supervisors` | guru/pengawas presensi |
| `students_default` | semua siswa default |
| `notification_admins` | pengelola notifikasi |

Alasan memakai group:

```text
Siswa tidak perlu dibuatkan preferensi individual sejak awal.
Backend cukup membaca default group students_default.
Jika ada user tertentu butuh pengecualian, baru isi user_notification_preferences.
```

## 5. Rule notifikasi baru untuk scan HP

```sql
INSERT INTO `notification_rules` (
  `event_key`, `rule_name`, `module_name`, `entity_type`, `default_level_notif`, `importance_level`,
  `required_perm_slug`, `target_role_slug`, `target_group_slug`, `target_policy_slug`, `default_frequency`,
  `default_popup_enabled`, `default_inbox_enabled`, `default_email_enabled`, `default_whatsapp_enabled`, `default_system_enabled`,
  `is_active`, `is_critical_locked`, `user_configurable`, `admin_configurable`, `rule_ui_group`, `recommended_action`
) VALUES
  ('attendance_scan_flagged_unresolved', 'Scan QR beda rombel belum di-resolve', 'attendance', 'log_scan_qr', 'warning', 'required', 'attendance.validate', 'guru_pengawas', 'teacher_supervisors', NULL, 'instant', 1, 1, 0, 0, 1, 1, 0, 0, 1, 'Presensi Scan QR', 'Buka halaman presensi dan resolve data flagged.'),
  ('attendance_scan_session_interrupted', 'Sesi scan presensi terputus', 'attendance', 'scanner_sessions', 'error', 'urgent', 'attendance.scan', 'guru_pengawas', 'teacher_supervisors', NULL, 'instant', 1, 1, 0, 0, 1, 1, 0, 0, 1, 'Presensi Scan QR', 'Lanjutkan presensi atau tandai sesi selesai.'),
  ('attendance_rombel_unfinished', 'Presensi rombel belum selesai', 'attendance', 'scanner_sessions', 'warning', 'required', 'attendance.read', 'guru_pengawas', 'teacher_supervisors', NULL, 'instant', 1, 1, 0, 0, 1, 1, 0, 0, 1, 'Presensi Scan QR', 'Periksa siswa belum presensi dan lakukan resolve.'),
  ('attendance_scanner_session_expired', 'Sesi scan kedaluwarsa', 'attendance', 'scanner_sessions', 'warning', 'required', 'attendance.scan', 'operator_lab', 'lab_operators', NULL, 'daily', 0, 1, 0, 0, 1, 1, 0, 0, 1, 'Presensi Scan QR', 'Periksa sesi scanner yang kedaluwarsa.'),
  ('notification_preference_admin_changed', 'Preferensi notifikasi user diubah admin', 'notification_preferences', 'user_notification_preferences', 'info', 'required', 'notification_preferences.read', NULL, 'notification_admins', NULL, 'instant', 1, 1, 0, 0, 1, 1, 0, 0, 1, 'Pengaturan Notifikasi', 'Tinjau perubahan preferensi notifikasi.'),
  ('role_notification_preference_changed', 'Default notifikasi role/group berubah', 'notification_preferences', 'role_notification_preferences', 'info', 'required', 'notification_preferences.manage', 'admin_akademik', 'notification_admins', NULL, 'instant', 1, 1, 0, 0, 1, 1, 0, 0, 1, 'Pengaturan Notifikasi', 'Tinjau konfigurasi default role/group.');
```

## 6. Aturan backend yang wajib mengikuti seed

1. User biasa hanya boleh mengubah notifikasi `optional`.
2. Notifikasi `required`, `urgent`, dan `critical` tidak boleh dimatikan penuh oleh user biasa.
3. Admin hanya boleh mengatur user dengan `role_level` lebih rendah dari dirinya.
4. Jika `is_admin_enforced = 1`, preference user tidak boleh dioverride oleh user tersebut.
5. Jika `role_notification_preferences.is_enforced = 1`, default role/group menjadi batas minimum.
6. Resolver harus membaca role, group, policy, permission, dan custom condition secara berurutan berdasarkan `priority`.

## 7. Catatan kompatibilitas

Permission lama berikut tetap dipertahankan sebagai alias kompatibilitas:

```text
notifications.read
notifications.write
```

Pengembangan baru sebaiknya memakai permission granular di atas.
