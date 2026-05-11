# Analisis Pemotongan Modular DB Rajasa 3.8 MVP

Tanggal: 2026-05-11  
Basis: `prototype-db-3.8.sql`  
Output: `3.8-mvp-modular`

## 1. Keputusan pemotongan

Paket ini memakai strategi **modularisasi + penghapusan future development**. DB tidak dipangkas secara buta, tetapi dipecah menjadi modul agar implementasi lokal bisa dimulai dari bagian MVP tanpa membawa fitur yang belum diperlukan.

Future development yang dihapus dari paket ini:

| Area | Keputusan | Detail teknis |
|---|---|---|
| AI recognition | Dihapus | Tabel `ai_recognition_jobs` dihapus. Kolom/opsi AI pada `presensi_online` juga diturunkan menjadi verifikasi manual saja. |
| Ujian | Dihapus | Tabel `sesi_ujian` dan `peserta_ujian` dihapus. Permission `exams.*` dan konfigurasi `module.exams.enabled` tidak disertakan. |
| Nilai | Dihapus | Tabel `mata_pelajaran` dan `nilai_akademik` dihapus. Permission `grades.*`, import type `nilai_akademik`, dan view nilai tidak disertakan. |
| Notifikasi WhatsApp/email | Dihapus dari notifikasi | Channel notifikasi hanya `in_app` dan `system`. Kolom `email_enabled`, `whatsapp_enabled`, `default_email_enabled`, dan `default_whatsapp_enabled` tidak disertakan. |

## 2. Modul SQL

| Urutan | File | Isi |
|---:|---|---|
| 000 | `000_database_and_version.sql` | Database dan `schema_versions`. |
| 001 | `001_access_base.sql` | Role, permission, policy, group dasar. |
| 002 | `002_academic_identity.sql` | Jurusan, rombel, siswa, profil, mutasi, penempatan, wali kelas. |
| 003 | `003_users_access_runtime.sql` | User, role user, policy user, group user, session, access token. |
| 004 | `004_facility_schedule_scanner.sql` | Jenis ruangan, ruangan, perangkat, plotting, jadwal, scanner device/session. |
| 005 | `005_files_archive_audit.sql` | Media, arsip, cold archive, user activities. |
| 006 | `006_attendance_qr_online.sql` | QR token, log scan, presensi, presensi online manual. |
| 007 | `007_support_config_buffers.sql` | Konfigurasi, buffer/cache, kalender, notifikasi admin legacy. |
| 008 | `008_import_wizard.sql` | Import jobs, column mapping, row logs untuk data mitra minimal. |
| 009 | `009_notification_lite.sql` | Notifikasi in-app/system tanpa email/WhatsApp. |
| 010 | `010_seed_minimal_mvp.sql` | Seed role, permission, policy, konfigurasi, jurusan AKL, rule notifikasi lite. |
| 011 | `011_views_mvp.sql` | View MVP: rombel display, import rows, rekap sesi, notifikasi. |
| 999 | `999_install_all.sql` | Installer berbasis `SOURCE`. |

## 3. Keputusan khusus yang dikunci

### 3.1 Rombel

Input mitra `10 AKL` diputuskan sebagai satu rombel tunggal. Sistem boleh menyimpan `nomor_rombel = 1` untuk kebutuhan internal, tetapi UI tetap menampilkan `10 AKL`, bukan `10 AKL 1`.

Kolom pendukung:

- `rombel.tingkat_angka` untuk angka `10`, `11`, `12`, atau `13`;
- `rombel.is_nomor_rombel_inferred` untuk menandai nomor internal hasil asumsi;
- `rombel.label_rombel` untuk tampilan familiar guru;
- `rombel.label_rombel_raw` untuk nilai mentah dari file;
- `rombel.display_mode` dengan default `tanpa_nomor`.

### 3.2 Import data mitra

Import difokuskan pada kontrak `NO`, `NISN`, `NAMA`, dan `KELAS`. Nilai `NO` tidak otomatis menjadi nomor absen.

Kolom pendukung:

- `import_jobs.source_contract_version`;
- `import_jobs.use_no_as_absen`;
- `import_jobs.kelas_display_mode`;
- `import_row_logs.source_no`;
- `import_row_logs.source_nisn`;
- `import_row_logs.source_nama`;
- `import_row_logs.source_kelas`;
- `import_row_logs.normalized_rombel_label`.

### 3.3 Ruangan fleksibel

Presensi tidak lagi wajib bergantung pada mapping permanen rombel ke ruangan. `scanner_sessions` dan `presensi` mendukung mode lokasi:

- `master_ruangan`;
- `input_manual`;
- `tidak_dicatat`;
- `fleksibel`.

Tambahan koreksi pada paket modular: `log_scan_qr.ruangan_id` dibuat nullable karena scan web berbasis sesi dapat berjalan dengan `lokasi_mode = tidak_dicatat`.

## 4. Pemeriksaan 3x

### Pemeriksaan 1 — Ketepatan pemotongan modul

Hasil:

- Total tabel yang dibuat paket modular: **61**.
- Tabel future development yang wajib dihapus dan tidak muncul sebagai `CREATE TABLE`: `ai_recognition_jobs, mata_pelajaran, nilai_akademik, peserta_ujian, sesi_ujian`.
- Tabel future development yang masih muncul: `Tidak ada`.

### Pemeriksaan 2 — Ketepatan foreign key

Hasil static FK parser:

```json
[]
```

Interpretasi: daftar kosong berarti seluruh `REFERENCES` pada tabel yang dibuat masih mengarah ke tabel yang ikut dibuat dalam paket modular.

Perbaikan khusus yang diterapkan:

- `presensi.scanner_session_id` diberi index `idx_presensi_scanner_session` sebelum foreign key `fk_presensi_scanner_session`.
- `presensi` tetap memiliki unique per sesi melalui `uk_presensi_session_siswa`.
- `log_scan_qr.ruangan_id` dibuat nullable dan FK-nya memakai `ON DELETE SET NULL` agar mode lokasi fleksibel tidak bentrok dengan scan tanpa ruangan tetap.

### Pemeriksaan 3 — Ketepatan penghapusan future development

Hasil pencarian token future development:

```json
{
  "ai_recognition_jobs": false,
  "sesi_ujian": false,
  "peserta_ujian": false,
  "nilai_akademik": false,
  "mata_pelajaran": false,
  "grades_permission": false,
  "exams_permission": false,
  "ai_manage_permission": false,
  "notification_whatsapp": true,
  "notification_email_enabled": false
}
```

Interpretasi:

- Semua nama tabel future development harus bernilai `false`.
- `notification_whatsapp` dan `notification_email_enabled` harus bernilai `false`.
- Field email umum pada profil/guru tidak dihapus karena itu data identitas kontak, bukan channel notifikasi.

## 5. Cara import lokal

Letakkan folder ini ke repo sebagai:

```text
database/3.8-mvp-modular/
```

Reset database sesuai environment container:

```bash
docker compose exec db sh -lc 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS \`$MYSQL_DATABASE\`; CREATE DATABASE \`$MYSQL_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"'
```

Import semua modul satu per satu:

```bash
for f in database/3.8-mvp-modular/modules/[0-9][0-9][0-9]_*.sql; do
  echo "==> $f"
  docker compose exec -T db sh -lc 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < "$f"
done
```

Atau gunakan installer `999_install_all.sql` jika path `SOURCE` cocok di environment lokal.

## 6. Catatan implementasi

Paket ini bukan Prisma migration. Paket ini adalah **SQL modular MVP** agar database tidak terasa terlalu besar saat implementasi awal. Setelah modul ini stabil, backend dapat bergerak ke import siswa, parser `KELAS`, dan presensi berbasis `scanner_session`.


## 7. Hasil pemeriksaan akhir setelah sanitasi SQL

```json
{
  "total_tables_created": 61,
  "removed_tables_still_present": [],
  "removed_tables_absent": [
    "ai_recognition_jobs",
    "mata_pelajaran",
    "nilai_akademik",
    "peserta_ujian",
    "sesi_ujian"
  ],
  "fk_errors": [],
  "future_tokens_sql": {
    "ai_recognition_jobs": false,
    "sesi_ujian": false,
    "peserta_ujian": false,
    "nilai_akademik": false,
    "mata_pelajaran": false,
    "grades_permission": false,
    "exams_permission": false,
    "ai_manage_permission": false,
    "notification_whatsapp": false,
    "notification_email_enabled": false
  },
  "presensi_scanner_session_index_present": true,
  "presensi_session_unique_present": true,
  "log_scan_ruangan_nullable": true,
  "notification_channels_lite": true,
  "import_jobs_no_nilai_enum": true
}
```

Catatan: dokumen analisis boleh menyebut istilah yang dihapus untuk keperluan audit. Pemeriksaan token di atas dilakukan pada file SQL modul, bukan pada narasi dokumentasi.
