-- Buat database baru
CREATE DATABASE IF NOT EXISTS sistem_absensi_lab
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Pilih database
USE sistem_absensi_lab;

-- 1. SISTEM HAK AKSES (Modular & Scalable)
CREATE TABLE `roles` (
  `role_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `nama_role` varchar(50) NOT NULL 
) ENGINE=InnoDB;

CREATE TABLE `permissions` (
  `perm_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `perm_slug` varchar(100) UNIQUE NOT NULL, 
  `keterangan` text
) ENGINE=InnoDB;

CREATE TABLE `role_permissions` (
  `role_id` int(11) UNSIGNED NOT NULL,
  `perm_id` int(11) UNSIGNED NOT NULL,
  PRIMARY KEY (`role_id`, `perm_id`),
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`),
  FOREIGN KEY (`perm_id`) REFERENCES `permissions`(`perm_id`)
) ENGINE=InnoDB;


-- 2. USER & DATA INDUK ===================================================================
CREATE TABLE `guru_staff` (
  `guru_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `nip` varchar(20) UNIQUE DEFAULT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `jabatan` varchar(50) DEFAULT NULL
) ENGINE=InnoDB;

CREATE TABLE `siswa` (
  `siswa_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `nisn` varchar(20) UNIQUE NOT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `jenis_kelamin` enum('L','P') NOT NULL,
  `angkatan` year(4) NOT NULL,
  `status` enum('aktif','lulus','keluar','mutasi') DEFAULT 'aktif'
) ENGINE=InnoDB;

-- Fitur Mutasi: Histori Transfer Masuk & Keluar
CREATE TABLE `siswa_mutasi` (
  `mutasi_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `jenis_mutasi` enum('masuk', 'keluar') NOT NULL,
  `tanggal` date NOT NULL,
  `sekolah_asal_tujuan` varchar(100),
  `alasan` text,
  FOREIGN KEY (`siswa_id`) REFERENCES `siswa`(`siswa_id`)
) ENGINE=InnoDB;

CREATE TABLE `users` (
  `user_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `username` varchar(50) UNIQUE NOT NULL,
  `password` varchar(255) NOT NULL,
  `role_id` int(11) UNSIGNED NOT NULL,
  `user_type` enum('siswa', 'guru_staff') NOT NULL, 
  `ref_id` int(11) UNSIGNED NOT NULL, -- Merujuk ke siswa_id atau guru_id
  `valid_until` datetime DEFAULT NULL, -- Untuk akses sementara/Intern
  `status` enum('aktif','nonaktif') DEFAULT 'aktif',
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`)
) ENGINE=InnoDB;

CREATE TABLE `user_permissions` (
  `user_id` int(11) UNSIGNED NOT NULL,
  `perm_id` int(11) UNSIGNED NOT NULL,
  `is_allowed` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`user_id`, `perm_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`),
  FOREIGN KEY (`perm_id`) REFERENCES `permissions`(`perm_id`)
) ENGINE=InnoDB;


-- 3. PERANGKAT & RUANGAN ===================================================================
CREATE TABLE `perangkat_esp32` (
  `mac_address` varchar(17) PRIMARY KEY,
  `ip_address` varchar(45), 
  `status_perangkat` enum('online', 'offline', 'maintenance') DEFAULT 'online'
) ENGINE=InnoDB;

CREATE TABLE `ruangan` (
  `ruangan_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `kode_ruangan` varchar(20) UNIQUE NOT NULL,
  `nama_ruangan` varchar(50) NOT NULL,
  `jenis_ruangan` enum('lab', 'kelas_teori', 'kantor', 'perpustakaan') NOT NULL,
  `mac_address_esp32` varchar(17), 
  `status` enum('aktif','nonaktif','maintenance') DEFAULT 'aktif',
  FOREIGN KEY (`mac_address_esp32`) REFERENCES `perangkat_esp32`(`mac_address`)
) ENGINE=InnoDB;


-- 4. AKADEMIK & PLOTTING ===================================================================
CREATE TABLE `jurusan` (
  `jurusan_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `kode_jurusan` varchar(10) NOT NULL,
  `nama_jurusan` varchar(100) NOT NULL,
  `singkatan` varchar(10) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE `rombel` (
  `rombel_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `tingkatan` enum('X', 'XI', 'XII', 'XIII') NOT NULL,
  `jurusan_id` int(11) UNSIGNED NOT NULL,
  `nomor_rombel` int(2) DEFAULT 1,
  FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
) ENGINE=InnoDB;

CREATE TABLE `plotting_rombel` (
  `plotting_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `rombel_id` int(11) UNSIGNED NOT NULL,
  `ruangan_id` int(11) UNSIGNED NOT NULL,
  `tahun_ajaran` varchar(9) NOT NULL,
  `user_id` int(11) UNSIGNED NULL COMMENT 'Guru pengawas (ref: users)',
  `jam_pulang_default` time DEFAULT '15:00:00',
  FOREIGN KEY (`rombel_id`) REFERENCES `rombel`(`rombel_id`),
  FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
) ENGINE=InnoDB;