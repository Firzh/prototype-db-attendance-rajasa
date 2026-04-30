# Proto DB 3.5 changes” Daftar Penambahan dan Perubahan

Basis file: `prototype-db-3.4(3).sql`  
Output baru: `proto-db-3.5.sql`

## 1. Penambahan tabel `rombel_wali_kelas`

Tujuan: memisahkan relasi wali kelas resmi dari `plotting_rombel.user_id`.

Desain relasi:

- `rombel_wali_kelas.rombel_id` mengarah ke `rombel.rombel_id`.
- `rombel_wali_kelas.guru_id` mengarah ke `guru_staff.guru_id`.
- `tahun_ajaran` dan `semester` disimpan agar histori wali kelas tidak tertimpa.
- `aktif_unique_key` dibuat sebagai generated column agar hanya ada satu wali kelas aktif untuk satu rombel pada tahun ajaran dan semester yang sama.

Catatan desain:

- `plotting_rombel.user_id` tetap dipakai sebagai penanggung jawab operasional/PIC ruangan.
- Wali kelas tidak diletakkan di `plotting_rombel` karena wali kelas melekat pada rombel dan periode akademik, bukan pada ruangan.

## 2. Penambahan tabel import wizard

Tabel baru:

1. `import_jobs`
2. `import_column_mappings`
3. `import_row_logs`

Tujuan: mendukung alur import data operator/admin:

1. Upload file Excel/CSV.
2. Deteksi jenis import.
3. Mapping kolom.
4. Preview data.
5. Validasi otomatis.
6. Tampilkan error.
7. Eksekusi import.
8. Tampilkan ringkasan hasil.

Jenis import yang didukung:

- `master_siswa`
- `siswa_penempatan_rombel`
- `update_penempatan_rombel`
- `nilai_akademik`

Catatan desain:

- `import_jobs` menyimpan status proses import, parser, file, periode akademik, jumlah baris valid/error, dan ringkasan hasil.
- `import_column_mappings` menyimpan hasil pencocokan kolom file dengan field sistem.
- `import_row_logs` menyimpan log validasi per baris, termasuk error seperti NISN kosong, kode jurusan tidak ditemukan, atau nomor absen dobel.
- Parser backend default disiapkan melalui konfigurasi `import.default_backend_parser = openspout`.

## 3. Penambahan validasi nomor absen aktif

Perubahan pada tabel `penempatan_siswa_rombel`:

- Menambahkan generated column `aktif_absen_key`.
- Menambahkan unique key `uk_penempatan_no_absen_aktif`.

Tujuan: mencegah nomor absen aktif dobel pada rombel, tahun ajaran, dan semester yang sama.

Catatan:

- `no_absen` tetap boleh `NULL`.
- Validasi ini hanya mengunci data aktif (`is_aktif = 1`).

## 4. Penambahan model notifikasi generik

Tabel baru:

1. `notification_rules`
2. `notifikasi`
3. `notifikasi_penerima`
4. `user_notification_preferences`

Model ini dipilih sebagai gabungan terbaik dari catatan grandeur karena memisahkan:

- aturan global notifikasi,
- event/masalah yang terjadi,
- penerima notifikasi,
- preferensi pribadi user.

### `notification_rules`

Menyimpan aturan global, misalnya:

- event `plotting_incomplete`,
- modul `academic`,
- permission minimal `academic.write`,
- target role `admin_akademik`,
- frekuensi `daily`,
- level default `warning`.

### `notifikasi`

Menyimpan event/masalah aktual.

Field penting:

- `event_key`
- `module_name`
- `entity_type`
- `entity_id`
- `dedupe_key`
- `level_notif`
- `required_perm_slug`
- `target_role_slug`
- `is_resolved`
- `resolved_at`

Catatan penting:

- `is_resolved` berbeda dari `is_read`.
- `is_resolved` berarti masalah selesai.
- `dedupe_key` + `open_unique_key` mencegah spam notifikasi open untuk masalah yang sama.

### `notifikasi_penerima`

Menyimpan penerima per user.

Field penting:

- `notif_id`
- `user_id`
- `delivery_channel`
- `is_read`
- `read_at`
- `delivered_at`

Catatan penting:

- `is_read` hanya berarti user sudah membaca.
- Status selesai tetap ada di `notifikasi.is_resolved`.

### `user_notification_preferences`

Menyimpan preferensi pribadi user.

Contoh:

- popup aktif/nonaktif,
- inbox aktif/nonaktif,
- email aktif/nonaktif,
- frekuensi instant/daily/weekly/off,
- mute event tertentu.

Catatan:

- Notifikasi critical tetap dikontrol oleh `notification_rules.is_critical_locked`.
- User biasa tidak seharusnya bisa mematikan notifikasi critical.

## 5. Seed notification rules default

Rule default yang ditambahkan:

- `plotting_incomplete`
- `room_class_slot_full`
- `student_without_rombel`
- `student_import_partial_failed`
- `grade_import_partial_failed`
- `attendance_online_pending_review`
- `system_storage_critical`

Tujuan: notifikasi operasional dikirim berdasarkan event dan permission, bukan sekadar broadcast ke semua user.

## 6. Penambahan konfigurasi default

Konfigurasi baru:

- `academic.tahun_ajaran_aktif`
- `academic.semester_aktif`
- `module.exams.enabled`
- `import.default_backend_parser`
- `plotting.max_rombel_per_ruang_kelas`

Catatan:

- `module.exams.enabled` diset `false` karena modul ujian sementara nonaktif.
- Tabel `sesi_ujian` dan `peserta_ujian` tetap dipertahankan untuk pengembangan berikutnya.

## 7. Penambahan permission import dan nilai

Permission baru:

- `import.read`
- `import.write`
- `grades.read`
- `grades.write`

Policy yang diperbarui:

- `academic_admin_access` mendapat akses import dan nilai.
- `teacher_supervisor_access` mendapat akses baca nilai.

## 8. Stored procedure `sp_upsert_jurusan_ruangan_buffer`

Tujuan: membantu backend mengisi `jurusan_ruangan_buffer` saat ruangan dibuat atau dimapping.

Fungsi:

- mengambil `kode_jurusan`,
- menentukan prefix nama ruangan (`Kelas`, `Lab`, `Kantor`),
- menentukan `urut_auto`,
- membuat `nama_ruangan` otomatis,
- insert/update buffer mapping jurusan-ruangan.

Catatan:

- `jurusan_ruangan_buffer` tetap dipertahankan karena masih menyimpan relasi tampilan jurusan-ruangan.
- Tabel ini belum dihapus karena `ruangan` belum memiliki `nama_ruangan`, `jenis_ruangan`, dan `jurusan_id` secara langsung.

## 9. Trigger validasi maksimal 2 rombel per ruang kelas

Trigger baru:

- `trg_plotting_rombel_bi_max2_kelas`
- `trg_plotting_rombel_bu_max2_kelas`

Tujuan:

- mencegah satu ruangan jenis `kelas` dipakai lebih dari 2 rombel aktif pada tahun ajaran dan semester yang sama.

Pesan validasi:

> Ruangan ini sudah dipakai oleh 2 rombel pada semester ini. Pilih ruangan lain atau nonaktifkan salah satu plotting.

Catatan:

- Validasi hanya aktif untuk ruangan yang diidentifikasi sebagai `jenis_ruangan = kelas` pada `jurusan_ruangan_buffer`.
- Kloter tidak disimpan sebagai field baru. Kloter dihitung otomatis melalui view.

## 10. View baru untuk UI/dashboard

View baru:

1. `v_rombel_wali_kelas_aktif`
2. `v_plotting_rombel_kloter`
3. `v_rombel_plotting_status_aktif`
4. `v_dashboard_plotting_rombel`
5. `v_notifikasi_inbox`
6. `v_import_jobs_ringkas`

### `v_rombel_wali_kelas_aktif`

Menampilkan rombel, jurusan, guru wali kelas, tahun ajaran, semester, dan status aktif.

### `v_plotting_rombel_kloter`

Menghitung kloter otomatis untuk ruangan jenis kelas menggunakan urutan plotting aktif.

### `v_rombel_plotting_status_aktif`

Menampilkan status apakah setiap rombel aktif sudah diplotting pada tahun ajaran dan semester aktif.

### `v_dashboard_plotting_rombel`

Menghasilkan ringkasan dashboard:

- total rombel aktif,
- total sudah diplotting,
- total belum diplotting,
- persentase plotting.

### `v_notifikasi_inbox`

Menampilkan inbox notifikasi per user dengan status baca dan status selesai.

### `v_import_jobs_ringkas`

Menampilkan ringkasan proses import untuk halaman admin/operator.

## 11. Catatan implementasi backend

Beberapa validasi tetap harus ditangani di backend walaupun struktur DB sudah disiapkan:

- auto-generate `import_code`,
- deteksi jenis import dan confidence,
- mapping kolom berdasarkan alias header,
- validasi NISN, NIS, jenis kelamin, kode jurusan, rombel, dan no absen,
- update cache `siswa.jurusan_id_aktif`, `siswa.rombel_id_aktif`, dan `siswa.kelas_aktif`,
- pencarian user penerima notifikasi berdasarkan permission efektif,
- resolve otomatis notifikasi yang kondisinya sudah selesai.

## 12. Catatan risiko

- `notifikasi_admin` masih dipertahankan sebagai legacy. Modul baru sebaiknya mulai memakai `notifikasi`, `notifikasi_penerima`, dan `notification_rules`.
- Trigger maksimal 2 rombel bergantung pada data `jurusan_ruangan_buffer`. Jika mapping ruangan belum dibuat, trigger tidak bisa mengetahui apakah ruangan tersebut jenis kelas.
- `academic.tahun_ajaran_aktif` harus diisi oleh admin agar view dashboard plotting aktif dapat bekerja optimal.
