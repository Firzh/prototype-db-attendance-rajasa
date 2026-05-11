-- =========================================================
-- 011 - VIEWS MVP
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

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
CREATE OR REPLACE VIEW `v_notifikasi_inbox` AS
SELECT
  np.`recipient_id`,
  np.`user_id`,
  np.`delivery_channel`,
  np.`is_read`,
  np.`read_at`,
  n.`notif_id`,
  n.`event_key`,
  n.`module_name`,
  n.`entity_type`,
  n.`entity_id`,
  n.`pesan`,
  n.`level_notif`,
  n.`importance_level`,
  n.`action_label`,
  n.`action_url`,
  n.`is_resolved`,
  n.`created_at`
FROM `notifikasi_penerima` np
JOIN `notifikasi` n ON n.`notif_id` = np.`notif_id`;

CREATE OR REPLACE VIEW `v_role_notification_preferences_detail` AS
SELECT
  rnp.`role_notification_pref_id`,
  rnp.`principal_type`,
  rnp.`principal_key`,
  rnp.`module_name`,
  rnp.`event_key`,
  rnp.`frequency`,
  rnp.`popup_enabled`,
  rnp.`inbox_enabled`,
  rnp.`system_enabled`,
  rnp.`is_muted`,
  rnp.`is_enforced`,
  rnp.`priority`,
  ro.`role_slug`,
  g.`group_slug`,
  p.`policy_slug`,
  rnp.`required_perm_slug`,
  u.`username` AS `configured_by_username`,
  rnp.`admin_note`,
  rnp.`updated_at`
FROM `role_notification_preferences` rnp
LEFT JOIN `roles` ro ON ro.`role_id` = rnp.`role_id`
LEFT JOIN `groups` g ON g.`group_id` = rnp.`group_id`
LEFT JOIN `policies` p ON p.`policy_id` = rnp.`policy_id`
LEFT JOIN `users` u ON u.`user_id` = rnp.`configured_by_user_id`;

CREATE OR REPLACE VIEW `v_notification_rules_admin` AS
SELECT
  `rule_id`, `event_key`, `rule_name`, `module_name`, `entity_type`,
  `default_level_notif`, `importance_level`, `required_perm_slug`,
  `target_role_slug`, `target_group_slug`, `target_policy_slug`,
  `default_frequency`, `default_popup_enabled`, `default_inbox_enabled`,
  `default_system_enabled`, `user_configurable`, `admin_configurable`,
  `rule_ui_group`, `recommended_action`, `is_active`, `is_critical_locked`,
  `updated_at`
FROM `notification_rules`;

