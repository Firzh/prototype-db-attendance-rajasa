-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 19 Apr 2026 pada 17.41
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

-- --------------------------------------------------------

--
-- Struktur dari tabel `calendar_akademik`
--

CREATE TABLE `calendar_akademik` (
  `id` int(10) UNSIGNED NOT NULL,
  `nama_kegiatan` varchar(255) NOT NULL,
  `tanggal` date NOT NULL,
  `jenis_kegiatan` enum('Libur Nasional','Hari Belajar','Ujian','Semester Baru','Kenaikan Kelas','Wisuda','Lainnya') DEFAULT 'Lainnya',
  `keterangan` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(2, 'Studi Banding ke Jakarta', '2026-06-01', '2026-06-03', 'Jakarta', 'Kunjungan industri RPL dan TKJ', NULL);

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
  `km` enum('Kelompok A (Normatif)','Kelompok B (Adaptif)','Kelompok C (Produktif)') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(2, 'Pembayaran SPP Bulan April', 'Harap segera melunasi SPP bulan April sebelum tanggal 30', 'Keuangan', '2026-04-15', 'Sedang', NULL);

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
  `role` enum('admin_operator','admin_jurusan') NOT NULL DEFAULT 'admin_jurusan',
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
(2, 'admintkj', '$2y$10$Rl9RK9em59tJVaZxo/wVWeCgANrDKCUKDC2l0FqfNwrQu6SJaRISK', 'Admin Jurusan TKJ', 'tkj@smkrajasa.sch.id', '081234567892', 'admin_jurusan', NULL, NULL, NULL, NULL, '2026-03-04 17:23:16', '2026-03-04 19:07:39', 'aktif', 1);

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
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `calendar_akademik`
--
ALTER TABLE `calendar_akademik`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `jadwal_pelajaran`
--
ALTER TABLE `jadwal_pelajaran`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `jurusan`
--
ALTER TABLE `jurusan`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `kegiatan_sekolah`
--
ALTER TABLE `kegiatan_sekolah`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

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
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `nilai_akademik`
--
ALTER TABLE `nilai_akademik`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `notifikasi`
--
ALTER TABLE `notifikasi`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `pembayaran_spp`
--
ALTER TABLE `pembayaran_spp`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `pengumuman`
--
ALTER TABLE `pengumuman`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT untuk tabel `peserta_ujian`
--
ALTER TABLE `peserta_ujian`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `presensi`
--
ALTER TABLE `presensi`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

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
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

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
