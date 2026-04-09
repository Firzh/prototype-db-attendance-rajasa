CREATE TABLE `admin_activities` (
  `adm_activity_id` int(11) UNSIGNED NOT NULL,
  `user_id` int(11) UNSIGNED NOT NULL,
  `activity_type` varchar(50) NOT NULL COMMENT 'Jenis aktivitas (login, logout, view_data, update_data, etc.)',
  `activity_description` text DEFAULT NULL COMMENT 'Deskripsi detail aktivitas',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'IP address pengguna',
  `user_agent` text DEFAULT NULL COMMENT 'Browser/Device info',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `jurusan` (
  `jurusan_id` int(11) UNSIGNED NOT NULL,
  `kode_jurusan` varchar(10) NOT NULL COMMENT 'Kode unik jurusan, ex: TKJ, RPL, MM',
  `nama_jurusan` varchar(100) NOT NULL COMMENT 'Nama lengkap jurusan',
  `singkatan` varchar(10) NOT NULL COMMENT 'Singkatan jurusan',
  `ketua_jurusan` varchar(100) DEFAULT NULL COMMENT 'Nama ketua jurusan',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `status` enum('aktif','nonaktif') DEFAULT 'aktif'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `log_akses` (
  `log_id` int(11) UNSIGNED NOT NULL,
  `ruangan_id` int(11) UNSIGNED NOT NULL,
  `rfid_uid` varchar(50) DEFAULT NULL COMMENT 'UID RFID yang dicoba',
  `foto_capture` varchar(255) DEFAULT NULL COMMENT 'Foto yang diambil ESP32-CAM',
  `status` enum('id_tidak_terdaftar','kartu_diblokir','ruangan_tidak_cocok','foto_buram','lainnya') NOT NULL,
  `keterangan` text DEFAULT NULL,
  `tanggal` date NOT NULL,
  `waktu` time NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- masih dalam pengembangan
CREATE TABLE `presensi` (
  `presensi_id` int(11) UNSIGNED NOT NULL,
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `ruangan_id` int(11) UNSIGNED NOT NULL,
  `jurusan_id` int(11) UNSIGNED NOT NULL,
  `tanggal` date NOT NULL,
  `waktu_masuk` time NOT NULL,
  `waktu_keluar` time DEFAULT NULL,
  `status` enum('hadir','izin','sakit','alpha','terlambat') DEFAULT 'hadir',
  `keterangan` text DEFAULT NULL,
  `foto_scan_1` varchar(255) DEFAULT NULL COMMENT 'Foto saat scan masuk',
  `foto_scan_2` varchar(255) DEFAULT NULL COMMENT 'Foto kedua',
  `foto_scan_3` varchar(255) DEFAULT NULL COMMENT 'Foto ketiga',
  `rfid_uid` varchar(50) DEFAULT NULL COMMENT 'UID RFID yang discan',
  `validasi` enum('valid','tidak_valid','pending') DEFAULT 'valid',
  `diverifikasi_oleh` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID admin yang verifikasi',
  `waktu_verifikasi` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ruangan` (
  `ruangan_id` int(11) UNSIGNED NOT NULL,
  `kode_ruangan` varchar(20) NOT NULL COMMENT 'Kode ruangan, ex: LAB-TKJ-01',
  `nama_ruangan` varchar(100) NOT NULL COMMENT 'Nama ruangan',
  `jurusan_id` int(11) UNSIGNED NOT NULL,
  `kapasitas` int(11) DEFAULT 30 COMMENT 'Kapasitas maksimum siswa',
  `lokasi` varchar(100) DEFAULT NULL COMMENT 'Lokasi/detail ruangan',
  `esp32_cam_id` varchar(50) DEFAULT NULL COMMENT 'ID unik ESP32-CAM di ruangan ini',
  `esp32_cam_ip` varchar(20) DEFAULT NULL COMMENT 'IP address ESP32-CAM',
  `status` enum('aktif','nonaktif','maintenance') DEFAULT 'aktif',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `siswa` (
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `nisn` varchar(20) NOT NULL COMMENT 'Nomor Induk Siswa Nasional',
  `nis` varchar(20) NOT NULL COMMENT 'Nomor Induk Sekolah',
  `nama_lengkap` varchar(100) NOT NULL,
  `jenis_kelamin` enum('L','P') NOT NULL COMMENT 'L=Laki-laki, P=Perempuan',
  `tempat_lahir` varchar(50) DEFAULT NULL,
  `tanggal_lahir` date DEFAULT NULL,
  `alamat` text DEFAULT NULL,
  `no_telp` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `jurusan_id` int(11) UNSIGNED NOT NULL,
  `kelas` varchar(10) NOT NULL COMMENT 'Ex: X, XI, XII',
  `rombel` varchar(10) NOT NULL COMMENT 'Rombongan belajar, ex: TKJ-1, TKJ-2',
  `rfid_uid` varchar(50) DEFAULT NULL COMMENT 'UID kartu RFID siswa',
  `foto` varchar(255) DEFAULT NULL COMMENT 'Path foto siswa',
  `nama_ortu` varchar(100) DEFAULT NULL COMMENT 'Nama orang tua/wali',
  `no_telp_ortu` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `status` enum('aktif','nonaktif','lulus','keluar') DEFAULT 'aktif'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `users` (
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL COMMENT 'Password terenkripsi bcrypt',
  `nama_lengkap` varchar(100) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `no_telp` varchar(20) DEFAULT NULL,
  `role` enum('admin_operator','admin_jurusan') NOT NULL DEFAULT 'admin_jurusan',
  `jurusan_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'NULL untuk admin_operator, terisi untuk admin_jurusan',
  `ruangan_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'Ruangan yang dikelola (opsional)',
  `foto_profile` varchar(255) DEFAULT NULL,
  `last_login` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `status` enum('aktif','nonaktif','terkunci') DEFAULT 'aktif'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_sessions` (
  `session_id` int(11) UNSIGNED NOT NULL,
  `user_id` int(11) UNSIGNED NOT NULL,
  `session_token` varchar(255) NOT NULL COMMENT 'JWT token yang digunakan',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'IP address pengguna',
  `user_agent` text DEFAULT NULL COMMENT 'Browser/Device info',
  `logged_in_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Waktu login',
  `last_activity` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Waktu aktivitas terakhir',
  `is_online` tinyint(1) DEFAULT 1 COMMENT 'Status online (1) atau offline (0)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;