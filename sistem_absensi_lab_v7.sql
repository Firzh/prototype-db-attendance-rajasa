-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 26 Apr 2026 pada 20.45
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
-- Struktur dari tabel `beasiswa`
--

CREATE TABLE `beasiswa` (
  `id` int(11) UNSIGNED NOT NULL,
  `nama_beasiswa` varchar(200) NOT NULL,
  `penyedia` varchar(100) NOT NULL,
  `jumlah_dana` decimal(12,2) DEFAULT NULL,
  `kuota` int(11) DEFAULT 1,
  `tanggal_pembukaan` date NOT NULL,
  `tanggal_penutupan` date NOT NULL,
  `persyaratan` text DEFAULT NULL,
  `status` enum('aktif','nonaktif') DEFAULT 'aktif',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `beasiswa`
--

INSERT INTO `beasiswa` (`id`, `nama_beasiswa`, `penyedia`, `jumlah_dana`, `kuota`, `tanggal_pembukaan`, `tanggal_penutupan`, `persyaratan`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Beasiswa Prestasi Akademik', 'Dinas Pendidikan Jawa Timur', 2000000.00, 10, '2026-04-01', '2026-05-31', '1. Nilai rata-rata minimal 85\n2. Tidak sedang menerima beasiswa lain\n3. Surat keterangan aktif sekolah\n4. Fotokopi rapor semester terakhir', 'aktif', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(2, 'Beasiswa Keluarga Tidak Mampu (KIP)', 'Kemendikbud RI', 1800000.00, 5, '2026-04-15', '2026-06-15', '1. Memiliki Kartu Indonesia Pintar (KIP)\n2. Penghasilan orang tua di bawah UMR\n3. Surat keterangan tidak mampu dari kelurahan\n4. Fotokopi KK dan KTP orang tua', 'aktif', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(3, 'Beasiswa Olimpiade Sains', 'Yayasan Rajasa Surabaya', 1500000.00, 3, '2026-05-01', '2026-07-01', '1. Pernah mengikuti olimpiade tingkat kota/provinsi\n2. Nilai matematika dan IPA minimal 80\n3. Rekomendasi dari guru pembimbing\n4. Essay motivasi (500 kata)', 'aktif', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(4, 'Beasiswa Jurusan RPL', 'PT. Teknologi Nusantara', 3000000.00, 2, '2026-03-01', '2026-04-30', '1. Siswa aktif jurusan RPL\n2. Nilai pemrograman minimal 88\n3. Memiliki portofolio proyek\n4. Mengikuti seleksi wawancara', 'nonaktif', '2026-04-24 06:34:19', '2026-04-24 06:34:19');

-- --------------------------------------------------------

--
-- Struktur dari tabel `calendar_akademik`
--

CREATE TABLE `calendar_akademik` (
  `id` int(10) UNSIGNED NOT NULL,
  `nama_kegiatan` varchar(255) NOT NULL,
  `tanggal` date NOT NULL,
  `jenis_kegiatan` enum('Libur Nasional','Hari Belajar','Ujian','Semester Baru','Kenaikan Kelas','Wisuda','Lainnya','Kegiatan Sekolah','Kunjungan','') DEFAULT 'Lainnya',
  `keterangan` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `calendar_akademik`
--

INSERT INTO `calendar_akademik` (`id`, `nama_kegiatan`, `tanggal`, `jenis_kegiatan`, `keterangan`) VALUES
(1, 'Hari Kartini', '2026-04-21', 'Libur Nasional', 'Libur memperingati Hari Kartini'),
(2, 'UTS Semester Genap', '2026-04-28', 'Ujian', 'Ujian Tengah Semester Genap 2025/2026'),
(3, 'UTS Semester Genap', '2026-04-29', 'Ujian', 'Ujian Tengah Semester Genap 2025/2026'),
(4, 'UTS Semester Genap', '2026-04-30', 'Ujian', 'Ujian Tengah Semester Genap 2025/2026'),
(5, 'Libur Hari Buruh', '2026-05-01', 'Libur Nasional', 'Hari Buruh Internasional'),
(6, 'Pentas Seni Akhir Tahun', '2026-05-15', '', 'Penampilan siswa semua jurusan di aula'),
(7, 'UAS Semester Genap', '2026-06-01', 'Ujian', 'Ujian Akhir Semester Genap 2025/2026'),
(8, 'Kenaikan Kelas', '2026-06-20', 'Kenaikan Kelas', 'Pembagian rapor dan pengumuman kenaikan kelas'),
(9, 'Libur Semester Genap', '2026-06-22', '', 'Libur akhir tahun ajaran 2025/2026'),
(10, 'Hari Kartini', '2026-04-21', 'Libur Nasional', 'Memperingati Hari Kartini'),
(11, 'UTS Semester Genap Mulai', '2026-04-27', 'Ujian', 'Ujian Tengah Semester Genap dimulai'),
(12, 'UTS Semester Genap', '2026-04-28', 'Ujian', 'UTS hari kedua'),
(13, 'UTS Semester Genap', '2026-04-29', 'Ujian', 'UTS hari ketiga'),
(14, 'UTS Semester Genap Selesai', '2026-04-30', 'Ujian', 'UTS hari terakhir'),
(15, 'Hari Buruh Internasional', '2026-05-01', 'Libur Nasional', 'Libur Hari Buruh'),
(16, 'Hari Pendidikan Nasional', '2026-05-02', 'Hari Belajar', 'Upacara peringatan Hardiknas'),
(17, 'Kenaikan Isa Almasih', '2026-05-14', 'Libur Nasional', 'Libur Nasional'),
(18, 'Pentas Seni Akhir Tahun', '2026-05-15', '', 'Penampilan seni semua kelas di aula sekolah'),
(19, 'Pentas Seni Akhir Tahun', '2026-05-16', '', 'Hari kedua pentas seni'),
(20, 'Studi Banding ke Jakarta', '2026-06-01', '', 'Kunjungan industri jurusan RPL dan TKJ'),
(21, 'Studi Banding ke Jakarta', '2026-06-02', '', 'Kunjungan hari kedua'),
(22, 'Studi Banding ke Jakarta', '2026-06-03', '', 'Kunjungan hari ketiga'),
(23, 'UAS Semester Genap Mulai', '2026-06-08', 'Ujian', 'Ujian Akhir Semester Genap dimulai'),
(24, 'UAS Semester Genap', '2026-06-09', 'Ujian', 'UAS hari kedua'),
(25, 'UAS Semester Genap', '2026-06-10', 'Ujian', 'UAS hari ketiga'),
(26, 'UAS Semester Genap', '2026-06-11', 'Ujian', 'UAS hari keempat'),
(27, 'UAS Semester Genap Selesai', '2026-06-12', 'Ujian', 'UAS hari terakhir'),
(28, 'Pengumuman Kenaikan Kelas', '2026-06-19', 'Kenaikan Kelas', 'Pengumuman hasil kenaikan kelas'),
(29, 'Pembagian Rapor', '2026-06-20', 'Kenaikan Kelas', 'Pembagian rapor semester genap'),
(30, 'Libur Akhir Tahun Ajaran', '2026-06-22', '', 'Libur panjang akhir tahun ajaran 2025/2026'),
(31, 'Tahun Ajaran Baru', '2026-07-13', 'Semester Baru', 'Hari pertama masuk tahun ajaran 2026/2027'),
(32, 'Masa Orientasi Siswa', '2026-07-13', 'Semester Baru', 'MOS untuk siswa baru kelas X'),
(33, 'Masa Orientasi Siswa', '2026-07-14', 'Semester Baru', 'MOS hari kedua'),
(34, 'Masa Orientasi Siswa', '2026-07-15', 'Semester Baru', 'MOS hari ketiga'),
(35, 'Hari Kartini', '2026-04-21', 'Libur Nasional', 'Memperingati Hari Kartini'),
(36, 'UTS Semester Genap Mulai', '2026-04-27', 'Ujian', 'Ujian Tengah Semester Genap dimulai'),
(37, 'UTS Semester Genap', '2026-04-28', 'Ujian', 'UTS hari kedua'),
(38, 'UTS Semester Genap', '2026-04-29', 'Ujian', 'UTS hari ketiga'),
(39, 'UTS Semester Genap Selesai', '2026-04-30', 'Ujian', 'UTS hari terakhir'),
(40, 'Hari Buruh Internasional', '2026-05-01', 'Libur Nasional', 'Libur Hari Buruh'),
(41, 'Hari Pendidikan Nasional', '2026-05-02', 'Hari Belajar', 'Upacara peringatan Hardiknas'),
(42, 'Kenaikan Isa Almasih', '2026-05-14', 'Libur Nasional', 'Libur Nasional'),
(43, 'Pentas Seni Akhir Tahun', '2026-05-15', '', 'Penampilan seni semua kelas di aula sekolah'),
(44, 'Pentas Seni Akhir Tahun', '2026-05-16', '', 'Hari kedua pentas seni'),
(45, 'Studi Banding ke Jakarta', '2026-06-01', '', 'Kunjungan industri jurusan RPL dan TKJ'),
(46, 'Studi Banding ke Jakarta', '2026-06-02', '', 'Kunjungan hari kedua'),
(47, 'Studi Banding ke Jakarta', '2026-06-03', '', 'Kunjungan hari ketiga'),
(48, 'UAS Semester Genap Mulai', '2026-06-08', 'Ujian', 'Ujian Akhir Semester Genap dimulai'),
(49, 'UAS Semester Genap', '2026-06-09', 'Ujian', 'UAS hari kedua'),
(50, 'UAS Semester Genap', '2026-06-10', 'Ujian', 'UAS hari ketiga'),
(51, 'UAS Semester Genap', '2026-06-11', 'Ujian', 'UAS hari keempat'),
(52, 'UAS Semester Genap Selesai', '2026-06-12', 'Ujian', 'UAS hari terakhir'),
(53, 'Pengumuman Kenaikan Kelas', '2026-06-19', 'Kenaikan Kelas', 'Pengumuman hasil kenaikan kelas'),
(54, 'Pembagian Rapor', '2026-06-20', 'Kenaikan Kelas', 'Pembagian rapor semester genap'),
(55, 'Libur Akhir Tahun Ajaran', '2026-06-22', '', 'Libur panjang akhir tahun ajaran 2025/2026'),
(56, 'Tahun Ajaran Baru', '2026-07-13', 'Semester Baru', 'Hari pertama masuk tahun ajaran 2026/2027'),
(57, 'Masa Orientasi Siswa', '2026-07-13', 'Semester Baru', 'MOS untuk siswa baru kelas X'),
(58, 'Masa Orientasi Siswa', '2026-07-14', 'Semester Baru', 'MOS hari kedua'),
(59, 'Masa Orientasi Siswa', '2026-07-15', 'Semester Baru', 'MOS hari ketiga'),
(60, 'Hari Kartini', '2026-04-21', 'Libur Nasional', 'Memperingati Hari Kartini'),
(61, 'UTS Semester Genap Mulai', '2026-04-27', 'Ujian', 'Ujian Tengah Semester Genap dimulai'),
(62, 'UTS Semester Genap', '2026-04-28', 'Ujian', 'UTS hari kedua'),
(63, 'UTS Semester Genap', '2026-04-29', 'Ujian', 'UTS hari ketiga'),
(64, 'UTS Semester Genap Selesai', '2026-04-30', 'Ujian', 'UTS hari terakhir'),
(65, 'Hari Buruh Internasional', '2026-05-01', 'Libur Nasional', 'Libur Hari Buruh'),
(66, 'Hari Pendidikan Nasional', '2026-05-02', 'Hari Belajar', 'Upacara peringatan Hardiknas'),
(67, 'Kenaikan Isa Almasih', '2026-05-14', 'Libur Nasional', 'Libur Nasional'),
(68, 'Pentas Seni Akhir Tahun', '2026-05-15', 'Kegiatan Sekolah', 'Penampilan seni semua kelas di aula sekolah'),
(69, 'Pentas Seni Akhir Tahun', '2026-05-16', 'Kegiatan Sekolah', 'Hari kedua pentas seni'),
(70, 'Studi Banding ke Jakarta', '2026-06-01', 'Kunjungan', 'Kunjungan industri jurusan RPL dan TKJ'),
(71, 'Studi Banding ke Jakarta', '2026-06-02', 'Kunjungan', 'Kunjungan hari kedua'),
(72, 'Studi Banding ke Jakarta', '2026-06-03', 'Kunjungan', 'Kunjungan hari ketiga'),
(73, 'UAS Semester Genap Mulai', '2026-06-08', 'Ujian', 'Ujian Akhir Semester Genap dimulai'),
(74, 'UAS Semester Genap', '2026-06-09', 'Ujian', 'UAS hari kedua'),
(75, 'UAS Semester Genap', '2026-06-10', 'Ujian', 'UAS hari ketiga'),
(76, 'UAS Semester Genap', '2026-06-11', 'Ujian', 'UAS hari keempat'),
(77, 'UAS Semester Genap Selesai', '2026-06-12', 'Ujian', 'UAS hari terakhir'),
(78, 'Pengumuman Kenaikan Kelas', '2026-06-19', 'Kenaikan Kelas', 'Pengumuman hasil kenaikan kelas'),
(79, 'Pembagian Rapor', '2026-06-20', 'Kenaikan Kelas', 'Pembagian rapor semester genap'),
(80, 'Libur Akhir Tahun Ajaran', '2026-06-22', 'Lainnya', 'Libur panjang akhir tahun ajaran 2025/2026'),
(81, 'Tahun Ajaran Baru', '2026-07-13', 'Semester Baru', 'Hari pertama masuk tahun ajaran 2026/2027'),
(82, 'Masa Orientasi Siswa', '2026-07-13', 'Semester Baru', 'MOS untuk siswa baru kelas X'),
(83, 'Masa Orientasi Siswa', '2026-07-14', 'Semester Baru', 'MOS hari kedua'),
(84, 'Masa Orientasi Siswa', '2026-07-15', 'Semester Baru', 'MOS hari ketiga'),
(85, 'Hari Kartini', '2026-04-21', 'Libur Nasional', 'Memperingati Hari Kartini'),
(86, 'UTS Semester Genap - Hari 1', '2026-04-27', 'Ujian', 'Ujian Tengah Semester Genap mulai'),
(87, 'UTS Semester Genap - Hari 2', '2026-04-28', 'Ujian', 'UTS hari kedua'),
(88, 'UTS Semester Genap - Hari 3', '2026-04-29', 'Ujian', 'UTS hari ketiga'),
(89, 'UTS Semester Genap - Hari 4', '2026-04-30', 'Ujian', 'UTS hari terakhir'),
(90, 'Hari Buruh Internasional', '2026-05-01', 'Libur Nasional', 'Libur Hari Buruh'),
(91, 'Hari Pendidikan Nasional', '2026-05-02', 'Hari Belajar', 'Upacara Hardiknas'),
(92, 'Kenaikan Isa Almasih', '2026-05-14', 'Libur Nasional', 'Libur Nasional'),
(93, 'Pentas Seni Akhir Tahun', '2026-05-15', 'Lainnya', 'Penampilan seni semua kelas di aula'),
(94, 'Pentas Seni Akhir Tahun', '2026-05-16', 'Lainnya', 'Pentas seni hari kedua'),
(95, 'Studi Banding Jakarta', '2026-06-01', 'Lainnya', 'Kunjungan industri RPL dan TKJ'),
(96, 'Studi Banding Jakarta', '2026-06-02', 'Lainnya', 'Kunjungan hari kedua'),
(97, 'UAS Semester Genap - Hari 1', '2026-06-08', 'Ujian', 'Ujian Akhir Semester Genap'),
(98, 'UAS Semester Genap - Hari 2', '2026-06-09', 'Ujian', 'UAS hari kedua'),
(99, 'UAS Semester Genap - Hari 3', '2026-06-10', 'Ujian', 'UAS hari ketiga'),
(100, 'UAS Semester Genap - Hari 4', '2026-06-11', 'Ujian', 'UAS hari keempat'),
(101, 'UAS Semester Genap Selesai', '2026-06-12', 'Ujian', 'UAS hari terakhir'),
(102, 'Pengumuman Kenaikan Kelas', '2026-06-19', 'Kenaikan Kelas', 'Pengumuman hasil kenaikan kelas'),
(103, 'Pembagian Rapor', '2026-06-20', 'Kenaikan Kelas', 'Pembagian rapor semester genap'),
(104, 'Libur Akhir Tahun Ajaran', '2026-06-22', 'Lainnya', 'Libur panjang akhir tahun ajaran'),
(105, 'Tahun Ajaran Baru 2026/2027', '2026-07-13', 'Semester Baru', 'Hari pertama masuk tahun ajaran baru'),
(106, 'Masa Orientasi Siswa', '2026-07-13', 'Semester Baru', 'MOS untuk siswa baru kelas X'),
(107, 'Wisuda Kelas XII', '2026-07-20', 'Wisuda', 'Upacara wisuda kelas XII');

-- --------------------------------------------------------

--
-- Struktur dari tabel `jadwal_pelajaran`
--

CREATE TABLE `jadwal_pelajaran` (
  `id` int(11) UNSIGNED NOT NULL,
  `kelas_id` int(11) UNSIGNED NOT NULL,
  `mata_pelajaran_id` int(11) UNSIGNED NOT NULL,
  `guru_id` int(11) UNSIGNED DEFAULT NULL,
  `hari` enum('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu') NOT NULL,
  `jam_mulai` time NOT NULL,
  `jam_selesai` time NOT NULL,
  `ruang` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `jadwal_pelajaran`
--

INSERT INTO `jadwal_pelajaran` (`id`, `kelas_id`, `mata_pelajaran_id`, `guru_id`, `hari`, `jam_mulai`, `jam_selesai`, `ruang`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 10, 'Senin', '07:00:00', '08:30:00', 'Ruang Teori 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(2, 1, 7, 10, 'Senin', '08:30:00', '10:30:00', 'Lab Komputer 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(3, 1, 9, 10, 'Senin', '10:45:00', '12:15:00', 'Lab Komputer 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(4, 1, 2, 10, 'Selasa', '07:00:00', '08:30:00', 'Ruang Teori 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(5, 1, 8, 10, 'Selasa', '08:30:00', '10:30:00', 'Lab Komputer 2', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(6, 1, 10, 10, 'Selasa', '10:45:00', '12:15:00', 'Ruang Teori 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(7, 1, 3, 10, 'Rabu', '07:00:00', '08:30:00', 'Ruang Teori 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(8, 1, 4, 10, 'Rabu', '08:30:00', '10:00:00', 'Ruang Teori 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(9, 1, 7, 10, 'Rabu', '10:15:00', '12:15:00', 'Lab Komputer 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(10, 1, 5, 10, 'Kamis', '07:00:00', '08:30:00', 'Lapangan', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(11, 1, 9, 10, 'Kamis', '08:45:00', '10:45:00', 'Lab Komputer 2', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(12, 1, 8, 10, 'Kamis', '10:45:00', '12:15:00', 'Lab Komputer 2', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(13, 1, 1, 10, 'Jumat', '07:00:00', '08:30:00', 'Ruang Teori 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(14, 1, 6, 10, 'Jumat', '08:30:00', '10:00:00', 'Ruang Teori 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(15, 1, 10, 10, 'Sabtu', '07:00:00', '08:30:00', 'Lab Komputer 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(16, 1, 2, 10, 'Sabtu', '08:30:00', '10:00:00', 'Ruang Teori 1', '2026-04-24 06:34:19', '2026-04-24 06:34:19');

-- --------------------------------------------------------

--
-- Struktur dari tabel `jurusan`
--

CREATE TABLE `jurusan` (
  `id` int(10) UNSIGNED NOT NULL,
  `kode_jurusan` varchar(20) NOT NULL,
  `nama_jurusan` varchar(255) NOT NULL,
  `deskripsi` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `jurusan`
--

INSERT INTO `jurusan` (`id`, `kode_jurusan`, `nama_jurusan`, `deskripsi`) VALUES
(1, 'TKJ', 'Teknik Komputer dan Jaringan', 'Jurusan yang mempelajari tentang komputer dan jaringan'),
(2, 'RPL', 'Rekayasa Perangkat Lunak', 'Jurusan yang mempelajari tentang pengembangan perangkat lunak'),
(3, 'MM', 'Multimedia', 'Jurusan yang mempelajari tentang desain dan produksi media digital');

-- --------------------------------------------------------

--
-- Struktur dari tabel `kegiatan_sekolah`
--

CREATE TABLE `kegiatan_sekolah` (
  `id` int(10) UNSIGNED NOT NULL,
  `nama_kegiatan` varchar(255) NOT NULL,
  `tanggal_mulai` date DEFAULT NULL,
  `tanggal_selesai` date DEFAULT NULL,
  `lokasi` varchar(255) DEFAULT NULL,
  `deskripsi` text DEFAULT NULL,
  `peserta` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `kegiatan_sekolah`
--

INSERT INTO `kegiatan_sekolah` (`id`, `nama_kegiatan`, `tanggal_mulai`, `tanggal_selesai`, `lokasi`, `deskripsi`, `peserta`) VALUES
(1, 'Pentas Seni Akhir Tahun', '2026-05-15', '2026-05-16', 'Aula SMK Rajasa', 'Penampilan siswa dari semua jurusan', NULL),
(2, 'Studi Banding ke Jakarta', '2026-06-01', '2026-06-03', 'Jakarta', 'Kunjungan industri RPL dan TKJ', NULL),
(3, 'Upacara Hari Pendidikan Nasional', '2026-05-02', '2026-05-02', 'Lapangan Upacara SMK Rajasa', 'Upacara peringatan Hari Pendidikan Nasional ke-61', 'Semua siswa dan guru'),
(4, 'Olimpiade Matematika Tingkat Kota', '2026-05-10', '2026-05-10', 'SMAN 5 Surabaya', 'Olimpiade matematika antar SMA/SMK se-Kota Surabaya', 'Perwakilan siswa terpilih'),
(5, 'Seminar Karir dan Dunia Kerja', '2026-05-20', '2026-05-20', 'Aula SMK Rajasa', 'Seminar tentang peluang kerja di bidang IT dan persiapan memasuki dunia kerja', 'Siswa kelas XII'),
(6, 'Ujian Kompetensi Keahlian (UKK)', '2026-05-25', '2026-05-27', 'Lab Komputer SMK Rajasa', 'Ujian praktik kompetensi keahlian untuk siswa kelas XII sebagai syarat kelulusan', 'Siswa kelas XII'),
(7, 'Rapat Orang Tua Siswa', '2026-06-05', '2026-06-05', 'Aula SMK Rajasa', 'Rapat koordinasi antara pihak sekolah dan orang tua/wali siswa terkait perkembangan akademik dan kehadiran', 'Orang tua/wali siswa');

-- --------------------------------------------------------

--
-- Struktur dari tabel `kelas`
--

CREATE TABLE `kelas` (
  `id` int(10) UNSIGNED NOT NULL,
  `nama_kelas` varchar(100) NOT NULL,
  `tingkat` enum('10','11','12') NOT NULL,
  `jurusan_id` int(10) UNSIGNED DEFAULT NULL,
  `tahun_ajaran` varchar(9) NOT NULL,
  `wali_kelas` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `kelas`
--

INSERT INTO `kelas` (`id`, `nama_kelas`, `tingkat`, `jurusan_id`, `tahun_ajaran`, `wali_kelas`) VALUES
(1, 'XII RPL 1', '12', 2, '2025/2026', 'Pak Budi'),
(2, 'XI TKJ 2', '11', 1, '2025/2026', 'Bu Siti'),
(3, 'X MM 1', '10', 3, '2025/2026', 'Pak Andi');

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
-- Struktur dari tabel `logs`
--

CREATE TABLE `logs` (
  `id` int(11) UNSIGNED NOT NULL,
  `user_id` int(11) UNSIGNED DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `table_name` varchar(100) NOT NULL,
  `record_id` int(11) DEFAULT NULL,
  `old_value` text DEFAULT NULL,
  `new_value` text DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
-- Struktur dari tabel `mata_pelajaran`
--

CREATE TABLE `mata_pelajaran` (
  `id` int(10) UNSIGNED NOT NULL,
  `kode_mapel` varchar(20) NOT NULL,
  `nama_mapel` varchar(255) NOT NULL,
  `jurusan_id` int(10) UNSIGNED DEFAULT NULL,
  `km` enum('Kelompok A','Kelompok B','Kelompok C','Kelompok A (Normatif)','Kelompok B (Adaptif)','Kelompok C (Produktif)','') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `mata_pelajaran`
--

INSERT INTO `mata_pelajaran` (`id`, `kode_mapel`, `nama_mapel`, `jurusan_id`, `km`) VALUES
(1, 'MTK', 'Matematika', NULL, ''),
(2, 'BIN', 'Bahasa Indonesia', NULL, ''),
(3, 'BIG', 'Bahasa Inggris', NULL, ''),
(4, 'PKN', 'Pendidikan Kewarganegaraan', NULL, ''),
(5, 'WEB', 'Pemrograman Web', 2, ''),
(6, 'DB', 'Basis Data', 2, ''),
(7, 'ALGO', 'Algoritma dan Pemrograman', 2, ''),
(10, 'SIM', 'Simulasi dan Komunikasi Digital', 2, ''),
(11, 'JRG', 'Teknologi Jaringan Berbasis Luas', 1, ''),
(12, 'ADM', 'Administrasi Sistem Jaringan', 1, ''),
(13, 'DES', 'Desain Grafis', 3, ''),
(14, 'VID', 'Produksi Video', 3, '');

-- --------------------------------------------------------

--
-- Struktur dari tabel `nilai_akademik`
--

CREATE TABLE `nilai_akademik` (
  `id` int(10) UNSIGNED NOT NULL,
  `siswa_id` int(10) UNSIGNED NOT NULL,
  `mata_pelajaran_id` int(10) UNSIGNED NOT NULL,
  `nilai_harian` decimal(5,2) DEFAULT NULL,
  `nilai_uts` decimal(5,2) DEFAULT NULL,
  `nilai_uas` decimal(5,2) DEFAULT NULL,
  `nilai_praktek` decimal(5,2) DEFAULT NULL,
  `semester` enum('Ganjil','Genap') DEFAULT NULL,
  `tahun_ajaran` varchar(9) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `nilai_akademik`
--

INSERT INTO `nilai_akademik` (`id`, `siswa_id`, `mata_pelajaran_id`, `nilai_harian`, `nilai_uts`, `nilai_uas`, `nilai_praktek`, `semester`, `tahun_ajaran`) VALUES
(1, 1, 1, 82.00, 78.00, 80.00, NULL, 'Ganjil', '2025/2026'),
(2, 1, 2, 88.00, 85.00, 87.00, NULL, 'Ganjil', '2025/2026'),
(3, 1, 3, 75.00, 72.00, 74.00, NULL, 'Ganjil', '2025/2026'),
(4, 1, 4, 90.00, 88.00, 89.00, NULL, 'Ganjil', '2025/2026'),
(5, 1, 5, 92.00, 90.00, 91.00, 88.00, 'Ganjil', '2025/2026'),
(6, 1, 6, 85.00, 83.00, 84.00, 90.00, 'Ganjil', '2025/2026'),
(7, 1, 7, 89.00, 87.00, 88.00, 92.00, 'Ganjil', '2025/2026'),
(8, 1, 1, 82.00, 78.00, 80.00, NULL, 'Ganjil', '2025/2026'),
(9, 1, 2, 88.00, 85.00, 87.00, NULL, 'Ganjil', '2025/2026'),
(10, 1, 3, 75.00, 72.00, 74.00, NULL, 'Ganjil', '2025/2026'),
(11, 1, 4, 90.00, 88.00, 89.00, NULL, 'Ganjil', '2025/2026'),
(12, 1, 5, 85.00, 80.00, 82.00, NULL, 'Ganjil', '2025/2026'),
(13, 1, 6, 78.00, 76.00, 77.00, NULL, 'Ganjil', '2025/2026'),
(14, 1, 7, 92.00, 90.00, 91.00, 88.00, 'Ganjil', '2025/2026'),
(15, 1, 10, 84.00, 82.00, 83.00, 85.00, 'Ganjil', '2025/2026'),
(16, 1, 1, 84.00, 80.00, 82.00, NULL, 'Genap', '2025/2026'),
(17, 1, 2, 90.00, 87.00, 88.00, NULL, 'Genap', '2025/2026'),
(18, 1, 3, 77.00, 74.00, 76.00, NULL, 'Genap', '2025/2026'),
(19, 1, 4, 91.00, 89.00, 90.00, NULL, 'Genap', '2025/2026'),
(20, 1, 7, 94.00, 92.00, 93.00, 91.00, 'Genap', '2025/2026'),
(25, 2, 1, 76.00, 74.00, 75.00, NULL, 'Ganjil', '2025/2026'),
(26, 2, 2, 83.00, 80.00, 81.00, NULL, 'Ganjil', '2025/2026'),
(27, 2, 3, 70.00, 68.00, 69.00, NULL, 'Ganjil', '2025/2026'),
(28, 2, 11, 88.00, 85.00, 86.00, 90.00, 'Ganjil', '2025/2026'),
(29, 2, 12, 84.00, 82.00, 83.00, 87.00, 'Ganjil', '2025/2026'),
(30, 1, 1, 82.00, 78.00, 80.00, NULL, 'Ganjil', '2025/2026'),
(31, 1, 2, 88.00, 85.00, 87.00, NULL, 'Ganjil', '2025/2026'),
(32, 1, 3, 75.00, 72.00, 74.00, NULL, 'Ganjil', '2025/2026'),
(33, 1, 4, 90.00, 88.00, 89.00, NULL, 'Ganjil', '2025/2026'),
(34, 1, 5, 85.00, 80.00, 82.00, NULL, 'Ganjil', '2025/2026'),
(35, 1, 6, 78.00, 76.00, 77.00, NULL, 'Ganjil', '2025/2026'),
(36, 1, 7, 92.00, 90.00, 91.00, 88.00, 'Ganjil', '2025/2026'),
(37, 1, 8, 87.00, 85.00, 86.00, 90.00, 'Ganjil', '2025/2026'),
(38, 1, 9, 89.00, 87.00, 88.00, 92.00, 'Ganjil', '2025/2026'),
(39, 1, 10, 84.00, 82.00, 83.00, 85.00, 'Ganjil', '2025/2026'),
(40, 1, 1, 84.00, 80.00, 82.00, NULL, 'Genap', '2025/2026'),
(41, 1, 2, 90.00, 87.00, 88.00, NULL, 'Genap', '2025/2026'),
(42, 1, 3, 77.00, 74.00, 76.00, NULL, 'Genap', '2025/2026'),
(43, 1, 4, 91.00, 89.00, 90.00, NULL, 'Genap', '2025/2026'),
(44, 1, 7, 94.00, 92.00, 93.00, 91.00, 'Genap', '2025/2026'),
(45, 1, 8, 88.00, 86.00, 87.00, 92.00, 'Genap', '2025/2026'),
(46, 1, 9, 91.00, 89.00, 90.00, 94.00, 'Genap', '2025/2026'),
(47, 2, 1, 76.00, 74.00, 75.00, NULL, 'Ganjil', '2025/2026'),
(48, 2, 2, 83.00, 80.00, 81.00, NULL, 'Ganjil', '2025/2026'),
(49, 2, 3, 70.00, 68.00, 69.00, NULL, 'Ganjil', '2025/2026'),
(50, 2, 11, 88.00, 85.00, 86.00, 90.00, 'Ganjil', '2025/2026'),
(51, 2, 12, 84.00, 82.00, 83.00, 87.00, 'Ganjil', '2025/2026'),
(52, 1, 1, 82.00, 78.00, 80.00, NULL, 'Ganjil', '2025/2026'),
(53, 1, 2, 88.00, 85.00, 87.00, NULL, 'Ganjil', '2025/2026'),
(54, 1, 3, 75.00, 72.00, 74.00, NULL, 'Ganjil', '2025/2026'),
(55, 1, 4, 90.00, 88.00, 89.00, NULL, 'Ganjil', '2025/2026'),
(56, 1, 5, 85.00, 80.00, 82.00, NULL, 'Ganjil', '2025/2026'),
(57, 1, 6, 78.00, 76.00, 77.00, NULL, 'Ganjil', '2025/2026'),
(58, 1, 7, 92.00, 90.00, 91.00, 88.00, 'Ganjil', '2025/2026'),
(59, 1, 10, 84.00, 82.00, 83.00, 85.00, 'Ganjil', '2025/2026'),
(60, 1, 1, 84.00, 80.00, 82.00, NULL, 'Genap', '2025/2026'),
(61, 1, 2, 90.00, 87.00, 88.00, NULL, 'Genap', '2025/2026'),
(62, 1, 3, 77.00, 74.00, 76.00, NULL, 'Genap', '2025/2026'),
(63, 1, 4, 92.00, 90.00, 91.00, NULL, 'Genap', '2025/2026'),
(64, 1, 5, 87.00, 82.00, 84.00, NULL, 'Genap', '2025/2026'),
(65, 1, 6, 80.00, 78.00, 79.00, NULL, 'Genap', '2025/2026'),
(66, 1, 7, 94.00, 92.00, 93.00, 90.00, 'Genap', '2025/2026'),
(67, 1, 10, 86.00, 84.00, 85.00, 87.00, 'Genap', '2025/2026'),
(68, 2, 1, 76.00, 74.00, 75.00, NULL, 'Ganjil', '2025/2026'),
(69, 2, 2, 83.00, 80.00, 81.00, NULL, 'Ganjil', '2025/2026'),
(70, 2, 3, 70.00, 68.00, 69.00, NULL, 'Ganjil', '2025/2026'),
(71, 2, 11, 88.00, 85.00, 86.00, 90.00, 'Ganjil', '2025/2026'),
(72, 2, 12, 84.00, 82.00, 83.00, 87.00, 'Ganjil', '2025/2026'),
(73, 3, 1, 80.00, 78.00, 79.00, NULL, 'Ganjil', '2025/2026'),
(74, 3, 2, 85.00, 82.00, 83.00, NULL, 'Ganjil', '2025/2026'),
(75, 3, 3, 72.00, 70.00, 71.00, NULL, 'Ganjil', '2025/2026'),
(76, 3, 14, 90.00, 88.00, 89.00, 92.00, 'Ganjil', '2025/2026'),
(77, 1, 1, 82.00, 78.00, 80.00, NULL, 'Ganjil', '2025/2026'),
(78, 1, 2, 88.00, 85.00, 87.00, NULL, 'Ganjil', '2025/2026'),
(79, 1, 3, 75.00, 72.00, 74.00, NULL, 'Ganjil', '2025/2026'),
(80, 1, 4, 90.00, 88.00, 89.00, NULL, 'Ganjil', '2025/2026'),
(81, 1, 5, 85.00, 80.00, 82.00, NULL, 'Ganjil', '2025/2026'),
(82, 1, 6, 78.00, 76.00, 77.00, NULL, 'Ganjil', '2025/2026'),
(83, 1, 7, 92.00, 90.00, 91.00, 88.00, 'Ganjil', '2025/2026'),
(84, 1, 10, 84.00, 82.00, 83.00, 85.00, 'Ganjil', '2025/2026'),
(85, 1, 1, 84.00, 80.00, 82.00, NULL, 'Genap', '2025/2026'),
(86, 1, 2, 90.00, 87.00, 88.00, NULL, 'Genap', '2025/2026'),
(87, 1, 3, 77.00, 74.00, 76.00, NULL, 'Genap', '2025/2026'),
(88, 1, 7, 94.00, 92.00, 93.00, 91.00, 'Genap', '2025/2026'),
(89, 2, 1, 76.00, 74.00, 75.00, NULL, 'Ganjil', '2025/2026'),
(90, 2, 2, 83.00, 80.00, 81.00, NULL, 'Ganjil', '2025/2026'),
(91, 2, 3, 70.00, 68.00, 69.00, NULL, 'Ganjil', '2025/2026'),
(92, 2, 11, 88.00, 85.00, 86.00, 90.00, 'Ganjil', '2025/2026'),
(93, 2, 12, 84.00, 82.00, 83.00, 87.00, 'Ganjil', '2025/2026');

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

--
-- Dumping data untuk tabel `notifikasi`
--

INSERT INTO `notifikasi` (`id`, `user_id`, `judul`, `pesan`, `tipe`, `is_read`, `link`, `created_at`) VALUES
(4, 1, 'Pengumuman UTS', 'UTS Semester Genap akan dilaksanakan 27-30 April 2026. Persiapkan diri Anda!', 'info', 0, NULL, '2026-04-24 06:34:19'),
(5, 1, 'Reminder SPP', 'SPP bulan April belum dibayar. Harap segera melunasi sebelum tanggal 30 April.', 'warning', 0, NULL, '2026-04-24 06:34:19'),
(6, 1, 'Nilai Sudah Keluar', 'Nilai UTS Semester Ganjil 2025/2026 sudah dapat dilihat.', 'success', 0, NULL, '2026-04-24 06:34:19'),
(7, 1, 'Pengumuman UTS', 'UTS Semester Genap akan dilaksanakan 27-30 April 2026. Persiapkan diri Anda!', 'info', 0, NULL, '2026-04-24 06:35:37'),
(8, 1, 'Reminder SPP', 'SPP bulan April belum dibayar. Harap segera melunasi sebelum tanggal 30 April.', 'warning', 0, NULL, '2026-04-24 06:35:37'),
(9, 1, 'Nilai Sudah Keluar', 'Nilai UTS Semester Ganjil 2025/2026 sudah dapat dilihat.', 'success', 0, NULL, '2026-04-24 06:35:37'),
(10, 1, 'Pengumuman UTS', 'UTS Semester Genap akan dilaksanakan 27-30 April 2026. Persiapkan diri Anda!', 'info', 0, NULL, '2026-04-24 06:42:58'),
(11, 1, 'Reminder SPP', 'SPP bulan April belum dibayar. Harap segera melunasi sebelum tanggal 30 April.', 'warning', 0, NULL, '2026-04-24 06:42:58'),
(12, 1, 'Nilai Sudah Keluar', 'Nilai UTS Semester Ganjil 2025/2026 sudah dapat dilihat.', 'success', 0, NULL, '2026-04-24 06:42:58');

-- --------------------------------------------------------

--
-- Struktur dari tabel `pembayaran_spp`
--

CREATE TABLE `pembayaran_spp` (
  `id` int(10) UNSIGNED NOT NULL,
  `siswa_id` int(10) UNSIGNED NOT NULL,
  `bulan` varchar(20) NOT NULL,
  `tahun` varchar(4) NOT NULL,
  `jumlah` decimal(10,0) NOT NULL,
  `status_pembayaran` enum('Lunas','Belum Bayar') DEFAULT 'Belum Bayar',
  `tanggal_bayar` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `pembayaran_spp`
--

INSERT INTO `pembayaran_spp` (`id`, `siswa_id`, `bulan`, `tahun`, `jumlah`, `status_pembayaran`, `tanggal_bayar`) VALUES
(1, 1, 'Januari', '2026', 300000, 'Lunas', '2026-01-08'),
(2, 1, 'Februari', '2026', 300000, 'Lunas', '2026-02-10'),
(3, 1, 'Maret', '2026', 300000, 'Lunas', '2026-03-07'),
(4, 1, 'April', '2026', 300000, 'Belum Bayar', NULL),
(5, 1, 'Mei', '2026', 300000, 'Belum Bayar', NULL),
(6, 1, 'Januari', '2026', 300000, 'Lunas', '2026-01-08'),
(7, 1, 'Februari', '2026', 300000, 'Lunas', '2026-02-10'),
(8, 1, 'Maret', '2026', 300000, 'Lunas', '2026-03-07'),
(9, 1, 'April', '2026', 300000, 'Belum Bayar', NULL),
(10, 1, 'Mei', '2026', 300000, 'Belum Bayar', NULL),
(11, 1, 'Juli', '2025', 300000, 'Lunas', '2025-07-10'),
(12, 1, 'Agustus', '2025', 300000, 'Lunas', '2025-08-08'),
(13, 1, 'September', '2025', 300000, 'Lunas', '2025-09-05'),
(14, 1, 'Oktober', '2025', 300000, 'Lunas', '2025-10-09'),
(15, 1, 'November', '2025', 300000, 'Lunas', '2025-11-07'),
(16, 1, 'Desember', '2025', 300000, 'Lunas', '2025-12-05'),
(17, 2, 'Januari', '2026', 300000, 'Lunas', '2026-01-12'),
(18, 2, 'Februari', '2026', 300000, 'Lunas', '2026-02-14'),
(19, 2, 'Maret', '2026', 300000, 'Belum Bayar', NULL),
(20, 2, 'April', '2026', 300000, 'Belum Bayar', NULL),
(21, 1, 'Januari', '2026', 300000, 'Lunas', '2026-01-08'),
(22, 1, 'Februari', '2026', 300000, 'Lunas', '2026-02-10'),
(23, 1, 'Maret', '2026', 300000, 'Lunas', '2026-03-07'),
(24, 1, 'April', '2026', 300000, 'Belum Bayar', NULL),
(25, 1, 'Mei', '2026', 300000, 'Belum Bayar', NULL),
(26, 1, 'Juli', '2025', 300000, 'Lunas', '2025-07-10'),
(27, 1, 'Agustus', '2025', 300000, 'Lunas', '2025-08-08'),
(28, 1, 'September', '2025', 300000, 'Lunas', '2025-09-05'),
(29, 1, 'Oktober', '2025', 300000, 'Lunas', '2025-10-09'),
(30, 1, 'November', '2025', 300000, 'Lunas', '2025-11-07'),
(31, 1, 'Desember', '2025', 300000, 'Lunas', '2025-12-05'),
(32, 2, 'Januari', '2026', 300000, 'Lunas', '2026-01-12'),
(33, 2, 'Februari', '2026', 300000, 'Lunas', '2026-02-14'),
(34, 2, 'Maret', '2026', 300000, 'Belum Bayar', NULL),
(35, 2, 'April', '2026', 300000, 'Belum Bayar', NULL),
(36, 1, 'Juli', '2025', 300000, 'Lunas', '2025-07-10'),
(37, 1, 'Agustus', '2025', 300000, 'Lunas', '2025-08-08'),
(38, 1, 'September', '2025', 300000, 'Lunas', '2025-09-05'),
(39, 1, 'Oktober', '2025', 300000, 'Lunas', '2025-10-09'),
(40, 1, 'November', '2025', 300000, 'Lunas', '2025-11-07'),
(41, 1, 'Desember', '2025', 300000, 'Lunas', '2025-12-05'),
(42, 1, 'Januari', '2026', 300000, 'Lunas', '2026-01-08'),
(43, 1, 'Februari', '2026', 300000, 'Lunas', '2026-02-10'),
(44, 1, 'Maret', '2026', 300000, 'Lunas', '2026-03-07'),
(45, 1, 'April', '2026', 300000, 'Belum Bayar', NULL),
(46, 1, 'Mei', '2026', 300000, 'Belum Bayar', NULL),
(47, 2, 'Juli', '2025', 300000, 'Lunas', '2025-07-12'),
(48, 2, 'Agustus', '2025', 300000, 'Lunas', '2025-08-10'),
(49, 2, 'September', '2025', 300000, 'Lunas', '2025-09-08'),
(50, 2, 'Oktober', '2025', 300000, '', '2025-10-15'),
(51, 2, 'November', '2025', 300000, 'Lunas', '2025-11-10'),
(52, 2, 'Desember', '2025', 300000, 'Lunas', '2025-12-08'),
(53, 2, 'Januari', '2026', 300000, 'Lunas', '2026-01-12'),
(54, 2, 'Februari', '2026', 300000, 'Lunas', '2026-02-14'),
(55, 2, 'Maret', '2026', 300000, 'Belum Bayar', NULL),
(56, 2, 'April', '2026', 300000, 'Belum Bayar', NULL),
(57, 3, 'Juli', '2025', 300000, 'Lunas', '2025-07-15'),
(58, 3, 'Agustus', '2025', 300000, 'Lunas', '2025-08-12'),
(59, 3, 'September', '2025', 300000, 'Lunas', '2025-09-10'),
(60, 3, 'Oktober', '2025', 300000, 'Lunas', '2025-10-12'),
(61, 3, 'November', '2025', 300000, '', '2025-11-15'),
(62, 3, 'Desember', '2025', 300000, 'Lunas', '2025-12-10'),
(63, 3, 'Januari', '2026', 300000, 'Lunas', '2026-01-15'),
(64, 3, 'Februari', '2026', 300000, '', '2026-02-20'),
(65, 3, 'Maret', '2026', 300000, 'Belum Bayar', NULL),
(66, 3, 'April', '2026', 300000, 'Belum Bayar', NULL),
(67, 1, 'Juli', '2025', 300000, 'Lunas', '2025-07-10'),
(68, 1, 'Agustus', '2025', 300000, 'Lunas', '2025-08-08'),
(69, 1, 'September', '2025', 300000, 'Lunas', '2025-09-05'),
(70, 1, 'Oktober', '2025', 300000, 'Lunas', '2025-10-09'),
(71, 1, 'November', '2025', 300000, 'Lunas', '2025-11-07'),
(72, 1, 'Desember', '2025', 300000, 'Lunas', '2025-12-05'),
(73, 1, 'Januari', '2026', 300000, 'Lunas', '2026-01-08'),
(74, 1, 'Februari', '2026', 300000, 'Lunas', '2026-02-10'),
(75, 1, 'Maret', '2026', 300000, 'Lunas', '2026-03-07'),
(76, 1, 'April', '2026', 300000, 'Belum Bayar', NULL),
(77, 1, 'Mei', '2026', 300000, 'Belum Bayar', NULL),
(78, 2, 'Januari', '2026', 300000, 'Lunas', '2026-01-12'),
(79, 2, 'Februari', '2026', 300000, 'Lunas', '2026-02-14'),
(80, 2, 'Maret', '2026', 300000, 'Belum Bayar', NULL),
(81, 2, 'April', '2026', 300000, 'Belum Bayar', NULL);

-- --------------------------------------------------------

--
-- Struktur dari tabel `pengumuman`
--

CREATE TABLE `pengumuman` (
  `id` int(10) UNSIGNED NOT NULL,
  `judul` varchar(255) NOT NULL,
  `isi_pengumuman` text NOT NULL,
  `kategori` enum('Akademik','Keuangan','Ekstrakurikuler','Umum') DEFAULT 'Umum',
  `tanggal_terbit` date NOT NULL,
  `prioritas` enum('Rendah','Sedang','Tinggi','Darurat') DEFAULT 'Sedang',
  `lampiran_file` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `pengumuman`
--

INSERT INTO `pengumuman` (`id`, `judul`, `isi_pengumuman`, `kategori`, `tanggal_terbit`, `prioritas`, `lampiran_file`) VALUES
(1, 'Ujian Akhir Semester Ganjil', 'UAS akan dilaksanakan mulai tanggal 10 Mei 2026', 'Akademik', '2026-04-19', 'Tinggi', NULL),
(2, 'Pembayaran SPP Bulan April', 'Harap segera melunasi SPP bulan April sebelum tanggal 30', 'Keuangan', '2026-04-15', 'Sedang', NULL),
(3, 'Jadwal UTS Semester Genap 2025/2026', 'Ujian Tengah Semester Genap akan dilaksanakan mulai tanggal 27 April 2026 sampai 30 April 2026. Siswa diwajibkan hadir 30 menit sebelum ujian dimulai dan membawa kartu ujian.', 'Akademik', '2026-04-20', 'Tinggi', NULL),
(4, 'Informasi Studi Banding ke Jakarta', 'Akan diadakan studi banding ke Jakarta pada tanggal 1-3 Juni 2026 untuk jurusan RPL dan TKJ. Biaya partisipasi Rp 500.000. Pendaftaran paling lambat 15 Mei 2026.', 'Akademik', '2026-04-18', 'Sedang', NULL),
(5, 'Penerimaan Beasiswa Prestasi Akademik', 'Dinas Pendidikan Jawa Timur membuka pendaftaran beasiswa prestasi akademik. Kuota 10 siswa. Pendaftaran dibuka 1 April - 31 Mei 2026. Formulir tersedia di TU.', 'Keuangan', '2026-04-01', 'Sedang', NULL),
(6, 'Kegiatan Pentas Seni Akhir Tahun', 'SMK Rajasa Surabaya akan mengadakan Pentas Seni Akhir Tahun pada 15-16 Mei 2026 di Aula sekolah. Semua kelas wajib menampilkan minimal satu penampilan. Koordinasi dengan wali kelas masing-masing.', 'Ekstrakurikuler', '2026-04-10', 'Rendah', NULL),
(7, 'Pengingat Pembayaran SPP Bulan April', 'Bagi siswa yang belum melunasi SPP bulan April, harap segera melakukan pembayaran ke bagian administrasi sekolah sebelum tanggal 30 April 2026. Akan dikenakan denda Rp 10.000 per hari keterlambatan.', 'Keuangan', '2026-04-22', 'Tinggi', NULL);

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
  `id` int(10) UNSIGNED NOT NULL,
  `siswa_id` int(10) UNSIGNED NOT NULL,
  `tanggal` date NOT NULL,
  `status_kehadiran` enum('Hadir','Sakit','Izin','Alpha','Terlambat') DEFAULT 'Hadir',
  `keterangan` text DEFAULT NULL,
  `jam_masuk` time DEFAULT NULL,
  `jam_pulang` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `presensi`
--

INSERT INTO `presensi` (`id`, `siswa_id`, `tanggal`, `status_kehadiran`, `keterangan`, `jam_masuk`, `jam_pulang`) VALUES
(1, 1, '2026-04-01', 'Hadir', NULL, '07:15:00', '15:00:00'),
(2, 1, '2026-04-02', 'Hadir', NULL, '07:10:00', '15:00:00'),
(3, 1, '2026-04-03', 'Terlambat', 'Bangun kesiangan', '08:05:00', '15:00:00'),
(4, 1, '2026-04-04', 'Hadir', NULL, '07:05:00', '15:00:00'),
(5, 1, '2026-04-07', 'Izin', 'Acara keluarga', NULL, NULL),
(6, 1, '2026-04-08', 'Hadir', NULL, '07:20:00', '15:00:00'),
(7, 1, '2026-04-09', 'Hadir', NULL, '07:15:00', '15:00:00'),
(8, 1, '2026-04-10', 'Sakit', 'Demam', NULL, NULL),
(9, 1, '2026-04-11', 'Sakit', 'Masih sakit', NULL, NULL),
(10, 1, '2026-04-14', 'Hadir', NULL, '07:10:00', '15:00:00'),
(11, 1, '2026-04-15', 'Hadir', NULL, '07:15:00', '15:00:00'),
(12, 1, '2026-04-16', 'Hadir', NULL, '07:12:00', '15:00:00'),
(13, 1, '2026-04-17', 'Alpha', NULL, NULL, NULL),
(14, 1, '2026-04-21', 'Hadir', NULL, '07:08:00', '15:00:00'),
(15, 1, '2026-04-22', 'Hadir', NULL, '07:15:00', '15:00:00'),
(16, 1, '2026-04-01', 'Hadir', NULL, '07:15:00', '15:00:00'),
(17, 1, '2026-04-02', 'Hadir', NULL, '07:10:00', '15:00:00'),
(18, 1, '2026-04-03', 'Terlambat', 'Bangun kesiangan', '08:05:00', '15:00:00'),
(19, 1, '2026-04-04', 'Hadir', NULL, '07:05:00', '15:00:00'),
(20, 1, '2026-04-07', 'Izin', 'Acara keluarga', NULL, NULL),
(21, 1, '2026-04-08', 'Hadir', NULL, '07:20:00', '15:00:00'),
(22, 1, '2026-04-09', 'Hadir', NULL, '07:15:00', '15:00:00'),
(23, 1, '2026-04-10', 'Sakit', 'Demam', NULL, NULL),
(24, 1, '2026-04-11', 'Sakit', 'Masih sakit', NULL, NULL),
(25, 1, '2026-04-14', 'Hadir', NULL, '07:10:00', '15:00:00'),
(26, 1, '2026-04-15', 'Hadir', NULL, '07:15:00', '15:00:00'),
(27, 1, '2026-04-16', 'Hadir', NULL, '07:12:00', '15:00:00'),
(28, 1, '2026-04-17', 'Alpha', NULL, NULL, NULL),
(29, 1, '2026-04-21', 'Hadir', NULL, '07:08:00', '15:00:00'),
(30, 1, '2026-04-22', 'Hadir', NULL, '07:15:00', '15:00:00'),
(31, 1, '2026-03-03', 'Hadir', NULL, '07:10:00', '15:00:00'),
(32, 1, '2026-03-04', 'Hadir', NULL, '07:12:00', '15:00:00'),
(33, 1, '2026-03-05', 'Hadir', NULL, '07:15:00', '15:00:00'),
(34, 1, '2026-03-06', 'Izin', 'Keperluan keluarga', NULL, NULL),
(35, 1, '2026-03-10', 'Hadir', NULL, '07:08:00', '15:00:00'),
(36, 1, '2026-03-11', 'Hadir', NULL, '07:20:00', '15:00:00'),
(37, 1, '2026-03-12', 'Hadir', NULL, '07:15:00', '15:00:00'),
(38, 1, '2026-03-13', 'Terlambat', 'Macet', '08:10:00', '15:00:00'),
(39, 1, '2026-03-17', 'Hadir', NULL, '07:05:00', '15:00:00'),
(40, 1, '2026-03-18', 'Hadir', NULL, '07:15:00', '15:00:00'),
(41, 1, '2026-03-19', 'Hadir', NULL, '07:10:00', '15:00:00'),
(42, 1, '2026-03-20', 'Alpha', NULL, NULL, NULL),
(43, 1, '2026-03-24', 'Hadir', NULL, '07:15:00', '15:00:00'),
(44, 1, '2026-03-25', 'Hadir', NULL, '07:12:00', '15:00:00'),
(45, 1, '2026-03-26', 'Sakit', 'Flu', NULL, NULL),
(46, 1, '2026-03-27', 'Hadir', NULL, '07:15:00', '15:00:00'),
(47, 1, '2026-02-03', 'Hadir', NULL, '07:10:00', '15:00:00'),
(48, 1, '2026-02-04', 'Hadir', NULL, '07:15:00', '15:00:00'),
(49, 1, '2026-02-05', 'Hadir', NULL, '07:12:00', '15:00:00'),
(50, 1, '2026-02-10', 'Terlambat', 'Hujan lebat', '08:20:00', '15:00:00'),
(51, 1, '2026-02-11', 'Hadir', NULL, '07:15:00', '15:00:00'),
(52, 1, '2026-02-12', 'Hadir', NULL, '07:10:00', '15:00:00'),
(53, 1, '2026-02-17', 'Hadir', NULL, '07:08:00', '15:00:00'),
(54, 1, '2026-02-18', 'Izin', 'Ada keperluan', NULL, NULL),
(55, 1, '2026-02-19', 'Hadir', NULL, '07:15:00', '15:00:00'),
(56, 1, '2026-02-24', 'Hadir', NULL, '07:12:00', '15:00:00'),
(57, 1, '2026-02-25', 'Hadir', NULL, '07:15:00', '15:00:00'),
(58, 1, '2026-02-26', 'Hadir', NULL, '07:10:00', '15:00:00'),
(59, 1, '2026-04-01', 'Hadir', NULL, '07:15:00', '15:00:00'),
(60, 1, '2026-04-02', 'Hadir', NULL, '07:10:00', '15:00:00'),
(61, 1, '2026-04-03', 'Terlambat', 'Bangun kesiangan', '08:05:00', '15:00:00'),
(62, 1, '2026-04-04', 'Hadir', NULL, '07:05:00', '15:00:00'),
(63, 1, '2026-04-07', 'Izin', 'Acara keluarga', NULL, NULL),
(64, 1, '2026-04-08', 'Hadir', NULL, '07:20:00', '15:00:00'),
(65, 1, '2026-04-09', 'Hadir', NULL, '07:15:00', '15:00:00'),
(66, 1, '2026-04-10', 'Sakit', 'Demam', NULL, NULL),
(67, 1, '2026-04-11', 'Sakit', 'Masih sakit', NULL, NULL),
(68, 1, '2026-04-14', 'Hadir', NULL, '07:10:00', '15:00:00'),
(69, 1, '2026-04-15', 'Hadir', NULL, '07:15:00', '15:00:00'),
(70, 1, '2026-04-16', 'Hadir', NULL, '07:12:00', '15:00:00'),
(71, 1, '2026-04-17', 'Alpha', NULL, NULL, NULL),
(72, 1, '2026-04-21', 'Hadir', NULL, '07:08:00', '15:00:00'),
(73, 1, '2026-04-22', 'Hadir', NULL, '07:15:00', '15:00:00'),
(74, 1, '2026-03-03', 'Hadir', NULL, '07:10:00', '15:00:00'),
(75, 1, '2026-03-04', 'Hadir', NULL, '07:12:00', '15:00:00'),
(76, 1, '2026-03-05', 'Hadir', NULL, '07:15:00', '15:00:00'),
(77, 1, '2026-03-06', 'Izin', 'Keperluan keluarga', NULL, NULL),
(78, 1, '2026-03-10', 'Hadir', NULL, '07:08:00', '15:00:00'),
(79, 1, '2026-03-11', 'Hadir', NULL, '07:20:00', '15:00:00'),
(80, 1, '2026-03-12', 'Hadir', NULL, '07:15:00', '15:00:00'),
(81, 1, '2026-03-13', 'Terlambat', 'Macet', '08:10:00', '15:00:00'),
(82, 1, '2026-03-17', 'Hadir', NULL, '07:05:00', '15:00:00'),
(83, 1, '2026-03-18', 'Hadir', NULL, '07:15:00', '15:00:00'),
(84, 1, '2026-03-19', 'Hadir', NULL, '07:10:00', '15:00:00'),
(85, 1, '2026-03-20', 'Alpha', NULL, NULL, NULL),
(86, 1, '2026-03-24', 'Hadir', NULL, '07:15:00', '15:00:00'),
(87, 1, '2026-03-25', 'Hadir', NULL, '07:12:00', '15:00:00'),
(88, 1, '2026-03-26', 'Sakit', 'Flu', NULL, NULL),
(89, 1, '2026-03-27', 'Hadir', NULL, '07:15:00', '15:00:00'),
(90, 1, '2026-02-03', 'Hadir', NULL, '07:10:00', '15:00:00'),
(91, 1, '2026-02-04', 'Hadir', NULL, '07:15:00', '15:00:00'),
(92, 1, '2026-02-05', 'Hadir', NULL, '07:12:00', '15:00:00'),
(93, 1, '2026-02-10', 'Terlambat', 'Hujan lebat', '08:20:00', '15:00:00'),
(94, 1, '2026-02-11', 'Hadir', NULL, '07:15:00', '15:00:00'),
(95, 1, '2026-02-12', 'Hadir', NULL, '07:10:00', '15:00:00'),
(96, 1, '2026-02-17', 'Hadir', NULL, '07:08:00', '15:00:00'),
(97, 1, '2026-02-18', 'Izin', 'Ada keperluan', NULL, NULL),
(98, 1, '2026-02-19', 'Hadir', NULL, '07:15:00', '15:00:00'),
(99, 1, '2026-02-24', 'Hadir', NULL, '07:12:00', '15:00:00'),
(100, 1, '2026-02-25', 'Hadir', NULL, '07:15:00', '15:00:00'),
(101, 1, '2026-02-26', 'Hadir', NULL, '07:10:00', '15:00:00'),
(102, 1, '2026-04-01', 'Hadir', NULL, '07:15:00', '15:00:00'),
(103, 1, '2026-04-02', 'Hadir', NULL, '07:10:00', '15:00:00'),
(104, 1, '2026-04-03', 'Terlambat', 'Bangun kesiangan', '08:05:00', '15:00:00'),
(105, 1, '2026-04-04', 'Hadir', NULL, '07:05:00', '15:00:00'),
(106, 1, '2026-04-07', 'Izin', 'Acara keluarga', NULL, NULL),
(107, 1, '2026-04-08', 'Hadir', NULL, '07:20:00', '15:00:00'),
(108, 1, '2026-04-09', 'Hadir', NULL, '07:15:00', '15:00:00'),
(109, 1, '2026-04-10', 'Sakit', 'Demam', NULL, NULL),
(110, 1, '2026-04-11', 'Sakit', 'Masih sakit', NULL, NULL),
(111, 1, '2026-04-14', 'Hadir', NULL, '07:10:00', '15:00:00'),
(112, 1, '2026-04-15', 'Hadir', NULL, '07:12:00', '15:00:00'),
(113, 1, '2026-04-16', 'Hadir', NULL, '07:08:00', '15:00:00'),
(114, 1, '2026-04-17', 'Hadir', NULL, '07:18:00', '15:00:00'),
(115, 1, '2026-04-18', 'Hadir', NULL, '07:14:00', '15:00:00'),
(116, 1, '2026-04-22', 'Hadir', NULL, '07:11:00', '15:00:00'),
(117, 2, '2026-04-01', 'Hadir', NULL, '07:20:00', '15:00:00'),
(118, 2, '2026-04-02', 'Hadir', NULL, '07:15:00', '15:00:00'),
(119, 2, '2026-04-03', 'Hadir', NULL, '07:10:00', '15:00:00'),
(120, 2, '2026-04-04', 'Izin', 'Sakit kepala', NULL, NULL),
(121, 2, '2026-04-07', 'Hadir', NULL, '07:18:00', '15:00:00'),
(122, 2, '2026-04-08', 'Hadir', NULL, '07:22:00', '15:00:00'),
(123, 2, '2026-04-09', 'Terlambat', 'Macet', '08:10:00', '15:00:00'),
(124, 2, '2026-04-10', 'Hadir', NULL, '07:12:00', '15:00:00'),
(125, 2, '2026-04-11', 'Hadir', NULL, '07:14:00', '15:00:00'),
(126, 2, '2026-04-14', 'Hadir', NULL, '07:16:00', '15:00:00'),
(127, 3, '2026-04-01', 'Hadir', NULL, '07:25:00', '15:00:00'),
(128, 3, '2026-04-02', 'Hadir', NULL, '07:18:00', '15:00:00'),
(129, 3, '2026-04-03', 'Hadir', NULL, '07:20:00', '15:00:00'),
(130, 3, '2026-04-04', 'Hadir', NULL, '07:22:00', '15:00:00'),
(131, 3, '2026-04-07', 'Alpha', 'Tidak ada kabar', NULL, NULL),
(132, 3, '2026-04-08', 'Hadir', NULL, '07:15:00', '15:00:00'),
(133, 3, '2026-04-09', 'Hadir', NULL, '07:17:00', '15:00:00'),
(134, 3, '2026-04-10', 'Hadir', NULL, '07:19:00', '15:00:00'),
(135, 3, '2026-04-11', 'Hadir', NULL, '07:21:00', '15:00:00'),
(136, 3, '2026-04-14', 'Sakit', 'Flu', NULL, NULL),
(137, 1, '2026-04-01', 'Hadir', NULL, '07:15:00', '15:00:00'),
(138, 1, '2026-04-02', 'Hadir', NULL, '07:10:00', '15:00:00'),
(139, 1, '2026-04-03', 'Terlambat', 'Bangun kesiangan', '08:05:00', '15:00:00'),
(140, 1, '2026-04-04', 'Hadir', NULL, '07:05:00', '15:00:00'),
(141, 1, '2026-04-07', 'Izin', 'Acara keluarga', NULL, NULL),
(142, 1, '2026-04-08', 'Hadir', NULL, '07:20:00', '15:00:00'),
(143, 1, '2026-04-09', 'Hadir', NULL, '07:15:00', '15:00:00'),
(144, 1, '2026-04-10', 'Sakit', 'Demam', NULL, NULL),
(145, 1, '2026-04-11', 'Sakit', 'Masih sakit', NULL, NULL),
(146, 1, '2026-04-14', 'Hadir', NULL, '07:10:00', '15:00:00'),
(147, 1, '2026-04-15', 'Hadir', NULL, '07:15:00', '15:00:00'),
(148, 1, '2026-04-16', 'Hadir', NULL, '07:12:00', '15:00:00'),
(149, 1, '2026-04-17', 'Alpha', NULL, NULL, NULL),
(150, 1, '2026-04-21', 'Hadir', NULL, '07:08:00', '15:00:00'),
(151, 1, '2026-04-22', 'Hadir', NULL, '07:15:00', '15:00:00'),
(152, 1, '2026-03-03', 'Hadir', NULL, '07:10:00', '15:00:00'),
(153, 1, '2026-03-04', 'Hadir', NULL, '07:12:00', '15:00:00'),
(154, 1, '2026-03-05', 'Hadir', NULL, '07:15:00', '15:00:00'),
(155, 1, '2026-03-06', 'Izin', 'Keperluan keluarga', NULL, NULL),
(156, 1, '2026-03-10', 'Hadir', NULL, '07:08:00', '15:00:00'),
(157, 1, '2026-03-11', 'Hadir', NULL, '07:20:00', '15:00:00'),
(158, 1, '2026-03-12', 'Hadir', NULL, '07:15:00', '15:00:00'),
(159, 1, '2026-03-13', 'Terlambat', 'Macet', '08:10:00', '15:00:00'),
(160, 1, '2026-03-17', 'Hadir', NULL, '07:05:00', '15:00:00'),
(161, 1, '2026-03-18', 'Hadir', NULL, '07:15:00', '15:00:00'),
(162, 1, '2026-03-19', 'Hadir', NULL, '07:10:00', '15:00:00'),
(163, 1, '2026-03-20', 'Alpha', NULL, NULL, NULL),
(164, 1, '2026-03-24', 'Hadir', NULL, '07:15:00', '15:00:00'),
(165, 1, '2026-03-25', 'Hadir', NULL, '07:12:00', '15:00:00'),
(166, 1, '2026-03-26', 'Sakit', 'Flu', NULL, NULL),
(167, 1, '2026-03-27', 'Hadir', NULL, '07:15:00', '15:00:00'),
(168, 1, '2026-02-03', 'Hadir', NULL, '07:10:00', '15:00:00'),
(169, 1, '2026-02-04', 'Hadir', NULL, '07:15:00', '15:00:00'),
(170, 1, '2026-02-05', 'Hadir', NULL, '07:12:00', '15:00:00'),
(171, 1, '2026-02-10', 'Terlambat', 'Hujan lebat', '08:20:00', '15:00:00'),
(172, 1, '2026-02-11', 'Hadir', NULL, '07:15:00', '15:00:00'),
(173, 1, '2026-02-12', 'Hadir', NULL, '07:10:00', '15:00:00'),
(174, 1, '2026-02-17', 'Hadir', NULL, '07:08:00', '15:00:00'),
(175, 1, '2026-02-18', 'Izin', 'Ada keperluan', NULL, NULL),
(176, 1, '2026-02-19', 'Hadir', NULL, '07:15:00', '15:00:00'),
(177, 1, '2026-02-24', 'Hadir', NULL, '07:12:00', '15:00:00'),
(178, 1, '2026-02-25', 'Hadir', NULL, '07:15:00', '15:00:00'),
(179, 1, '2026-02-26', 'Hadir', NULL, '07:10:00', '15:00:00');

-- --------------------------------------------------------

--
-- Struktur dari tabel `presensi_lab`
--

CREATE TABLE `presensi_lab` (
  `id` int(11) UNSIGNED NOT NULL,
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `tanggal` date NOT NULL,
  `jam_masuk` time DEFAULT NULL,
  `jam_keluar` time DEFAULT NULL,
  `status` enum('hadir','terlambat','izin','sakit','alfa') DEFAULT 'hadir',
  `keterangan` text DEFAULT NULL,
  `foto_bukti` varchar(255) DEFAULT NULL,
  `lokasi_scan` varchar(100) DEFAULT NULL,
  `device_id` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `presensi_sekolah`
--

CREATE TABLE `presensi_sekolah` (
  `id` int(11) UNSIGNED NOT NULL,
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `tanggal` date NOT NULL,
  `jam_masuk` time DEFAULT NULL,
  `jam_pulang` time DEFAULT NULL,
  `status_kehadiran` enum('hadir','izin','sakit','alfa') DEFAULT 'hadir',
  `keterangan` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `rapor`
--

CREATE TABLE `rapor` (
  `id` int(11) UNSIGNED NOT NULL,
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `semester` enum('Ganjil','Genap') NOT NULL,
  `tahun_ajaran` varchar(9) DEFAULT NULL COMMENT 'Format: 2024/2025',
  `nilai_rata_rata` decimal(4,2) DEFAULT NULL,
  `peringkat` int(11) DEFAULT NULL,
  `catatan_wali` text DEFAULT NULL,
  `tanggal_terbit` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `rapor`
--

INSERT INTO `rapor` (`id`, `siswa_id`, `semester`, `tahun_ajaran`, `nilai_rata_rata`, `peringkat`, `catatan_wali`, `tanggal_terbit`, `created_at`, `updated_at`) VALUES
(1, 1, 'Ganjil', '2025/2026', 85.40, 3, 'Ahmad menunjukkan perkembangan yang baik terutama di bidang pemrograman. Perlu meningkatkan kehadiran.', '2025-12-20', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(2, 1, 'Genap', '2024/2025', 83.70, 5, 'Prestasi akademik stabil. Diharapkan lebih aktif dalam kegiatan ekstrakurikuler.', '2025-06-20', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(3, 1, 'Ganjil', '2024/2025', 80.20, 7, 'Siswa cukup baik namun perlu meningkatkan nilai mata pelajaran umum.', '2024-12-20', '2026-04-24 06:34:19', '2026-04-24 06:34:19'),
(4, 2, 'Ganjil', '2025/2026', 79.80, 8, 'Siti menunjukkan kemajuan di bidang jaringan komputer. Terus pertahankan.', '2025-12-20', '2026-04-24 06:34:19', '2026-04-24 06:34:19');

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

--
-- Dumping data untuk tabel `siswa`
--

INSERT INTO `siswa` (`id`, `nisn`, `nis`, `nama_lengkap`, `jenis_kelamin`, `tempat_lahir`, `tanggal_lahir`, `alamat`, `no_telp`, `email`, `jurusan_id`, `kelas`, `rombel`, `rfid_uid`, `foto`, `nama_ortu`, `no_telp_ortu`, `created_at`, `updated_at`, `status`) VALUES
(1, '0065123456', '220145', 'Ahmad Fikri Prasetyo', 'L', 'Surabaya', '2007-03-15', 'Jl. Genteng Kali No. 10, Surabaya', '081211111111', 'ahmad.fikri@gmail.com', 2, 'XII', 'RPL-1', NULL, NULL, 'Budi Prasetyo', '081222222222', '2026-04-24 06:27:43', '2026-04-24 06:27:43', 'aktif'),
(2, '0065123457', '220146', 'Siti Nurhaliza', 'P', 'Surabaya', '2007-07-20', 'Jl. Raya Darmo No. 45, Surabaya', '081233333333', 'siti.nur@gmail.com', 1, 'XI', 'TKJ-2', NULL, NULL, 'Agus Santoso', '081244444444', '2026-04-24 06:27:43', '2026-04-24 06:27:43', 'aktif'),
(3, '0065123458', '220147', 'Rizki Dwi Putra', 'L', 'Gresik', '2008-01-10', 'Jl. Pahlawan No. 5, Gresik', '081255555555', 'rizki.dwi@gmail.com', 3, 'X', 'MM-1', NULL, NULL, 'Dedi Kurniawan', '081266666666', '2026-04-24 06:27:43', '2026-04-24 06:27:43', 'aktif');

-- --------------------------------------------------------

--
-- Struktur dari tabel `siswa_wali`
--

CREATE TABLE `siswa_wali` (
  `id` int(10) UNSIGNED NOT NULL,
  `siswa_id` int(10) UNSIGNED NOT NULL,
  `wali_murid_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `siswa_wali`
--

INSERT INTO `siswa_wali` (`id`, `siswa_id`, `wali_murid_id`) VALUES
(1, 1, 1),
(2, 2, 2),
(3, 3, 3);

-- --------------------------------------------------------

--
-- Struktur dari tabel `students`
--

CREATE TABLE `students` (
  `id` int(10) UNSIGNED NOT NULL,
  `nisn` varchar(20) NOT NULL,
  `nama_lengkap` varchar(255) NOT NULL,
  `kelas_id` int(10) UNSIGNED DEFAULT NULL,
  `jurusan_id` int(10) UNSIGNED DEFAULT NULL,
  `nama_ortu` varchar(255) DEFAULT NULL,
  `no_hp_ortu` varchar(20) DEFAULT NULL,
  `email_ortu` varchar(255) DEFAULT NULL,
  `alamat` text DEFAULT NULL,
  `foto_siswa` varchar(255) DEFAULT NULL,
  `status_aktif` enum('Aktif','Nonaktif') DEFAULT 'Aktif',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `students`
--

INSERT INTO `students` (`id`, `nisn`, `nama_lengkap`, `kelas_id`, `jurusan_id`, `nama_ortu`, `no_hp_ortu`, `email_ortu`, `alamat`, `foto_siswa`, `status_aktif`, `created_at`, `updated_at`) VALUES
(1, '1234567890', 'Ahmad Fikri Prasetyo', 1, 2, 'Budi Prasetyo', '+6281234567890', 'budi.prasetyo@email.com', 'Jl. Contoh Alamat No. 123, Kota Surabaya', NULL, 'Aktif', '2026-04-18 18:20:56', '2026-04-18 18:20:56'),
(2, '0987654321', 'Siti Nurhaliza', 2, 1, 'Agus Santoso', '+6281234567891', 'agus.santoso@email.com', 'Jl. Contoh Alamat No. 456, Kota Surabaya', NULL, 'Aktif', '2026-04-18 18:20:56', '2026-04-18 18:20:56'),
(3, '1122334455', 'Rizki Dwi Putra', 3, 3, 'Dedi Kurniawan', '+6281234567892', 'dedi.kurniawan@email.com', 'Jl. Contoh Alamat No. 789, Kota Surabaya', NULL, 'Aktif', '2026-04-18 18:20:56', '2026-04-18 18:20:56');

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
  `role` enum('admin_operator','admin_jurusan','guru','siswa') NOT NULL DEFAULT 'admin_jurusan',
  `jurusan_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'NULL untuk admin_operator, terisi untuk admin_jurusan',
  `ruangan_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'Ruangan yang dikelola (opsional)',
  `foto_profile` varchar(255) DEFAULT NULL,
  `last_login` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `status` enum('aktif','nonaktif','terkunci') DEFAULT 'aktif',
  `status_aktif` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `nama_lengkap`, `email`, `no_telp`, `role`, `jurusan_id`, `ruangan_id`, `foto_profile`, `last_login`, `created_at`, `updated_at`, `status`, `status_aktif`) VALUES
(1, 'admin', '$2y$10$Rl9RK9em59tJVaZxo/wVWeCgANrDKCUKDC2l0FqfNwrQu6SJaRISK', 'Administrator Utama', 'admin@smkrajasa.sch.id', '081234567890', 'admin_operator', NULL, NULL, NULL, '2026-03-05 08:11:54', '2026-03-04 17:23:16', '2026-03-05 01:11:54', 'aktif', 1),
(2, 'admintkj', '$2y$10$Rl9RK9em59tJVaZxo/wVWeCgANrDKCUKDC2l0FqfNwrQu6SJaRISK', 'Admin Jurusan TKJ', 'tkj@smkrajasa.sch.id', '081234567892', 'admin_jurusan', NULL, NULL, NULL, NULL, '2026-03-04 17:23:16', '2026-03-04 19:07:39', 'aktif', 1),
(12, 'guru_mm', '$2y$10$Rl9RK9em59tJVaZxo/wVWeCgANrDKCUKDC2l0FqfNwrQu6SJaRISK', 'Pak Dedi Kurniawan', 'dedi.kurniawan@smkrajasa.sch.id', '081299999999', 'guru', 3, NULL, NULL, NULL, '2026-04-24 06:27:43', '2026-04-24 06:27:43', 'aktif', 1),
(22, 'siswa.220147', '$2y$10$Rl9RK9em59tJVaZxo/wVWeCgANrDKCUKDC2l0FqfNwrQu6SJaRISK', 'Rizki Dwi Putra', 'rizki.dwi@gmail.com', '081255555555', 'siswa', 3, NULL, NULL, NULL, '2026-04-24 06:27:43', '2026-04-24 06:27:43', 'aktif', 1);

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
,`nama_jurusan` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `v_presensi_detail`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `v_presensi_detail` (
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `v_rekap_harian`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `v_rekap_harian` (
);

-- --------------------------------------------------------

--
-- Struktur dari tabel `wali_murid`
--

CREATE TABLE `wali_murid` (
  `id` int(10) UNSIGNED NOT NULL,
  `nama_wali` varchar(255) NOT NULL,
  `hubungan` varchar(50) DEFAULT NULL,
  `no_hp` varchar(20) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `alamat` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `wali_murid`
--

INSERT INTO `wali_murid` (`id`, `nama_wali`, `hubungan`, `no_hp`, `email`, `alamat`, `created_at`, `updated_at`) VALUES
(1, 'Budi Prasetyo', 'Ayah', '+6281234567890', 'budi.prasetyo@email.com', 'Jl. Contoh Alamat No. 123, Kota Surabaya', '2026-04-18 18:20:56', '2026-04-18 18:20:56'),
(2, 'Agus Santoso', 'Ayah', '+6281234567891', 'agus.santoso@email.com', 'Jl. Contoh Alamat No. 456, Kota Surabaya', '2026-04-18 18:20:56', '2026-04-18 18:20:56'),
(3, 'Dedi Kurniawan', 'Ayah', '+6281234567892', 'dedi.kurniawan@email.com', 'Jl. Contoh Alamat No. 789, Kota Surabaya', '2026-04-18 18:20:56', '2026-04-18 18:20:56');

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
-- Indeks untuk tabel `beasiswa`
--
ALTER TABLE `beasiswa`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `calendar_akademik`
--
ALTER TABLE `calendar_akademik`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `jadwal_pelajaran`
--
ALTER TABLE `jadwal_pelajaran`
  ADD PRIMARY KEY (`id`),
  ADD KEY `kelas_id` (`kelas_id`),
  ADD KEY `mata_pelajaran_id` (`mata_pelajaran_id`),
  ADD KEY `guru_id` (`guru_id`);

--
-- Indeks untuk tabel `jurusan`
--
ALTER TABLE `jurusan`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `kode_jurusan` (`kode_jurusan`);

--
-- Indeks untuk tabel `kegiatan_sekolah`
--
ALTER TABLE `kegiatan_sekolah`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `kelas`
--
ALTER TABLE `kelas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jurusan_id` (`jurusan_id`);

--
-- Indeks untuk tabel `konfigurasi`
--
ALTER TABLE `konfigurasi`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `kunci` (`kunci`),
  ADD KEY `updated_by` (`updated_by`);

--
-- Indeks untuk tabel `logs`
--
ALTER TABLE `logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indeks untuk tabel `log_akses`
--
ALTER TABLE `log_akses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ruangan_id` (`ruangan_id`);

--
-- Indeks untuk tabel `mata_pelajaran`
--
ALTER TABLE `mata_pelajaran`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `kode_mapel` (`kode_mapel`),
  ADD KEY `jurusan_id` (`jurusan_id`);

--
-- Indeks untuk tabel `nilai_akademik`
--
ALTER TABLE `nilai_akademik`
  ADD PRIMARY KEY (`id`),
  ADD KEY `siswa_id` (`siswa_id`),
  ADD KEY `mata_pelajaran_id` (`mata_pelajaran_id`);

--
-- Indeks untuk tabel `notifikasi`
--
ALTER TABLE `notifikasi`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indeks untuk tabel `pembayaran_spp`
--
ALTER TABLE `pembayaran_spp`
  ADD PRIMARY KEY (`id`),
  ADD KEY `siswa_id` (`siswa_id`);

--
-- Indeks untuk tabel `pengumuman`
--
ALTER TABLE `pengumuman`
  ADD PRIMARY KEY (`id`);

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
  ADD KEY `siswa_id` (`siswa_id`);

--
-- Indeks untuk tabel `presensi_lab`
--
ALTER TABLE `presensi_lab`
  ADD PRIMARY KEY (`id`),
  ADD KEY `siswa_id` (`siswa_id`);

--
-- Indeks untuk tabel `presensi_sekolah`
--
ALTER TABLE `presensi_sekolah`
  ADD PRIMARY KEY (`id`),
  ADD KEY `siswa_id` (`siswa_id`);

--
-- Indeks untuk tabel `rapor`
--
ALTER TABLE `rapor`
  ADD PRIMARY KEY (`id`),
  ADD KEY `siswa_id` (`siswa_id`);

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
-- Indeks untuk tabel `siswa_wali`
--
ALTER TABLE `siswa_wali`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_siswa_wali` (`siswa_id`,`wali_murid_id`),
  ADD KEY `wali_murid_id` (`wali_murid_id`);

--
-- Indeks untuk tabel `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nisn` (`nisn`),
  ADD KEY `kelas_id` (`kelas_id`),
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
-- Indeks untuk tabel `wali_murid`
--
ALTER TABLE `wali_murid`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `admin_activities`
--
ALTER TABLE `admin_activities`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `beasiswa`
--
ALTER TABLE `beasiswa`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT untuk tabel `calendar_akademik`
--
ALTER TABLE `calendar_akademik`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=108;

--
-- AUTO_INCREMENT untuk tabel `jadwal_pelajaran`
--
ALTER TABLE `jadwal_pelajaran`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT untuk tabel `jurusan`
--
ALTER TABLE `jurusan`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `kegiatan_sekolah`
--
ALTER TABLE `kegiatan_sekolah`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT untuk tabel `kelas`
--
ALTER TABLE `kelas`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `konfigurasi`
--
ALTER TABLE `konfigurasi`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT untuk tabel `logs`
--
ALTER TABLE `logs`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `log_akses`
--
ALTER TABLE `log_akses`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `mata_pelajaran`
--
ALTER TABLE `mata_pelajaran`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT untuk tabel `nilai_akademik`
--
ALTER TABLE `nilai_akademik`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=94;

--
-- AUTO_INCREMENT untuk tabel `notifikasi`
--
ALTER TABLE `notifikasi`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT untuk tabel `pembayaran_spp`
--
ALTER TABLE `pembayaran_spp`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=82;

--
-- AUTO_INCREMENT untuk tabel `pengumuman`
--
ALTER TABLE `pengumuman`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT untuk tabel `peserta_ujian`
--
ALTER TABLE `peserta_ujian`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `presensi`
--
ALTER TABLE `presensi`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=180;

--
-- AUTO_INCREMENT untuk tabel `presensi_lab`
--
ALTER TABLE `presensi_lab`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `presensi_sekolah`
--
ALTER TABLE `presensi_sekolah`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `rapor`
--
ALTER TABLE `rapor`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

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
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `siswa_wali`
--
ALTER TABLE `siswa_wali`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `students`
--
ALTER TABLE `students`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT untuk tabel `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `wali_murid`
--
ALTER TABLE `wali_murid`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `admin_activities`
--
ALTER TABLE `admin_activities`
  ADD CONSTRAINT `admin_activities_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `kelas`
--
ALTER TABLE `kelas`
  ADD CONSTRAINT `kelas_ibfk_1` FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan` (`id`) ON DELETE SET NULL;

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
-- Ketidakleluasaan untuk tabel `mata_pelajaran`
--
ALTER TABLE `mata_pelajaran`
  ADD CONSTRAINT `mata_pelajaran_ibfk_1` FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan` (`id`) ON DELETE SET NULL;

--
-- Ketidakleluasaan untuk tabel `nilai_akademik`
--
ALTER TABLE `nilai_akademik`
  ADD CONSTRAINT `nilai_akademik_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `nilai_akademik_ibfk_2` FOREIGN KEY (`mata_pelajaran_id`) REFERENCES `mata_pelajaran` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `notifikasi`
--
ALTER TABLE `notifikasi`
  ADD CONSTRAINT `notifikasi_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `pembayaran_spp`
--
ALTER TABLE `pembayaran_spp`
  ADD CONSTRAINT `pembayaran_spp_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `students` (`id`) ON DELETE CASCADE;

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
  ADD CONSTRAINT `presensi_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `students` (`id`) ON DELETE CASCADE;

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
-- Ketidakleluasaan untuk tabel `siswa_wali`
--
ALTER TABLE `siswa_wali`
  ADD CONSTRAINT `siswa_wali_ibfk_1` FOREIGN KEY (`siswa_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `siswa_wali_ibfk_2` FOREIGN KEY (`wali_murid_id`) REFERENCES `wali_murid` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `students`
--
ALTER TABLE `students`
  ADD CONSTRAINT `students_ibfk_1` FOREIGN KEY (`kelas_id`) REFERENCES `kelas` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `students_ibfk_2` FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan` (`id`) ON DELETE SET NULL;

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
