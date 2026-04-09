# Catatan revisi database SQL

## Sumber acuan
- `prototype-db-2.4.sql`
- `prototype-db-2.4-fixed.sql`

## Yang dipertahankan
- `jurusan`, `rombel`, `guru_staff`, `siswa`, `profil_siswa`, `ruangan`, `perangkat_esp32`, `plotting_rombel`, `presensi`, `peserta_ujian`, `konfigurasi`, `admin_activities`, `notifikasi_admin`, `user_sessions`, `kalender_akademik`
- Field snapshot seperti `jurusan_snapshot`, `kelas_snapshot`
- Field pendukung sorting/filter seperti `kelas_aktif`, `label_rombel`, `rombel` pada `profil_siswa`
- Konsep `roles`, `permissions`, `role_permissions`, `user_permissions`

## Yang diubah
- Sistem akses diperluas menjadi **hybrid**:
  - RBAC kompatibel (`roles`, `permissions`, `role_permissions`, `user_permissions`)
  - AWS-like policy layer (`policies`, `policy_permissions`, `role_policies`, `user_policies`, `groups`, dst.)
- Sistem identitas scan diganti dari RFID menjadi **QR code**:
  - tambah `qr_tokens`
  - tambah `log_scan_qr`
  - presensi terhubung ke log scan QR
- `plotting_rombel` dipertahankan, lalu ditambah `jadwal_lab` supaya jadwal tidak hanya per tahun ajaran tetapi juga per hari/jam.
- `ruangan` tidak lagi menyimpan satu `mac_address_esp32` langsung; diganti `ruangan_perangkat` agar mendukung banyak perangkat per ruangan dan histori pergantian perangkat.

## Yang digabung
- `siswa_transfer_masuk` + `siswa_transfer_keluar` -> `siswa_mutasi`
- Disediakan view:
  - `v_siswa_transfer_masuk`
  - `v_siswa_transfer_keluar`

## Yang dibetulkan dari file lama
- FK ke tabel yang tidak valid (`guru-pengawas`)
- jejak RFID (`rfid_uid`) dihapus dari model utama
- view dummy yang dulu dibuat sebagai tabel biasa, kini dibuat sebagai **VIEW** betulan
- beberapa tabel lama yang belum punya PK/AUTO_INCREMENT lengkap kini sudah dirapikan
- kolom login/session dilengkapi agar lebih aman dan mudah diaudit

## Tambahan tabel buffer dan alasan
- `ruangan_perangkat`
  - alasan: satu ruangan bisa punya beberapa ESP32/ESP32-CAM dan perangkat bisa diganti
- `jadwal_lab`
  - alasan: plotting per tahun ajaran saja tidak cukup untuk operasi harian
- `penempatan_siswa_rombel`
  - alasan: historisasi perpindahan rombel per tahun ajaran/semester

## Catatan implementasi
- File SQL disusun untuk **MySQL 8+**
- Tetap memakai `utf8mb4`
- Sudah disiapkan seed minimal roles, permissions, dan policies
