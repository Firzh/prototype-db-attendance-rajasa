# README DB 3.8 - Presensi Lab Rajasa

Tanggal: 2026-05-11  
Versi: `prototype-db-3.8`

## 1. Ringkasan

DB 3.8 adalah revisi dari DB 3.7 untuk menyesuaikan sistem dengan batasan data nyata dari mitra. Mitra hanya menyediakan data siswa minimal: `NO`, `NISN`, `NAMA`, dan `KELAS`.

Keputusan paling penting:

```text
Input mitra  : 10 AKL
Internal DB  : tingkatan=X, tingkat_angka=10, jurusan=AKL, nomor_rombel=1
Tampilan UI  : 10 AKL
Bukan        : 10 AKL 1
```

## 2. Kapan memakai file ini?

### Fresh install

Gunakan:

```bash
mysql -u root -p < prototype-db-3.8.sql
```

### Upgrade dari DB 3.7

Gunakan:

```bash
mysql -u root -p sistem_absensi_lab_qr < prototype-db-3.7-to-3.8-migration.sql
```

Sebelum upgrade, lakukan backup:

```bash
mysqldump -u root -p sistem_absensi_lab_qr > backup-before-db38.sql
```

## 3. Urutan penerapan yang disarankan

1. Backup database.
2. Jalankan migration `prototype-db-3.7-to-3.8-migration.sql`.
3. Jalankan validasi tabel `siswa`, `rombel`, `import_jobs`, `import_row_logs`, `scanner_sessions`, dan `presensi`.
4. Update backend parser `KELAS`.
5. Update frontend agar mengambil `display_label` rombel.
6. Uji import file contoh mitra.
7. Uji sesi scanner tanpa ruangan tetap.

## 4. Validasi setelah migration

### 4.1 Cek kolom siswa nullable

```sql
SHOW COLUMNS FROM siswa LIKE 'jenis_kelamin';
SHOW COLUMNS FROM siswa LIKE 'angkatan';
```

Expected: kolom dapat `NULL`.

### 4.2 Cek rombel display

```sql
SELECT * FROM v_rombel_display ORDER BY tingkat_angka, kode_jurusan, nomor_rombel;
```

Expected: rombel tunggal hasil `10 AKL` tampil sebagai `10 AKL`, bukan `10 AKL 1`.

### 4.3 Cek kontrak import

```sql
SHOW COLUMNS FROM import_jobs LIKE 'use_no_as_absen';
SHOW COLUMNS FROM import_row_logs LIKE 'source_kelas';
```

Expected: kolom tersedia.

### 4.4 Cek lokasi fleksibel

```sql
SHOW COLUMNS FROM scanner_sessions LIKE 'lokasi_mode';
SHOW COLUMNS FROM presensi LIKE 'lokasi_mode';
```

Expected: kolom tersedia dengan default `tidak_dicatat`.

### 4.5 Cek unique anti double scan per sesi

```sql
SHOW INDEX FROM presensi WHERE Key_name = 'uk_presensi_session_siswa';
```

Expected: unique key tersedia pada `scanner_session_id, siswa_id`.

## 5. Kontrak data import MVP

File mitra minimal:

| NO | NISN | NAMA | KELAS |
|---:|---|---|---|
| 1 | 0096672112 | AISYAH LISTYA NARISTA | 10 AKL |
| 2 | 0106325606 | AISYAH NUR AMALINA | 10 AKL |

Aturan:

1. `NISN` wajib string.
2. `NAMA` wajib.
3. `KELAS` wajib dan diparse.
4. `NO` default hanya nomor urut sumber.
5. `NO` tidak masuk `no_absen` kecuali admin memilih `use_no_as_absen = 1`.
6. `jenis_kelamin` dan `angkatan` boleh kosong.

## 6. Aturan parser kelas

Backend harus membaca format:

```text
^(10|11|12|13)\s+([A-Z0-9]+)(?:\s+(\d+))?$
```

Mapping:

| Angka | `tingkatan` |
|---:|---|
| 10 | X |
| 11 | XI |
| 12 | XII |
| 13 | XIII |

Jika nomor rombel tidak ada, sistem mengisi `nomor_rombel = 1`, `is_nomor_rombel_inferred = 1`, dan `display_mode = 'tanpa_nomor'`.

## 7. Alur sesi scanner DB 3.8

1. Guru/operator memilih rombel, contoh `10 AKL`.
2. Guru/operator memilih lokasi:
   - `tidak_dicatat`;
   - `master_ruangan`;
   - `input_manual`;
   - `fleksibel`.
3. Backend membuat `scanner_sessions`.
4. Backend mengisi snapshot rombel dan lokasi.
5. Scan siswa menghasilkan `log_scan_qr` dan `presensi`.
6. Anti double scan dijaga oleh `uk_presensi_session_siswa`.

## 8. Rollback

Rollback tersedia di:

```bash
mysql -u root -p sistem_absensi_lab_qr < prototype-db-3.8-rollback.sql
```

Catatan penting: rollback ke DB 3.7 dapat gagal jika sudah ada `NULL` pada `siswa.jenis_kelamin` atau `siswa.angkatan`. Jangan mengisi nilai palsu hanya untuk memaksa rollback.

## 9. Checklist sebelum masuk BE

- [ ] Migration DB 3.8 berhasil.
- [ ] `AKL` tersedia pada tabel `jurusan`.
- [ ] `v_rombel_display` menghasilkan `10 AKL`.
- [ ] `import_row_logs` bisa menyimpan `source_no`, `source_nisn`, `source_nama`, dan `source_kelas`.
- [ ] `scanner_sessions.lokasi_mode` tersedia.
- [ ] `presensi.ruangan_id` boleh NULL.
- [ ] `uk_presensi_session_siswa` tersedia.

## 10. Catatan implementasi

DB 3.8 tidak menghapus tabel kompleks dari DB 3.7. Fitur notifikasi, presensi online, arsip, media, policy, dan role tetap dipertahankan sebagai roadmap. MVP hanya mengaktifkan area import siswa, rombel, sesi scanner, dan rekap presensi berbasis sesi.
