-- =========================================================
-- DATABASE: sistem_absensi_lab_qr
-- VERSI   : 3.3
-- FOKUS   : Absensi lab berbasis QR code, manage users, user activities, dan cold archive
-- ENGINE  : MySQL 8+
-- =========================================================

-- ---------------------------------------------------------
-- CATATAN DESAIN PENTING
-- 1) Field/tabel berjejak RFID tidak dipakai lagi sebagai sumber utama.
--    Fungsinya diganti oleh tabel qr_tokens dan log_scan_qr.
-- 2) siswa_transfer_masuk dan siswa_transfer_keluar digabung menjadi siswa_mutasi
--    agar tidak ada duplikasi data. View kompatibilitas tetap disediakan.
-- 3) Relasi ruangan -> perangkat tidak lagi ditaruh langsung pada satu field di tabel ruangan,
--    karena satu ruangan bisa memiliki beberapa perangkat dan perangkat bisa diganti.
--    Untuk itu dipakai tabel buffer ruangan_perangkat.
-- 4) Sistem hak akses dibuat hybrid:
--    - tetap ada roles, permissions, role_permissions, user_permissions (kompatibel)
--    - ditambah policy-based access ala AWS-like untuk skala besar.
-- 5) Beberapa field snapshot dan field teks legacy tetap dipertahankan karena berguna untuk
--    sorting spesifik, filter custom, riwayat historis, dan kompatibilitas laporan.
-- 6) Pengelolaan berkas dan arsip tidak hanya dilakukan di backend PHP. Metadata file, batch arsip,
--    dan detail arsip dicatat di tabel khusus agar proses audit, restore, dan retention period
--    dapat dilacak langsung dari database.
-- 7) Beberapa pasangan field path file + media_id sengaja dipertahankan sebagai dual-reference:
--    path dipakai untuk akses cepat/kompatibilitas lama, media_id dipakai untuk arsip, audit, dan restore.
-- 8) admin_activities pada versi 3.2 diganti menjadi user_activities pada versi 3.3.
--    Audit log tidak hanya mencatat admin, tetapi juga operator, guru/staff, siswa, intern,
--    magang, pengawas, dan akun system.
-- 9) user_manage_buffer dan user_activity_display_buffer disiapkan sebagai cache tampilan.
--    Source of truth tetap users, user_roles, roles, siswa, guru_staff, dan user_activities.
-- 10) Cold archive user_activities dilakukan bulanan oleh scheduler aplikasi/cron.
--     Database menyimpan metadata archive, path file hasil kompres, checksum, status verifikasi,
--     dan relasi ke arsip_batch/media_berkas.
-- 11) user_access_tokens disiapkan untuk custom QR akses akun sementara. Ini berbeda dari
--     qr_tokens/log_scan_qr yang dipakai untuk scan presensi/ruangan siswa.
-- ---------------------------------------------------------

CREATE DATABASE IF NOT EXISTS `sistem_absensi_lab_qr`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `sistem_absensi_lab_qr`;

-- =========================================================
-- 1. IAM / ACCESS CONTROL (AWS-LIKE + COMPATIBLE)
-- =========================================================

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

-- Kompatibel dengan 2.4-fixed, tetapi ditambah resource_scope
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

-- =========================================================
-- 2. MASTER AKADEMIK & IDENTITAS
-- =========================================================

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
  `tingkatan` ENUM('X','XI','XII','XIII') NOT NULL COMMENT 'Tingkat kelas. Contoh implementasi: ''XII''.',
  `jurusan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi jurusan terkait.',
  `nomor_rombel` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Nomor urut rombel dalam kombinasi tingkatan dan jurusan. Contoh implementasi: 1 untuk TKJ-1.',
  `label_rombel` VARCHAR(30) DEFAULT NULL COMMENT 'Buffer label custom/sorting. Contoh implementasi: ''XII-TKJ-1''. Nilai dapat dibentuk backend dari tingkatan, jurusan, dan nomor rombel.',
  `status` ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`rombel_id`),
  UNIQUE KEY `uk_rombel_unique` (`tingkatan`, `jurusan_id`, `nomor_rombel`),
  KEY `idx_rombel_status` (`status`),
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
  `jenis_kelamin` ENUM('L','P') NOT NULL COMMENT 'L=Laki-laki, P=Perempuan',
  `angkatan` YEAR NOT NULL COMMENT 'Tahun angkatan siswa. Contoh implementasi: 2024.',
  `jurusan_id_aktif` INT UNSIGNED DEFAULT NULL COMMENT 'Cache jurusan aktif untuk sorting/filter cepat. Sumber historis tetap mengacu ke penempatan_siswa_rombel atau snapshot transaksi.',
  `rombel_id_aktif` INT UNSIGNED DEFAULT NULL COMMENT 'Cache rombel aktif untuk sorting/filter cepat. Sumber historis tetap mengacu ke penempatan_siswa_rombel.',
  `kelas_aktif` VARCHAR(20) DEFAULT NULL COMMENT 'Cache label kelas aktif untuk sorting/filter cepat. Kandidat tetap dipertahankan selama UI masih membutuhkan akses cepat tanpa join.',
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

-- =========================================================
-- 3. USER LOGIN / AKUN
-- =========================================================

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
-- 4. PERANGKAT, RUANGAN, PLOTTING, JADWAL
-- =========================================================

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
-- kode ruangan berdasarkan jurusan_ruangan_buffer.nama_ruangan capitalized & space --> '-'

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

-- Tabel buffer relasi ruangan <-> perangkat, ditambah histori penggunaan perangkat
-- bisa digunakan untuk perangkat lain jika akan ditambahkan
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

-- Tabel buffer jadwal aktual agar plotting tidak terlalu kaku
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

-- =========================================================
-- 5. MANAJEMEN BERKAS & ARSIP
-- =========================================================

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

-- =========================================================
-- 6. QR TOKEN & LOG SCAN
-- =========================================================

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
  `ruangan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ruangan terkait.',
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
    ON DELETE RESTRICT ON UPDATE CASCADE,
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

-- =========================================================
-- 7. PRESENSI OFFLINE / QR
-- =========================================================

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

-- =========================================================
-- 8. PRESENSI ONLINE, BUKTI PEMBELAJARAN, DAN PERSIAPAN AI
-- =========================================================

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
  `metode_verifikasi` ENUM('manual','manual_dengan_bantuan_ai','ai_otomatis') NOT NULL DEFAULT 'manual' COMMENT 'Metode verifikasi. Saat ini default manual sesuai kebutuhan awal sistem.',
  `ai_status` ENUM('pending_pengembangan','belum_dikirim','antri','diproses','selesai','gagal','diabaikan') NOT NULL DEFAULT 'pending_pengembangan' COMMENT 'Status integrasi AI lokal ringan. Default ''pending_pengembangan'' sampai modul AI benar-benar diaktifkan.',
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

CREATE TABLE `ai_recognition_jobs` (

  `ai_job_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik job analisis AI untuk presensi online.',
  `presensi_online_id` BIGINT UNSIGNED NOT NULL COMMENT 'Referensi pengajuan presensi online yang akan dianalisis.',
  `lampiran_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Lampiran spesifik yang menjadi input AI, bila analisis dilakukan per file.',
  `task_type` ENUM('face_presence','screen_context','chat_context','multi_context') NOT NULL DEFAULT 'multi_context' COMMENT 'Jenis analisis AI yang direncanakan.',
  `model_name` VARCHAR(100) DEFAULT NULL COMMENT 'Nama model AI lokal ringan. Contoh implementasi: ''local_context_v1''.',
  `model_version` VARCHAR(50) DEFAULT NULL COMMENT 'Versi model AI. Contoh implementasi: ''2026.04''.',
  `job_status` ENUM('pending_pengembangan','antri','diproses','selesai','gagal','diabaikan') NOT NULL DEFAULT 'pending_pengembangan' COMMENT 'Status job AI. Default mengikuti kondisi bahwa fitur AI masih wacana/pending.',
  `confidence_score` DECIMAL(5,2) DEFAULT NULL COMMENT 'Nilai confidence AI bila nanti sudah aktif. Contoh implementasi: 87.50.',
  `hasil_ringkas_json` JSON DEFAULT NULL COMMENT 'Ringkasan hasil AI dalam format JSON bila modul AI sudah berjalan.',
  `error_message` TEXT DEFAULT NULL COMMENT 'Pesan error bila proses AI gagal.',
  `requested_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu job diminta/dicatat.',
  `processed_at` DATETIME DEFAULT NULL COMMENT 'Waktu job selesai diproses.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`ai_job_id`),
  KEY `idx_ai_recognition_jobs_status` (`job_status`, `task_type`),
  KEY `idx_ai_recognition_jobs_submission` (`presensi_online_id`),
  CONSTRAINT `fk_ai_recognition_jobs_submission`
    FOREIGN KEY (`presensi_online_id`) REFERENCES `presensi_online`(`presensi_online_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ai_recognition_jobs_lampiran`
    FOREIGN KEY (`lampiran_id`) REFERENCES `presensi_online_lampiran`(`lampiran_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 9. UJIAN
-- =========================================================

CREATE TABLE `sesi_ujian` (

  `sesi_ujian_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik sesi ujian.',
  `kode_ujian` VARCHAR(20) NOT NULL COMMENT 'Kode unik sesi ujian. Contoh implementasi: ''UTS-TKJ-01''. Umumnya dibentuk backend dari jenis ujian, identitas ruangan, dan urutan sesi.',
  `nama_ujian` VARCHAR(100) NOT NULL COMMENT 'Nama ujian. Contoh implementasi: ''UTS Semester Ganjil''.',
  `jurusan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi jurusan terkait.',
  `ruangan_id` INT UNSIGNED NOT NULL COMMENT 'Referensi ruangan terkait.',
  `plotting_id` INT UNSIGNED DEFAULT NULL COMMENT 'Referensi plotting rombel terkait.',
  `tahun_ajaran` VARCHAR(9) DEFAULT NULL COMMENT 'Tahun ajaran akademik. Contoh implementasi: ''2025/2026''.',
  `semester` ENUM('ganjil','genap','pendek') DEFAULT NULL COMMENT 'Semester akademik. Contoh implementasi: ''ganjil''.',
  `tanggal_mulai` DATE NOT NULL COMMENT 'Tanggal mulai berlaku. Contoh implementasi: awal semester atau awal sesi.',
  `tanggal_selesai` DATE NOT NULL COMMENT 'Tanggal selesai berlaku. Contoh implementasi: akhir semester atau akhir event.',
  `waktu_mulai` TIME NOT NULL COMMENT 'Kolom waktu_mulai. Contoh implementasi: isi sesuai kebutuhan modul sesi_ujian.',
  `waktu_selesai` TIME NOT NULL COMMENT 'Kolom waktu_selesai. Contoh implementasi: isi sesuai kebutuhan modul sesi_ujian.',
  `durasi_menit` INT UNSIGNED NOT NULL DEFAULT 90 COMMENT 'Durasi ujian dalam menit. Contoh implementasi: 90.',
  `mata_pelajaran` VARCHAR(100) DEFAULT NULL COMMENT 'Nama mata pelajaran. Contoh implementasi: ''Administrasi Sistem Jaringan''.',
  `pengawas_id` INT UNSIGNED DEFAULT NULL COMMENT 'User pengawas ujian. Contoh implementasi: guru pengawas ruang lab.',
  `keterangan` TEXT DEFAULT NULL COMMENT 'Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.',
  `status` ENUM('draft','aktif','selesai','dibatalkan') NOT NULL DEFAULT 'draft' COMMENT 'Status data. Nilai mengikuti ENUM pada kolom ini. Contoh implementasi: ''aktif''.',
  `created_by` INT UNSIGNED DEFAULT NULL COMMENT 'User pembuat data. Contoh implementasi: admin akademik yang membuat sesi ujian.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`sesi_ujian_id`),
  UNIQUE KEY `uk_sesi_ujian_kode` (`kode_ujian`),
  KEY `idx_sesi_ujian_lookup` (`tanggal_mulai`, `status`, `ruangan_id`),
  CONSTRAINT `fk_sesi_ujian_jurusan`
    FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_sesi_ujian_ruangan`
    FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_sesi_ujian_plotting`
    FOREIGN KEY (`plotting_id`) REFERENCES `plotting_rombel`(`plotting_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_sesi_ujian_pengawas`
    FOREIGN KEY (`pengawas_id`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_sesi_ujian_created_by`
    FOREIGN KEY (`created_by`) REFERENCES `users`(`user_id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `peserta_ujian` (

  `peserta_ujian_id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID unik peserta ujian.',
  `sesi_ujian_id` INT UNSIGNED NOT NULL COMMENT 'Referensi/ID unik untuk sesi ujian. Contoh implementasi: nilai numerik sesuai data master.',
  `siswa_id` INT UNSIGNED NOT NULL COMMENT 'Referensi siswa terkait.',
  `no_urut` INT UNSIGNED DEFAULT NULL COMMENT 'Nomor urut duduk',
  `status_kehadiran` ENUM('hadir','tidak_hadir','izin','sakit') NOT NULL DEFAULT 'tidak_hadir' COMMENT 'Status kehadiran peserta ujian. Contoh implementasi: ''hadir'' atau ''izin''.',
  `waktu_hadir` DATETIME DEFAULT NULL COMMENT 'Waktu hadir peserta ujian. Contoh implementasi: ''2026-05-10 07:10:00''.',
  `nilai` DECIMAL(5,2) DEFAULT NULL COMMENT 'Nilai konfigurasi. Contoh implementasi: ''15'' atau JSON pengaturan.',
  `keterangan` TEXT DEFAULT NULL COMMENT 'Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Waktu record dibuat otomatis. Contoh implementasi: ''2026-04-09 08:15:00''.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Waktu record terakhir diperbarui otomatis. Contoh implementasi: ''2026-04-09 10:00:00''.',
  PRIMARY KEY (`peserta_ujian_id`),
  UNIQUE KEY `uk_peserta_ujian_unique` (`sesi_ujian_id`, `siswa_id`),
  KEY `idx_peserta_ujian_lookup` (`sesi_ujian_id`, `status_kehadiran`, `no_urut`),
  CONSTRAINT `fk_peserta_ujian_sesi`
    FOREIGN KEY (`sesi_ujian_id`) REFERENCES `sesi_ujian`(`sesi_ujian_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_peserta_ujian_siswa`
    FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 10. KONFIGURASI, LOG, NOTIFIKASI, KALENDER
-- =========================================================

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

-- =========================================================
-- 11. BUFFER VIEW TABLE
-- =========================================================

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
-- memilih jenis ruangan saja
-- nama ruangan auto generate dari jenis_ruangan, jurusan, dan auto increment


-- =========================================================
-- BUFFER SNAPSHOT PRESENSI (NONAKTIF / PENGEMBANGAN LANJUT)
-- Tabel ini disiapkan bila nanti snapshot langsung di tabel `presensi`
-- ingin dipusatkan agar penulisan lebih hemat dan konsisten.
-- Untuk tahap sekarang sengaja masih di-comment.
-- =========================================================

-- CREATE TABLE `presensi_snapshot_buffer` (
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


-- =========================================================
-- MIGRASI BERTAHAP JIKA BUFFER SNAPSHOT DIAKTIFKAN (NONAKTIF)
-- Kolom snapshot lama tetap dipertahankan sebagai fallback selama masa transisi.
-- Jangan langsung drop kolom snapshot lama.
-- =========================================================

-- ALTER TABLE `presensi`
--   ADD COLUMN `snapshot_buffer_id` BIGINT UNSIGNED DEFAULT NULL AFTER `jadwal_id`,
--   MODIFY `jurusan_snapshot` VARCHAR(50) DEFAULT NULL COMMENT 'Fallback historis bila buffer belum dipakai atau data manual.',
--   MODIFY `kelas_snapshot` VARCHAR(20) DEFAULT NULL COMMENT 'Fallback historis bila buffer belum dipakai atau data manual.',
--   MODIFY `rombel_snapshot` VARCHAR(20) DEFAULT NULL COMMENT 'Fallback historis bila buffer belum dipakai atau data manual.',
--   ADD KEY `idx_presensi_snapshot_buffer` (`snapshot_buffer_id`),
--   ADD CONSTRAINT `fk_presensi_snapshot_buffer`
--     FOREIGN KEY (`snapshot_buffer_id`) REFERENCES `presensi_snapshot_buffer`(`snapshot_buffer_id`)
--     ON DELETE SET NULL ON UPDATE CASCADE;


-- =========================================================
-- CATATAN REDUNDANSI TERKENDALI (DOKUMENTASI DESAIN)
-- 1) siswa.jurusan_id_aktif, siswa.rombel_id_aktif, dan siswa.kelas_aktif
--    adalah cache untuk filter/sorting cepat; sumber historis tetap penempatan_siswa_rombel.
-- 2) profil_siswa.rombel adalah field legacy paling redundan dan dapat dinonaktifkan bertahap
--    setelah seluruh UI/ekspor memakai relasi utama.
-- 3) pasangan path file + media_id pada log_scan_qr/presensi sengaja dipertahankan:
--    path untuk akses cepat/kompatibilitas lama, media_id untuk audit dan arsip.
-- 4) presensi_online menyimpan snapshot keputusan terakhir, sedangkan histori review detail
--    tetap dicatat di presensi_online_verifikasi.
-- 5) jurusan_dashboard_buffer dan jurusan_ruangan_buffer adalah tabel buffer/cache laporan,
--    bukan source of truth utama.
-- =========================================================

-- =========================================================
-- 12. SEED DATA MINIMAL IAM
-- =========================================================

INSERT INTO `roles` (`nama_role`, `role_slug`, `deskripsi`, `is_system`) VALUES
('Super Admin', 'super_admin', 'Akses penuh ke seluruh modul', 1),
('Admin Akademik', 'admin_akademik', 'Kelola data akademik dan presensi', 1),
('Guru Pengawas', 'guru_pengawas', 'Memantau jadwal, presensi, dan ujian', 1),
('Operator Lab', 'operator_lab', 'Mengelola perangkat, scan, dan ruangan lab', 1),
('Siswa', 'siswa', 'Akses mandiri terbatas untuk profil dan riwayat presensi', 1),
('Intern', 'intern', 'Akses terbatas sementara', 1);

INSERT INTO `master_jenis_ruangan` (`kode_jenis_ruangan`, `nama_jenis_ruangan`, `deskripsi`, `is_system`, `status`) VALUES
('lab', 'Laboratorium', 'Ruangan praktik/lab yang menjadi lokasi utama presensi QR.', 1, 'aktif'),
('kelas_teori', 'Kelas Teori', 'Ruangan pembelajaran teori.', 1, 'aktif'),
('kantor', 'Kantor', 'Ruangan kerja staf/guru.', 1, 'aktif'),
('perpustakaan', 'Perpustakaan', 'Ruangan perpustakaan atau ruang literasi.', 1, 'aktif');

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
('attendance.read', 'attendance', 'read', 'Melihat data presensi'),
('attendance.write', 'attendance', 'write', 'Mengelola data presensi'),
('attendance.validate', 'attendance', 'validate', 'Memvalidasi data presensi'),
('attendance.online_submit', 'attendance', 'submit', 'Mengirim pengajuan presensi online beserta lampiran'),
('attendance.online_review', 'attendance', 'review', 'Meninjau dan memverifikasi presensi online'),
('qr.read', 'qr', 'read', 'Melihat token QR'),
('qr.generate', 'qr', 'generate', 'Membuat / reset QR'),
('qr.revoke', 'qr', 'revoke', 'Menonaktifkan QR'),
('exams.read', 'exams', 'read', 'Melihat data ujian'),
('exams.write', 'exams', 'write', 'Mengelola sesi ujian'),
('reports.read', 'reports', 'read', 'Melihat rekap/laporan'),
('reports.export', 'reports', 'export', 'Mengunduh / ekspor laporan'),
('settings.read', 'settings', 'read', 'Melihat konfigurasi'),
('settings.write', 'settings', 'write', 'Mengubah konfigurasi'),
('notifications.read', 'notifications', 'read', 'Melihat notifikasi'),
('notifications.write', 'notifications', 'write', 'Membuat/ubah notifikasi'),
('audit.read', 'audit', 'read', 'Melihat audit log'),
('media.read', 'media', 'read', 'Melihat metadata dan berkas pendukung'),
('media.write', 'media', 'write', 'Mengelola metadata dan unggahan berkas'),
('archive.read', 'archive', 'read', 'Melihat batch dan detail arsip'),
('archive.archive', 'archive', 'archive', 'Menjalankan proses arsip atau restore data'),
('ai.manage', 'ai', 'manage', 'Mengelola antrian dan hasil AI recognition'),
('session.manage', 'session', 'manage', 'Mengelola sesi login');

INSERT INTO `policies` (`policy_name`, `policy_slug`, `policy_type`, `deskripsi`, `is_system`) VALUES
('FullAccess', 'full_access', 'managed', 'Akses penuh ke seluruh resource', 1),
('AcademicAdminAccess', 'academic_admin_access', 'managed', 'Akses administrasi akademik dan presensi', 1),
('TeacherSupervisorAccess', 'teacher_supervisor_access', 'managed', 'Akses guru pengawas', 1),
('LabOperatorAccess', 'lab_operator_access', 'managed', 'Akses operator lab dan perangkat', 1),
('StudentSelfService', 'student_self_service', 'managed', 'Akses siswa untuk data diri dan presensi sendiri', 1),
('InternReadOnly', 'intern_read_only', 'managed', 'Akses baca terbatas untuk pengguna sementara', 1);

-- Full access
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 1
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'full_access';

-- Academic admin
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 10
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'academic_admin_access'
  AND pm.perm_slug IN (
    'students.read','students.write','academic.read','academic.write',
    'attendance.read','attendance.write','attendance.validate','attendance.online_review',
    'reports.read','reports.export','notifications.read','notifications.write',
    'qr.read','qr.generate','qr.revoke','exams.read','exams.write',
    'media.read','media.write','archive.read','archive.archive','ai.manage'
  );

-- Teacher supervisor
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 20
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'teacher_supervisor_access'
  AND pm.perm_slug IN (
    'students.read','academic.read','attendance.read','attendance.validate','attendance.online_review',
    'reports.read','notifications.read','exams.read','exams.write','media.read'
  );

-- Lab operator
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 20
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'lab_operator_access'
  AND pm.perm_slug IN (
    'rooms.read','rooms.write','devices.read','devices.write',
    'attendance.scan','attendance.read','qr.read','notifications.read',
    'reports.read','audit.read','media.read'
  );

-- Student self service
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', 'self/*', 30
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'student_self_service'
  AND pm.perm_slug IN ('attendance.read','attendance.online_submit','qr.read','notifications.read','media.read');

-- Intern read only
INSERT INTO `policy_permissions` (`policy_id`, `perm_id`, `effect`, `resource_scope`, `priority`)
SELECT p.policy_id, pm.perm_id, 'allow', '*', 40
FROM `policies` p
JOIN `permissions` pm
WHERE p.policy_slug = 'intern_read_only'
  AND pm.perm_slug IN (
    'students.read','academic.read','rooms.read','devices.read',
    'attendance.read','reports.read','notifications.read','media.read','archive.read'
  );

INSERT INTO `role_policies` (`role_id`, `policy_id`)
SELECT r.role_id, p.policy_id
FROM `roles` r
JOIN `policies` p
WHERE (r.role_slug = 'super_admin' AND p.policy_slug = 'full_access')
   OR (r.role_slug = 'admin_akademik' AND p.policy_slug = 'academic_admin_access')
   OR (r.role_slug = 'guru_pengawas' AND p.policy_slug = 'teacher_supervisor_access')
   OR (r.role_slug = 'operator_lab' AND p.policy_slug = 'lab_operator_access')
   OR (r.role_slug = 'siswa' AND p.policy_slug = 'student_self_service')
   OR (r.role_slug = 'intern' AND p.policy_slug = 'intern_read_only');

-- =========================================================
-- 13. VIEWS
-- =========================================================

CREATE OR REPLACE VIEW `v_siswa_transfer_masuk` AS
-- transfer_id: Referensi/ID unik untuk transfer. Contoh implementasi: nilai numerik sesuai data master.
-- siswa_id: Referensi siswa terkait.
-- nisn: Nomor induk siswa nasional. Contoh implementasi: '0065123456'.
-- nama_lengkap: Nama lengkap entitas. Contoh implementasi: 'Budi Santoso'.
-- asal_sekolah: Kolom asal_sekolah. Contoh implementasi: isi sesuai kebutuhan modul v_siswa_transfer_masuk.
-- tanggal_masuk: Kolom tanggal_masuk. Contoh implementasi: isi sesuai kebutuhan modul v_siswa_transfer_masuk.
-- keterangan: Keterangan tambahan. Contoh implementasi: alasan validasi, catatan scan, atau deskripsi event.
SELECT
  sm.mutasi_id AS transfer_id,
  s.siswa_id,
  s.nisn,
  s.nama_lengkap,
  sm.sekolah_asal_tujuan AS asal_sekolah,
  sm.tanggal AS tanggal_masuk,
  sm.alasan AS keterangan
FROM `siswa_mutasi` sm
JOIN `siswa` s ON s.siswa_id = sm.siswa_id
WHERE sm.jenis_mutasi = 'masuk';

CREATE OR REPLACE VIEW `v_siswa_transfer_keluar` AS
-- transfer_id: Referensi/ID unik untuk transfer. Contoh implementasi: nilai numerik sesuai data master.
-- siswa_id: Referensi siswa terkait.
-- tujuan_sekolah: Kolom tujuan_sekolah. Contoh implementasi: isi sesuai kebutuhan modul v_siswa_transfer_keluar.
-- tanggal_keluar: Kolom tanggal_keluar. Contoh implementasi: isi sesuai kebutuhan modul v_siswa_transfer_keluar.
-- alasan: Alasan mutasi atau catatan terkait. Contoh implementasi: 'Pindah domisili'.
SELECT
  sm.mutasi_id AS transfer_id,
  sm.siswa_id,
  sm.sekolah_asal_tujuan AS tujuan_sekolah,
  sm.tanggal AS tanggal_keluar,
  sm.alasan
FROM `siswa_mutasi` sm
WHERE sm.jenis_mutasi = 'keluar';

CREATE OR REPLACE VIEW `v_log_scan_ringkas` AS
SELECT
  l.log_id,
  l.scan_uuid,
  l.status,
  l.scan_type,
  l.scan_method,
  l.keterangan,
  l.tanggal,
  l.waktu,
  l.scanned_at,
  l.foto_capture,
  r.kode_ruangan,
  COALESCE(jrb.nama_ruangan, r.kode_ruangan) AS nama_ruangan,
  s.nisn,
  s.nis,
  s.nama_lengkap AS nama_siswa,
  j.nama_jurusan,
  qt.qr_reference,
  p.mac_address,
  p.versi_firmware
FROM `log_scan_qr` l
JOIN `ruangan` r
  ON r.ruangan_id = l.ruangan_id
LEFT JOIN (
  SELECT
    ruangan_id,
    MAX(nama_ruangan) AS nama_ruangan,
    MAX(jenis_ruangan) AS jenis_ruangan
  FROM `jurusan_ruangan_buffer`
  WHERE `status` = 'aktif'
  GROUP BY ruangan_id
) jrb ON jrb.ruangan_id = l.ruangan_id
LEFT JOIN `siswa` s ON s.siswa_id = l.siswa_id
LEFT JOIN `jurusan` j ON j.jurusan_id = s.jurusan_id_aktif
LEFT JOIN `qr_tokens` qt ON qt.qr_token_id = l.qr_token_id
LEFT JOIN `perangkat_esp32` p ON p.perangkat_id = l.perangkat_id;

-- View kompatibilitas agar nama view lama tetap bisa dipakai modul yang belum diperbarui.
CREATE OR REPLACE VIEW `v_log_scan_qr_detail` AS
SELECT * FROM `v_log_scan_ringkas`;

CREATE OR REPLACE VIEW `v_presensi_detail` AS
SELECT
  pr.presensi_id,
  pr.tanggal,
  pr.waktu_masuk,
  pr.waktu_keluar,
  pr.waktu_pulang_plan,
  pr.status,
  pr.status_checkout,
  pr.keterangan,
  pr.validasi,

  s.nisn,
  s.nis,
  s.nama_lengkap AS nama_siswa,

  COALESCE(
    NULLIF(pr.kelas_snapshot, ''),
    CAST(rb.tingkatan AS CHAR),
    s.kelas_aktif
  ) AS kelas,

  COALESCE(
    NULLIF(pr.rombel_snapshot, ''),
    rb.label_rombel,
    CONCAT(CAST(rb.tingkatan AS CHAR), '-', j_plot.kode_jurusan, '-', rb.nomor_rombel)
  ) AS rombel,

  COALESCE(
    NULLIF(pr.jurusan_snapshot, ''),
    j_plot.nama_jurusan,
    j_siswa.nama_jurusan
  ) AS jurusan_snapshot,

  COALESCE(
    NULLIF(pr.tahun_ajaran_snapshot, ''),
    pl.tahun_ajaran
  ) AS tahun_ajaran,

  COALESCE(
    pr.semester_snapshot,
    pl.semester
  ) AS semester,

  jrb.jenis_ruangan,
  COALESCE(jrb.nama_ruangan, r.kode_ruangan) AS nama_ruangan,
  r.kode_ruangan,

  qt.qr_reference,
  pr.bukti_izin_sakit,
  pr.foto_scan_masuk,
  pr.foto_scan_keluar

FROM `presensi` pr
JOIN `siswa` s ON s.siswa_id = pr.siswa_id
JOIN `ruangan` r ON r.ruangan_id = pr.ruangan_id

LEFT JOIN `plotting_rombel` pl ON pl.plotting_id = pr.plotting_id
LEFT JOIN `rombel` rb ON rb.rombel_id = pl.rombel_id
LEFT JOIN `jurusan` j_plot ON j_plot.jurusan_id = rb.jurusan_id
LEFT JOIN `jurusan` j_siswa ON j_siswa.jurusan_id = s.jurusan_id_aktif

LEFT JOIN (
  SELECT
    ruangan_id,
    MAX(nama_ruangan) AS nama_ruangan,
    MAX(jenis_ruangan) AS jenis_ruangan
  FROM `jurusan_ruangan_buffer`
  WHERE `status` = 'aktif'
  GROUP BY ruangan_id
) jrb ON jrb.ruangan_id = pr.ruangan_id

LEFT JOIN `log_scan_qr` ls ON ls.log_id = pr.scan_masuk_log_id
LEFT JOIN `qr_tokens` qt ON qt.qr_token_id = ls.qr_token_id;

CREATE OR REPLACE VIEW `v_rekap_harian` AS
SELECT
  pr.tanggal,

  COALESCE(
    NULLIF(pr.jurusan_snapshot, ''),
    j_plot.nama_jurusan,
    j_siswa.nama_jurusan
  ) AS nama_jurusan,

  COALESCE(jrb.nama_ruangan, r.kode_ruangan) AS nama_ruangan,

  COALESCE(
    NULLIF(pr.tahun_ajaran_snapshot, ''),
    pl.tahun_ajaran
  ) AS tahun_ajaran,

  COALESCE(
    pr.semester_snapshot,
    pl.semester
  ) AS semester,

  SUM(CASE WHEN pr.status = 'hadir' THEN 1 ELSE 0 END) AS total_hadir,
  SUM(CASE WHEN pr.status = 'terlambat' THEN 1 ELSE 0 END) AS total_terlambat,
  SUM(CASE WHEN pr.status = 'sakit' THEN 1 ELSE 0 END) AS total_sakit,
  SUM(CASE WHEN pr.status = 'izin' THEN 1 ELSE 0 END) AS total_izin,
  SUM(CASE WHEN pr.status = 'alpha' THEN 1 ELSE 0 END) AS total_alpha,
  COUNT(*) AS total_siswa_tercatat

FROM `presensi` pr
JOIN `ruangan` r ON r.ruangan_id = pr.ruangan_id

LEFT JOIN `plotting_rombel` pl ON pl.plotting_id = pr.plotting_id
LEFT JOIN `rombel` rb ON rb.rombel_id = pl.rombel_id
LEFT JOIN `jurusan` j_plot ON j_plot.jurusan_id = rb.jurusan_id
LEFT JOIN `siswa` s ON s.siswa_id = pr.siswa_id
LEFT JOIN `jurusan` j_siswa ON j_siswa.jurusan_id = s.jurusan_id_aktif

LEFT JOIN (
  SELECT
    ruangan_id,
    MAX(nama_ruangan) AS nama_ruangan
  FROM `jurusan_ruangan_buffer`
  WHERE `status` = 'aktif'
  GROUP BY ruangan_id
) jrb ON jrb.ruangan_id = pr.ruangan_id

GROUP BY
  pr.tanggal,
  COALESCE(NULLIF(pr.jurusan_snapshot, ''), j_plot.nama_jurusan, j_siswa.nama_jurusan),
  COALESCE(jrb.nama_ruangan, r.kode_ruangan),
  COALESCE(NULLIF(pr.tahun_ajaran_snapshot, ''), pl.tahun_ajaran),
  COALESCE(pr.semester_snapshot, pl.semester);


CREATE OR REPLACE VIEW `v_presensi_online_detail` AS
-- presensi_online_id: ID unik pengajuan presensi online.
-- submission_uuid: UUID submission untuk API/client.
-- tanggal_presensi: Tanggal presensi online yang diajukan.
-- waktu_submit: Waktu siswa mengirim bukti.
-- status_pengajuan: Status alur pengajuan presensi online.
-- status_presensi_final: Status presensi akhir hasil verifikasi.
-- metode_verifikasi: Metode verifikasi yang dipakai saat ini.
-- ai_status: Status kesiapan/proses AI untuk submission.
-- nisn: Nomor induk siswa nasional.
-- nis: Nomor induk siswa internal sekolah.
-- nama_siswa: Nama siswa.
-- mode_pembelajaran: Mode belajar online.
-- platform_bukti: Platform utama sumber bukti.
-- jumlah_lampiran: Jumlah lampiran bukti pada submission.
-- diverifikasi_oleh: Username/verifikator terakhir.
-- waktu_verifikasi: Waktu keputusan verifikasi.
SELECT
  po.presensi_online_id,
  po.submission_uuid,
  po.tanggal_presensi,
  po.waktu_submit,
  po.status_pengajuan,
  po.status_presensi_final,
  po.metode_verifikasi,
  po.ai_status,
  s.nisn,
  s.nis,
  s.nama_lengkap AS nama_siswa,
  po.mode_pembelajaran,
  po.platform_bukti,
  COUNT(pol.lampiran_id) AS jumlah_lampiran,
  u.username AS diverifikasi_oleh,
  po.waktu_verifikasi
FROM `presensi_online` po
JOIN `siswa` s ON s.siswa_id = po.siswa_id
LEFT JOIN `presensi_online_lampiran` pol ON pol.presensi_online_id = po.presensi_online_id
LEFT JOIN `users` u ON u.user_id = po.diverifikasi_oleh
GROUP BY
  po.presensi_online_id, po.submission_uuid, po.tanggal_presensi, po.waktu_submit,
  po.status_pengajuan, po.status_presensi_final, po.metode_verifikasi, po.ai_status,
  s.nisn, s.nis, s.nama_lengkap, po.mode_pembelajaran, po.platform_bukti, u.username, po.waktu_verifikasi;

CREATE OR REPLACE VIEW `v_media_arsip_status` AS
-- media_id: ID unik metadata file.
-- owner_table: Tabel pemilik utama file.
-- owner_id: Primary key pemilik file.
-- kategori_berkas: Jenis file yang disimpan.
-- storage_path: Path file saat ini.
-- archive_status: Status arsip file.
-- retention_days: Masa simpan aktif file.
-- archived_at: Waktu file diarsipkan.
SELECT
  m.media_id,
  m.owner_table,
  m.owner_id,
  m.kategori_berkas,
  m.storage_path,
  m.archive_status,
  m.retention_days,
  m.archived_at
FROM `media_berkas` m;


CREATE OR REPLACE VIEW `v_manage_users` AS
SELECT
  u.user_id,
  u.username,
  COALESCE(s.nama_lengkap, gs.nama_lengkap, u.username) AS nama_lengkap,
  s.nisn,
  GROUP_CONCAT(DISTINCT r.nama_role ORDER BY r.nama_role SEPARATOR ', ') AS role,
  MIN(r.role_slug) AS primary_role_slug,
  u.user_type AS tipe_user,
  js.jurusan_id,
  js.kode_jurusan,
  js.nama_jurusan,
  u.status,
  u.valid_until,
  CASE
    WHEN u.valid_until IS NULL THEN 'permanen'
    WHEN u.valid_until < NOW() THEN 'expired'
    WHEN u.valid_until <= DATE_ADD(NOW(), INTERVAL 14 DAY) THEN 'segera_berakhir'
    ELSE 'aktif_sementara'
  END AS valid_until_class,
  u.last_login,
  CASE
    WHEN MAX(CASE WHEN us.is_online = 1 AND us.logout_at IS NULL AND us.last_activity >= DATE_SUB(NOW(), INTERVAL 15 MINUTE) THEN 1 ELSE 0 END) = 1
    THEN 'online'
    ELSE 'offline'
  END AS online_status,
  MAX(us.last_activity) AS last_activity,
  u.created_at,
  u.updated_at
FROM `users` u
LEFT JOIN `siswa` s ON s.siswa_id = u.siswa_id
LEFT JOIN `guru_staff` gs ON gs.guru_id = u.guru_id
LEFT JOIN `jurusan` js ON js.jurusan_id = s.jurusan_id_aktif
LEFT JOIN `user_roles` ur ON ur.user_id = u.user_id AND ur.is_active = 1
LEFT JOIN `roles` r ON r.role_id = ur.role_id
LEFT JOIN `user_sessions` us ON us.user_id = u.user_id
GROUP BY
  u.user_id, u.username, s.nama_lengkap, gs.nama_lengkap, s.nisn,
  u.user_type, js.jurusan_id, js.kode_jurusan, js.nama_jurusan,
  u.status, u.valid_until, u.last_login, u.created_at, u.updated_at;

CREATE OR REPLACE VIEW `v_user_activities_display` AS
SELECT
  ua.log_id,
  COALESCE(ua.nama_lengkap_snapshot, ua.username_snapshot, CONCAT('User#', ua.user_id)) AS user_label,
  ua.username_snapshot,
  ua.nisn_snapshot,
  ua.role_snapshot,
  ua.role_slug_snapshot,
  ua.user_type_snapshot,
  ua.action_type,
  ua.module_name,
  ua.target_table,
  ua.target_id,
  ua.status,
  LEFT(ua.activity_description, 255) AS keterangan_ringkas,
  ua.ruangan_id,
  COALESCE(ua.kode_ruangan_snapshot, r.kode_ruangan) AS ruangan_label,
  ua.ip_address,
  LEFT(ua.user_agent, 150) AS browser_device,
  ua.archive_status,
  ua.created_at AS activity_created_at
FROM `user_activities` ua
LEFT JOIN `ruangan` r ON r.ruangan_id = ua.ruangan_id;

CREATE OR REPLACE VIEW `v_user_activities_advanced` AS
SELECT
  ua.log_id,
  ua.user_id,
  ua.username_snapshot,
  ua.nama_lengkap_snapshot,
  ua.nisn_snapshot,
  ua.role_snapshot,
  ua.role_slug_snapshot,
  ua.user_type_snapshot,
  ua.action_type,
  ua.module_name,
  ua.target_table,
  ua.target_id,
  ua.status,
  ua.activity_description,
  ua.ruangan_id,
  COALESCE(ua.kode_ruangan_snapshot, r.kode_ruangan) AS kode_ruangan,
  ua.ip_address,
  ua.user_agent,
  ua.archive_status,
  ua.archived_at,
  ua.cold_archive_id,
  uca.compressed_file_name,
  uca.storage_path AS cold_archive_path,
  ua.arsip_batch_id,
  ua.created_at AS activity_created_at
FROM `user_activities` ua
LEFT JOIN `ruangan` r ON r.ruangan_id = ua.ruangan_id
LEFT JOIN `user_activity_cold_archives` uca ON uca.cold_archive_id = ua.cold_archive_id;

-- =========================================================
-- 14. Auto Filler (OPSIONAL / NONAKTIF)
-- ---------------------------------------------------------
-- Auto filler bukan struktur database. Ini hanya contoh query operasional
-- untuk mengisi data buffer/referensi saat admin menambah data baru.
-- Jalankan terpisah dari file schema utama bila memang diperlukan.
-- =========================================================

-- Contoh 14A - helper saat admin menambah mapping jurusan <-> ruangan kelas
-- Parameter aplikasi:
--   :jurusan_id  -> ID jurusan yang dipilih
--   :ruangan_id  -> ID ruangan yang dipilih
--
-- INSERT INTO jurusan_ruangan_buffer (jurusan_id, ruangan_id, jenis_ruangan, nama_ruangan, urut_auto, status)
-- SELECT
--   j.jurusan_id,
--   :ruangan_id,
--   'kelas',
--   CONCAT('Kelas ', j.kode_jurusan, ' ', COALESCE(MAX(b.urut_auto), 0) + 1),
--   COALESCE(MAX(b.urut_auto), 0) + 1,
--   'aktif'
-- FROM jurusan j
-- LEFT JOIN jurusan_ruangan_buffer b
--   ON b.jurusan_id = j.jurusan_id
--  AND b.jenis_ruangan = 'kelas'
-- WHERE j.jurusan_id = :jurusan_id
-- GROUP BY j.jurusan_id, j.kode_jurusan;

-- Contoh 14B - bulk sync buffer ruang kelas dari plotting_rombel
-- INSERT INTO jurusan_ruangan_buffer (jurusan_id, ruangan_id, jenis_ruangan, nama_ruangan, urut_auto, status)
-- SELECT
--   j.jurusan_id,
--   pr.ruangan_id,
--   'kelas',
--   CONCAT('Kelas ', j.kode_jurusan, ' ', COALESCE(MAX(b.urut_auto), 0) + 1),
--   COALESCE(MAX(b.urut_auto), 0) + 1,
--   'aktif'
-- FROM jurusan j
-- JOIN rombel rb
--   ON rb.jurusan_id = j.jurusan_id
-- JOIN plotting_rombel pr
--   ON pr.rombel_id = rb.rombel_id
-- LEFT JOIN jurusan_ruangan_buffer b
--   ON b.jurusan_id = j.jurusan_id
--  AND b.jenis_ruangan = 'kelas'
-- LEFT JOIN jurusan_ruangan_buffer ex
--   ON ex.jurusan_id = j.jurusan_id
--  AND ex.ruangan_id = pr.ruangan_id
-- WHERE ex.buffer_id IS NULL
-- GROUP BY j.jurusan_id, j.kode_jurusan, pr.ruangan_id;

-- =========================================================
-- 15. Backfill (OPSIONAL / NONAKTIF)
-- ---------------------------------------------------------
-- Backfill adalah query migrasi satu kali untuk mengisi kolom baru pada data lama.
-- Ini berbeda dari auto filler:
-- - auto filler dipakai saat menambah data referensi/buffer baru
-- - backfill dipakai untuk melengkapi record yang sudah terlanjur ada
-- Jalankan hanya jika database sudah berisi data lama dan Anda menambahkan
-- kolom snapshot baru seperti tahun_ajaran_snapshot / semester_snapshot.
-- =========================================================

-- UPDATE `presensi` pr
-- LEFT JOIN `plotting_rombel` pl
--   ON pl.plotting_id = pr.plotting_id
-- SET
--   pr.tahun_ajaran_snapshot = COALESCE(pr.tahun_ajaran_snapshot, pl.tahun_ajaran),
--   pr.semester_snapshot = COALESCE(pr.semester_snapshot, pl.semester)
-- WHERE pr.tahun_ajaran_snapshot IS NULL
--    OR pr.semester_snapshot IS NULL;


-- Contoh 15B - migrasi admin_activities versi 3.2 ke user_activities versi 3.3
-- Jalankan hanya jika database lama sudah berisi data admin_activities sebelum upgrade schema.
-- INSERT INTO user_activities (
--   user_id, username_snapshot, nama_lengkap_snapshot, role_snapshot, role_slug_snapshot,
--   user_type_snapshot, action_type, module_name, target_table, target_id,
--   status, activity_description, ip_address, user_agent, created_at
-- )
-- SELECT
--   aa.user_id,
--   u.username,
--   COALESCE(s.nama_lengkap, gs.nama_lengkap, u.username),
--   r.nama_role,
--   r.role_slug,
--   u.user_type,
--   aa.activity_type,
--   aa.module_name,
--   aa.target_table,
--   aa.target_id,
--   'sukses',
--   aa.activity_description,
--   aa.ip_address,
--   aa.user_agent,
--   aa.created_at
-- FROM admin_activities aa
-- LEFT JOIN users u ON u.user_id = aa.user_id
-- LEFT JOIN siswa s ON s.siswa_id = u.siswa_id
-- LEFT JOIN guru_staff gs ON gs.guru_id = u.guru_id
-- LEFT JOIN user_roles ur ON ur.user_id = u.user_id AND ur.is_active = 1
-- LEFT JOIN roles r ON r.role_id = ur.role_id;

-- =========================================================
-- SELESAI
-- =========================================================