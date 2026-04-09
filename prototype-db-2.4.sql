-- Buat database baru
CREATE DATABASE IF NOT EXISTS sistem_absensi_lab
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Pilih database
USE sistem_absensi_lab;

--
-- Struktur dari tabel `jurusan`
--

CREATE TABLE `jurusan` (
  `jurusan_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `kode_jurusan` varchar(10) NOT NULL COMMENT 'Kode unik jurusan, ex: TKJ, RPL, MM',
  `nama_jurusan` varchar(100) NOT NULL COMMENT 'Nama lengkap jurusan',
  `singkatan` varchar(10) NOT NULL COMMENT 'Singkatan jurusan',
  `ketua_jurusan` varchar(100) DEFAULT NULL COMMENT 'Nama ketua jurusan',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `status` enum('aktif','nonaktif') DEFAULT 'aktif',
  PRIMARY KEY (`jurusan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `ruangan`
--

CREATE TABLE `ruangan` (
  `ruangan_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `kode_ruangan` varchar(20) NOT NULL COMMENT 'Kode ruangan, ex: LAB-TKJ-01',
  `nama_ruangan` varchar(50) NOT NULL COMMENT 'Ex: Ruangan X TKJ-1, Lab-VoIP',
  `jenis_ruangan` enum('lab', 'kelas_teori', 'kantor', 'perpustakaan') NOT NULL,
  `mac_address_esp32` varchar(17), 
  `kapasitas` int(11) DEFAULT 30 COMMENT 'Kapasitas maksimum siswa',

  `fasilitas` text DEFAULT NULL COMMENT 'Deskripsi fasilitas dalam ruangan',
  `lokasi` varchar(100) DEFAULT NULL COMMENT 'Deskripsi posisi ruangan',
  `status` enum('aktif','nonaktif','maintenance') DEFAULT 'aktif',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
  PRIMARY KEY (`ruangan_id`),
  FOREIGN KEY (`mac_address_esp32`) REFERENCES `perangkat_esp32`(`mac_address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- --------------------------------------------------------

-- 
-- Struktur dari tabel `plotting_rombel`
-- 

CREATE TABLE `plotting_rombel` (
  `plotting_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `rombel_id` int(11) UNSIGNED NOT NULL,
  `ruangan_id` int(11) UNSIGNED NOT NULL,
  `tahun_ajaran` varchar(9) NOT NULL COMMENT 'Contoh: 2025/2026',
  `user_id` int(11) NULL,
  `jam_pulang_default` time DEFAULT '15:00:00',
  FOREIGN KEY (`rombel_id`) REFERENCES `rombel`(`rombel_id`),
  FOREIGN KEY (`ruangan_id`) REFERENCES `ruangan`(`ruangan_id`),
  FOREIGN KEY (`user_id`) REFERENCES `guru-pengawas`(`user_id`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- --------------------------------------------------------

--
-- Struktur dari tabel `rombel`
--

-- Mempermudah referensi: XII TKJ 1, XI RPL 2, dsb.
CREATE TABLE `rombel` (
  `rombel_id` int(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `tingkatan` enum('X', 'XI', 'XII', 'XIII') NOT NULL,
  `jurusan_id` int(11) UNSIGNED NOT NULL,
  `nomor_rombel` int(2) DEFAULT 1 COMMENT 'Contoh: 1 (untuk TKJ-1)',
  FOREIGN KEY (`jurusan_id`) REFERENCES `jurusan`(`jurusan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- --------------------------------------------------------

--
-- Struktur dari tabel `perangkat_esp32`
--

CREATE TABLE `perangkat_esp32` (
  `mac_address` varchar(17) PRIMARY KEY,
  `ip_address` varchar(45), 
  `versi_firmware` varchar(20),
  `status_perangkat` enum('online', 'offline', 'maintenance') DEFAULT 'online',
  `last_ping` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- --------------------------------------------------------

--
-- Struktur dari tabel `admin_activity`
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

CREATE TABLE `notifikasi_admin` (
  `notif_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `pesan` text NOT NULL,
  `ruangan_id` int(11) UNSIGNED DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`notif_id`)
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
-- 4. Tabel Presensi
--

CREATE TABLE `presensi` (
  `presensi_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `ruangan_id` int(11) UNSIGNED NOT NULL,
  `tanggal` date NOT NULL,
  `waktu_masuk` time DEFAULT NULL,
  `waktu_pulang_plan` time DEFAULT '15:00:00' COMMENT 'Waktu pulang default',
  `status` enum('hadir','terlambat','alpha','izin','sakit') DEFAULT 'alpha',
  `bukti_izin_sakit` varchar(255) DEFAULT NULL COMMENT 'Format: Sakit/Izin-YYYY-MM-DD-HHMMSS.jpg',
  `foto_scan` varchar(255) DEFAULT NULL COMMENT 'Format: NISN-YYYY-MM-DD-HHMMSS.jpg',

  -- Snapshot Fields --
  `jurusan_snapshot` varchar(50) NOT NULL COMMENT 'Nama jurusan saat absen diambil',
  `kelas_snapshot` varchar(20) NOT NULL COMMENT 'Kelas saat absen diambil',

  -- Bagian Validasi --
  `validasi` enum('valid','tidak_valid','pending') DEFAULT 'valid',
  `diverifikasi_oleh` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID admin yang verifikasi',
  `waktu_verifikasi` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`presensi_id`),
  INDEX (`tanggal`, `siswa_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- 5. Siswa Transfer Masuk
-- 

CREATE TABLE `siswa_transfer_masuk` (
  `transfer_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nisn` varchar(20) NOT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `asal_sekolah` varchar(100) DEFAULT NULL,
  `tanggal_masuk` date NOT NULL,
  `keterangan` text DEFAULT NULL,
  PRIMARY KEY (`transfer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- 6. Siswa Transfer Keluar
-- 

CREATE TABLE `siswa_transfer_keluar` (
  `transfer_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `tujuan_sekolah` varchar(100) DEFAULT NULL,
  `tanggal_keluar` date NOT NULL,
  `alasan` text DEFAULT NULL,
  PRIMARY KEY (`transfer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel ``
--



-- --------------------------------------------------------

--
-- Struktur dari tabel `sesi_ujian`
--

-- CREATE TABLE `sesi_ujian` (
--   `id` int(11) UNSIGNED NOT NULL,
--   `kode_ujian` varchar(20) NOT NULL,
--   `nama_ujian` varchar(100) NOT NULL COMMENT 'Ex: UTS Semester 1, UAS Semester 2',
--   `jurusan_id` int(11) UNSIGNED NOT NULL,
--   `ruangan_id` int(11) UNSIGNED NOT NULL,
--   `tanggal_mulai` date NOT NULL,
--   `tanggal_selesai` date NOT NULL,
--   `waktu_mulai` time NOT NULL,
--   `waktu_selesai` time NOT NULL,
--   `durasi_menit` int(11) DEFAULT 90 COMMENT 'Durasi ujian dalam menit',
--   `mata_pelajaran` varchar(100) DEFAULT NULL,
--   `pengawas_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID admin yang menjadi pengawas',
--   `keterangan` text DEFAULT NULL,
--   `status` enum('draft','aktif','selesai','dibatalkan') DEFAULT 'draft',
--   `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
--   `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
--   `created_by` int(11) UNSIGNED DEFAULT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `siswa`
--

CREATE TABLE `siswa` (
  `siswa_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nisn` varchar(20) UNIQUE NOT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `jenis_kelamin` enum('L','P') NOT NULL COMMENT 'L=Laki-laki, P=Perempuan',
  `jurusan_id` int(11) UNSIGNED NOT NULL,
  `kelas` varchar(10) NOT NULL,
  `angkatan` year(4) NOT NULL,
  `qr_vendor_link` text DEFAULT NULL COMMENT 'Link URL dari vendor (Google Form link)',
  `status` enum('aktif','lulus','keluar','mutasi') DEFAULT 'aktif',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`siswa_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Struktur dari tabel `profil_siswa`
--

CREATE TABLE `profil_siswa`(
  `profil_siswa_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `siswa_id` int(11) UNSIGNED NOT NULL,
  `tempat_lahir` varchar(50) DEFAULT NULL,
  `tanggal_lahir` date DEFAULT NULL,
  `alamat` text DEFAULT NULL,
  `no_telp` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `rombel` varchar(10) NOT NULL COMMENT 'Rombongan belajar, ex: TKJ-1, TKJ-2',
  `nama_ortu` varchar(100) DEFAULT NULL COMMENT 'Nama orang tua/wali',
  `no_telp_ortu` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`profil_siswa_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `users`
--

CREATE TABLE `users` (
  `user_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` varchar(50) UNIQUE NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin', 'guru', 'intern', 'siswa') NOT NULL,
  `ref_id` int(11) UNSIGNED DEFAULT NULL COMMENT 'ID dari tabel siswa atau guru/staff',
  `valid_until` datetime DEFAULT NULL COMMENT 'Khusus untuk role intern (akses berbatas waktu)',
  `status` enum('aktif','nonaktif') DEFAULT 'aktif',
  `last_login` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Tabel Guru & Staff (Referensi untuk users role guru/admin)
--

CREATE TABLE `guru_staff` (
  `guru_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nip` varchar(20) UNIQUE DEFAULT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `no_telp` varchar(20) DEFAULT NULL,
  `jabatan` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`guru_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
-- Struktur dari tabel 'kalender_akademik'
-- masih butuh RnD

CREATE TABLE `kalender_akademik` (
  `kalender_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tanggal` date NOT NULL,
  `keterangan` varchar(100) NOT NULL,
  `tipe` enum('libur_nasional', 'libur_sekolah', 'event_khusus') DEFAULT 'libur_sekolah',
  PRIMARY KEY (`kalender_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
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

--
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

