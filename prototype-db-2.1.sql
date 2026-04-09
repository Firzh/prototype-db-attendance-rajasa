-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 04 Mar 2026 pada 22.24
-- Versi server: 10.4.32-MariaDB
-- Versi PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `sistem_absensi_lab`
--

-- --------------------------------------------------------

--
-- Struktur dari tabel `admin_activities`
--

-- =====================================================
-- SISTEM ABSENSI LAB KOMPUTER SMK RAJASA SURABAYA
-- Database Schema & Dummy Data - Versi 2
-- =====================================================
-- Cara Penggunaan:
-- 1. Buka phpMyAdmin di browser (http://localhost/phpmyadmin)
-- 2. Klik tab "SQL"
-- 3. Copy seluruh isi file ini
-- 4. Paste ke kolom SQL
-- 5. Klik "Go" atau "Kirim"
-- =====================================================

-- Hapus database jika sudah ada (opsional, hati-hati!)
-- DROP DATABASE IF EXISTS sistem_absensi_lab;

-- Buat database baru
CREATE DATABASE IF NOT EXISTS sistem_absensi_lab
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Pilih database
USE sistem_absensi_lab;

CREATE TABLE `admin_activities` (
  `id` int(11) UNSIGNED NOT NULL,
  `user_id` int(11) UNSIGNED NOT NULL,
  `activity_type` varchar(50) NOT NULL COMMENT 'Jenis aktivitas (login, logout, view_data, update_data, etc.)',
  `activity_description` text DEFAULT NULL COMMENT 'Deskripsi detail aktivitas',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'IP address pengguna',
  `user_agent` text DEFAULT NULL COMMENT 'Browser/Device info',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `jurusan`
--

CREATE TABLE `jurusan` (
  `id` int(11) UNSIGNED NOT NULL,
  `kode_jurusan` varchar(10) NOT NULL COMMENT 'Kode unik jurusan, ex: TKJ, RPL, MM',
  `nama_jurusan` varchar(100) NOT NULL COMMENT 'Nama lengkap jurusan',
  `singkatan` varchar(10) NOT NULL COMMENT 'Singkatan jurusan',
  `ketua_jurusan` varchar(100) DEFAULT NULL COMMENT 'Nama ketua jurusan',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `status` enum('aktif','nonaktif') DEFAULT 'aktif'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `jurusan`
--

INSERT INTO `jurusan` (`id`, `kode_jurusan`, `nama_jurusan`, `singkatan`, `ketua_jurusan`, `created_at`, `updated_at`, `status`) VALUES
(1, 'TKJ', 'Teknik Komputer dan Jaringan', 'TKJ', 'Dr. Ahmad Supriyadi, S.Kom., M.Kom.', '2026-03-04 17:23:16', '2026-03-04 17:23:16', 'aktif'),
(2, 'TL', 'Teknik Listrik', 'TL', 'Dra. Sri Lestari, M.Pd.', '2026-03-04 17:23:16', '2026-03-04 17:23:16', 'aktif'),
(3, 'TM', 'Teknik Mesin', 'TM', 'Bambang Prasetya, S.Sn., M.Sn.', '2026-03-04 17:23:16', '2026-03-04 17:23:16', 'aktif');

-- --------------------------------------------------------

--
-- Struktur dari tabel `konfigurasi`
--

CREATE TABLE `konfigurasi` (
  `id` int(11) UNSIGNED NOT NULL,
  `kunci` varchar(50) NOT NULL,
  `nilai` text DEFAULT NULL,
  `keterangan` varchar(255) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_by` int(11) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `konfigurasi`
--

INSERT INTO `konfigurasi` (`id`, `kunci`, `nilai`, `keterangan`, `updated_at`, `updated_by`) VALUES
(1, 'nama_sekolah', 'SMK Rajasa Surabaya', 'Nama lengkap sekolah', '2026-03-04 17:23:16', NULL),
(2, 'alamat_sekolah', 'Jl. Raya Rajasa No. 123, Surabaya', 'Alamat sekolah', '2026-03-04 17:23:16', NULL),
(3, 'tahun_ajaran', '2024/2025', 'Tahun ajaran aktif', '2026-03-04 17:23:16', NULL),
(4, 'semester', '1', 'Semester aktif', '2026-03-04 17:23:16', NULL),
(5, 'jam_masuk', '07:30:00', 'Jam masuk standar', '2026-03-04 17:23:16', NULL),
(6, 'jam_pulang', '15:00:00', 'Jam pulang standar', '2026-03-04 17:23:16', NULL),
(7, 'toleransi_keterlambatan', '15', 'Toleransi keterlambatan dalam menit', '2026-03-04 17:23:16', NULL),
(8, 'timezone', 'Asia/Jakarta', 'Zona waktu sistem', '2026-03-04 17:23:16', NULL),
(9, 'esp32_api_key', 'rajasa2024secure', 'API Key untuk ESP32-CAM', '2026-03-04 17:23:16', NULL),
(10, 'foto_quality', 'high', 'Kualitas foto capture', '2026-03-04 17:23:16', NULL),
(11, 'door_open_duration', '5', 'Durasi pintu terbuka dalam detik', '2026-03-04 17:23:16', NULL),
(12, 'maintenance_mode', '0', 'Mode maintenance (0=off, 1=on)', '2026-03-04 17:23:16', NULL);

-- --------------------------------------------------------

--
-- Struktur dari tabel `log_akses`
--

CREATE TABLE `log_akses` (
  `id` int(11) UNSIGNED NOT NULL,
  `ruangan_id` int(11) UNSIGNED NOT NULL,
  `rfid_uid` varchar(50) DEFAULT NULL COMMENT 'UID RFID yang dicoba',
  `foto_capture` varchar(255) DEFAULT NULL COMMENT 'Foto yang diambil ESP32-CAM',
  `status` enum('id_tidak_terdaftar','kartu_diblokir','ruangan_tidak_cocok','foto_buram','lainnya') NOT NULL,
  `keterangan` text DEFAULT NULL,
  `tanggal` date NOT NULL,
  `waktu` time NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `notifikasi`
--

CREATE TABLE `notifikasi` (
  `id` int(11) UNSIGNED NOT NULL,
  `user_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'NULL untuk broadcast',
  `judul` varchar(100) NOT NULL,
  `pesan` text NOT NULL,
  `tipe` enum('info','warning','success','error') DEFAULT 'info',
  `is_read` tinyint(1) DEFAULT 0,
  `link` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `peserta_ujian`
--

CREATE TABLE `peserta_ujian` (
  `id` int(11) UNSIGNED NOT NULL,
  `sesi_ujian_id` int(11) UNSIGNED NOT NULL,
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `no_urut` int(11) DEFAULT NULL COMMENT 'Nomor urut duduk',
  `status_kehadiran` enum('hadir','tidak_hadir','izin','sakit') DEFAULT 'tidak_hadir',
  `waktu_hadir` datetime DEFAULT NULL,
  `nilai` decimal(5,2) DEFAULT NULL,
  `keterangan` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `presensi`
--

CREATE TABLE `presensi` (
  `id` int(11) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Struktur dari tabel `ruangan`
--

CREATE TABLE `ruangan` (
  `id` int(11) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Struktur dari tabel `sesi_ujian`
--

CREATE TABLE `sesi_ujian` (
  `id` int(11) UNSIGNED NOT NULL,
  `kode_ujian` varchar(20) NOT NULL,
  `nama_ujian` varchar(100) NOT NULL COMMENT 'Ex: UTS Semester 1, UAS Semester 2',
  `jurusan_id` int(11) UNSIGNED NOT NULL,
  `ruangan_id` int(11) UNSIGNED NOT NULL,
  `tanggal_mulai` date NOT NULL,
  `tanggal_selesai` date NOT NULL,
  `waktu_mulai` time NOT NULL,
  `waktu_selesai` time NOT NULL,
  `durasi_menit` int(11) DEFAULT 90 COMMENT 'Durasi ujian dalam menit',
  `mata_pelajaran` varchar(100) DEFAULT NULL,
  `pengawas_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID admin yang menjadi pengawas',
  `keterangan` text DEFAULT NULL,
  `status` enum('draft','aktif','selesai','dibatalkan') DEFAULT 'draft',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_by` int(11) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `siswa`
--

CREATE TABLE `siswa` (
  `id` int(11) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Struktur dari tabel `users`
--

CREATE TABLE `users` (
  `id` int(11) UNSIGNED NOT NULL,
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

--
-- Dumping data untuk tabel `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `nama_lengkap`, `email`, `no_telp`, `role`, `jurusan_id`, `ruangan_id`, `foto_profile`, `last_login`, `created_at`, `updated_at`, `status`) VALUES
(1, 'admin', '$2y$10$Rl9RK9em59tJVaZxo/wVWeCgANrDKCUKDC2l0FqfNwrQu6SJaRISK', 'Administrator Utama', 'admin@smkrajasa.sch.id', '081234567890', 'admin_operator', NULL, NULL, NULL, '2026-03-05 03:52:45', '2026-03-04 17:23:16', '2026-03-04 21:03:12', 'aktif'),
(2, 'admintkj', '$2y$10$Rl9RK9em59tJVaZxo/wVWeCgANrDKCUKDC2l0FqfNwrQu6SJaRISK', 'Admin Jurusan TKJ', 'tkj@smkrajasa.sch.id', '081234567892', 'admin_jurusan', 1, NULL, NULL, NULL, '2026-03-04 17:23:16', '2026-03-04 19:07:39', 'aktif');

-- --------------------------------------------------------

--
-- Struktur dari tabel `user_sessions`
--

CREATE TABLE `user_sessions` (
  `id` int(11) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `v_log_akses_detail`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `v_log_akses_detail` (
`id` int(11) unsigned
,`rfid_uid` varchar(50)
,`status` enum('id_tidak_terdaftar','kartu_diblokir','ruangan_tidak_cocok','foto_buram','lainnya')
,`keterangan` text
,`tanggal` date
,`waktu` time
,`nama_ruangan` varchar(100)
,`kode_ruangan` varchar(20)
,`nama_jurusan` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `v_presensi_detail`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `v_presensi_detail` (
`id` int(11) unsigned
,`tanggal` date
,`waktu_masuk` time
,`waktu_keluar` time
,`status` enum('hadir','izin','sakit','alpha','terlambat')
,`keterangan` text
,`validasi` enum('valid','tidak_valid','pending')
,`nisn` varchar(20)
,`nis` varchar(20)
,`nama_siswa` varchar(100)
,`kelas` varchar(10)
,`rombel` varchar(10)
,`rfid_uid` varchar(50)
,`nama_jurusan` varchar(100)
,`nama_ruangan` varchar(100)
,`kode_ruangan` varchar(20)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `v_rekap_harian`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `v_rekap_harian` (
`tanggal` date
,`nama_jurusan` varchar(100)
,`nama_ruangan` varchar(100)
,`total_hadir` bigint(21)
,`total_terlambat` bigint(21)
,`total_sakit` bigint(21)
,`total_izin` bigint(21)
,`total_alpha` bigint(21)
,`total_siswa` bigint(21)
);

-- --------------------------------------------------------

--
-- Struktur untuk view `v_log_akses_detail`
--
DROP TABLE IF EXISTS `v_log_akses_detail`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_log_akses_detail`  AS SELECT `la`.`id` AS `id`, `la`.`rfid_uid` AS `rfid_uid`, `la`.`status` AS `status`, `la`.`keterangan` AS `keterangan`, `la`.`tanggal` AS `tanggal`, `la`.`waktu` AS `waktu`, `r`.`nama_ruangan` AS `nama_ruangan`, `r`.`kode_ruangan` AS `kode_ruangan`, `j`.`nama_jurusan` AS `nama_jurusan` FROM ((`log_akses` `la` join `ruangan` `r` on(`la`.`ruangan_id` = `r`.`id`)) join `jurusan` `j` on(`r`.`jurusan_id` = `j`.`id`)) ;

-- --------------------------------------------------------

--
-- Struktur untuk view `v_presensi_detail`
--
DROP TABLE IF EXISTS `v_presensi_detail`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_presensi_detail`  AS SELECT `p`.`id` AS `id`, `p`.`tanggal` AS `tanggal`, `p`.`waktu_masuk` AS `waktu_masuk`, `p`.`waktu_keluar` AS `waktu_keluar`, `p`.`status` AS `status`, `p`.`keterangan` AS `keterangan`, `p`.`validasi` AS `validasi`, `s`.`nisn` AS `nisn`, `s`.`nis` AS `nis`, `s`.`nama_lengkap` AS `nama_siswa`, `s`.`kelas` AS `kelas`, `s`.`rombel` AS `rombel`, `s`.`rfid_uid` AS `rfid_uid`, `j`.`nama_jurusan` AS `nama_jurusan`, `r`.`nama_ruangan` AS `nama_ruangan`, `r`.`kode_ruangan` AS `kode_ruangan` FROM (((`presensi` `p` join `siswa` `s` on(`p`.`siswa_id` = `s`.`id`)) join `jurusan` `j` on(`p`.`jurusan_id` = `j`.`id`)) join `ruangan` `r` on(`p`.`ruangan_id` = `r`.`id`)) ;

-- --------------------------------------------------------

--
-- Struktur untuk view `v_rekap_harian`
--
DROP TABLE IF EXISTS `v_rekap_harian`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_rekap_harian`  AS SELECT `p`.`tanggal` AS `tanggal`, `j`.`nama_jurusan` AS `nama_jurusan`, `r`.`nama_ruangan` AS `nama_ruangan`, count(case when `p`.`status` = 'hadir' then 1 end) AS `total_hadir`, count(case when `p`.`status` = 'terlambat' then 1 end) AS `total_terlambat`, count(case when `p`.`status` = 'sakit' then 1 end) AS `total_sakit`, count(case when `p`.`status` = 'izin' then 1 end) AS `total_izin`, count(case when `p`.`status` = 'alpha' then 1 end) AS `total_alpha`, count(0) AS `total_siswa` FROM ((`presensi` `p` join `jurusan` `j` on(`p`.`jurusan_id` = `j`.`id`)) join `ruangan` `r` on(`p`.`ruangan_id` = `r`.`id`)) GROUP BY `p`.`tanggal`, `p`.`jurusan_id`, `p`.`ruangan_id` ;

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `admin_activities`
--
ALTER TABLE `admin_activities`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_activity_type` (`activity_type`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indeks untuk tabel `jurusan`
--
ALTER TABLE `jurusan`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `kode_jurusan` (`kode_jurusan`);

--
-- Indeks untuk tabel `konfigurasi`
--
ALTER TABLE `konfigurasi`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `kunci` (`kunci`),
  ADD KEY `updated_by` (`updated_by`);

--
-- Indeks untuk tabel `log_akses`
--
ALTER TABLE `log_akses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ruangan_id` (`ruangan_id`);

--
-- Indeks untuk tabel `notifikasi`
--
ALTER TABLE `notifikasi`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indeks untuk tabel `peserta_ujian`
--
ALTER TABLE `peserta_ujian`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_peserta` (`sesi_ujian_id`,`siswa_id`),
  ADD KEY `siswa_id` (`siswa_id`);

--
-- Indeks untuk tabel `presensi`
--
ALTER TABLE `presensi`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_presensi_harian` (`siswa_id`,`ruangan_id`,`tanggal`),
  ADD KEY `ruangan_id` (`ruangan_id`),
  ADD KEY `jurusan_id` (`jurusan_id`),
  ADD KEY `diverifikasi_oleh` (`diverifikasi_oleh`);

--
-- Indeks untuk tabel `ruangan`
--
ALTER TABLE `ruangan`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `kode_ruangan` (`kode_ruangan`),
  ADD KEY `jurusan_id` (`jurusan_id`);

--
-- Indeks untuk tabel `sesi_ujian`
--
ALTER TABLE `sesi_ujian`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `kode_ujian` (`kode_ujian`),
  ADD KEY `jurusan_id` (`jurusan_id`),
  ADD KEY `ruangan_id` (`ruangan_id`),
  ADD KEY `pengawas_id` (`pengawas_id`),
  ADD KEY `created_by` (`created_by`);

--
-- Indeks untuk tabel `siswa`
--
ALTER TABLE `siswa`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nisn` (`nisn`),
  ADD UNIQUE KEY `nis` (`nis`),
  ADD KEY `jurusan_id` (`jurusan_id`);

--
-- Indeks untuk tabel `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `jurusan_id` (`jurusan_id`),
  ADD KEY `ruangan_id` (`ruangan_id`);

--
-- Indeks untuk tabel `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_session_token` (`session_token`),
  ADD KEY `idx_last_activity` (`last_activity`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `admin_activities`
--
ALTER TABLE `admin_activities`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `jurusan`
--
ALTER TABLE `jurusan`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `konfigurasi`
--
ALTER TABLE `konfigurasi`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT untuk tabel `log_akses`
--
ALTER TABLE `log_akses`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `notifikasi`
--
ALTER TABLE `notifikasi`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `peserta_ujian`
--
ALTER TABLE `peserta_ujian`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `presensi`
--
ALTER TABLE `presensi`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `ruangan`
--
ALTER TABLE `ruangan`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `sesi_ujian`
--
ALTER TABLE `sesi_ujian`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `siswa`
--
ALTER TABLE `siswa`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT untuk tabel `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `admin_activities`
--
ALTER TABLE `admin_activities`
  ADD CONSTRAINT `admin_activities_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `konfigurasi`
--
ALTER TABLE `konfigurasi`
  ADD CONSTRAINT `konfigurasi_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `log_akses`
--
ALTER TABLE `log_akses`
  ADD CONSTRAINT `log_akses_ibfk_1` FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `notifikasi`
--
ALTER TABLE `notifikasi`
  ADD CONSTRAINT `notifikasi_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `peserta_ujian`
--
ALTER TABLE `peserta_ujian`
  ADD CONSTRAINT `peserta_ujian_ibfk_1` FOREIGN KEY (`sesi_ujian_id`) REFERENCES `sesi_ujian` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `peserta_ujian_ibfk_2` FOREIGN KEY (`siswa_id`) REFERENCES `siswa` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `presensi`
--
ALTER TABLE `presensi`
  ADD CONSTRAINT `presensi_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `siswa` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `presensi_ibfk_2` FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `presensi_ibfk_3` FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `presensi_ibfk_4` FOREIGN KEY (`diverifikasi_oleh`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `ruangan`
--
ALTER TABLE `ruangan`
  ADD CONSTRAINT `ruangan_ibfk_1` FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `sesi_ujian`
--
ALTER TABLE `sesi_ujian`
  ADD CONSTRAINT `sesi_ujian_ibfk_1` FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `sesi_ujian_ibfk_2` FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `sesi_ujian_ibfk_3` FOREIGN KEY (`pengawas_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `sesi_ujian_ibfk_4` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `siswa`
--
ALTER TABLE `siswa`
  ADD CONSTRAINT `siswa_ibfk_1` FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `users_ibfk_2` FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD CONSTRAINT `user_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;