# Dokumentasi Fitur Database `sistem_absensi_lab_qr` v3.1

## 1. Ringkasan umum

Versi ini merupakan kelanjutan dari `prototype-db-3.0_documented.sql` dengan tiga fokus utama:

1. mengimplementasikan hasil analisis pada komentar yang sebelumnya masih bertanda `!` atau `?`,
2. menambahkan fitur **presensi online** berbasis unggahan bukti pembelajaran,
3. menambahkan **mekanisme pengarsipan menyeluruh** untuk foto, lampiran, log, dan metadata arsip.

File SQL hasil implementasi:
- `prototype-db-3.1_extended.sql`

---

## 2. Implementasi hasil analisis kebutuhan (bagian 1)

### 2.1 `permissions.action_name`
**Masalah sebelumnya:** masih `VARCHAR`, sehingga rawan typo dan inkonsisten.  
**Implementasi:** diubah menjadi `ENUM` agar nilai aksi terbatas dan konsisten.

Nilai yang disediakan:
- `read`
- `create`
- `update`
- `delete`
- `write`
- `scan`
- `validate`
- `assign_role`
- `generate`
- `revoke`
- `export`
- `manage`
- `submit`
- `review`
- `archive`

**Manfaat:**
- mencegah typo,
- memudahkan query/filter permission,
- menjaga konsistensi RBAC dan policy.

### 2.2 `policies.policy_type`
**Masalah sebelumnya:** komentar belum menjelaskan makna `managed` dan `inline`.  
**Implementasi:** komentar diperluas.

**Makna final:**
- `managed`: policy standar bawaan sistem, reusable, dapat ditempelkan ke banyak role/user.
- `inline`: policy khusus, menempel langsung pada role atau user tertentu, cocok untuk pengecualian atau akses temporer.

### 2.3 `profil_siswa.rombel`
**Masalah sebelumnya:** ada pertanyaan apakah field ini sebaiknya diganti referensi langsung.  
**Implementasi:** field tetap dipertahankan sebagai **field legacy/custom label**.

**Alasan dipertahankan:**
- kebutuhan sorting cepat,
- kompatibilitas ekspor lama,
- snapshot tampilan cepat,
- tidak menggantikan relasi akademik utama.

Relasi akademik utama tetap:
- `siswa.rombel_id_aktif`
- `penempatan_siswa_rombel.rombel_id`

### 2.4 `ruangan.jenis_ruangan`
**Masalah sebelumnya:** menggunakan `ENUM`, sehingga setiap penambahan jenis ruangan harus mengubah struktur SQL/kode.  
**Implementasi:** dibuat tabel master baru:

- `master_jenis_ruangan`

Field `ruangan.jenis_ruangan` diubah menjadi `VARCHAR(30)` dan direlasikan ke:
- `master_jenis_ruangan.kode_jenis_ruangan`

**Manfaat:**
- jenis ruangan baru dapat ditambah lewat data master,
- tidak perlu alter table untuk setiap jenis baru,
- lebih fleksibel untuk sekolah/lab dengan kebutuhan berbeda.

### 2.5 `presensi.plotting_id`
**Masalah sebelumnya:** dipertanyakan apakah sebaiknya `NOT NULL`.  
**Implementasi:** **tetap boleh `NULL`** dengan komentar yang diperjelas.

**Alasan dipertahankan nullable:**
- presensi manual,
- presensi susulan,
- presensi yang disinkronkan dari jalur online,
- aktivitas di luar plotting reguler.

### 2.6 `presensi.waktu_pulang_plan`
**Masalah sebelumnya:** perlu mekanisme custom.  
**Implementasi:** komentar diperjelas bahwa nilai default dapat dioverride dari:
- `plotting_rombel`,
- `jadwal_lab`,
- event khusus dari backend.

### 2.7 `presensi.status_checkout`
**Masalah sebelumnya:** sempat akan diubah ke `DEFAULT NULL`, tetapi dibatalkan.  
**Implementasi final:**
- `NOT NULL`
- default `belum_checkout`

**Alasan:**
- status awal presensi lebih eksplisit,
- memudahkan query daftar siswa yang belum scan keluar,
- tidak perlu interpretasi `NULL` sebagai status bisnis.

### 2.8 Mekanisme file pada `presensi` dan `log_scan_qr`
**Masalah sebelumnya:** komentar menandai perlunya mekanisme penyimpanan berkas.  
**Implementasi:**
- field path lama tetap dipertahankan untuk kompatibilitas,
- ditambahkan integrasi ke tabel metadata berkas.

Tambahan baru:
- `log_scan_qr.foto_capture_media_id`
- `presensi.bukti_izin_media_id`
- `presensi.foto_scan_masuk_media_id`
- `presensi.foto_scan_keluar_media_id`

Semua mengarah ke:
- `media_berkas.media_id`

**Manfaat:**
- path lama tetap bisa dipakai aplikasi lama,
- berkas kini punya metadata resmi untuk arsip, audit, dan restore.

---

## 3. Implementasi lengkap fitur presensi online (bagian 3)

### 3.1 Tujuan fitur
Fitur ini disiapkan untuk presensi online saat siswa tidak scan QR fisik, tetapi mengirim bukti ke server, misalnya:
- foto selfie saat mengikuti pembelajaran,
- screenshot Zoom,
- screenshot Google Meet,
- bukti chat WhatsApp jika pembelajaran/tugas berlangsung via WA.

### 3.2 Prinsip awal implementasi
- **server-side upload**
- **AI masih pending**
- **default verifikasi manual**
- guru/staff memutuskan hasil akhir melalui enum status yang jelas

### 3.3 Tabel baru

#### A. `presensi_online`
Tabel utama pengajuan presensi online.

Fungsi:
- mencatat satu submission presensi online,
- menyimpan mode belajar,
- menyimpan platform bukti,
- menyimpan status pengajuan,
- menyimpan status presensi final,
- menyimpan status AI,
- menyimpan verifikator dan waktu verifikasi.

Field penting:
- `submission_uuid`: ID aman untuk API/UI
- `mode_pembelajaran`: `daring_sinkron`, `daring_asinkron`, `tugas_wa`, `blended`, `lainnya`
- `platform_bukti`: `zoom`, `gmeet`, `wa`, `lms`, `upload_manual`, `lainnya`
- `status_pengajuan`: `draft`, `diajukan`, `ditinjau`, `disetujui`, `ditolak`, `perlu_perbaikan`
- `status_presensi_final`: `hadir`, `izin`, `sakit`, `tugas`, `alpha`
- `metode_verifikasi`: default `manual`
- `ai_status`: default `pending_pengembangan`

#### B. `presensi_online_lampiran`
Mencatat seluruh file bukti per submission.

Jenis bukti:
- `selfie`
- `screenshot_zoom`
- `screenshot_gmeet`
- `bukti_chat_wa`
- `dokumen_pendukung`

Setiap lampiran terhubung ke:
- `presensi_online`
- `media_berkas`

#### C. `presensi_online_verifikasi`
Riwayat review manual oleh guru/staff.

Fungsi:
- menyimpan histori keputusan verifikasi,
- menyimpan siapa yang memverifikasi,
- menyimpan catatan review manual.

Keputusan:
- `ditinjau`
- `disetujui`
- `ditolak`
- `perlu_perbaikan`

#### D. `ai_recognition_jobs`
Tabel persiapan integrasi AI lokal ringan.

Saat ini belum diwajibkan aktif, tetapi sudah disiapkan untuk:
- antrian job AI,
- tipe analisis,
- nama model,
- versi model,
- status job,
- confidence score,
- hasil ringkas JSON.

Task type:
- `face_presence`
- `screen_context`
- `chat_context`
- `multi_context`

Status default:
- `pending_pengembangan`

### 3.4 Alur bisnis presensi online

#### Tahap 1 — siswa mengirim pengajuan
1. siswa membuat submission di `presensi_online`,
2. backend membuat `submission_uuid`,
3. status awal:
   - `status_pengajuan = diajukan`
   - `status_presensi_final = hadir` (masih sementara sampai diverifikasi)
   - `metode_verifikasi = manual`
   - `ai_status = pending_pengembangan`

#### Tahap 2 — unggah bukti
1. setiap file diunggah ke storage server,
2. backend mencatat metadata file di `media_berkas`,
3. setiap file dihubungkan ke submission melalui `presensi_online_lampiran`.

#### Tahap 3 — review manual
1. guru membuka daftar pengajuan,
2. guru melihat semua lampiran,
3. guru membuat keputusan di `presensi_online_verifikasi`,
4. data utama di `presensi_online` diperbarui:
   - `status_pengajuan`
   - `status_presensi_final`
   - `catatan_verifikator`
   - `diverifikasi_oleh`
   - `waktu_verifikasi`

#### Tahap 4 — AI (future ready)
Jika AI nanti diaktifkan:
1. backend membuat record di `ai_recognition_jobs`,
2. AI membaca lampiran,
3. AI mengisi `confidence_score` dan `hasil_ringkas_json`,
4. guru tetap dapat override hasil AI melalui verifikasi manual.

### 3.5 Hak akses yang ditambahkan
Permission baru:
- `attendance.online_submit`
- `attendance.online_review`
- `media.read`
- `media.write`
- `archive.read`
- `archive.archive`
- `ai.manage`

Distribusi umum:
- `Siswa`: submit pengajuan online + lihat milik sendiri
- `Guru Pengawas`: review dan verifikasi
- `Admin Akademik`: review, verifikasi, arsip, media, AI queue
- `Intern`: hanya baca sesuai policy

---

## 4. Mekanisme pengarsipan menyeluruh

## 4.1 Jawaban inti
**Tidak lagi hanya terjadi di backend PHP saja.**

Backend PHP tetap menjadi orkestrator proses, tetapi metadata arsip sekarang dicatat di tabel khusus:
- `media_berkas`
- `arsip_batch`
- `arsip_detail`

Jadi:
- **PHP/server** menangani eksekusi fisik file dan proses periodik,
- **database** menyimpan jejak resmi, status, batch, dan histori pengarsipan.

## 4.2 Komponen pengarsipan

### A. `media_berkas`
Menyimpan metadata semua file penting:
- owner tabel
- owner id
- kategori berkas
- nama asli
- nama sistem
- mime type
- checksum
- storage disk
- storage path
- retention days
- archive status
- archived at

Ini menjadi **pusat metadata file** untuk:
- foto scan QR,
- bukti izin/sakit,
- foto selfie,
- screenshot Zoom/GMeet,
- bukti chat WA,
- dokumen pendukung lain.

### B. `arsip_batch`
Mencatat satu sesi proses arsip untuk suatu periode.

Contoh:
- arsip semester ganjil 2026
- arsip log scan Januari–Maret
- arsip media presensi online 180 hari

### C. `arsip_detail`
Mencatat item satu per satu di dalam batch arsip:
- tabel sumber
- primary key sumber
- media terkait
- path asal
- path arsip
- checksum
- status
- archived_at
- restored_at

## 4.3 Objek yang bisa diarsipkan

### Presensi QR/offline
- tabel bisnis: `presensi`
- lampiran: `bukti_izin_sakit`, `foto_scan_masuk`, `foto_scan_keluar`
- metadata lampiran: `media_berkas`

### Log scan QR
- tabel bisnis: `log_scan_qr`
- lampiran: `foto_capture`
- metadata lampiran: `media_berkas`

### Presensi online
- tabel bisnis: `presensi_online`
- lampiran: `presensi_online_lampiran`
- file bukti: selfie, screenshot, bukti chat
- metadata lampiran: `media_berkas`

### Audit dan log administratif
- `admin_activities`
- `user_sessions`
- batch ekspor atau cold storage jika retention period tercapai

## 4.4 Mekanisme kerja pengarsipan per periode

### Langkah 1 — tentukan periode
Contoh:
- per bulan
- per semester
- per tahun
- setelah `retention_days` terpenuhi

### Langkah 2 — buat batch arsip
Backend membuat record di `arsip_batch`, misalnya:
- `nama_batch = arsip_presensi_semester_genap_2026`
- `periode_mulai = 2026-01-01`
- `periode_selesai = 2026-06-30`

### Langkah 3 — pilih data kandidat
Backend menyeleksi data berdasarkan:
- `presensi.tanggal`
- `log_scan_qr.scanned_at`
- `presensi_online.tanggal_presensi`
- `media_berkas.retention_days`
- `media_berkas.archive_status`

### Langkah 4 — catat detail item
Setiap data/file yang masuk batch dicatat di `arsip_detail`.

Jika ada file:
- `media_id` diisi
- `path_sumber` diisi
- `path_arsip` diisi setelah dipindahkan

### Langkah 5 — pindahkan file
Backend memindahkan file dari storage aktif ke:
- object storage,
- cold storage,
- folder arsip,
- zip export.

Sesudah berhasil:
- `media_berkas.archive_status = diarsipkan`
- `media_berkas.archived_at` diisi
- `media_berkas.storage_path` dapat diperbarui bila lokasi berubah

### Langkah 6 — perlakuan terhadap row data
Ada dua strategi yang dapat dipilih:
1. **soft archive**
   - row utama tetap di tabel aktif,
   - file/lampiran dipindahkan ke storage arsip,
   - metadata arsip tetap dilacak.

2. **hard archive**
   - data diekspor ke database/file arsip khusus,
   - item dicatat di `arsip_detail`,
   - row aktif dapat dihapus atau dipertahankan sesuai kebijakan.

Struktur saat ini mendukung kedua pendekatan, tetapi lebih aman memulai dari **soft archive**.

### Langkah 7 — restore bila dibutuhkan
Jika ada audit atau kebutuhan sengketa:
1. cari batch di `arsip_batch`,
2. cari item di `arsip_detail`,
3. ambil lokasi file dari `path_arsip`,
4. pulihkan file ke storage aktif,
5. update:
   - `arsip_detail.status = dipulihkan`
   - `arsip_detail.restored_at`
   - `media_berkas.archive_status = dipulihkan`

## 4.5 Kesimpulan arsitektur arsip
Dengan skema baru:
- pengarsipan **bukan hanya urusan PHP**,
- database ikut menyimpan metadata, status, dan histori batch,
- file tetap dipindah oleh backend,
- tetapi jejak prosesnya tetap terdokumentasi secara formal di database.

---

## 5. Dokumentasi fitur-fitur database

## 5.1 IAM / akses kontrol
Tabel:
- `roles`
- `permissions`
- `policies`
- `policy_permissions`
- `role_permissions`
- `groups`
- `user_roles`
- `user_permissions`
- `role_policies`
- `user_policies`
- `group_users`
- `group_roles`
- `group_policies`
- `user_sessions`

Fungsi:
- RBAC kompatibel dengan desain lama,
- policy-based access ala AWS-like,
- dukungan group-based access,
- akses temporer seperti intern,
- override per user,
- audit sesi login.

## 5.2 Master akademik dan identitas
Tabel:
- `jurusan`
- `rombel`
- `guru_staff`
- `siswa`
- `profil_siswa`
- `siswa_mutasi`
- `penempatan_siswa_rombel`

Fungsi:
- master identitas siswa/guru,
- histori mutasi,
- penempatan siswa per rombel, tahun ajaran, semester,
- snapshot cepat untuk filter dan sorting.

## 5.3 Ruangan, perangkat, plotting, dan jadwal
Tabel:
- `master_jenis_ruangan`
- `ruangan`
- `perangkat_esp32`
- `ruangan_perangkat`
- `plotting_rombel`
- `jadwal_lab`

Fungsi:
- master ruangan fleksibel,
- relasi multi-perangkat per ruangan,
- histori penempatan perangkat,
- plotting rombel ke ruangan,
- jadwal lab detail per hari/jam.

## 5.4 QR token dan log scan
Tabel:
- `qr_tokens`
- `log_scan_qr`

Fungsi:
- menyimpan identitas dan histori token QR,
- mendukung QR vendor dinamis,
- menyimpan hash payload,
- menyimpan log scan lengkap,
- mendukung check-in, check-out, manual override.

## 5.5 Presensi offline / QR
Tabel:
- `presensi`

Fungsi:
- rekap presensi utama berbasis QR/manual,
- menyimpan waktu masuk/keluar,
- menyimpan status hadir/izin/sakit/alpha,
- menyimpan snapshot kelas/jurusan/rombel,
- menyimpan validasi,
- menyimpan relasi ke log scan,
- menyimpan relasi ke metadata file.

## 5.6 Presensi online
Tabel:
- `presensi_online`
- `presensi_online_lampiran`
- `presensi_online_verifikasi`
- `ai_recognition_jobs`

Fungsi:
- pengajuan presensi online server-side,
- lampiran selfie/screenshot/chat,
- review manual oleh guru,
- persiapan AI recognition lokal ringan.

## 5.7 Media dan arsip
Tabel:
- `media_berkas`
- `arsip_batch`
- `arsip_detail`

Fungsi:
- pusat metadata berkas,
- retention policy,
- status arsip file,
- batch pengarsipan,
- restore dan audit arsip.

## 5.8 Ujian
Tabel:
- `sesi_ujian`
- `peserta_ujian`

Fungsi:
- sesi ujian per ruangan/jurusan,
- peserta dan status kehadiran,
- dukungan nilai dan pengawas.

## 5.9 Konfigurasi, log, notifikasi, kalender
Tabel:
- `konfigurasi`
- `admin_activities`
- `notifikasi_admin`
- `kalender_akademik`

Fungsi:
- parameter sistem,
- audit aktivitas admin,
- notifikasi operasional,
- kalender akademik.

## 5.10 Views
View:
- `v_siswa_transfer_masuk`
- `v_siswa_transfer_keluar`
- `v_log_scan_qr_detail`
- `v_presensi_detail`
- `v_rekap_harian`
- `v_presensi_online_detail`
- `v_media_arsip_status`

Fungsi:
- memudahkan laporan,
- memudahkan rekap operasional,
- mempermudah monitoring submission online dan status arsip file.

---

## 6. Catatan implementasi backend

### 6.1 Apa yang tetap dikerjakan backend PHP
Backend/server tetap mengerjakan:
- upload file,
- validasi MIME/ukuran,
- rename file sistem,
- hitung checksum,
- penempatan path ke storage,
- pembuatan batch arsip,
- pemindahan file ke cold storage/object storage,
- restore file dari arsip,
- sinkronisasi status ke DB.

### 6.2 Apa yang kini dicatat oleh database
Database kini menyimpan:
- metadata berkas lengkap,
- relasi file ke entitas bisnis,
- retention policy,
- batch arsip,
- detail item arsip,
- status AI job,
- riwayat verifikasi presensi online.

---

## 7. Hasil akhir implementasi

Yang sudah terimplementasi di SQL:
1. resolusi komentar analisis yang bertanda `!/?`,
2. master jenis ruangan fleksibel,
3. metadata file terpusat,
4. arsip batch dan arsip detail,
5. pengaitan file presensi lama ke metadata resmi,
6. presensi online lengkap,
7. tabel persiapan AI lokal ringan,
8. seed permission tambahan,
9. view tambahan untuk presensi online dan status arsip.

