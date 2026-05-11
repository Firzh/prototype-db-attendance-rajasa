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

