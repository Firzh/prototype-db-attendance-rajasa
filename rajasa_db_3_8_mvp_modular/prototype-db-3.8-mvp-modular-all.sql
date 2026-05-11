
-- =========================================================
-- SOURCE MODULE: 000_database_and_version.sql
-- =========================================================

-- =========================================================
-- RAJASA DB 3.8 MVP MODULAR - DATABASE AND VERSION
-- =========================================================
CREATE DATABASE IF NOT EXISTS `sistem_absensi_lab_qr`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `sistem_absensi_lab_qr`;

SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `schema_versions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `version` VARCHAR(30) NOT NULL UNIQUE,
  `name` VARCHAR(150) NOT NULL,
  `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `checksum_sha256` CHAR(64) DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- SOURCE MODULE: 001_access_base.sql
-- =========================================================

-- =========================================================
-- 001 - ACCESS BASE: roles, permissions, policies, groups
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `roles` (

  `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik role. Contoh implementasi: 1=Super Admin, 2=Admin Akademik.',
  `nama_role` VARCHAR(50) NOT NULL COMMENT 'Nama tampilan role. Contoh implementasi: ''Guru Pengawas''.',
  `role_slug` VARCHAR(50) NOT NULL COMMENT 'Slug role untuk pemanggilan sistem/API. Contoh implementasi: ''guru_pengawas''. Umumnya dibentuk dari nama role dengan format huruf kecil dan underscore.',
  `deskripsi` TEXT DEFAULT NULL COMMENT 'Penjelasan fungsi role. Contoh implementasi: ''Memantau jadwal, presensi, dan ujian''. Boleh NULL bila nama role sudah cukup jelas.',
  `is_system` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda role bawaan sistem. Contoh implementasi: 1=bawaan sistem, 0=role kustom.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uk_roles_nama_role` (`nama_role`),
  UNIQUE KEY `uk_roles_role_slug` (`role_slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `permissions` (

  `perm_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik permission. Contoh implementasi: 15 untuk attendance.read.',
  `perm_slug` VARCHAR(100) NOT NULL COMMENT 'Kode izin unik. Contoh implementasi: ''attendance.validate''.',
  `module_name` VARCHAR(50) NOT NULL COMMENT 'Nama modul asal izin. Contoh implementasi: ''attendance''.',
  `action_name` ENUM('read','create','update','delete','write','scan','validate','assign_role','generate','revoke','export','manage','submit','review','archive') NOT NULL DEFAULT 'read' COMMENT 'Aksi pada modul. Nilai dibatasi agar konsisten antar-permission. Contoh implementasi: ''read'', ''write'', ''validate'', ''submit'', atau ''review''.',
  `keterangan` TEXT DEFAULT NULL COMMENT 'Deskripsi izin. Contoh implementasi: ''Memvalidasi data presensi''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`perm_id`),
  UNIQUE KEY `uk_permissions_perm_slug` (`perm_slug`),
  KEY `idx_permissions_module_action` (`module_name`, `action_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `policies` (

  `policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik policy. Contoh implementasi: 1=FullAccess.',
  `policy_name` VARCHAR(100) NOT NULL COMMENT 'Nama tampilan policy untuk admin/developer. Contoh implementasi: ''AcademicAdminAccess'' atau ''TeacherSupervisorAccess''.',
  `policy_slug` VARCHAR(100) NOT NULL COMMENT 'Slug policy untuk referensi sistem/API. Contoh implementasi: ''academic_admin_access''.',
  `policy_type` ENUM('managed','inline') NOT NULL DEFAULT 'managed' COMMENT 'Jenis policy. ''managed'' dipakai untuk policy standar yang dikelola sistem dan dapat dipakai ulang oleh banyak role/user. ''inline'' dipakai untuk policy khusus yang menempel langsung pada role/user tertentu untuk kebutuhan pengecualian atau akses temporer.',
  `deskripsi` TEXT DEFAULT NULL COMMENT 'Penjelasan cakupan policy. Contoh implementasi: ''Akses administrasi akademik dan presensi''. Boleh NULL bila nama policy sudah cukup jelas.',
  `is_system` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda policy bawaan sistem. Contoh implementasi: 1 untuk policy standar.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`policy_id`),
  UNIQUE KEY `uk_policies_name` (`policy_name`),
  UNIQUE KEY `uk_policies_slug` (`policy_slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `policy_permissions` (

  `policy_permission_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi detail policy-permission.',
  `policy_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ke policy. Contoh implementasi: policy FullAccess.',
  `perm_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ke permission. Contoh implementasi: permission ''users.read''.',
  `effect` ENUM('allow','deny') NOT NULL DEFAULT 'allow' COMMENT 'Efek rule. Contoh implementasi: ''allow'' atau ''deny''.',
  `resource_scope` VARCHAR(150) NOT NULL DEFAULT '*' COMMENT 'Cakupan resource. Contoh implementasi: ''*'' untuk semua resource, ''self/*'' untuk data milik sendiri.',
  `conditions_json` JSON DEFAULT NULL COMMENT 'Kondisi tambahan berbentuk JSON. Contoh implementasi: {''jam_mulai'':''07:00'',''hari'':[''senin'',''selasa'']}. Boleh NULL jika rule tidak memerlukan kondisi tambahan.',
  `priority` SMALLINT UNSIGNED NOT NULL DEFAULT 100 COMMENT 'Prioritas evaluasi rule. Contoh implementasi: 1 lebih tinggi dari 100.',
  PRIMARY KEY (`policy_permission_id`),
  UNIQUE KEY `uk_policy_permissions_unique_rule` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`),
  KEY `idx_policy_permissions_perm` (`perm_id`),
  CONSTRAINT `fk_policy_permissions_policy`
    FOREIGN KEY (`policy_id`) REFERENCES `policies`(`policy_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_policy_permissions_permission`
    FOREIGN KEY (`perm_id`) REFERENCES `permissions`(`perm_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_permissions` (

  `role_id` INT UNSIGNED NOT NULL COMMENT 'Referensi role yang memperoleh permission.',
  `perm_id` INT UNSIGNED NOT NULL COMMENT 'Referensi permission pada role.',
  `is_allowed` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Override izin role. Contoh implementasi: 1=diizinkan, 0=ditolak.',
  `resource_scope` VARCHAR(150) NOT NULL DEFAULT '*' COMMENT 'Cakupan resource untuk role. Contoh implementasi: ''*'', ''room/LAB-TKJ-01'', atau ''self/*''. Nilai ini diisi manual oleh admin atau otomatis oleh backend saat membuat rule khusus.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`role_id`, `perm_id`, `resource_scope`),
  KEY `idx_role_permissions_perm` (`perm_id`),
  CONSTRAINT `fk_role_permissions_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_permissions_permission`
    FOREIGN KEY (`perm_id`) REFERENCES `permissions`(`perm_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `groups` (

  `group_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik group user.',
  `group_name` VARCHAR(100) NOT NULL COMMENT 'Nama tampilan group. Contoh implementasi: ''Operator Lab Gedung A''.',
  `group_slug` VARCHAR(100) NOT NULL COMMENT 'Slug group. Contoh implementasi: ''operator_lab_gedung_a''.',
  `deskripsi` TEXT DEFAULT NULL COMMENT 'Penjelasan fungsi group. Boleh NULL bila nama group sudah cukup jelas.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`group_id`),
  UNIQUE KEY `uk_groups_group_name` (`group_name`),
  UNIQUE KEY `uk_groups_group_slug` (`group_slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


ALTER TABLE `roles`
  ADD COLUMN `role_level` SMALLINT UNSIGNED NOT NULL DEFAULT 80 COMMENT 'Hierarki role. Angka lebih kecil berarti wewenang lebih tinggi.' AFTER `role_slug`;

ALTER TABLE `groups`
  ADD COLUMN `group_type` ENUM('generic','student','notification','attendance','import','academic') NOT NULL DEFAULT 'generic' AFTER `group_slug`,
  ADD COLUMN `group_level` SMALLINT UNSIGNED NOT NULL DEFAULT 80 AFTER `group_type`,
  ADD COLUMN `is_system` TINYINT(1) NOT NULL DEFAULT 0 AFTER `group_level`;


-- =========================================================
-- SOURCE MODULE: 002_academic_identity.sql
-- =========================================================

-- =========================================================
-- 002 - ACADEMIC IDENTITY: jurusan, rombel, siswa, penempatan
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `jurusan` (

  `jurusan_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik jurusan. Contoh implementasi: 1=TKJ.',
  `kode_jurusan` VARCHAR(10) NOT NULL COMMENT 'Kode unik jurusan. Contoh implementasi: ''TKJ'', ''RPL'', atau ''MM''.',
  `nama_jurusan` VARCHAR(100) NOT NULL COMMENT 'Nama lengkap jurusan. Contoh implementasi: ''Teknik Komputer dan Jaringan''.',
  `ketua_jurusan` VARCHAR(100) DEFAULT NULL COMMENT 'Nama ketua jurusan. Contoh implementasi: ''Drs. Ahmad''.',
  `deskripsi_jurusan` VARCHAR(255) DEFAULT NULL COMMENT 'Catatan tambahan.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`jurusan_id`),
  UNIQUE KEY `uk_jurusan_kode` (`kode_jurusan`),
  KEY `idx_jurusan_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rombel` (

  `rombel_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik rombongan belajar.',
  `tingkatan` ENUM('X','XI','XII','XIII') NOT NULL COMMENT 'Tingkat kelas internal. Contoh: X untuk input mitra 10.',
  `tingkat_angka` TINYINT UNSIGNED DEFAULT NULL COMMENT 'Angka tingkat dari label mitra: 10, 11, 12, atau 13. Dipakai untuk tampilan UI guru/admin.',
  `jurusan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi jurusan terkait.',
  `nomor_rombel` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Nomor internal rombel. Jika input 10 AKL dan hanya ada satu rombel, simpan 1 secara internal tetapi jangan tampilkan sebagai 10 AKL 1.',
  `is_nomor_rombel_inferred` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 jika nomor_rombel dibuat otomatis karena data mitra tidak menyediakan nomor rombel eksplisit.',
  `label_rombel` VARCHAR(30) DEFAULT NULL COMMENT 'Label tampilan rombel untuk UI. Contoh: 10 AKL. Jangan otomatis menambahkan angka 1 jika hanya ada satu rombel.',
  `label_rombel_raw` VARCHAR(50) DEFAULT NULL COMMENT 'Label kelas/rombel mentah dari sumber import. Contoh: 10 AKL.',
  `display_mode` ENUM('tanpa_nomor','dengan_nomor','custom') NOT NULL DEFAULT 'tanpa_nomor' COMMENT 'Aturan tampilan rombel. Default tanpa_nomor agar 10 AKL tidak tampil sebagai 10 AKL 1.',
  `is_inferred_from_import` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 jika rombel dibuat otomatis dari parser KELAS file mitra.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`rombel_id`),
  UNIQUE KEY `uk_rombel_unique` (`tingkatan`, `jurusan_id`, `nomor_rombel`),
  KEY `idx_rombel_status` (`status`),
  KEY `idx_rombel_display` (`status`, `tingkat_angka`, `label_rombel`),
  CONSTRAINT `chk_rombel_tingkat_angka` CHECK (`tingkat_angka` IS NULL OR `tingkat_angka` IN (10,11,12,13)),
  CONSTRAINT `fk_rombel_jurusan`
    FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `guru_staff` (

  `guru_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik guru/staff.',
  `nip` VARCHAR(20) DEFAULT NULL COMMENT 'Nomor induk pegawai. Contoh implementasi: ''198706102010011001''.',
  `nama_lengkap` VARCHAR(100) NOT NULL COMMENT 'Nama lengkap entitas. Contoh implementasi: ''Budi Santoso''.',
  `no_telp` VARCHAR(20) DEFAULT NULL COMMENT 'Nomor telepon. Contoh implementasi: ''081234567890''.',
  `email` VARCHAR(100) DEFAULT NULL COMMENT 'Alamat email. Contoh implementasi: ''guru@sekolah.sch.id''.',
  `jabatan` VARCHAR(50) DEFAULT NULL COMMENT 'Jabatan pegawai. Contoh implementasi: ''Kepala Lab''.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`guru_id`),
  UNIQUE KEY `uk_guru_staff_nip` (`nip`),
  UNIQUE KEY `uk_guru_staff_email` (`email`),
  KEY `idx_guru_staff_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `siswa` (

  `siswa_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik siswa.',
  `nisn` VARCHAR(20) NOT NULL COMMENT 'Nomor induk siswa nasional. Contoh implementasi: ''0065123456''.',
  `nis` VARCHAR(20) DEFAULT NULL COMMENT 'Nomor induk siswa internal sekolah. Contoh implementasi: ''220145''.',
  `nama_lengkap` VARCHAR(100) NOT NULL COMMENT 'Nama lengkap entitas. Contoh implementasi: ''Budi Santoso''.',
  `jenis_kelamin` ENUM('L','P') NULL COMMENT 'L=Laki-laki, P=Perempuan. DB 3.8 MVP: boleh NULL karena file mitra tidak menyediakan gender.',
  `angkatan` YEAR NULL COMMENT 'Tahun angkatan siswa. DB 3.8 MVP: boleh NULL karena file mitra hanya menyediakan NO, NISN, NAMA, KELAS.',
  `jurusan_id_aktif` INT UNSIGNED DEFAULT NULL COMMENT 'Cache jurusan aktif untuk sorting/filter cepat. Sumber historis tetap mengacu ke penempatan_siswa_rombel atau snapshot transaksi.',
  `rombel_id_aktif` INT UNSIGNED DEFAULT NULL COMMENT 'Cache rombel aktif untuk sorting/filter cepat. Sumber historis tetap mengacu ke penempatan_siswa_rombel.',
  `kelas_aktif` VARCHAR(20) DEFAULT NULL COMMENT 'Cache label kelas aktif untuk UI. Gunakan format familiar guru: 10 AKL, bukan 10 AKL 1.',
  `qr_vendor_link` TEXT DEFAULT NULL COMMENT 'Link URL vendor QR lama/opsional',
  `catatan` VARCHAR(255) DEFAULT NULL COMMENT 'Catatan tambahan.',
  `status` ENUM('aktif','lulus','keluar','mutasi') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`siswa_id`),
  UNIQUE KEY `uk_siswa_nisn` (`nisn`),
  UNIQUE KEY `uk_siswa_nis` (`nis`),
  KEY `idx_siswa_status` (`status`),
  KEY `idx_siswa_sorting` (`status`, `angkatan`, `jurusan_id_aktif`, `kelas_aktif`),
  CONSTRAINT `fk_siswa_jurusan_aktif`
    FOREIGN KEY (`jurusan_id_aktif`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_siswa_rombel_aktif`
    FOREIGN KEY (`rombel_id_aktif`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `profil_siswa` (

  `profil_siswa_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik profil siswa.',
  `siswa_id` INT UNSIGNED NOT NULL COMMENT 'Referensi siswa terkait.',
  `tempat_lahir` VARCHAR(50) DEFAULT NULL COMMENT 'Tempat lahir siswa. Contoh implementasi: ''Surabaya''.',
  `tanggal_lahir` DATE DEFAULT NULL COMMENT 'Tanggal lahir. Contoh implementasi: ''2008-05-14''.',
  `alamat` TEXT DEFAULT NULL COMMENT 'Alamat lengkap. Contoh implementasi: ''Jl. Melati No. 10, Surabaya''.',
  `no_telp` VARCHAR(20) DEFAULT NULL COMMENT 'Nomor telepon. Contoh implementasi: ''081234567890''.',
  `email` VARCHAR(100) DEFAULT NULL COMMENT 'Alamat email. Contoh implementasi: ''guru@sekolah.sch.id''.',
  `rombel` VARCHAR(20) DEFAULT NULL COMMENT 'Field legacy/custom label yang tetap dipertahankan sementara untuk sorting spesifik, kebutuhan ekspor lama, dan snapshot tampilan cepat. Nilai ini bukan relasi utama; sumber relasi akademik tetap rombel_id/penempatan_siswa_rombel. Kandidat untuk dinonaktifkan bertahap bila seluruh ekspor/UI sudah memakai relasi utama.',
  `nama_ortu` VARCHAR(100) DEFAULT NULL COMMENT 'Nama orang tua/wali. Contoh implementasi: ''Slamet Riyadi''.',
  `no_telp_ortu` VARCHAR(20) DEFAULT NULL COMMENT 'Nomor telepon orang tua/wali. Contoh implementasi: ''081298765432''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`profil_siswa_id`),
  UNIQUE KEY `uk_profil_siswa_siswa_id` (`siswa_id`),
  UNIQUE KEY `uk_profil_siswa_email` (`email`),
  CONSTRAINT `fk_profil_siswa_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `siswa_mutasi` (

  `mutasi_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik transaksi mutasi siswa.',
  `siswa_id` INT UNSIGNED NOT NULL COMMENT 'Referensi siswa terkait. Saat mutasi jenis ''masuk'', field ini tetap mengarah ke data siswa yang sudah dibuat lebih dulu agar histori siswa dan akun tetap konsisten.',
  `jenis_mutasi` ENUM('masuk','keluar') NOT NULL COMMENT 'Jenis mutasi siswa. Contoh implementasi: ''masuk'' atau ''keluar''.',
  `tanggal` DATE NOT NULL COMMENT 'Tanggal kejadian/transaksi. Contoh implementasi: ''2026-07-15''.',
  `sekolah_asal_tujuan` VARCHAR(100) DEFAULT NULL COMMENT 'Sekolah asal atau tujuan mutasi. Contoh implementasi: ''SMKN 2 Surabaya''.',
  `alasan` TEXT DEFAULT NULL COMMENT 'Alasan mutasi atau catatan terkait. Contoh implementasi: ''Pindah domisili''.',
  `nomor_surat` VARCHAR(100) DEFAULT NULL COMMENT 'Nomor surat resmi. Contoh implementasi: ''421.3/SMK/2026/045''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`mutasi_id`),
  KEY `idx_siswa_mutasi_siswa_tanggal` (`siswa_id`, `tanggal`),
  KEY `idx_siswa_mutasi_jenis` (`jenis_mutasi`),
  CONSTRAINT `fk_siswa_mutasi_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `penempatan_siswa_rombel` (

  `penempatan_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik riwayat penempatan siswa ke rombel.',
  `siswa_id` INT UNSIGNED NOT NULL COMMENT 'Referensi siswa terkait.',
  `rombel_id` INT UNSIGNED NOT NULL COMMENT 'Referensi rombel terkait.',
  `tahun_ajaran` VARCHAR(9) NOT NULL COMMENT 'Contoh: 2025/2026',
  `semester` ENUM('ganjil','genap','pendek') NOT NULL DEFAULT 'ganjil' COMMENT 'Semester akademik. Contoh implementasi: ''ganjil''.',
  `no_absen` SMALLINT UNSIGNED DEFAULT NULL COMMENT 'Nomor absen siswa di rombel. Contoh implementasi: 17.',
  `tanggal_mulai` DATE DEFAULT NULL COMMENT 'Tanggal mulai berlaku. Contoh implementasi: awal semester atau awal sesi.',
  `tanggal_selesai` DATE DEFAULT NULL COMMENT 'Tanggal selesai berlaku. Contoh implementasi: akhir semester atau akhir event.',
  `is_aktif` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Kolom is_aktif. Contoh implementasi: isi sesuai kebutuhan modul penempatan_siswa_rombel.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`penempatan_id`),
  UNIQUE KEY `uk_penempatan_siswa_rombel` (`siswa_id`, `rombel_id`, `tahun_ajaran`, `semester`),
  KEY `idx_penempatan_rombel_lookup` (`rombel_id`, `tahun_ajaran`, `semester`, `is_aktif`),
  CONSTRAINT `fk_penempatan_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_penempatan_rombel`
    FOREIGN KEY (`rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rombel_wali_kelas` (
  `wali_kelas_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik penugasan wali kelas.',
  `rombel_id` INT UNSIGNED NOT NULL COMMENT 'Referensi rombel yang memiliki wali kelas.',
  `guru_id` INT UNSIGNED NOT NULL COMMENT 'Referensi guru/staff yang menjadi wali kelas.',
  `tahun_ajaran` VARCHAR(9) NOT NULL COMMENT 'Contoh: 2025/2026.',
  `semester` ENUM('ganjil','genap','pendek') NOT NULL DEFAULT 'ganjil' COMMENT 'Semester akademik penugasan wali kelas.',
  `tanggal_mulai` DATE DEFAULT NULL COMMENT 'Tanggal mulai penugasan wali kelas.',
  `tanggal_selesai` DATE DEFAULT NULL COMMENT 'Tanggal selesai penugasan wali kelas.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status penugasan wali kelas.',
  `aktif_unique_key` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `status` = 'aktif' THEN 1 ELSE NULL END) STORED COMMENT 'Kunci bantu agar hanya satu wali kelas aktif per rombel/periode.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`wali_kelas_id`),
  UNIQUE KEY `uk_rombel_wali_kelas_aktif` (`rombel_id`, `tahun_ajaran`, `semester`, `aktif_unique_key`),
  KEY `idx_rombel_wali_kelas_guru` (`guru_id`, `tahun_ajaran`, `semester`, `status`),
  KEY `idx_rombel_wali_kelas_periode` (`tahun_ajaran`, `semester`, `status`),
  CONSTRAINT `fk_rombel_wali_kelas_rombel`
    FOREIGN KEY (`rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rombel_wali_kelas_guru`
    FOREIGN KEY (`guru_id`) REFERENCES `guru_staff`(`guru_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- =========================================================
-- SOURCE MODULE: 003_users_access_runtime.sql
-- =========================================================

-- =========================================================
-- 003 - USERS ACCESS RUNTIME: users, roles relations, sessions
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `users` (

  `user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik akun login.',
  `username` VARCHAR(50) NOT NULL COMMENT 'Username akun login. Contoh implementasi: ''siswa.220145''.',
  `password_hash` VARCHAR(255) NOT NULL COMMENT 'Hash password, bukan password mentah. Contoh implementasi: hasil bcrypt/argon2.',
  `user_type` ENUM('siswa','guru_staff','system') NOT NULL DEFAULT 'system' COMMENT 'Jenis pemilik akun. Contoh implementasi: ''siswa'', ''guru_staff'', atau ''system''.',
  `siswa_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi siswa terkait.',
  `guru_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi guru/staff terkait.',
  `valid_until` DATETIME DEFAULT NULL COMMENT 'Khusus akses sementara seperti intern atau akun tamu',
  `status` ENUM('aktif','nonaktif','terblokir') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `last_login` DATETIME DEFAULT NULL COMMENT 'Waktu login terakhir user. Contoh implementasi: ''2026-04-09 07:21:00''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_users_username` (`username`),
  UNIQUE KEY `uk_users_siswa_id` (`siswa_id`),
  UNIQUE KEY `uk_users_guru_id` (`guru_id`),
  KEY `idx_users_status_type` (`status`, `user_type`),
  CONSTRAINT `fk_users_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_users_guru`
    FOREIGN KEY (`guru_id`) REFERENCES `guru_staff`(`guru_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_roles` (

  `user_role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi user-role.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user yang terkait. Contoh implementasi: user admin yang login atau menerima notifikasi.',
  `role_id` INT UNSIGNED NOT NULL COMMENT 'Referensi role terkait. Contoh implementasi: role ''operator_lab''.',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda relasi aktif. Contoh implementasi: 1=aktif, 0=nonaktif.',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom assigned_at. Contoh implementasi: isi sesuai kebutuhan modul user_roles.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  PRIMARY KEY (`user_role_id`),
  UNIQUE KEY `uk_user_roles_active` (`user_id`, `role_id`),
  KEY `idx_user_roles_role_active` (`role_id`, `is_active`),
  CONSTRAINT `fk_user_roles_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_roles_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_roles_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_permissions` (

  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user yang terkait. Contoh implementasi: user admin yang login atau menerima notifikasi.',
  `perm_id` INT UNSIGNED NOT NULL COMMENT 'Referensi permission terkait.',
  `is_allowed` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda izin diperbolehkan atau ditolak. Contoh implementasi: 1=allow, 0=deny.',
  `resource_scope` VARCHAR(150) NOT NULL DEFAULT '*' COMMENT 'Cakupan resource yang diizinkan. Contoh implementasi: ''*'', ''self/*'', atau ''room/LAB-TKJ-01''.',
  `valid_until` DATETIME DEFAULT NULL COMMENT 'Batas akhir akun/izin berlaku. Contoh implementasi: akun intern aktif sampai ''2026-06-30 23:59:59''.',
  `catatan` VARCHAR(255) DEFAULT NULL COMMENT 'Catatan tambahan. Contoh implementasi: ''Akses sementara untuk supervisi ujian''.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`user_id`, `perm_id`, `resource_scope`),
  KEY `idx_user_permissions_perm` (`perm_id`),
  CONSTRAINT `fk_user_permissions_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_permissions_permission`
    FOREIGN KEY (`perm_id`) REFERENCES `permissions`(`perm_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_permissions_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_policies` (

  `role_policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi role-policy.',
  `role_id` INT UNSIGNED NOT NULL COMMENT 'Referensi role terkait. Contoh implementasi: role ''operator_lab''.',
  `policy_id` INT UNSIGNED NOT NULL COMMENT 'Referensi policy terkait.',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom assigned_at. Contoh implementasi: isi sesuai kebutuhan modul role_policies.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  PRIMARY KEY (`role_policy_id`),
  UNIQUE KEY `uk_role_policies_role_policy` (`role_id`, `policy_id`),
  CONSTRAINT `fk_role_policies_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_policies_policy`
    FOREIGN KEY (`policy_id`) REFERENCES `policies`(`policy_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_policies_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_policies` (

  `user_policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi user-policy.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user yang terkait. Contoh implementasi: user admin yang login atau menerima notifikasi.',
  `policy_id` INT UNSIGNED NOT NULL COMMENT 'Referensi policy terkait.',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom assigned_at. Contoh implementasi: isi sesuai kebutuhan modul user_policies.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  PRIMARY KEY (`user_policy_id`),
  UNIQUE KEY `uk_user_policies_user_policy` (`user_id`, `policy_id`),
  CONSTRAINT `fk_user_policies_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_policies_policy`
    FOREIGN KEY (`policy_id`) REFERENCES `policies`(`policy_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_policies_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `group_users` (

  `group_user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik anggota group.',
  `group_id` INT UNSIGNED NOT NULL COMMENT 'Referensi group terkait.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user yang terkait. Contoh implementasi: user admin yang login atau menerima notifikasi.',
  `added_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom added_at. Contoh implementasi: isi sesuai kebutuhan modul group_users.',
  `added_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user yang menambahkan anggota ke group.',
  PRIMARY KEY (`group_user_id`),
  UNIQUE KEY `uk_group_users_group_user` (`group_id`, `user_id`),
  CONSTRAINT `fk_group_users_group`
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`group_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_users_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_users_added_by`
    FOREIGN KEY (`added_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `group_roles` (

  `group_role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi group-role.',
  `group_id` INT UNSIGNED NOT NULL COMMENT 'Referensi group terkait.',
  `role_id` INT UNSIGNED NOT NULL COMMENT 'Referensi role terkait. Contoh implementasi: role ''operator_lab''.',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom assigned_at. Contoh implementasi: isi sesuai kebutuhan modul group_roles.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  PRIMARY KEY (`group_role_id`),
  UNIQUE KEY `uk_group_roles_group_role` (`group_id`, `role_id`),
  CONSTRAINT `fk_group_roles_group`
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`group_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_roles_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_roles_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `group_policies` (

  `group_policy_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi group-policy.',
  `group_id` INT UNSIGNED NOT NULL COMMENT 'Referensi group terkait.',
  `policy_id` INT UNSIGNED NOT NULL COMMENT 'Referensi policy terkait.',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Kolom assigned_at. Contoh implementasi: isi sesuai kebutuhan modul group_policies.',
  `assigned_by` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi user pemberi assignment. Contoh implementasi: user Super Admin yang menetapkan role/policy.',
  PRIMARY KEY (`group_policy_id`),
  UNIQUE KEY `uk_group_policies_group_policy` (`group_id`, `policy_id`),
  CONSTRAINT `fk_group_policies_group`
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`group_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_policies_policy`
    FOREIGN KEY (`policy_id`) REFERENCES `policies`(`policy_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_group_policies_assigned_by`
    FOREIGN KEY (`assigned_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_sessions` (

  `session_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik sesi login.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user yang terkait. Contoh implementasi: user admin yang login atau menerima notifikasi.',
  `session_token` VARCHAR(255) NOT NULL COMMENT 'JWT/session token',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT 'Alamat IP client/perangkat. Contoh implementasi: ''192.168.1.10''.',
  `user_agent` TEXT DEFAULT NULL COMMENT 'Identitas browser/perangkat. Contoh implementasi: ''Mozilla/5.0 ...''.',
  `logged_in_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu mulai sesi login. Contoh implementasi: ''2026-04-09 07:00:00''.',
  `last_activity` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu aktivitas terakhir pada sesi. Contoh implementasi: ''2026-04-09 07:45:00''.',
  `logout_at` DATETIME DEFAULT NULL COMMENT 'Waktu logout user. Contoh implementasi: ''2026-04-09 08:00:00''.',
  `is_online` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Status sesi masih aktif. Contoh implementasi: 1=online, 0=offline.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`session_id`),
  UNIQUE KEY `uk_user_sessions_token` (`session_token`(191)),
  KEY `idx_user_sessions_user_online` (`user_id`, `is_online`),
  CONSTRAINT `fk_user_sessions_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_access_tokens` (

  `token_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik custom QR/token akses user. Dipakai untuk akun sementara seperti pengawas, intern, atau magang.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi user penerima token akses.',
  `token_reference` VARCHAR(100) NOT NULL COMMENT 'Kode referensi internal token. Contoh: UAT-2026-04-INTERN-001.',
  `token_payload_hash` CHAR(64) NOT NULL COMMENT 'Hash payload QR/token. Payload mentah tidak disimpan sebagai kunci utama.',
  `token_type` ENUM('temporary_login','custom_qr_access','pengawas','intern','magang','other') NOT NULL DEFAULT 'custom_qr_access' COMMENT 'Jenis token akses user.',
  `valid_from` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu mulai token berlaku.',
  `valid_until` DATETIME DEFAULT NULL COMMENT 'Waktu token berakhir. NULL berarti mengikuti valid_until akun user.',
  `max_use_count` INT UNSIGNED DEFAULT NULL COMMENT 'Batas jumlah pemakaian token. NULL berarti tidak dibatasi oleh jumlah pakai.',
  `used_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Jumlah token sudah digunakan.',
  `status` ENUM('aktif','nonaktif','dicabut','kedaluwarsa') NOT NULL DEFAULT 'aktif' COMMENT 'Status token akses user.',
  `issued_by` INT UNSIGNED DEFAULT NULL COMMENT 'User yang menerbitkan token.',
  `revoked_by` INT UNSIGNED DEFAULT NULL COMMENT 'User yang mencabut token.',
  `revoked_at` DATETIME DEFAULT NULL COMMENT 'Waktu token dicabut.',
  `revoked_reason` VARCHAR(255) DEFAULT NULL COMMENT 'Alasan pencabutan token.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis.',
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `uk_user_access_token_reference` (`token_reference`),
  UNIQUE KEY `uk_user_access_token_payload_hash` (`token_payload_hash`),
  KEY `idx_user_access_tokens_user_status` (`user_id`, `status`, `valid_until`),
  KEY `idx_user_access_tokens_type_status` (`token_type`, `status`, `valid_until`),
  CONSTRAINT `fk_user_access_tokens_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_access_tokens_issued_by`
    FOREIGN KEY (`issued_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_user_access_tokens_revoked_by`
    FOREIGN KEY (`revoked_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- =========================================================
-- SOURCE MODULE: 004_facility_schedule_scanner.sql
-- =========================================================

-- =========================================================
-- 004 - FACILITY SCHEDULE SCANNER: ruang, perangkat, plotting, jadwal, scanner
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `master_jenis_ruangan` (

  `kode_jenis_ruangan` VARCHAR(30) NOT NULL COMMENT 'Kode jenis ruangan yang fleksibel dan dapat ditambah tanpa mengubah struktur tabel utama. Contoh implementasi: ''lab'', ''kelas_teori'', ''kantor'', ''perpustakaan'', atau ''studio''.',
  `nama_jenis_ruangan` VARCHAR(100) NOT NULL COMMENT 'Nama tampilan jenis ruangan. Contoh implementasi: ''Laboratorium''.',
  `deskripsi` TEXT DEFAULT NULL COMMENT 'Penjelasan tambahan untuk jenis ruangan. Contoh implementasi: ''Ruangan praktik dengan perangkat komputer''.',
  `is_system` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda jenis ruangan bawaan sistem. Contoh implementasi: 1=bawaan, 0=custom sekolah.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status master jenis ruangan. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`kode_jenis_ruangan`),
  UNIQUE KEY `uk_master_jenis_ruangan_nama` (`nama_jenis_ruangan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ruangan` (

  `ruangan_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik ruangan.',
  `kode_ruangan` VARCHAR(20) NOT NULL COMMENT 'Kode unik ruangan. Contoh implementasi: ''LAB-TKJ-01'' atau ''KLS-RPL-02''.',
  `kapasitas` INT UNSIGNED NOT NULL DEFAULT 30 COMMENT 'Kapasitas maksimum ruangan. Contoh implementasi: 36 siswa.',
  `fasilitas` TEXT DEFAULT NULL COMMENT 'Deskripsi fasilitas ruangan. Contoh implementasi: ''36 PC, projector, AC''.',
  `lokasi` VARCHAR(100) DEFAULT NULL COMMENT 'Lokasi fisik ruangan. Contoh implementasi: ''Gedung A Lantai 2''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`ruangan_id`),
  UNIQUE KEY `uk_ruangan_kode` (`kode_ruangan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `perangkat_esp32` (

  `perangkat_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik perangkat ESP32.',
  `mac_address` VARCHAR(17) NOT NULL COMMENT 'MAC address perangkat. Contoh implementasi: ''A4:CF:12:34:56:78''.',
  `serial_number` VARCHAR(50) DEFAULT NULL COMMENT 'Nomor seri perangkat. Contoh implementasi: ''ESP32-QR-0001''.',
  `device_type` ENUM('esp32','esp32_cam','esp32_qr_scanner') NOT NULL DEFAULT 'esp32_cam' COMMENT 'Tipe perangkat. Contoh implementasi: ''esp32_qr_scanner''.',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT 'Alamat IP client/perangkat. Contoh implementasi: ''192.168.1.10''.',
  `versi_firmware` VARCHAR(20) DEFAULT NULL COMMENT 'Versi firmware/perangkat lunak perangkat. Contoh implementasi: ''1.0.7''.',
  `status_perangkat` ENUM('online','offline','maintenance') NOT NULL DEFAULT 'online' COMMENT 'Status operasional perangkat. Contoh implementasi: ''online''.',
  `last_ping` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu heartbeat terakhir perangkat. Contoh implementasi: ''2026-04-09 08:10:00''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`perangkat_id`),
  UNIQUE KEY `uk_perangkat_mac_address` (`mac_address`),
  UNIQUE KEY `uk_perangkat_serial_number` (`serial_number`),
  KEY `idx_perangkat_status_type` (`status_perangkat`, `device_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ruangan_perangkat` (

  `ruangan_perangkat_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik relasi ruangan-perangkat.',
  `ruangan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ruangan terkait.',
  `perangkat_id` INT UNSIGNED NOT NULL COMMENT 'Referensi perangkat terkait.',
  `fungsi_perangkat` ENUM('scanner_qr','kamera','display','gateway','lainnya') NOT NULL DEFAULT 'scanner_qr' COMMENT 'Peran perangkat di ruangan. Contoh implementasi: ''scanner_qr'' atau ''kamera''.',
  `is_primary` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda perangkat utama/token utama. Contoh implementasi: 1=utama.',
  `mulai_dipakai` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu mulai perangkat dipakai di ruangan. Contoh implementasi: ''2026-01-10 06:30:00''.',
  `selesai_dipakai` DATETIME DEFAULT NULL COMMENT 'Waktu selesai penggunaan relasi. Contoh implementasi: NULL bila masih aktif.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  PRIMARY KEY (`ruangan_perangkat_id`),
  UNIQUE KEY `uk_ruangan_perangkat_active_pair` (`ruangan_id`, `perangkat_id`, `mulai_dipakai`),
  KEY `idx_ruangan_perangkat_lookup` (`ruangan_id`, `status`, `is_primary`),
  CONSTRAINT `fk_ruangan_perangkat_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ruangan_perangkat_perangkat`
    FOREIGN KEY (`perangkat_id`) REFERENCES `perangkat_esp32`(`perangkat_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `plotting_rombel` (

  `plotting_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik plotting rombel ke ruangan.',
  `rombel_id` INT UNSIGNED NOT NULL COMMENT 'Referensi rombel terkait.',
  `ruangan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ruangan terkait.',
  `tahun_ajaran` VARCHAR(9) NOT NULL COMMENT 'Contoh: 2025/2026',
  `semester` ENUM('ganjil','genap','pendek') NOT NULL DEFAULT 'ganjil' COMMENT 'Semester akademik. Contoh implementasi: ''ganjil''.',
  `user_id` INT UNSIGNED DEFAULT NULL COMMENT 'Guru pengawas / penanggung jawab',
  `jam_pulang_default` TIME NOT NULL DEFAULT '15:00:00' COMMENT 'Jam pulang default. Contoh implementasi: ''15:00:00''.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`plotting_id`),
  UNIQUE KEY `uk_plotting_rombel_unique` (`rombel_id`, `ruangan_id`, `tahun_ajaran`, `semester`),
  KEY `idx_plotting_lookup` (`tahun_ajaran`, `semester`, `ruangan_id`, `status`),
  CONSTRAINT `fk_plotting_rombel_rombel`
    FOREIGN KEY (`rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_plotting_rombel_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_plotting_rombel_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `jadwal_lab` (

  `jadwal_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik jadwal lab.',
  `plotting_id` INT UNSIGNED NOT NULL COMMENT 'Referensi plotting rombel terkait.',
  `hari` ENUM('senin','selasa','rabu','kamis','jumat','sabtu','minggu') NOT NULL COMMENT 'Hari pelaksanaan jadwal. Contoh implementasi: ''senin''.',
  `jam_mulai` TIME NOT NULL COMMENT 'Jam mulai jadwal. Contoh implementasi: ''07:00:00''.',
  `jam_selesai` TIME NOT NULL COMMENT 'Jam selesai jadwal. Contoh implementasi: ''09:30:00''.',
  `toleransi_terlambat_menit` SMALLINT UNSIGNED NOT NULL DEFAULT 15 COMMENT 'Batas keterlambatan dalam menit. Contoh implementasi: 15.',
  `qr_checkout_wajib` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Penanda apakah scan pulang wajib. Nilai 1 berarti siswa wajib melakukan scan saat keluar agar status pulang dianggap lengkap. Nilai 0 berarti checkout tidak diwajibkan.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`jadwal_id`),
  UNIQUE KEY `uk_jadwal_lab_unique` (`plotting_id`, `hari`, `jam_mulai`, `jam_selesai`),
  KEY `idx_jadwal_lab_lookup` (`hari`, `jam_mulai`, `status`),
  CONSTRAINT `fk_jadwal_lab_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `scanner_devices` (
  `scanner_device_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik perangkat scanner umum. Dipakai untuk HP, tablet, desktop browser, atau perangkat lain.',
  `device_uuid` CHAR(36) NOT NULL COMMENT 'UUID device dari aplikasi/browser. Untuk web, nilai dapat disimpan di localStorage agar device dikenali ulang.',
  `user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User terakhir/utama yang memakai device. Boleh NULL untuk device yang belum terikat permanen.',
  `device_label` VARCHAR(100) DEFAULT NULL COMMENT 'Label tampilan device. Contoh: HP Pak Budi, Tablet Staff TU.',
  `device_type` ENUM('web_mobile','web_tablet','web_desktop','esp32_cam','other') NOT NULL DEFAULT 'web_mobile' COMMENT 'Tipe device scanner. Untuk alur baru umumnya web_mobile.',
  `browser_name` VARCHAR(100) DEFAULT NULL COMMENT 'Nama browser hasil parsing user agent. Contoh: Chrome Mobile.',
  `browser_version` VARCHAR(50) DEFAULT NULL COMMENT 'Versi browser hasil parsing user agent.',
  `os_name` VARCHAR(100) DEFAULT NULL COMMENT 'Nama OS device. Contoh: Android, iOS, Windows.',
  `user_agent` TEXT DEFAULT NULL COMMENT 'User agent mentah dari request untuk audit teknis.',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT 'IP terakhir yang dipakai device saat scan.',
  `status` ENUM('aktif','nonaktif','blokir') NOT NULL DEFAULT 'aktif' COMMENT 'Status device scanner. Device dengan status blokir tidak boleh memulai sesi scan.',
  `trusted_at` DATETIME DEFAULT NULL COMMENT 'Waktu device ditandai dipercaya oleh admin/sistem. Boleh NULL jika belum memakai mekanisme trusted device.',
  `blocked_reason` VARCHAR(255) DEFAULT NULL COMMENT 'Alasan device diblokir bila status=blokir.',
  `last_used_at` DATETIME DEFAULT NULL COMMENT 'Waktu terakhir device dipakai untuk membuka/melanjutkan sesi scan.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`scanner_device_id`),
  UNIQUE KEY `uk_scanner_devices_uuid` (`device_uuid`),
  KEY `idx_scanner_devices_user_status` (`user_id`, `status`),
  KEY `idx_scanner_devices_type_status` (`device_type`, `status`),
  CONSTRAINT `fk_scanner_devices_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `scanner_sessions` (
  `scanner_session_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik sesi scan web.',
  `session_uuid` CHAR(36) NOT NULL COMMENT 'UUID sesi scan. Dibuat backend saat user membuka halaman scan.',
  `scanner_device_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi device scanner web.',
  `opened_by_user_id` INT UNSIGNED NOT NULL COMMENT 'User yang membuka sesi scan. Umumnya guru, admin, atau staff.',
  `closed_by_user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User yang menutup sesi scan. Boleh NULL jika sesi kedaluwarsa/terputus.',
  `context_type` ENUM('rombel','ruangan','jadwal') NOT NULL DEFAULT 'rombel' COMMENT 'Konteks scan. Untuk opsi A, default rombel.',
  `selected_rombel_id` INT UNSIGNED DEFAULT NULL COMMENT 'Rombel yang dipilih user sebelum scan. Wajib untuk opsi A.',
  `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Ruangan hasil turunan dari plotting_rombel aktif. Wajib diisi backend sebelum scan produktif.',
  `plotting_id` INT UNSIGNED DEFAULT NULL COMMENT 'Plotting aktif yang menjadi dasar relasi rombel ke ruangan.',
  `jadwal_id` INT UNSIGNED DEFAULT NULL COMMENT 'Jadwal terkait bila sesi scan berbasis jadwal lab.',
  `scan_type_default` ENUM('checkin','checkout') NOT NULL DEFAULT 'checkin' COMMENT 'Jenis scan default pada sesi ini.',
  `tanggal` DATE NOT NULL COMMENT 'Tanggal sesi scan.',
  `tahun_ajaran` VARCHAR(9) DEFAULT NULL COMMENT 'Snapshot tahun ajaran saat sesi dibuat. Biasanya dari konfigurasi academic.tahun_ajaran_aktif.',
  `semester` ENUM('ganjil','genap','pendek') DEFAULT NULL COMMENT 'Snapshot semester saat sesi dibuat.',
  `status` ENUM('aktif','dijeda','selesai','dibatalkan','kedaluwarsa','terputus') NOT NULL DEFAULT 'aktif' COMMENT 'Status operasional sesi scan.',
  `ended_reason` ENUM('selesai_normal','user_keluar_halaman','pause_manual','resume_manual','timeout','dibatalkan_user','system_cleanup','lainnya') DEFAULT NULL COMMENT 'Alasan sesi berubah/berakhir. Detail event tetap dapat dicatat di user_activities.',
  `open_unique_key` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `status` IN ('aktif','dijeda','terputus') THEN 1 ELSE NULL END) STORED COMMENT 'Kunci bantu agar user tidak membuka beberapa sesi aktif untuk rombel dan tipe scan yang sama.',
  `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu sesi dimulai.',
  `last_seen_at` DATETIME DEFAULT NULL COMMENT 'Heartbeat terakhir dari halaman scan. Dipakai untuk mendeteksi user keluar/terputus.',
  `paused_at` DATETIME DEFAULT NULL COMMENT 'Waktu sesi dijeda manual oleh user.',
  `resumed_at` DATETIME DEFAULT NULL COMMENT 'Waktu sesi dilanjutkan setelah pause.',
  `ended_at` DATETIME DEFAULT NULL COMMENT 'Waktu sesi selesai/dibatalkan/kedaluwarsa.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`scanner_session_id`),
  UNIQUE KEY `uk_scanner_sessions_uuid` (`session_uuid`),
  UNIQUE KEY `uk_scanner_sessions_open_context` (`opened_by_user_id`, `tanggal`, `selected_rombel_id`, `scan_type_default`, `open_unique_key`),
  KEY `idx_scanner_sessions_user_date` (`opened_by_user_id`, `tanggal`, `status`),
  KEY `idx_scanner_sessions_context` (`context_type`, `selected_rombel_id`, `ruangan_id`, `jadwal_id`, `status`),
  KEY `idx_scanner_sessions_plotting` (`plotting_id`, `tanggal`, `status`),
  CONSTRAINT `fk_scanner_sessions_device`
    FOREIGN KEY (`scanner_device_id`) REFERENCES `scanner_devices`(`scanner_device_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_opened_by`
    FOREIGN KEY (`opened_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_closed_by`
    FOREIGN KEY (`closed_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_rombel`
    FOREIGN KEY (`selected_rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_scanner_sessions_jadwal`
    FOREIGN KEY (`jadwal_id`) REFERENCES `jadwal_lab`(`jadwal_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
-- SOURCE MODULE: 005_files_archive_audit.sql
-- =========================================================

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


-- =========================================================
-- SOURCE MODULE: 006_attendance_qr_online.sql
-- =========================================================

-- =========================================================
-- 006 - ATTENDANCE QR ONLINE: qr token, scan log, presensi, online submission
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `qr_tokens` (

  `qr_token_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik token QR.',
  `siswa_id` INT UNSIGNED NOT NULL COMMENT 'Referensi siswa terkait.',
  `qr_reference` VARCHAR(100) NOT NULL COMMENT 'Kode referensi/slug QR internal untuk tampilan, pencarian, atau cetak. Dapat dibentuk dari nama/NISN agar mudah ditelusuri meskipun payload vendor berupa link dinamis.',
  `qr_payload_hash` CHAR(64) NOT NULL COMMENT 'Hash payload QR, bukan payload mentah. Dipakai untuk mencocokkan QR vendor yang dinamis tanpa menyimpan link sensitif sebagai kunci utama.',
  `qr_vendor_link` TEXT DEFAULT NULL COMMENT 'Link QR dari vendor bila payload memang berupa URL dinamis. Kolom ini disimpan sebagai referensi operasional, sedangkan pencocokan utama tetap dapat memakai hash dan identitas siswa.',
  `qr_version` VARCHAR(20) DEFAULT 'v1' COMMENT 'Versi format QR. Contoh implementasi: ''v1''.',
  `is_primary` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Penanda perangkat utama/token utama. Contoh implementasi: 1=utama.',
  `issued_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu token QR diterbitkan atau dicatat masuk ke sistem. Penting untuk audit, historisasi pergantian QR, dan sinkronisasi dengan vendor dinamis.',
  `expired_at` DATETIME DEFAULT NULL COMMENT 'Waktu token QR berakhir bila sekolah menerapkan masa berlaku internal. Boleh NULL bila QR vendor dianggap aktif terus sampai dicabut.',
  `status` ENUM('aktif','nonaktif','dicabut','kedaluwarsa') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `revoked_reason` VARCHAR(255) DEFAULT NULL COMMENT 'Alasan pencabutan token QR. Contoh implementasi: ''QR bocor, diganti token baru''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`qr_token_id`),
  UNIQUE KEY `uk_qr_tokens_reference` (`qr_reference`),
  UNIQUE KEY `uk_qr_tokens_payload_hash` (`qr_payload_hash`),
  KEY `idx_qr_tokens_siswa_status` (`siswa_id`, `status`, `is_primary`),
  CONSTRAINT `fk_qr_tokens_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `log_scan_qr` (

  `log_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik log scan QR.',
  `scan_uuid` CHAR(36) DEFAULT NULL COMMENT 'UUID unik per kejadian scan. Contoh implementasi: ''550e8400-e29b-41d4-a716-446655440000''.',
  `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi ruangan terkait. DB 3.8 MVP: boleh NULL karena sesi scan dapat memakai lokasi tidak_dicatat/input_manual.',
  `perangkat_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi perangkat terkait.',
  `jadwal_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi jadwal lab terkait.',
  `siswa_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi siswa terkait.',
  `qr_token_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi token QR yang dipakai saat scan.',
  `scanned_payload_hash` CHAR(64) DEFAULT NULL COMMENT 'Hash payload hasil scan saat kejadian. Contoh implementasi: hash QR yang dibaca scanner.',
  `scan_method` ENUM('qr','manual') NOT NULL DEFAULT 'qr' COMMENT 'Metode input scan. Contoh implementasi: ''qr'' otomatis atau ''manual'' oleh operator.',
  `scan_type` ENUM('checkin','checkout','uji_coba','akses') NOT NULL DEFAULT 'checkin' COMMENT 'Jenis scan. Contoh implementasi: ''checkin'', ''checkout'', ''uji_coba'', atau ''akses''.',
  `foto_capture` VARCHAR(255) DEFAULT NULL COMMENT 'Lokasi file foto capture dari ESP32-CAM bila dipakai. Kolom path ini dipertahankan untuk kompatibilitas cepat.',
  `foto_capture_media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi ke media_berkas untuk foto capture scan QR agar arsip dan restore dapat dilacak per file.',
  `status` ENUM(
    'berhasil',
    'qr_tidak_terdaftar',
    'qr_nonaktif',
    'qr_kedaluwarsa',
    'ruangan_tidak_cocok',
    'jadwal_tidak_cocok',
    'duplikat_scan',
    'foto_buram',
    'manual_override',
    'lainnya'
  ) NOT NULL COMMENT 'Status hasil scan QR. Contoh implementasi: ''berhasil'', ''qr_kedaluwarsa'', atau ''manual_override''.',
  `keterangan` TEXT DEFAULT NULL COMMENT 'Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.',
  `tanggal` DATE NOT NULL COMMENT 'Tanggal kejadian/transaksi. Contoh implementasi: ''2026-07-15''.',
  `waktu` TIME NOT NULL COMMENT 'Waktu kejadian. Contoh implementasi: ''07:12:05''.',
  `scanned_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Tanggal dan waktu lengkap scan. Contoh implementasi: ''2026-04-09 07:12:05''.',
  `origin_ip` VARCHAR(45) DEFAULT NULL COMMENT 'IP asal request scan. Contoh implementasi: IP gateway scanner atau server API.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`log_id`),
  UNIQUE KEY `uk_log_scan_qr_uuid` (`scan_uuid`),
  KEY `idx_log_scan_qr_time` (`tanggal`, `waktu`, `ruangan_id`),
  KEY `idx_log_scan_qr_status` (`status`, `scan_type`),
  KEY `idx_log_scan_qr_siswa` (`siswa_id`, `tanggal`),
  CONSTRAINT `fk_log_scan_qr_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_log_scan_qr_perangkat`
    FOREIGN KEY (`perangkat_id`) REFERENCES `perangkat_esp32`(`perangkat_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_log_scan_qr_jadwal`
    FOREIGN KEY (`jadwal_id`) REFERENCES `jadwal_lab`(`jadwal_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_log_scan_qr_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_log_scan_qr_qr_token`
    FOREIGN KEY (`qr_token_id`) REFERENCES `qr_tokens`(`qr_token_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_log_scan_qr_foto_capture_media`
    FOREIGN KEY (`foto_capture_media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi` (

  `presensi_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik data presensi harian.',
  `siswa_id` INT UNSIGNED NOT NULL COMMENT 'Referensi siswa terkait.',
  `ruangan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ruangan terkait.',
  `plotting_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi plotting rombel terkait. Kolom ini sengaja boleh NULL untuk kasus presensi manual, presensi susulan, presensi online yang disinkronkan, atau aktivitas di luar plotting reguler.',
  `jadwal_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi jadwal lab terkait.',
  `tanggal` DATE NOT NULL COMMENT 'Tanggal kejadian/transaksi. Contoh implementasi: ''2026-07-15''.',
  `waktu_masuk` TIME DEFAULT NULL COMMENT 'Jam masuk presensi. Contoh implementasi: ''07:05:00''.',
  `waktu_keluar` TIME DEFAULT NULL COMMENT 'Jam keluar presensi. Contoh implementasi: ''14:55:00''.',
  `waktu_pulang_plan` TIME NOT NULL DEFAULT '15:00:00' COMMENT 'Jam pulang yang direncanakan. Contoh implementasi: ''15:00:00''. Nilai default dapat dioverride dari plotting/jadwal/custom event oleh backend saat record presensi dibuat.',
  `status` ENUM('hadir','terlambat','alpha','izin','sakit') NOT NULL DEFAULT 'alpha' COMMENT 'Status hasil presensi. Contoh implementasi: ''hadir'', ''terlambat'', ''izin'', ''sakit'', atau ''alpha''.',
  `status_checkout` ENUM('belum_checkout','sudah_checkout','pulang_cepat') NOT NULL DEFAULT 'belum_checkout' COMMENT 'Status checkout/pulang. Default ''belum_checkout'' dipakai sampai ada scan keluar atau verifikasi pulang manual.',
  `bukti_izin_sakit` VARCHAR(255) DEFAULT NULL COMMENT 'Lokasi file bukti izin/sakit. Contoh implementasi: ''izin/2026-04-09/surat_dokter_220145.jpg''. Path ini tetap disimpan untuk akses cepat aplikasi lama.',
  `bukti_izin_media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi media_berkas untuk bukti izin/sakit agar file dapat dilacak dan diarsipkan secara formal.',
  `foto_scan_masuk` VARCHAR(255) DEFAULT NULL COMMENT 'Foto saat scan masuk. Contoh implementasi: ''scan_masuk/220145_20260409_070500.jpg''. Path ini dipertahankan untuk kompatibilitas cepat.',
  `foto_scan_masuk_media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi media_berkas untuk foto scan masuk.',
  `foto_scan_keluar` VARCHAR(255) DEFAULT NULL COMMENT 'Foto saat scan keluar. Contoh implementasi: ''scan_keluar/220145_20260409_145500.jpg''. Path ini dipertahankan untuk kompatibilitas cepat.',
  `foto_scan_keluar_media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi media_berkas untuk foto scan keluar.',
  `scan_masuk_log_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi log scan untuk masuk.',
  `scan_keluar_log_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi log scan untuk keluar.',
  `jurusan_snapshot` VARCHAR(50) NOT NULL COMMENT 'Nama jurusan saat presensi diambil',
  `kelas_snapshot` VARCHAR(20) NOT NULL COMMENT 'Label kelas saat presensi diambil',
  `rombel_snapshot` VARCHAR(20) DEFAULT NULL COMMENT 'Label rombel saat presensi diambil',
  `tahun_ajaran_snapshot` VARCHAR(9) DEFAULT NULL COMMENT 'Tahun ajaran saat presensi diambil. Contoh implementasi: ''2025/2026''.',
  `semester_snapshot` ENUM('ganjil','genap','pendek') DEFAULT NULL COMMENT 'Semester saat presensi diambil. Contoh implementasi: ''ganjil''.',
  `validasi` ENUM('valid','tidak_valid','pending') NOT NULL DEFAULT 'valid' COMMENT 'Status validasi data. Contoh implementasi: ''valid'', ''pending'', atau ''tidak_valid''.',
  `diverifikasi_oleh` INT UNSIGNED DEFAULT NULL COMMENT 'User yang memverifikasi data. Contoh implementasi: admin akademik.',
  `waktu_verifikasi` DATETIME DEFAULT NULL COMMENT 'Waktu data diverifikasi. Contoh implementasi: ''2026-04-09 09:00:00''.',
  `keterangan` TEXT DEFAULT NULL COMMENT 'Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`presensi_id`),
  KEY `idx_presensi_tanggal_siswa` (`tanggal`, `siswa_id`),
  KEY `idx_presensi_rekap` (`tanggal`, `ruangan_id`, `status`),
  KEY `idx_presensi_validasi` (`validasi`, `tanggal`),
  CONSTRAINT `fk_presensi_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_jadwal`
    FOREIGN KEY (`jadwal_id`) REFERENCES `jadwal_lab`(`jadwal_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_scan_masuk`
    FOREIGN KEY (`scan_masuk_log_id`) REFERENCES `log_scan_qr`(`log_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_scan_keluar`
    FOREIGN KEY (`scan_keluar_log_id`) REFERENCES `log_scan_qr`(`log_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_bukti_izin_media`
    FOREIGN KEY (`bukti_izin_media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_foto_scan_masuk_media`
    FOREIGN KEY (`foto_scan_masuk_media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_foto_scan_keluar_media`
    FOREIGN KEY (`foto_scan_keluar_media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_diverifikasi_oleh`
    FOREIGN KEY (`diverifikasi_oleh`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_online` (

  `presensi_online_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik pengajuan presensi online.',
  `submission_uuid` CHAR(36) NOT NULL COMMENT 'UUID unik submission agar aman dipakai di sisi client/API.',
  `siswa_id` INT UNSIGNED NOT NULL COMMENT 'Referensi siswa yang mengajukan presensi online.',
  `tanggal_presensi` DATE NOT NULL COMMENT 'Tanggal presensi online yang diajukan.',
  `waktu_submit` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu siswa mengirim bukti presensi online.',
  `plotting_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi plotting rombel bila presensi online masih terkait kelas/rombel reguler.',
  `jadwal_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi jadwal bila presensi online terkait sesi terjadwal.',
  `mode_pembelajaran` ENUM('daring_sinkron','daring_asinkron','tugas_wa','blended','lainnya') NOT NULL DEFAULT 'daring_sinkron' COMMENT 'Mode pembelajaran yang diikuti siswa.',
  `platform_bukti` ENUM('zoom','gmeet','wa','lms','upload_manual','lainnya') NOT NULL DEFAULT 'upload_manual' COMMENT 'Platform utama sumber bukti presensi.',
  `status_pengajuan` ENUM('draft','diajukan','ditinjau','disetujui','ditolak','perlu_perbaikan') NOT NULL DEFAULT 'diajukan' COMMENT 'Status alur pengajuan presensi online.',
  `status_presensi_final` ENUM('hadir','izin','sakit','tugas','alpha') NOT NULL DEFAULT 'hadir' COMMENT 'Keputusan status presensi akhir setelah diverifikasi.',
  `metode_verifikasi` ENUM('manual') NOT NULL DEFAULT 'manual' COMMENT 'Metode verifikasi MVP. AI recognition tidak disertakan pada paket modular ini.',
  `catatan_siswa` TEXT DEFAULT NULL COMMENT 'Catatan dari siswa saat mengirim bukti. Contoh implementasi: ''Mengikuti Zoom dari rumah, lampiran screenshot dan selfie''.',
  `catatan_verifikator` TEXT DEFAULT NULL COMMENT 'Catatan guru/operator saat meninjau pengajuan. Field ini menyimpan snapshot keputusan terakhir untuk akses cepat; histori lengkap tetap dicatat di presensi_online_verifikasi.',
  `diverifikasi_oleh` INT UNSIGNED DEFAULT NULL COMMENT 'User guru/staff yang memverifikasi pengajuan presensi online terakhir. Histori lengkap tetap dicatat di presensi_online_verifikasi.',
  `waktu_verifikasi` DATETIME DEFAULT NULL COMMENT 'Waktu keputusan verifikasi terakhir dibuat. Histori lengkap tetap dicatat di presensi_online_verifikasi.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`presensi_online_id`),
  UNIQUE KEY `uk_presensi_online_submission_uuid` (`submission_uuid`),
  KEY `idx_presensi_online_lookup` (`tanggal_presensi`, `status_pengajuan`, `status_presensi_final`),
  KEY `idx_presensi_online_siswa` (`siswa_id`, `tanggal_presensi`),
  CONSTRAINT `fk_presensi_online_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_online_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_online_jadwal`
    FOREIGN KEY (`jadwal_id`) REFERENCES `jadwal_lab`(`jadwal_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_online_diverifikasi_oleh`
    FOREIGN KEY (`diverifikasi_oleh`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_online_lampiran` (

  `lampiran_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik lampiran bukti presensi online.',
  `presensi_online_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referensi pengajuan presensi online.',
  `media_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referensi metadata file pada media_berkas.',
  `jenis_bukti` ENUM('selfie','screenshot_zoom','screenshot_gmeet','bukti_chat_wa','dokumen_pendukung') NOT NULL COMMENT 'Jenis bukti yang dilampirkan.',
  `is_utama` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Penanda lampiran utama yang paling representatif.',
  `urutan_tampil` SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Urutan tampilan lampiran di UI review.',
  `catatan` VARCHAR(255) DEFAULT NULL COMMENT 'Catatan singkat lampiran. Contoh implementasi: ''Selfie saat kelas dimulai''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`lampiran_id`),
  UNIQUE KEY `uk_presensi_online_lampiran_media` (`presensi_online_id`, `media_id`),
  KEY `idx_presensi_online_lampiran_jenis` (`jenis_bukti`, `is_utama`),
  CONSTRAINT `fk_presensi_online_lampiran_submission`
    FOREIGN KEY (`presensi_online_id`) REFERENCES `presensi_online`(`presensi_online_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_online_lampiran_media`
    FOREIGN KEY (`media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_online_verifikasi` (

  `verifikasi_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik riwayat verifikasi presensi online.',
  `presensi_online_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referensi pengajuan presensi online.',
  `verifikator_user_id` INT UNSIGNED NOT NULL COMMENT 'User guru/staff yang melakukan review.',
  `keputusan` ENUM('ditinjau','disetujui','ditolak','perlu_perbaikan') NOT NULL DEFAULT 'ditinjau' COMMENT 'Keputusan verifikasi untuk submission tertentu.',
  `status_presensi_hasil` ENUM('hadir','izin','sakit','tugas','alpha') NOT NULL DEFAULT 'hadir' COMMENT 'Status presensi hasil review.',
  `catatan_verifikasi` TEXT DEFAULT NULL COMMENT 'Catatan detail review manual. Contoh implementasi: ''Selfie sesuai, screenshot Zoom valid''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`verifikasi_id`),
  KEY `idx_presensi_online_verifikasi_submission` (`presensi_online_id`, `created_at`),
  CONSTRAINT `fk_presensi_online_verifikasi_submission`
    FOREIGN KEY (`presensi_online_id`) REFERENCES `presensi_online`(`presensi_online_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presensi_online_verifikasi_user`
    FOREIGN KEY (`verifikator_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. REVISI LOG SCAN QR UNTUK WEB SCANNER, FLAGGED, DAN IDEMPOTENCY
-- =========================================================
ALTER TABLE `log_scan_qr`
  ADD COLUMN `scanner_device_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi scanner_devices untuk scan via HP/browser.' AFTER `perangkat_id`,
  ADD COLUMN `scanner_session_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi scanner_sessions untuk konteks scan web.' AFTER `scanner_device_id`,
  ADD COLUMN `scanned_by_user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User login yang melakukan scan via website.' AFTER `scanner_session_id`,
  ADD COLUMN `client_request_uuid` CHAR(36) DEFAULT NULL COMMENT 'UUID idempotency dari frontend agar request scan yang terkirim ulang tidak diproses ganda.' AFTER `scan_uuid`,
  ADD COLUMN `scan_source` ENUM('legacy_esp32','web_hp','web_tablet','web_desktop','manual_web','system') NOT NULL DEFAULT 'legacy_esp32' COMMENT 'Sumber kejadian scan. Untuk alur baru umumnya web_hp.' AFTER `scan_method`,
  ADD COLUMN `context_type` ENUM('rombel','ruangan','jadwal','legacy_esp32') NOT NULL DEFAULT 'legacy_esp32' COMMENT 'Konteks scan saat kejadian. Untuk opsi A memakai rombel.' AFTER `scan_type`,
  ADD COLUMN `selected_rombel_id` INT UNSIGNED DEFAULT NULL COMMENT 'Rombel yang dipilih pada halaman scan. Dipakai untuk validasi siswa beda rombel.' AFTER `context_type`,
  ADD COLUMN `actual_rombel_id` INT UNSIGNED DEFAULT NULL COMMENT 'Rombel aktif pemilik QR menurut penempatan_siswa_rombel saat scan.' AFTER `selected_rombel_id`,
  ADD COLUMN `is_flagged` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 jika scan terdeteksi warning, misalnya QR siswa tidak sesuai rombel yang dipilih.' AFTER `actual_rombel_id`,
  ADD COLUMN `flag_reason` ENUM('none','siswa_tidak_sesuai_rombel','qr_dipakai_orang_lain','duplikat_scan','manual_review','lainnya') NOT NULL DEFAULT 'none' COMMENT 'Alasan flag/warning scan.' AFTER `is_flagged`,
  ADD COLUMN `flag_resolution_status` ENUM('tidak_perlu','belum_resolve','resolved','diabaikan') NOT NULL DEFAULT 'tidak_perlu' COMMENT 'Status tindak lanjut flagged scan pada halaman presensi.' AFTER `flag_reason`,
  ADD COLUMN `flagged_actual_siswa_id` INT UNSIGNED DEFAULT NULL COMMENT 'Siswa pelaku sebenarnya bila guru berhasil mencatat nama asli siswa yang memakai kartu orang lain.' AFTER `flag_resolution_status`,
  ADD COLUMN `flag_resolved_by_user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User yang menyelesaikan flagged scan.' AFTER `flagged_actual_siswa_id`,
  ADD COLUMN `flag_resolved_at` DATETIME DEFAULT NULL COMMENT 'Waktu flagged scan diselesaikan.' AFTER `flag_resolved_by_user_id`,
  ADD COLUMN `flag_note` TEXT DEFAULT NULL COMMENT 'Catatan guru/admin saat resolve flagged scan. Contoh: nama siswa yang melakukan kejahilan.' AFTER `flag_resolved_at`;

ALTER TABLE `log_scan_qr`
  MODIFY COLUMN `status` ENUM(
    'berhasil',
    'qr_tidak_terdaftar',
    'qr_nonaktif',
    'qr_kedaluwarsa',
    'ruangan_tidak_cocok',
    'jadwal_tidak_cocok',
    'duplikat_scan',
    'foto_buram',
    'manual_override',
    'akses_ditolak',
    'siswa_tidak_sesuai_rombel',
    'sesi_tidak_aktif',
    'siswa_tidak_aktif',
    'penempatan_tidak_ditemukan',
    'lainnya'
  ) NOT NULL COMMENT 'Status hasil scan QR. Contoh implementasi: berhasil, siswa_tidak_sesuai_rombel, duplikat_scan, atau manual_override.';

ALTER TABLE `log_scan_qr`
  ADD UNIQUE KEY `uk_log_scan_qr_client_request` (`client_request_uuid`),
  ADD KEY `idx_log_scan_qr_scanner_session` (`scanner_session_id`, `tanggal`, `status`),
  ADD KEY `idx_log_scan_qr_scanned_by` (`scanned_by_user_id`, `tanggal`),
  ADD KEY `idx_log_scan_qr_selected_rombel` (`selected_rombel_id`, `tanggal`),
  ADD KEY `idx_log_scan_qr_flagged` (`is_flagged`, `flag_resolution_status`, `tanggal`),
  ADD CONSTRAINT `fk_log_scan_qr_scanner_device`
    FOREIGN KEY (`scanner_device_id`) REFERENCES `scanner_devices`(`scanner_device_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_scanner_session`
    FOREIGN KEY (`scanner_session_id`) REFERENCES `scanner_sessions`(`scanner_session_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_scanned_by_user`
    FOREIGN KEY (`scanned_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_selected_rombel`
    FOREIGN KEY (`selected_rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_actual_rombel`
    FOREIGN KEY (`actual_rombel_id`) REFERENCES `rombel`(`rombel_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_flagged_actual_siswa`
    FOREIGN KEY (`flagged_actual_siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_log_scan_qr_flag_resolved_by`
    FOREIGN KEY (`flag_resolved_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 4. REVISI PRESENSI UNTUK WEB SCANNER DAN ANTI DOUBLE SCAN
-- =========================================================
ALTER TABLE `presensi`
  ADD COLUMN `presensi_source` ENUM('qr_esp32','qr_web','manual','online_sync') NOT NULL DEFAULT 'qr_esp32' COMMENT 'Sumber presensi. Untuk alur HP via website gunakan qr_web.' AFTER `scan_keluar_log_id`,
  ADD COLUMN `scanner_session_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Sesi scanner web yang menghasilkan presensi ini, bila ada.' AFTER `presensi_source`,
  ADD COLUMN `input_by_user_id` INT UNSIGNED DEFAULT NULL COMMENT 'User yang membuat/menginput presensi. Untuk qr_web biasanya guru/admin/staff yang login.' AFTER `scanner_session_id`,
  ADD COLUMN `plotting_key` INT UNSIGNED GENERATED ALWAYS AS (IFNULL(`plotting_id`, 0)) STORED COMMENT 'Generated key agar unique presensi tetap bekerja walau plotting_id NULL.' AFTER `jadwal_id`,
  ADD COLUMN `jadwal_key` INT UNSIGNED GENERATED ALWAYS AS (IFNULL(`jadwal_id`, 0)) STORED COMMENT 'Generated key agar unique presensi tetap bekerja walau jadwal_id NULL.' AFTER `plotting_key`;

ALTER TABLE `presensi`
  ADD UNIQUE KEY `uk_presensi_siswa_sesi_qr` (`siswa_id`, `tanggal`, `ruangan_id`, `plotting_key`, `jadwal_key`),
  ADD KEY `idx_presensi_scanner_session` (`scanner_session_id`, `tanggal`),
  ADD KEY `idx_presensi_source_session` (`presensi_source`, `scanner_session_id`, `tanggal`),
  ADD KEY `idx_presensi_input_by` (`input_by_user_id`, `tanggal`),
  ADD CONSTRAINT `fk_presensi_scanner_session`
    FOREIGN KEY (`scanner_session_id`) REFERENCES `scanner_sessions`(`scanner_session_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_presensi_input_by_user`
    FOREIGN KEY (`input_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE;

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
-- SOURCE MODULE: 007_support_config_buffers.sql
-- =========================================================

-- =========================================================
-- 007 - SUPPORT CONFIG BUFFERS: konfigurasi, legacy notif admin, cache/buffer
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `konfigurasi` (

  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik item konfigurasi.',
  `kunci` VARCHAR(50) NOT NULL COMMENT 'Kunci konfigurasi. Contoh implementasi: ''presensi.toleransi_menit''.',
  `nilai` TEXT DEFAULT NULL COMMENT 'Nilai konfigurasi. Contoh implementasi: ''15'' atau JSON pengaturan.',
  `tipe_nilai` ENUM('string','number','boolean','json','text') NOT NULL DEFAULT 'string' COMMENT 'Tipe data konfigurasi. Contoh implementasi: ''number'' atau ''json''.',
  `keterangan` VARCHAR(255) DEFAULT NULL COMMENT 'Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.',
  `updated_by` INT UNSIGNED DEFAULT NULL COMMENT 'User terakhir yang mengubah data. Contoh implementasi: admin sistem.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_konfigurasi_kunci` (`kunci`),
  CONSTRAINT `fk_konfigurasi_updated_by`
    FOREIGN KEY (`updated_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_manage_buffer` (

  `buffer_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik buffer tampilan manage users.',
  `user_id` INT UNSIGNED NOT NULL COMMENT 'Referensi akun pada tabel users.',
  `username` VARCHAR(50) NOT NULL,
  `nama_lengkap` VARCHAR(100) DEFAULT NULL,
  `nisn` VARCHAR(20) DEFAULT NULL,
  `role_summary` VARCHAR(255) DEFAULT NULL COMMENT 'Gabungan role aktif untuk tampilan ringkas.',
  `primary_role_slug` VARCHAR(50) DEFAULT NULL COMMENT 'Role utama untuk filter cepat.',
  `user_type` ENUM('siswa','guru_staff','system') NOT NULL,
  `jurusan_id` INT UNSIGNED DEFAULT NULL,
  `kode_jurusan` VARCHAR(10) DEFAULT NULL,
  `nama_jurusan` VARCHAR(100) DEFAULT NULL,
  `status` ENUM('aktif','nonaktif','terblokir') NOT NULL DEFAULT 'aktif',
  `valid_until` DATETIME DEFAULT NULL,
  `valid_until_class` ENUM('permanen','aktif_sementara','segera_berakhir','expired') NOT NULL DEFAULT 'permanen' COMMENT 'Klasifikasi valid_until hasil refresh aplikasi/scheduler.',
  `last_login` DATETIME DEFAULT NULL,
  `online_status` ENUM('online','offline') NOT NULL DEFAULT 'offline',
  `last_activity` DATETIME DEFAULT NULL,
  `created_at_source` DATETIME DEFAULT NULL COMMENT 'users.created_at untuk sorting/filter created_at.',
  `updated_at_source` DATETIME DEFAULT NULL COMMENT 'users.updated_at untuk informasi perubahan akun.',
  `synced_at` DATETIME DEFAULT NULL COMMENT 'Waktu terakhir buffer disinkronkan.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`buffer_id`),
  UNIQUE KEY `uk_user_manage_buffer_user` (`user_id`),
  KEY `idx_user_manage_search` (`username`, `nisn`, `nama_lengkap`),
  KEY `idx_user_manage_role_type` (`primary_role_slug`, `user_type`),
  KEY `idx_user_manage_jurusan` (`jurusan_id`, `status`),
  KEY `idx_user_manage_valid` (`valid_until_class`, `valid_until`),
  KEY `idx_user_manage_login` (`last_login`),
  KEY `idx_user_manage_online` (`online_status`, `last_activity`),
  CONSTRAINT `fk_user_manage_buffer_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_manage_buffer_jurusan`
    FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_activity_display_buffer` (

  `buffer_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik buffer tampilan log users.',
  `log_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referensi user_activities.log_id.',
  `user_label` VARCHAR(100) DEFAULT NULL COMMENT 'Nama tampil user untuk kolom User.',
  `username_snapshot` VARCHAR(50) DEFAULT NULL,
  `nisn_snapshot` VARCHAR(20) DEFAULT NULL,
  `role_snapshot` VARCHAR(50) DEFAULT NULL,
  `role_slug_snapshot` VARCHAR(50) DEFAULT NULL,
  `user_type_snapshot` ENUM('siswa','guru_staff','system') DEFAULT NULL,
  `action_type` VARCHAR(50) NOT NULL,
  `module_name` VARCHAR(50) DEFAULT NULL,
  `target_table` VARCHAR(50) DEFAULT NULL,
  `target_id` VARCHAR(100) DEFAULT NULL,
  `status` ENUM('sukses','gagal','peringatan','ditolak','dibatalkan') NOT NULL DEFAULT 'sukses',
  `keterangan_ringkas` VARCHAR(255) DEFAULT NULL COMMENT 'Ringkasan activity_description untuk tabel utama.',
  `ruangan_id` INT UNSIGNED DEFAULT NULL,
  `ruangan_label` VARCHAR(100) DEFAULT NULL COMMENT 'Kode/nama ruangan jika relevan.',
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `browser_device` VARCHAR(150) DEFAULT NULL COMMENT 'Ringkasan user_agent untuk filter audit teknis.',
  `activity_created_at` DATETIME NOT NULL COMMENT 'Timestamp aktivitas dari user_activities.created_at.',
  `archive_status` ENUM('hot','archived') NOT NULL DEFAULT 'hot',
  `synced_at` DATETIME DEFAULT NULL COMMENT 'Waktu terakhir buffer disinkronkan.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`buffer_id`),
  UNIQUE KEY `uk_user_activity_display_log` (`log_id`),
  KEY `idx_user_activity_display_user` (`username_snapshot`, `nisn_snapshot`, `user_label`),
  KEY `idx_user_activity_display_role_type` (`role_slug_snapshot`, `user_type_snapshot`),
  KEY `idx_user_activity_display_action_module` (`action_type`, `module_name`, `activity_created_at`),
  KEY `idx_user_activity_display_status` (`status`, `activity_created_at`),
  KEY `idx_user_activity_display_target` (`target_table`, `target_id`),
  KEY `idx_user_activity_display_ruangan` (`ruangan_id`, `activity_created_at`),
  KEY `idx_user_activity_display_ip` (`ip_address`, `activity_created_at`),
  KEY `idx_user_activity_display_archive` (`archive_status`, `activity_created_at`),
  CONSTRAINT `fk_user_activity_display_log`
    FOREIGN KEY (`log_id`) REFERENCES `user_activities`(`log_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_activity_display_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notifikasi_admin` (

  `notif_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik notifikasi admin.',
  `user_id` INT UNSIGNED DEFAULT NULL COMMENT 'Boleh NULL jika notifikasi broadcast',
  `pesan` TEXT NOT NULL COMMENT 'Isi pesan notifikasi. Contoh implementasi: ''Scan QR gagal di LAB-TKJ-01''.',
  `level_notif` ENUM('info','warning','error','critical') NOT NULL DEFAULT 'info' COMMENT 'Level notifikasi. Contoh implementasi: ''warning'' atau ''critical''.',
  `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi ruangan terkait.',
  `related_log_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi log scan terkait notifikasi.',
  `is_read` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Status baca notifikasi. Contoh implementasi: 0=belum dibaca, 1=sudah dibaca.',
  `read_at` DATETIME DEFAULT NULL COMMENT 'Waktu notifikasi dibaca. Contoh implementasi: ''2026-04-09 08:30:00''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`notif_id`),
  KEY `idx_notifikasi_admin_read` (`user_id`, `is_read`, `created_at`),
  CONSTRAINT `fk_notifikasi_admin_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_admin_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_admin_related_log`
    FOREIGN KEY (`related_log_id`) REFERENCES `log_scan_qr`(`log_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kalender_akademik` (

  `kalender_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik kalender akademik.',
  `tanggal` DATE NOT NULL COMMENT 'Tanggal kejadian/transaksi. Contoh implementasi: ''2026-07-15''.',
  `tanggal_selesai` DATE DEFAULT NULL COMMENT 'Tanggal selesai berlaku. Contoh implementasi: akhir semester atau akhir event.',
  `keterangan` VARCHAR(100) NOT NULL COMMENT 'Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.',
  `tipe` ENUM('libur_nasional','libur_sekolah','event_khusus') NOT NULL DEFAULT 'libur_sekolah' COMMENT 'Jenis item kalender. Contoh implementasi: ''libur_nasional''.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  PRIMARY KEY (`kalender_id`),
  KEY `idx_kalender_akademik_tanggal` (`tanggal`, `tipe`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `jurusan_dashboard_buffer` (

  `buffer_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `jurusan_id` INT UNSIGNED NOT NULL,
  `kode_jurusan` VARCHAR(10) NOT NULL,
  `nama_jurusan` VARCHAR(100) NOT NULL,
  `ketua_jurusan_nama` VARCHAR(100) DEFAULT NULL,
  `guru_id_ketua` INT UNSIGNED DEFAULT NULL,
  `total_siswa` INT UNSIGNED NOT NULL DEFAULT 0,
  `total_ruang_kelas` INT UNSIGNED NOT NULL DEFAULT 0,
  `total_ruang_lab` INT UNSIGNED NOT NULL DEFAULT 0,
  `tahun_ajaran` VARCHAR(9) DEFAULT NULL,
  `semester` ENUM('ganjil','genap','pendek') DEFAULT NULL,
  `status_jurusan` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `sumber_perhitungan` ENUM('otomatis','manual') NOT NULL DEFAULT 'otomatis',
  `last_sync_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`buffer_id`),
  UNIQUE KEY `uk_jurusan_dashboard_buffer` (`jurusan_id`, `tahun_ajaran`, `semester`),
  KEY `idx_jurusan_dashboard_status` (`status_jurusan`),
  CONSTRAINT `fk_jurusan_dashboard_buffer_jurusan`
    FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_jurusan_dashboard_buffer_guru`
    FOREIGN KEY (`guru_id_ketua`) REFERENCES `guru_staff`(`guru_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `jurusan_ruangan_buffer` (

  `buffer_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `jurusan_id` INT UNSIGNED NOT NULL,
  `ruangan_id` INT UNSIGNED NOT NULL,
  `jenis_ruangan` ENUM('kelas','lab','kantor') NOT NULL DEFAULT 'kelas',
  `nama_ruangan` VARCHAR(100) NOT NULL COMMENT 'Nama ruangan. Contoh implementasi: ''Lab TKJ 1''.',
  `urut_auto` SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Contoh implementasi: ''Lab TKJ 1,''Lab KJ 2''.',
  `status` ENUM('aktif','nonaktif','maintenance') NOT NULL DEFAULT 'aktif',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`buffer_id`),
  UNIQUE KEY `uk_jurusan_ruangan` (`jurusan_id`,`nama_ruangan`),
  CONSTRAINT `fk_buffer_jurusan` FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_buffer_ruangan` FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `presensi_snapshot_buffer` (
--
--   `snapshot_buffer_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
--   `plotting_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi plotting jika context berasal dari plotting reguler.',
--   `ruangan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi ruangan context.',
--   `jurusan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi jurusan context bila tersedia.',
--   `jurusan_snapshot` VARCHAR(100) DEFAULT NULL COMMENT 'Nama jurusan hasil snapshot/buffer.',
--   `kelas_snapshot` VARCHAR(20) DEFAULT NULL COMMENT 'Kelas hasil snapshot/buffer.',
--   `rombel_snapshot` VARCHAR(30) DEFAULT NULL COMMENT 'Rombel hasil snapshot/buffer.',
--   `tahun_ajaran_snapshot` VARCHAR(9) DEFAULT NULL COMMENT 'Tahun ajaran hasil snapshot/buffer.',
--   `semester_snapshot` ENUM('ganjil','genap','pendek') DEFAULT NULL COMMENT 'Semester hasil snapshot/buffer.',
--   `sumber_context` ENUM('plotting','manual','sinkron_online','custom_event') NOT NULL DEFAULT 'plotting',
--   `signature_hash` CHAR(64) DEFAULT NULL COMMENT 'Hash kombinasi context agar snapshot identik bisa dipakai ulang.',
--   `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
--   `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--
--   PRIMARY KEY (`snapshot_buffer_id`),
--   UNIQUE KEY `uk_presensi_snapshot_signature` (`signature_hash`),
--   KEY `idx_presensi_snapshot_lookup` (`plotting_id`,`ruangan_id`,`tahun_ajaran_snapshot`,`semester_snapshot`),
--
--   CONSTRAINT `fk_presensi_snapshot_plotting`
--     FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
--     ON DELETE SET NULL ON UPDATE CASCADE,
--
--   CONSTRAINT `fk_presensi_snapshot_ruangan`
--     FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
--     ON DELETE SET NULL ON UPDATE CASCADE,
--
--   CONSTRAINT `fk_presensi_snapshot_jurusan`
--     FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
--     ON DELETE SET NULL ON UPDATE CASCADE
--
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_ui_preferences` (
  `preference_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `theme_mode` ENUM('light','dark','system') NOT NULL DEFAULT 'system',
  `sidebar_collapsed` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`preference_id`),
  UNIQUE KEY `uk_user_ui_preferences_user` (`user_id`),
  CONSTRAINT `fk_user_ui_preferences_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- =========================================================
-- SOURCE MODULE: 008_import_wizard.sql
-- =========================================================

-- =========================================================
-- 008 - IMPORT WIZARD: import jobs, mappings, row logs
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE IF NOT EXISTS `import_jobs` (
  `import_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik proses import.',
  `import_code` VARCHAR(40) NOT NULL COMMENT 'Kode import untuk audit/UI. Contoh: IMP-20260430-0001.',
  `import_type` ENUM('master_siswa','siswa_penempatan_rombel','update_penempatan_rombel') NOT NULL COMMENT 'Jenis import yang diproses sistem.',
  `detected_type` ENUM('master_siswa','siswa_penempatan_rombel','update_penempatan_rombel','unknown') NOT NULL DEFAULT 'unknown' COMMENT 'Jenis data hasil deteksi parser.',
  `source_contract_version` VARCHAR(30) DEFAULT 'mitra-minimal-v1' COMMENT 'Kontrak sumber import. mitra-minimal-v1 berarti NO, NISN, NAMA, KELAS.',
  `detection_confidence` DECIMAL(5,2) DEFAULT NULL COMMENT 'Skor keyakinan parser 0-100.',
  `parser_engine` ENUM('openspout','fastexcelreader','papaparse','read_excel_file','manual','other') NOT NULL DEFAULT 'openspout' COMMENT 'Engine parser yang dipakai. Backend disarankan memakai openspout/fastexcelreader.',
  `original_filename` VARCHAR(255) NOT NULL COMMENT 'Nama file asli dari operator/admin.',
  `file_media_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Referensi media_berkas jika file import disimpan sebagai arsip.',
  `mime_type` VARCHAR(100) DEFAULT NULL,
  `file_size_bytes` BIGINT UNSIGNED DEFAULT NULL,
  `sheet_name` VARCHAR(100) DEFAULT NULL COMMENT 'Nama sheet aktif bila file XLSX memiliki banyak sheet.',
  `tahun_ajaran` VARCHAR(9) DEFAULT NULL COMMENT 'Periode akademik hasil deteksi/default aktif.',
  `semester` ENUM('ganjil','genap','pendek') DEFAULT NULL COMMENT 'Semester hasil deteksi/default aktif.',
  `status` ENUM('uploaded','detected','mapped','validated','processing','success','partial_failed','failed','cancelled') NOT NULL DEFAULT 'uploaded',
  `total_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `valid_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `warning_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `error_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `inserted_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `updated_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `skipped_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `options_json` JSON DEFAULT NULL COMMENT 'Opsi import. Contoh: mode pindah rombel, import valid saja, auto-create akun siswa.',
  `use_no_as_absen` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Default 0. Kolom NO dari file mitra adalah nomor urut sumber, bukan nomor absen, kecuali admin mengaktifkan opsi ini.',
  `kelas_display_mode` ENUM('tanpa_nomor','dengan_nomor','raw') NOT NULL DEFAULT 'tanpa_nomor' COMMENT 'Aturan display hasil parser KELAS. Default tanpa_nomor: 10 AKL tetap 10 AKL.',
  `error_summary` TEXT DEFAULT NULL COMMENT 'Ringkasan error untuk tampilan akhir import.',
  `created_by` INT UNSIGNED DEFAULT NULL COMMENT 'User operator/admin yang menjalankan import.',
  `started_at` DATETIME DEFAULT NULL,
  `finished_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`import_id`),
  UNIQUE KEY `uk_import_jobs_code` (`import_code`),
  KEY `idx_import_jobs_status` (`status`, `created_at`),
  KEY `idx_import_jobs_type_period` (`import_type`, `tahun_ajaran`, `semester`),
  KEY `idx_import_jobs_created_by` (`created_by`, `created_at`),
  CONSTRAINT `fk_import_jobs_media`
    FOREIGN KEY (`file_media_id`) REFERENCES `media_berkas`(`media_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_import_jobs_created_by`
    FOREIGN KEY (`created_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_import_jobs_confidence`
    CHECK (`detection_confidence` IS NULL OR (`detection_confidence` >= 0 AND `detection_confidence` <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `import_column_mappings` (
  `mapping_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `import_id` BIGINT UNSIGNED NOT NULL,
  `source_column_index` SMALLINT UNSIGNED NOT NULL COMMENT 'Urutan kolom pada file, mulai 1.',
  `source_column_name` VARCHAR(150) NOT NULL COMMENT 'Header asli dari file.',
  `sample_value` VARCHAR(255) DEFAULT NULL COMMENT 'Contoh isi dari beberapa baris awal untuk UI mapping.',
  `target_field` VARCHAR(120) DEFAULT NULL COMMENT 'Field sistem. Contoh: siswa.nisn, siswa.nama_lengkap, penempatan_siswa_rombel.no_absen.',
  `confidence` DECIMAL(5,2) DEFAULT NULL COMMENT 'Skor keyakinan auto-mapping 0-100.',
  `is_required` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Apakah field target wajib untuk jenis import ini.',
  `is_confirmed` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Apakah mapping sudah dikonfirmasi operator/admin.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`mapping_id`),
  UNIQUE KEY `uk_import_mapping_column` (`import_id`, `source_column_index`),
  KEY `idx_import_mapping_target` (`import_id`, `target_field`),
  CONSTRAINT `fk_import_mappings_job`
    FOREIGN KEY (`import_id`) REFERENCES `import_jobs`(`import_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_import_mapping_confidence`
    CHECK (`confidence` IS NULL OR (`confidence` >= 0 AND `confidence` <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `import_row_logs` (
  `row_log_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `import_id` BIGINT UNSIGNED NOT NULL,
  `row_number` INT UNSIGNED NOT NULL COMMENT 'Nomor baris pada file asli.',
  `row_status` ENUM('valid','warning','error','skipped','imported') NOT NULL DEFAULT 'valid',
  `message` TEXT DEFAULT NULL COMMENT 'Pesan validasi/error. Contoh: NISN kosong, kode jurusan tidak ditemukan.',
  `source_data_json` JSON DEFAULT NULL COMMENT 'Data mentah baris import setelah parser membaca file.',
  `normalized_data_json` JSON DEFAULT NULL COMMENT 'Data hasil normalisasi sebelum insert/update.',
  `target_table` VARCHAR(80) DEFAULT NULL COMMENT 'Tabel target jika baris berhasil diproses.',
  `target_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'ID target jika baris berhasil diproses.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`row_log_id`),
  KEY `idx_import_row_logs_import_status` (`import_id`, `row_status`, `row_number`),
  CONSTRAINT `fk_import_row_logs_job`
    FOREIGN KEY (`import_id`) REFERENCES `import_jobs`(`import_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- =========================================================
-- SOURCE MODULE: 009_notification_lite.sql
-- =========================================================

-- =========================================================
-- 009 - NOTIFICATION LITE: in-app/system only
-- Generated for Rajasa DB 3.8 MVP Modular
-- Source: prototype-db-3.8.sql
-- Notes: future modules removed: AI recognition, ujian, nilai, external notification channels.
-- =========================================================

USE `sistem_absensi_lab_qr`;

CREATE TABLE `notification_rules` (
  `rule_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_key` VARCHAR(100) NOT NULL COMMENT 'Kode event unik. Contoh: student_import_partial_failed.',
  `rule_name` VARCHAR(150) NOT NULL COMMENT 'Nama rule untuk UI admin.',
  `module_name` VARCHAR(50) NOT NULL COMMENT 'Modul pemilik notifikasi. Contoh: academic, students, attendance, import.',
  `entity_type` VARCHAR(50) DEFAULT NULL COMMENT 'Tipe entity terkait. Contoh: import_jobs.',
  `default_level_notif` ENUM('info','warning','error','critical') NOT NULL DEFAULT 'info',
  `importance_level` ENUM('optional','required','urgent','critical') NOT NULL DEFAULT 'optional',
  `required_perm_slug` VARCHAR(100) DEFAULT NULL COMMENT 'Permission minimal agar user menjadi target notifikasi.',
  `target_role_slug` VARCHAR(50) DEFAULT NULL COMMENT 'Role default target bila rule berbasis role.',
  `target_group_slug` VARCHAR(100) DEFAULT NULL COMMENT 'Group default target bila rule berbasis group.',
  `target_policy_slug` VARCHAR(100) DEFAULT NULL COMMENT 'Policy default target bila rule berbasis policy.',
  `default_frequency` ENUM('instant','daily','weekly','manual') NOT NULL DEFAULT 'instant',
  `default_popup_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `default_inbox_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `default_system_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `user_configurable` TINYINT(1) NOT NULL DEFAULT 1,
  `admin_configurable` TINYINT(1) NOT NULL DEFAULT 1,
  `rule_ui_group` VARCHAR(80) DEFAULT NULL,
  `recommended_action` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_critical_locked` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Jika 1, user preference tidak boleh mematikan notifikasi ini.',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`rule_id`),
  UNIQUE KEY `uk_notification_rules_event` (`event_key`),
  KEY `idx_notification_rules_module` (`module_name`, `is_active`),
  KEY `idx_notification_rules_importance` (`importance_level`, `is_active`),
  KEY `idx_notification_rules_perm` (`required_perm_slug`),
  KEY `idx_notification_rules_role` (`target_role_slug`),
  KEY `idx_notification_rules_group` (`target_group_slug`),
  KEY `idx_notification_rules_policy` (`target_policy_slug`),
  CONSTRAINT `fk_notification_rules_permission`
    FOREIGN KEY (`required_perm_slug`) REFERENCES `permissions`(`perm_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notification_rules_role`
    FOREIGN KEY (`target_role_slug`) REFERENCES `roles`(`role_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notification_rules_group`
    FOREIGN KEY (`target_group_slug`) REFERENCES `groups`(`group_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notification_rules_policy`
    FOREIGN KEY (`target_policy_slug`) REFERENCES `policies`(`policy_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notification_rules_created_by`
    FOREIGN KEY (`created_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notifikasi` (
  `notif_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `rule_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi rule yang memicu notifikasi.',
  `event_key` VARCHAR(100) NOT NULL,
  `module_name` VARCHAR(50) NOT NULL,
  `entity_type` VARCHAR(50) DEFAULT NULL,
  `entity_id` BIGINT UNSIGNED DEFAULT NULL,
  `dedupe_key` VARCHAR(180) DEFAULT NULL COMMENT 'Kunci untuk mencegah spam notifikasi event yang sama.',
  `pesan` TEXT NOT NULL,
  `level_notif` ENUM('info','warning','error','critical') NOT NULL DEFAULT 'info',
  `importance_level` ENUM('optional','required','urgent','critical') NOT NULL DEFAULT 'optional',
  `required_perm_slug` VARCHAR(100) DEFAULT NULL,
  `target_role_slug` VARCHAR(50) DEFAULT NULL,
  `target_group_slug` VARCHAR(100) DEFAULT NULL,
  `target_policy_slug` VARCHAR(100) DEFAULT NULL,
  `action_label` VARCHAR(80) DEFAULT NULL,
  `action_url` VARCHAR(255) DEFAULT NULL,
  `frequency` ENUM('instant','daily','weekly','manual') NOT NULL DEFAULT 'instant',
  `resolution_type` ENUM('auto','manual') NOT NULL DEFAULT 'auto',
  `is_resolved` TINYINT(1) NOT NULL DEFAULT 0,
  `open_unique_key` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `is_resolved` = 0 AND `dedupe_key` IS NOT NULL THEN 1 ELSE NULL END) STORED,
  `resolved_at` DATETIME DEFAULT NULL,
  `resolved_by` INT UNSIGNED DEFAULT NULL,
  `metadata_json` JSON DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`notif_id`),
  UNIQUE KEY `uk_notifikasi_dedupe_open` (`dedupe_key`, `open_unique_key`),
  KEY `idx_notifikasi_module` (`module_name`, `event_key`),
  KEY `idx_notifikasi_resolved` (`is_resolved`, `created_at`),
  KEY `idx_notifikasi_entity` (`entity_type`, `entity_id`),
  KEY `idx_notifikasi_perm` (`required_perm_slug`),
  CONSTRAINT `fk_notifikasi_rule`
    FOREIGN KEY (`rule_id`) REFERENCES `notification_rules`(`rule_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_permission`
    FOREIGN KEY (`required_perm_slug`) REFERENCES `permissions`(`perm_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_target_role`
    FOREIGN KEY (`target_role_slug`) REFERENCES `roles`(`role_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_target_group`
    FOREIGN KEY (`target_group_slug`) REFERENCES `groups`(`group_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_target_policy`
    FOREIGN KEY (`target_policy_slug`) REFERENCES `policies`(`policy_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_resolved_by`
    FOREIGN KEY (`resolved_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notifikasi_penerima` (
  `recipient_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `notif_id` BIGINT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `delivery_channel` ENUM('in_app','system') NOT NULL DEFAULT 'in_app',
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `read_at` DATETIME DEFAULT NULL,
  `delivered_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`recipient_id`),
  UNIQUE KEY `uk_notifikasi_penerima_user` (`notif_id`, `user_id`, `delivery_channel`),
  KEY `idx_notifikasi_penerima_inbox` (`user_id`, `is_read`, `created_at`),
  CONSTRAINT `fk_notifikasi_penerima_notif`
    FOREIGN KEY (`notif_id`) REFERENCES `notifikasi`(`notif_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_notifikasi_penerima_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_notification_preferences` (
  `preference_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `module_name` VARCHAR(50) NOT NULL,
  `event_key` VARCHAR(100) DEFAULT NULL,
  `frequency` ENUM('instant','daily','weekly','off') NOT NULL DEFAULT 'instant',
  `popup_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `inbox_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `system_enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `is_muted` TINYINT(1) NOT NULL DEFAULT 0,
  `configured_by_user_id` INT UNSIGNED DEFAULT NULL,
  `configuration_source` ENUM('self','admin','system','role_default','group_default','policy_default') NOT NULL DEFAULT 'self',
  `is_admin_enforced` TINYINT(1) NOT NULL DEFAULT 0,
  `admin_note` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`preference_id`),
  UNIQUE KEY `uk_user_notification_pref` (`user_id`, `module_name`, `event_key`),
  KEY `idx_user_notification_pref_module` (`module_name`, `event_key`),
  KEY `idx_user_notification_pref_configured_by` (`configured_by_user_id`),
  CONSTRAINT `fk_user_notification_pref_user`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_notification_pref_configured_by`
    FOREIGN KEY (`configured_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `role_notification_preferences` (
  `role_notification_pref_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `principal_type` ENUM('role','group','policy','permission','custom') NOT NULL DEFAULT 'role',
  `principal_key` VARCHAR(150) NOT NULL,
  `role_id` INT UNSIGNED DEFAULT NULL,
  `group_id` INT UNSIGNED DEFAULT NULL,
  `policy_id` INT UNSIGNED DEFAULT NULL,
  `required_perm_slug` VARCHAR(100) DEFAULT NULL,
  `module_name` VARCHAR(50) NOT NULL,
  `event_key` VARCHAR(100) DEFAULT NULL,
  `event_key_key` VARCHAR(100) GENERATED ALWAYS AS (IFNULL(`event_key`, '*')) STORED,
  `frequency` ENUM('inherit','instant','daily','weekly','off') NOT NULL DEFAULT 'inherit',
  `popup_enabled` TINYINT(1) DEFAULT NULL,
  `inbox_enabled` TINYINT(1) DEFAULT NULL,
  `system_enabled` TINYINT(1) DEFAULT NULL,
  `is_muted` TINYINT(1) NOT NULL DEFAULT 0,
  `is_enforced` TINYINT(1) NOT NULL DEFAULT 0,
  `priority` SMALLINT UNSIGNED NOT NULL DEFAULT 100,
  `conditions_json` JSON DEFAULT NULL,
  `configured_by_user_id` INT UNSIGNED DEFAULT NULL,
  `admin_note` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_notification_pref_id`),
  UNIQUE KEY `uk_role_notification_pref` (`principal_type`, `principal_key`, `module_name`, `event_key_key`),
  KEY `idx_role_notification_pref_role` (`role_id`),
  KEY `idx_role_notification_pref_group` (`group_id`),
  KEY `idx_role_notification_pref_policy` (`policy_id`),
  KEY `idx_role_notification_pref_permission` (`required_perm_slug`),
  KEY `idx_role_notification_pref_module` (`module_name`, `event_key`, `priority`),
  KEY `idx_role_notification_pref_configured_by` (`configured_by_user_id`),
  CONSTRAINT `fk_role_notification_pref_role`
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_notification_pref_group`
    FOREIGN KEY (`group_id`) REFERENCES `groups`(`group_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_notification_pref_policy`
    FOREIGN KEY (`policy_id`) REFERENCES `policies`(`policy_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_notification_pref_permission`
    FOREIGN KEY (`required_perm_slug`) REFERENCES `permissions`(`perm_slug`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_role_notification_pref_configured_by`
    FOREIGN KEY (`configured_by_user_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_role_notification_pref_principal_ref`
    CHECK (
      (`principal_type`='role' AND `role_id` IS NOT NULL)
      OR (`principal_type`='group' AND `group_id` IS NOT NULL)
      OR (`principal_type`='policy' AND `policy_id` IS NOT NULL)
      OR (`principal_type`='permission' AND `required_perm_slug` IS NOT NULL)
      OR (`principal_type`='custom')
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- =========================================================
-- SOURCE MODULE: 010_seed_minimal_mvp.sql
-- =========================================================

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
  ('plotting.max_rombel_per_ruang_kelas', '2', 'number', 'Batas maksimal rombel aktif pada satu ruangan jenis kelas per tahun ajaran/semester.'),
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


-- =========================================================
-- SOURCE MODULE: 011_views_mvp.sql
-- =========================================================

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

